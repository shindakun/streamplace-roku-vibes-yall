# Streamplace Roku Channel

A Roku TV app for watching live streams on [stream.place](https://stream.place) — open-source livestreaming on the AT Protocol.

## Features

- **Live Stream Grid** — Browse all currently live streams in a poster grid
- **HLS Playback** — Watch any live stream directly on your Roku TV  
- **Auto-Refresh** — Stream list refreshes every 30 seconds
- **Deep Linking** — Launch directly to a streamer by handle
- **Stream Info Overlay** — Shows streamer name and handle during playback

## Project Structure

```
streamplace-roku/
├── manifest              # Channel configuration
├── source/
│   └── main.brs          # Entry point
├── components/
│   ├── MainScene.xml     # Root scene layout (SceneGraph)
│   ├── MainScene.brs     # Scene logic, navigation, playback
│   ├── StreamContentTask.xml  # Task node definition
│   └── StreamContentTask.brs  # XRPC API fetcher
└── images/
    ├── channel_icon_hd.png    # 336x210 channel icon
    ├── channel_icon_sd.png    # 214x144 channel icon
    ├── splash_hd.png          # 1280x720 splash screen
    ├── splash_sd.png          # 720x480 splash screen
    └── default_poster.png     # Default stream thumbnail
```

## How It Works

### API Integration

The app uses stream.place's XRPC API endpoints (AT Protocol standard):

| Endpoint | Purpose |
|----------|---------|
| `place.stream.live.getLiveUsers` | Fetch currently live streamers |
| `place.stream.live.getRecommendations` | Fallback discovery |

Streams are played back via HLS at:
```
https://stream.place/api/playback/{handle}/ndex.m3u8
```

### Controls

| Button | Action |
|--------|--------|
| **D-pad** | Navigate stream grid |
| **OK** | Select stream / Toggle info overlay |
| **Back** | Stop playback, return to grid |
| **Options (*)** | Refresh stream list |

## Development Setup

### Prerequisites

1. A Roku device in [Developer Mode](https://developer.roku.com/docs/developer-program/getting-started/developer-setup.md)
2. Note your Roku's IP address (Settings > Network > About)

### Deploy to Roku

1. **Zip the channel:**
   ```bash
   cd streamplace-roku
   zip -r streamplace.zip manifest source/ components/ images/
   ```

2. **Upload via browser:**
   - Navigate to `http://<roku-ip>` in your browser
   - Click "Upload" and select `streamplace.zip`
   - The channel will install and launch automatically

3. **Or use curl:**
   ```bash
   curl -F "mysubmit=Install" \
        -F "archive=@streamplace.zip" \
        http://<roku-ip>/plugin_install \
        -u rokudev:<your-password>
   ```

### Debug

- **BrightScript console:** `telnet <roku-ip> 8085`
- **SceneGraph debug:** `telnet <roku-ip> 8080`

## Customization

### HLS URL Pattern

If stream.place changes their URL structure, update the `playStream()` function in `MainScene.brs`:

```brightscript
hlsUrl = "https://stream.place/api/playback/" + handle + "/index.m3u8"
```

### API Base URL

If running a self-hosted Streamplace node, update `baseUrl` in `StreamContentTask.brs`:

```brightscript
baseUrl = "https://your-node.example.com/xrpc/"
```

## Notes

- The app requires an active internet connection
- HLS playback uses H.264 video (natively supported by Roku)
- Audio codec from stream.place is Opus; Roku may need AAC transcoding
  from the server side for full compatibility
- Stream thumbnails use the `/og/{handle}` OpenGraph image endpoint
- The channel auto-refreshes the live stream list every 30 seconds

## License

MIT — Built for the AT Protocol ecosystem.
