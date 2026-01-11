import asyncio
import json
import logging
import uuid
from typing import Dict

from aiohttp import WSMsgType, web
from aiortc import RTCConfiguration, RTCPeerConnection, RTCSessionDescription

logger = logging.getLogger(__name__)


class VoiceStreamingServer:
    def __init__(self):
        self.connections: Dict[str, dict] = {}
        self.active_streams: Dict[str, Dict] = {}  # stream_id -> {track, receivers[]}
        self.app = web.Application()
        self.setup_routes()

    def setup_routes(self):
        self.app.router.add_get("/health", self.health_check)
        self.app.router.add_get("/ws", self.websocket_handler)

    async def health_check(self, request):
        return web.json_response(
            {
                "status": "healthy",
                "webrtc_available": True,
                "active_streams": len(self.active_streams),
                "connected_clients": len(self.connections),
            }
        )

    async def websocket_handler(self, request):
        ws = web.WebSocketResponse()
        await ws.prepare(request)

        connection_id = str(uuid.uuid4())
        self.connections[connection_id] = {
            "ws": ws,
            "pc": None,
            "role": None,  # 'sender' or 'receiver'
            "stream_id": None,
        }

        try:
            # Notify the client of available streams
            await self.send_available_streams(connection_id)

            async for msg in ws:
                if msg.type == WSMsgType.TEXT:
                    data = json.loads(msg.data)
                    await self.handle_message(connection_id, data)
                elif msg.type == WSMsgType.ERROR:
                    logger.error(f"WebSocket error: {ws.exception()}")

        except Exception as e:
            logger.error(f"WebSocket connection error: {e}")
        finally:
            await self.cleanup_connection(connection_id)

        return ws

    async def handle_message(self, connection_id: str, data: dict):
        message_type = data.get("type")
        connection = self.connections.get(connection_id)

        if not connection:
            return

        if message_type == "start_sending":
            await self.setup_sender(connection_id)
        elif message_type == "start_receiving":
            await self.setup_receiver(connection_id, data.get("stream_id"))
        elif message_type == "webrtc_offer":
            await self.handle_webrtc_offer(connection_id, data)
        elif message_type == "webrtc_answer":
            await self.handle_webrtc_answer(connection_id, data)
        elif message_type == "ice_candidate":
            await self.handle_ice_candidate(connection_id, data)
        elif message_type == "local_ip":
            await self.handle_local_ip(connection_id, data)

    async def setup_sender(self, connection_id: str):
        """Set up a client as an audio sender"""
        logger.info(f"Setting up sender for connection {connection_id}")
        connection = self.connections[connection_id]
        connection["role"] = "sender"

        # Create RTCPeerConnection with LAN-only ICE configuration
        # Empty iceServers means only host candidates (local IPs) will be used
        config = RTCConfiguration(iceServers=[])
        pc = RTCPeerConnection(configuration=config)
        connection["pc"] = pc

        @pc.on("track")
        async def on_track(track):
            if track.kind == "audio":
                logger.info(f"Received audio track from sender {connection_id}")

                # Store the audio stream
                stream_id = f"stream_{connection_id}"
                self.active_streams[stream_id] = {
                    "track": track,
                    "receivers": [],
                    "sender_id": connection_id,
                }
                connection["stream_id"] = stream_id

                logger.info(f"Stored stream {stream_id} for sender {connection_id}")
                logger.info(f"Active streams: {list(self.active_streams.keys())}")

                # Keep track alive
                @track.on("ended")
                async def on_ended():
                    logger.info(f"Audio track ended for {connection_id}")
                    if stream_id in self.active_streams:
                        # Notify receivers that stream ended
                        for receiver_id in self.active_streams[stream_id]["receivers"]:
                            if receiver_id in self.connections:
                                try:
                                    await self.connections[receiver_id]["ws"].send_str(
                                        json.dumps(
                                            {
                                                "type": "stream_ended",
                                                "stream_id": stream_id,
                                            }
                                        )
                                    )
                                except:
                                    pass
                        del self.active_streams[stream_id]
                    await self.broadcast_stream_ended(stream_id)

        @pc.on("iceconnectionstatechange")
        async def on_iceconnectionstatechange():
            logger.info(
                f"ICE connection state for sender {connection_id}: {pc.iceConnectionState}"
            )
            if pc.iceConnectionState == "failed":
                logger.warning(f"ICE connection failed for sender {connection_id}")
                await pc.close()
            elif pc.iceConnectionState == "connected":
                logger.info(f"ICE connection established for sender {connection_id}")
            elif pc.iceConnectionState == "completed":
                logger.info(f"ICE connection completed for sender {connection_id}")

        # Don't create offer here, wait for the client to send an offer after adding tracks
        await connection["ws"].send_str(
            json.dumps({"type": "sender_ready", "connection_id": connection_id})
        )

    async def setup_receiver(self, connection_id: str, stream_id: str = None):
        """Set up a client as an audio receiver"""
        connection = self.connections[connection_id]
        connection["role"] = "receiver"

        # If no specific stream requested, use the first available
        if not stream_id and self.active_streams:
            stream_id = next(iter(self.active_streams))

        if stream_id not in self.active_streams:
            await connection["ws"].send_str(
                json.dumps({"type": "error", "message": "No audio stream available"})
            )
            return

        # Add this receiver to the stream
        self.active_streams[stream_id]["receivers"].append(connection_id)
        connection["stream_id"] = stream_id

        # Create RTCPeerConnection with LAN-only ICE configuration
        config = RTCConfiguration(iceServers=[])
        pc = RTCPeerConnection(configuration=config)
        connection["pc"] = pc

        # Add the audio track from the sender
        source_track = self.active_streams[stream_id]["track"]
        pc.addTrack(source_track)

        @pc.on("iceconnectionstatechange")
        async def on_iceconnectionstatechange():
            logger.info(
                f"ICE connection state for receiver {connection_id}: {pc.iceConnectionState}"
            )
            if pc.iceConnectionState == "failed":
                logger.warning(f"ICE connection failed for receiver {connection_id}")
                await pc.close()
            elif pc.iceConnectionState == "connected":
                logger.info(f"ICE connection established for receiver {connection_id}")
            elif pc.iceConnectionState == "completed":
                logger.info(f"ICE connection completed for receiver {connection_id}")

        # Create and send offer to the receiver
        try:
            offer = await pc.createOffer()
            await pc.setLocalDescription(offer)

            await connection["ws"].send_str(
                json.dumps(
                    {
                        "type": "webrtc_offer",
                        "offer": {
                            "sdp": pc.localDescription.sdp,
                            "type": pc.localDescription.type,
                        },
                    }
                )
            )
        except Exception as e:
            logger.error(f"Error creating offer for receiver {connection_id}: {e}")
            await connection["ws"].send_str(
                json.dumps(
                    {"type": "error", "message": f"Error creating offer: {str(e)}"}
                )
            )

    async def send_available_streams(self, connection_id: str):
        """Send list of available streams to a client"""
        connection = self.connections.get(connection_id)
        if not connection:
            return

        stream_list = list(self.active_streams.keys())
        logger.info(f"Sending available streams to {connection_id}: {stream_list}")
        try:
            await connection["ws"].send_str(
                json.dumps({"type": "available_streams", "streams": stream_list})
            )
        except Exception as e:
            logger.error(f"Error sending available streams: {e}")

    async def broadcast_stream_available(self, stream_id: str):
        """Notify all clients about new stream"""
        logger.info(f"Broadcasting stream available: {stream_id}")
        message = json.dumps({"type": "stream_available", "stream_id": stream_id})

        # Send to all clients (to update their stream lists)
        for conn_id, conn in self.connections.items():
            try:
                await conn["ws"].send_str(message)
            except:
                pass

    async def broadcast_stream_ended(self, stream_id: str):
        """Notify all clients about ended stream"""
        message = json.dumps({"type": "stream_ended", "stream_id": stream_id})

        # Send to all clients (to update their stream lists)
        for conn_id, conn in self.connections.items():
            try:
                await conn["ws"].send_str(message)
            except:
                pass

    async def handle_webrtc_offer(self, connection_id: str, data: dict):
        connection = self.connections[connection_id]
        pc = connection["pc"]

        if not pc:
            return

        offer = RTCSessionDescription(
            sdp=data["offer"]["sdp"], type=data["offer"]["type"]
        )
        await pc.setRemoteDescription(offer)

        answer = await pc.createAnswer()
        await pc.setLocalDescription(answer)

        await connection["ws"].send_str(
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
        connection = self.connections[connection_id]
        pc = connection["pc"]

        if not pc:
            return

        answer = RTCSessionDescription(
            sdp=data["answer"]["sdp"], type=data["answer"]["type"]
        )
        await pc.setRemoteDescription(answer)

    async def handle_ice_candidate(self, connection_id: str, data: dict):
        connection = self.connections.get(connection_id)
        if not connection:
            logger.warning(f"No connection found for {connection_id}")
            return

        pc = connection.get("pc")

        if not pc:
            logger.warning(f"No peer connection for {connection_id}")
            return

        if not pc.remoteDescription:
            logger.warning(
                f"Cannot add ICE candidate for {connection_id}: No remote description yet"
            )
            return

        candidate_data = data.get("candidate")
        if not candidate_data:
            logger.info(f"Empty ICE candidate (end of candidates) for {connection_id}")
            return

        logger.info(
            f"Received ICE candidate for connection {connection_id}: {candidate_data}"
        )

        # Browser sends ICE candidates in this format:
        # {
        #   "candidate": "candidate:xxx 1 udp 2122260223 192.168.1.x 12345 typ host ...",
        #   "sdpMid": "0",
        #   "sdpMLineIndex": 0
        # }
        #
        # For aiortc, we need to parse the candidate string.
        # However, aiortc's trickle ICE support is limited.
        # The best approach is to just log and let the connection work
        # with candidates exchanged via SDP.

        try:
            # Check if this is a dict with 'candidate' string (browser format)
            if isinstance(candidate_data, dict):
                candidate_str = candidate_data.get("candidate", "")
                sdp_mid = candidate_data.get("sdpMid", "0")
                sdp_mline_index = candidate_data.get("sdpMLineIndex", 0)
            else:
                candidate_str = str(candidate_data)
                sdp_mid = "0"
                sdp_mline_index = 0

            # Empty candidate string means end of candidates
            if not candidate_str or candidate_str == "":
                logger.info(f"End of ICE candidates for {connection_id}")
                return

            # Log the candidate details for debugging
            logger.debug(f"ICE candidate string: {candidate_str}")
            logger.debug(f"sdpMid: {sdp_mid}, sdpMLineIndex: {sdp_mline_index}")

            # Note: aiortc handles ICE internally via the SDP exchange.
            # Trickle ICE (adding candidates after the offer/answer) has limited support.
            # The connection should still work because:
            # 1. Host candidates are included in the SDP
            # 2. aiortc's ICE implementation gathers its own candidates
            #
            # For LAN-only operation, this is usually sufficient.
            logger.info(
                f"ICE candidate received for {connection_id} (aiortc handles ICE internally)"
            )

        except Exception as e:
            logger.error(f"Error processing ICE candidate for {connection_id}: {e}")

    async def handle_local_ip(self, connection_id: str, data: dict):
        """Handle local IP address information from clients"""
        local_ip = data.get("ip")
        if local_ip:
            logger.info(f"Local IP for connection {connection_id}: {local_ip}")
            # Store the local IP in the connection data
            connection = self.connections.get(connection_id)
            if connection:
                connection["local_ip"] = local_ip

    async def cleanup_connection(self, connection_id: str):
        if connection_id in self.connections:
            connection = self.connections[connection_id]

            # If this was a sender, notify about stream ending
            if connection.get("role") == "sender" and connection.get("stream_id"):
                stream_id = connection["stream_id"]
                if stream_id in self.active_streams:
                    # Notify receivers that stream ended
                    for receiver_id in self.active_streams[stream_id]["receivers"]:
                        if receiver_id in self.connections:
                            try:
                                await self.connections[receiver_id]["ws"].send_str(
                                    json.dumps(
                                        {"type": "stream_ended", "stream_id": stream_id}
                                    )
                                )
                            except:
                                pass
                    del self.active_streams[stream_id]
                await self.broadcast_stream_ended(stream_id)

            # If this was a receiver, remove from stream receivers list
            elif connection.get("role") == "receiver" and connection.get("stream_id"):
                stream_id = connection["stream_id"]
                if stream_id in self.active_streams:
                    if connection_id in self.active_streams[stream_id]["receivers"]:
                        self.active_streams[stream_id]["receivers"].remove(
                            connection_id
                        )

            if connection.get("pc"):
                await connection["pc"].close()

            del self.connections[connection_id]

    async def run_server(self):
        port = 8080
        host = "0.0.0.0"

        runner = web.AppRunner(self.app)
        await runner.setup()

        site = web.TCPSite(runner, host, port)
        await site.start()

        logger.info(f"Voice streaming relay server started on {host}:{port}")

        # Keep the server running
        while True:
            await asyncio.sleep(3600)  # Sleep for an hour, or until interrupted


# Example usage
if __name__ == "__main__":
    # Configure logging
    logging.basicConfig(level=logging.INFO)

    # Create and run the server
    server = VoiceStreamingServer()

    try:
        asyncio.run(server.run_server())
    except KeyboardInterrupt:
        print("Server stopped")
