# HACS Installation & Configuration

This project is configured to be installed via [HACS](https://hacs.xyz/) (Home Assistant Community Store).

## 1. Add Custom Repository

Since this is not yet in the default HACS store, you need to add it manually:

1. Open **HACS** in Home Assistant.
2. Click the **3 dots** (top right) > **Custom repositories**.
3. **Repository**: Paste the URL of this GitHub repository.
4. **Category**: Select **Integration**.
5. Click **Add**.

## 2. Install the Integration

1. Find "Voice Streaming" in the list.
2. Click **Download**.
3. **Restart Home Assistant**.

## 3. Configuration (Dashboard)

The integration comes with two cards bundled inside it. We have registered a special path to access them: `/voice_streaming_static/`.

### Option A: Using Custom Panels (Sidebar)

Update your `configuration.yaml`:

```yaml
panel_custom:
  - name: voice-sending-card
    sidebar_title: Voice Send
    sidebar_icon: mdi:microphone
    url_path: voice-streaming
    # Point to the bundled file instead of /local/
    module_url: /voice_streaming_static/voice-sending-card.js

  - name: voice-receiving-card
    sidebar_title: Voice Receive
    sidebar_icon: mdi:headphones
    url_path: voice-receiving
    # Point to the bundled file instead of /local/
    module_url: /voice_streaming_static/voice-receiving-card.js
```

### Option B: Using Lovelace Dashboard

1. Go to **Settings** > **Dashboards** > **Resources**.
2. Add Resource:
   - URL: `/voice_streaming_static/voice-sending-card.js`
   - Type: JavaScript Module
3. Add Resource:
   - URL: `/voice_streaming_static/voice-receiving-card.js`
   - Type: JavaScript Module

Then you can use the cards in any view:

```yaml
type: custom:voice-sending-card
target_media_player: media_player.living_room
```

## 4. Updates

When a new release is created on GitHub:

1. Go to HACS.
2. You will see an update available.
3. Click **Update**.
4. The new frontend files and backend code will be installed automatically.

## Developer Note: Release Process

The `.github/workflows/release.yml` automatically:

1. Builds the frontend.
2. Bundles it into the `custom_components/voice_streaming/www/` folder.
3. Creates a `voice_streaming.zip` that HACS understands.

No manual file copying is required!
