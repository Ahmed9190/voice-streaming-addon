import asyncio
import fractions
import logging

import av
from aiohttp import web

logger = logging.getLogger(__name__)


class AudioStreamServer:
    def __init__(self, relay_server):
        self.relay_server = relay_server
        self.app = web.Application()
        self.app.router.add_get("/stream/latest.mp3", self.latest_stream_handler)
        self.app.router.add_get("/stream/{stream_id}.mp3", self.stream_handler)
        self.app.router.add_get("/stream/status", self.status_handler)
        self.runner = None
        self.site = None

    async def latest_stream_handler(self, request):
        if not self.relay_server.active_streams:
            return web.Response(status=404, text="No active streams")

        # Get latest stream (last inserted key)
        stream_id = list(self.relay_server.active_streams.keys())[-1]

        # Delegate to stream_handler
        request.match_info["stream_id"] = stream_id
        return await self.stream_handler(request)

    async def start(self, host="0.0.0.0", port=8081):
        self.runner = web.AppRunner(self.app)
        await self.runner.setup()
        self.site = web.TCPSite(self.runner, host, port)
        await self.site.start()
        logger.info(f"Audio Stream Server started on {host}:{port}")

    async def stop(self):
        if self.site:
            await self.site.stop()
        if self.runner:
            await self.runner.cleanup()

    async def status_handler(self, request):
        return web.json_response(
            {"active_streams": list(self.relay_server.active_streams.keys())}
        )

    async def stream_handler(self, request):
        stream_id = request.match_info["stream_id"]
        stream_info = self.relay_server.active_streams.get(stream_id)

        if not stream_info:
            return web.Response(status=404, text="Stream not found")

        logger.info(f"Starting audio stream for {stream_id} to {request.remote}")

        # Subscribe to the track via MediaRelay to get a fresh consumer
        source_track = stream_info["track"]
        try:
            track = self.relay_server.relay.subscribe(source_track)
        except Exception as e:
            logger.error(f"Failed to subscribe to track: {e}")
            return web.Response(status=500, text="Failed to subscribe to media track")

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

        # Setup MP3 encoding
        try:
            # Create MP3 encoder
            codec = av.codec.Codec("mp3", "w")
            codec_context = av.CodecContext.create(codec)
            codec_context.bit_rate = 128000
            codec_context.sample_rate = 44100
            codec_context.format = av.AudioFormat("s16p")
            codec_context.layout = "stereo"
            codec_context.time_base = fractions.Fraction(1, 44100)

            # Open the codec
            codec_context.open()

            # Resampler to ensure compatible format for MP3 encoder
            resampler = av.AudioResampler(
                format="s16p",
                layout="stereo",
                rate=44100,
            )

            # Start streaming
            while True:
                try:
                    frame = await track.recv()

                    # Resample
                    resampled_frames = resampler.resample(frame)

                    for r_frame in resampled_frames:
                        packets = codec_context.encode(r_frame)
                        for packet in packets:
                            await response.write(bytes(packet))

                except Exception as e:
                    # End of stream or error
                    logger.info(f"Stream ended or error: {e}")
                    break

        except asyncio.CancelledError:
            logger.info("Client disconnected")
        except Exception as e:
            logger.error(f"Streaming error: {e}")
        finally:
            # Clean up track subscription
            # track.stop() # aiortc tracks don't have stop(), they stop when upstream stops or GC?
            # MediaRelay tracks handle cleanup when they are no longer iterated?
            pass

        return response
