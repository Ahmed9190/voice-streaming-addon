"""Voice Streaming integration for Home Assistant."""

import logging

from homeassistant.components import websocket_api
from homeassistant.core import HomeAssistant
from homeassistant.helpers import config_validation as cv

_LOGGER = logging.getLogger(__name__)


DOMAIN = "voice_streaming"
STREAM_URL = "http://192.168.2.120:8081/stream/latest.mp3"

# This integration doesn't require YAML configuration
CONFIG_SCHEMA = cv.empty_config_schema(DOMAIN)


async def async_setup(hass: HomeAssistant, config: dict):
    """Set up the Voice Streaming component."""
    _LOGGER.info("Setting up Voice Streaming component")

    hass.data[DOMAIN] = {
        "websocket_connections": {},
    }

    # Register WebSocket API commands
    _LOGGER.info("Registering WebSocket commands")
    websocket_api.async_register_command(hass, websocket_voice_streaming)
    _LOGGER.info("WebSocket commands registered")

    async def play_on_speaker_service(call):
        """Play voice stream on a speaker."""
        entity_id = call.data.get("entity_id")

        # Use direct connection to the Audio Server (bypassing HA 8123 proxy which fails)
        # We use the known LAN IP + Port 8081
        # This avoids 404s and SSL issues for local speakers
        url = STREAM_URL

        _LOGGER.info(f"Playing stream on {entity_id} from {url}")

        await hass.services.async_call(
            "media_player",
            "play_media",
            {
                "entity_id": entity_id,
                "media_content_id": url,
                "media_content_type": "music",
            },
        )

    hass.services.async_register(DOMAIN, "play_on_speaker", play_on_speaker_service)

    return True


async def async_setup_entry(hass: HomeAssistant, entry):
    """Set up Voice Streaming from a config entry."""
    return True


@websocket_api.websocket_command(
    {
        "type": "voice_streaming/connect",
    }
)
@websocket_api.async_response
async def websocket_voice_streaming(hass, connection, msg):
    """Handle voice streaming WebSocket connection."""
    _LOGGER.info("Voice streaming WebSocket connection requested")

    # Send success message to client
    connection.send_message(
        websocket_api.result_message(msg["id"], {"status": "connected"})
    )
