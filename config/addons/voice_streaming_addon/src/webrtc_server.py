import asyncio
import io
import json
import logging
import uuid
from typing import Dict, Optional

import numpy as np
from aiohttp import WSMsgType, web
from aiohttp.web_ws import WebSocketResponse
from aiortc import (
    MediaStreamTrack,
    RTCIceCandidate,
    RTCPeerConnection,
    RTCSessionDescription,
)
from aiortc.contrib.media import MediaRelay
from pydub import AudioSegment

logger = logging.getLogger(__name__)


class MP3StreamTrack(MediaStreamTrack):
    """Track that buffers audio for MP3 streaming"""

    kind = "audio"

    def __init__(self, source_track):
        super().__init__()
        self.source_track = source_track
        self.buffer = asyncio.Queue(maxsize=100)
        self._task = asyncio.create_task(self._relay_frames())

    async def _relay_frames(self):
        """Relay frames from source to buffer"""
        try:
            while True:
                frame = await self.source_track.recv()
                if not self.buffer.full():
                    await self.buffer.put(frame)
        except Exception as e:
            logger.error(f"Frame relay error: {e}")

    async def recv(self):
        """Receive frame from buffer"""
        return await self.buffer.get()

    def stop(self):
        """Stop relaying"""
        if self._task:
            self._task.cancel()


class VoiceStreamingServer:
    def __init__(self):
        self.app = web.Application()
        self.setup_routes()

        # Connection management
        self.senders: Dict[str, dict] = {}  # sender_id → {ws, pc, track, stream_id}
        self.receivers: Dict[str, dict] = {}  # receiver_id → {ws, pc, stream_id}
        self.active_streams: Dict[str, MediaStreamTrack] = {}  # stream_id → audio_track

        # MP3 streaming
        self.mp3_buffers: Dict[str, bytearray] = {}  # stream_id → MP3 data
        self.relay = MediaRelay()

    def setup_routes(self):
        self.app.router.add_get("/health", self.health_check)
        self.app.router.add_get("/ws", self.websocket_handler)
        self.app.router.add_get("/stream/{stream_id}.mp3", self.stream_mp3)
        self.app.router.add_get("/stream/latest.mp3", self.stream_latest_mp3)

    async def health_check(self, request):
        active_streams = list(self.active_streams.keys())
        return web.json_response(
            {
                "status": "healthy",
                "active_streams": active_streams,
                "senders": len(self.senders),
                "receivers": len(self.receivers),
            }
        )

    async def websocket_handler(self, request):
        ws = web.WebSocketResponse()
        await ws.prepare(request)

        connection_id = str(uuid.uuid4())
        logger.info(f"New WebSocket connection: {connection_id}")

        try:
            async for msg in ws:
                if msg.type == WSMsgType.TEXT:
                    data = json.loads(msg.data)
                    await self.handle_message(connection_id, ws, data)
                elif msg.type == WSMsgType.ERROR:
                    logger.error(f"WebSocket error: {ws.exception()}")

        except Exception as e:
            logger.error(f"WebSocket connection error: {e}")
        finally:
            await self.cleanup_connection(connection_id)

        return ws

    async def handle_message(
        self, connection_id: str, ws: WebSocketResponse, data: dict
    ):
        message_type = data.get("type")

        if message_type == "start_sending":
            await self.setup_sender(connection_id, ws)
        elif message_type == "start_receiving":
            stream_id = data.get("stream_id")
            await self.setup_receiver(connection_id, ws, stream_id)
        elif message_type == "stop_stream":
            await self.stop_stream(connection_id)
        elif message_type == "get_available_streams":
            await self.send_available_streams(ws)
        elif message_type == "webrtc_offer":
            await self.handle_webrtc_offer(connection_id, data)
        elif message_type == "webrtc_answer":
            await self.handle_webrtc_answer(connection_id, data)
        elif message_type == "ice_candidate":
            await self.handle_ice_candidate(connection_id, data)

    async def setup_sender(self, connection_id: str, ws: WebSocketResponse):
        """Setup a sender connection"""
        logger.info(f"Setting up sender for connection {connection_id}")

        pc = RTCPeerConnection()
        stream_id = f"stream_{connection_id}"

        self.senders[connection_id] = {
            "ws": ws,
            "pc": pc,
            "stream_id": stream_id,
            "track": None,
        }

        @pc.on("track")
        async def on_track(track):
            if track.kind == "audio":
                logger.info(f"Received audio track from sender {connection_id}")

                # Store the track
                self.senders[connection_id]["track"] = track
                self.active_streams[stream_id] = track

                logger.info(f"Stored stream {stream_id} for sender {connection_id}")
                logger.info(f"Active streams: {list(self.active_streams.keys())}")

                # Broadcast stream availability
                await self.broadcast_stream_available(stream_id)

                # Subscribe to relay for MP3 encoding
                # This ensures we don't steal frames from the receivers
                mp3_track = self.relay.subscribe(track)
                asyncio.create_task(self.encode_to_mp3(stream_id, mp3_track))

        @pc.on("iceconnectionstatechange")
        async def on_ice_state_change():
            state = pc.iceConnectionState
            logger.info(f"ICE connection state for sender {connection_id}: {state}")
            if state == "completed":
                logger.info(f"ICE connection completed for sender {connection_id}")

        # Send sender_ready signal
        await ws.send_text(json.dumps({"type": "sender_ready"}))

    async def setup_receiver(
        self, connection_id: str, ws: WebSocketResponse, stream_id: Optional[str]
    ):
        """Setup a receiver connection"""
        logger.info(
            f"Setting up receiver for connection {connection_id}, stream: {stream_id}"
        )

        pc = RTCPeerConnection()

        self.receivers[connection_id] = {"ws": ws, "pc": pc, "stream_id": stream_id}

        # Don't add track yet - wait for receiver to send offer first
        # The track will be added when we receive the offer in handle_webrtc_offer

        @pc.on("iceconnectionstatechange")
        async def on_ice_state_change():
            state = pc.iceConnectionState
            logger.info(f"ICE connection state for receiver {connection_id}: {state}")

    async def handle_webrtc_offer(self, connection_id: str, data: dict):
        """Handle WebRTC offer from sender or receiver"""
        if connection_id in self.senders:
            # Offer from sender
            sender = self.senders[connection_id]
            pc = sender["pc"]

            offer = RTCSessionDescription(
                sdp=data["offer"]["sdp"], type=data["offer"]["type"]
            )
            await pc.setRemoteDescription(offer)

            answer = await pc.createAnswer()
            await pc.setLocalDescription(answer)

            # Wait for ICE gathering
            await asyncio.sleep(0.5)

            await sender["ws"].send_text(
                json.dumps(
                    {
                        "type": "webrtc_answer",
                        "answer": {
                            "sdp": pc.localDescription.sdp,
                            "type": pc.localDescription.type,
                        },
                    }
                )
            )
        elif connection_id in self.receivers:
            # Offer from receiver - add track and send answer
            receiver = self.receivers[connection_id]
            pc = receiver["pc"]
            stream_id = receiver["stream_id"]

            # Add the relayed track if stream exists
            if stream_id and stream_id in self.active_streams:
                source_track = self.active_streams[stream_id]
                relayed_track = self.relay.subscribe(source_track)
                pc.addTrack(relayed_track)
                logger.info(
                    f"Added track from stream {stream_id} to receiver {connection_id}"
                )

            offer = RTCSessionDescription(
                sdp=data["offer"]["sdp"], type=data["offer"]["type"]
            )
            await pc.setRemoteDescription(offer)

            answer = await pc.createAnswer()
            await pc.setLocalDescription(answer)

            # Wait for ICE gathering
            await asyncio.sleep(0.5)

            await receiver["ws"].send_text(
                json.dumps(
                    {
                        "type": "webrtc_answer",
                        "answer": {
                            "sdp": pc.localDescription.sdp,
                            "type": pc.localDescription.type,
                        },
                    }
                )
            )

    async def handle_webrtc_answer(self, connection_id: str, data: dict):
        """Handle WebRTC answer from receiver"""
        if connection_id in self.receivers:
            receiver = self.receivers[connection_id]
            pc = receiver["pc"]

            answer = RTCSessionDescription(
                sdp=data["answer"]["sdp"], type=data["answer"]["type"]
            )
            await pc.setRemoteDescription(answer)

    async def handle_ice_candidate(self, connection_id: str, data: dict):
        """Handle ICE candidate"""
        candidate_data = data.get("candidate")

        if connection_id in self.senders:
            pc = self.senders[connection_id]["pc"]
        elif connection_id in self.receivers:
            pc = self.receivers[connection_id]["pc"]
        else:
            return

        if candidate_data:
            candidate = RTCIceCandidate(
                sdpMid=candidate_data.get("sdpMid"),
                sdpMLineIndex=candidate_data.get("sdpMLineIndex"),
                candidate=candidate_data.get("candidate"),
            )
            await pc.addIceCandidate(candidate)
            logger.info(
                f"ICE candidate received for {connection_id} (aiortc handles ICE internally)"
            )

    async def send_available_streams(self, ws: WebSocketResponse):
        """Send list of available streams"""
        streams = list(self.active_streams.keys())
        logger.info(f"Sending available streams to {id(ws)}: {streams}")
        await ws.send_text(
            json.dumps({"type": "available_streams", "streams": streams})
        )

    async def broadcast_stream_available(self, stream_id: str):
        """Broadcast that a new stream is available"""
        logger.info(f"Broadcasting stream available: {stream_id}")
        message = json.dumps({"type": "stream_available", "stream_id": stream_id})

        # Send to all receivers
        for receiver in self.receivers.values():
            try:
                await receiver["ws"].send_text(message)
            except Exception as e:
                logger.error(f"Failed to broadcast to receiver: {e}")

    async def broadcast_stream_ended(self, stream_id: str):
        """Broadcast that a stream has ended"""
        logger.info(f"Broadcasting stream ended: {stream_id}")
        message = json.dumps({"type": "stream_ended", "stream_id": stream_id})

        for receiver in self.receivers.values():
            try:
                await receiver["ws"].send_text(message)
            except Exception as e:
                logger.error(f"Failed to broadcast to receiver: {e}")

    async def keep_track_alive(self, track: MediaStreamTrack):
        """Keep consuming frames to keep track alive"""
        try:
            while True:
                await track.recv()
        except Exception as e:
            logger.info(f"Track ended: {e}")

    async def encode_to_mp3(self, stream_id: str, track: MediaStreamTrack):
        """Encode audio track to MP3 for HTTP streaming"""
        logger.info(f"Starting MP3 encoding for {stream_id}")
        self.mp3_buffers[stream_id] = bytearray()

        frame_count = 0
        try:
            while stream_id in self.active_streams:
                try:
                    frame = await asyncio.wait_for(track.recv(), timeout=2.0)
                except asyncio.TimeoutError:
                    logger.warning(
                        f"Timeout waiting for frame from {stream_id} [DEBUG TRACE]"
                    )
                    continue

                frame_count += 1
                if frame_count % 50 == 0:
                    logger.info(
                        f"Proccessed {frame_count} frames for stream {stream_id}"
                    )

                # Convert frame to numpy array
                audio_array = frame.to_ndarray()

                # Send visualization data (downsampled) every 5 frames
                if frame_count % 5 == 0:
                    # Calculate simplified visualization data (RMS or raw samples)
                    # For now, just send a subset of samples to keep it light
                    raw_data = np.frombuffer(audio_array.tobytes(), dtype=np.int16)
                    # Downsample significantly for visualization
                    vis_data = raw_data[::100].tolist()

                    msg = {
                        "type": "audio_data",
                        "stream_id": stream_id,
                        "data": vis_data,
                        "timestamp": asyncio.get_event_loop().time(),
                    }
                    # Broadcast to all receivers of this stream (for viz)
                    for rid, r in self.receivers.items():
                        if r.get("stream_id") == stream_id:
                            asyncio.create_task(r["ws"].send_json(msg))

                # Convert to AudioSegment
                audio_segment = AudioSegment(
                    audio_array.tobytes(),
                    frame_rate=frame.sample_rate,
                    sample_width=audio_array.dtype.itemsize,
                    channels=len(frame.layout.channels),
                )

                # Export to MP3
                mp3_buffer = io.BytesIO()
                audio_segment.export(mp3_buffer, format="mp3", bitrate="128k")

                # Append to buffer (keep last 30 seconds)
                mp3_data = mp3_buffer.getvalue()
                self.mp3_buffers[stream_id].extend(mp3_data)

                # Limit buffer size (approximately 30 seconds at 128kbps)
                max_size = 128 * 1024 * 30 // 8  # 480KB
                if len(self.mp3_buffers[stream_id]) > max_size:
                    self.mp3_buffers[stream_id] = self.mp3_buffers[stream_id][
                        -max_size:
                    ]

        except Exception as e:
            logger.error(f"MP3 encoding error for {stream_id}: {e}")
        finally:
            if stream_id in self.mp3_buffers:
                del self.mp3_buffers[stream_id]

    async def stream_mp3(self, request):
        """Stream MP3 audio for a specific stream"""
        stream_id = request.match_info["stream_id"]

        if stream_id not in self.mp3_buffers:
            return web.Response(status=404, text="Stream not found")

        response = web.StreamResponse(
            status=200,
            reason="OK",
            headers={
                "Content-Type": "audio/mpeg",
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
            },
        )
        await response.prepare(request)

        try:
            # Send buffered data first
            if self.mp3_buffers[stream_id]:
                await response.write(bytes(self.mp3_buffers[stream_id]))

            # Stream live data
            while stream_id in self.active_streams:
                await asyncio.sleep(0.1)
                # In a real implementation, you'd stream new chunks here

        except Exception as e:
            logger.error(f"MP3 streaming error: {e}")
        finally:
            await response.write_eof()

        return response

    async def stream_latest_mp3(self, request):
        """Stream the latest available stream"""
        if not self.active_streams:
            return web.Response(status=404, text="No active streams")

        # Get the latest stream
        latest_stream_id = list(self.active_streams.keys())[-1]

        # Redirect to specific stream
        return web.HTTPFound(f"/stream/{latest_stream_id}.mp3")

    async def stop_stream(self, connection_id: str):
        """Stop a stream"""
        if connection_id in self.senders:
            stream_id = self.senders[connection_id]["stream_id"]
            if stream_id in self.active_streams:
                del self.active_streams[stream_id]
                await self.broadcast_stream_ended(stream_id)

    async def cleanup_connection(self, connection_id: str):
        """Clean up a connection"""
        logger.info(f"Cleaning up connection {connection_id}")

        if connection_id in self.senders:
            sender = self.senders[connection_id]
            stream_id = sender["stream_id"]

            # Remove from active streams
            if stream_id in self.active_streams:
                del self.active_streams[stream_id]
                await self.broadcast_stream_ended(stream_id)

            # Close peer connection
            if sender["pc"]:
                await sender["pc"].close()

            del self.senders[connection_id]
            logger.info(f"Sender {connection_id} cleaned up")

        if connection_id in self.receivers:
            receiver = self.receivers[connection_id]

            # Close peer connection
            if receiver["pc"]:
                await receiver["pc"].close()

            del self.receivers[connection_id]
            logger.info(f"Receiver {connection_id} cleaned up")

    async def run_server(self):
        runner = web.AppRunner(self.app)
        await runner.setup()

        site = web.TCPSite(runner, "0.0.0.0", 8080)
        await site.start()

        logger.info("Voice streaming server started on port 8080")
        logger.info("WebSocket endpoint: ws://localhost:8080/ws")
        logger.info("MP3 stream endpoint: http://localhost:8080/stream/latest.mp3")

        # Keep server running
        await asyncio.Event().wait()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    server = VoiceStreamingServer()
    asyncio.run(server.run_server())
