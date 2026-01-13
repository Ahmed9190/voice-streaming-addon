# 🎵 Streaming to Media Player

You can now stream your voice directly to a Google Home, Sonos, or any other media player in Home Assistant!

## How to Configure

1. Go to your Dashboard.
2. Edit the **Voice Sending Card**.
3. In the new **"Target Media Player"** field, enter your media player's entity ID.
   - Example: `media_player.living_room_speaker`
   - Example: `media_player.google_home_mini`

## How it Works

- **Start:** When you click the microphone 🎤, the card will:
  1. Start streaming audio to the backend.
  2. Automatically tell Home Assistant to play that stream on your selected speaker.
- **Stop:** When you click stop 🛑, it stops the media player.

## Requirements

- Usually requires the media player to be on the same local network.
- The stream URL used is `http://<YOUR_IP>:8081/stream/latest.mp3`.
- Ensure your media player can access this URL.
