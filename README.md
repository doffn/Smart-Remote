<div align="center">

<img src="https://raw.githubusercontent.com/doffn/doffneri/refs/heads/main/staticfiles/fevi.ico" width="100" height="100" style="border-radius: 20px;" />

# DoffRemote

### Turn your Android phone into a full STB remote controller & video caster

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](https://www.android.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-blueviolet)](https://github.com/doffn/doffremote/releases)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/doffn/doffremote/pulls)

**DoffRemote** connects your **Lifestar STB** (Set-Top Box) to the internet — control it wirelessly, cast any video from YouTube, movie sites, and live football streams directly to your TV screen.

[📥 Download APK](#installation) · [🐛 Report Bug](https://github.com/doffn/doffremote/issues) · [💡 Request Feature](https://github.com/doffn/doffremote/issues)

</div>

---

## 📸 Screenshots

<div align="center">

| Scan Page | Full Remote | Web Hub | About |
|:-----------:|:-----------:|:-------:|:--------------:|
| <img src="https://github.com/doffn/Lifestar-Smart-Remote/blob/main/screenshots/scan.jpg" width="180"/> | <img src="https://github.com/doffn/Lifestar-Smart-Remote/blob/main/screenshots/remote.jpg" width="180"/> | <img src="https://github.com/doffn/Lifestar-Smart-Remote/blob/main/screenshots/webapp.jpg" width="180"/> | <img src="https://github.com/doffn/Lifestar-Smart-Remote/blob/main/screenshots/about.jpg" width="180"/> |

> Screenshots are from a real device running Android 13. UI adapts to both light and dark modes.

</div>

---

## ✨ Features

### 📡 Smart Device Discovery
- Automatically scans your local Wi-Fi network for STB devices
- Remembers your last connected device and reconnects on startup
- **Persistent heartbeat** — pings every 5 seconds, auto-reconnects if the device drops
- Visual connection status badge in the app bar (green = connected, orange = reconnecting)
- Pull-to-refresh device list

### 🎮 Dual Remote Control
Two remote modes, switch anytime with a single tap:

| Feature | Mini Remote | Full Remote |
|---------|------------|-------------|
| D-Pad navigation | ✅ | ✅ |
| Volume +/- | ✅ | ✅ |
| Mute | ✅ | ✅ |
| Menu / Home / Back | ✅ | ✅ |
| FAV / EPG / INFO | ✅ | ✅ |
| Colour buttons (R/G/Y/B) | ✅ | ✅ |
| Numpad 0–9 | ❌ | ✅ |
| Channel +/- | ❌ | ✅ |
| TV/R, ZOOM, RECALL | ❌ | ✅ |
| EDIT / PAUSE / SLEEP | ❌ | ✅ |
| Playback (⏮ ⏭ ▶ ⏺) | ❌ | ✅ |

### 🌐 Web Hub & Video Caster
- Built-in **multi-tab browser** — open multiple streaming sites simultaneously
- **Universal video scraper** with a 13-phase extraction pipeline:
  - 🔴 Native network sniffing via `shouldInterceptRequest` (platform-level, most reliable)
  - 🟡 YouTube via `youtube_explode_dart` with SABR stream detection & filtering
  - 🟢 Invidious parallel fallback (5 instances fired simultaneously)
  - 🔵 Cobalt API, yt-dlp API fallbacks
  - ⚪ Dailymotion, Vimeo dedicated extractors
  - ⚪ DOM scan, JWPlayer/VideoJS/HLS.js config parsing
  - ⚪ `eval(atob())` obfuscation decoding
  - ⚪ Open Graph / JSON-LD metadata
  - ⚪ Iframe chain following
  - ⚪ Raw HTML regex + HTTP fallback
- Blocks **blob URLs**, ad domains, and YouTube's unplayable SABR streams
- Category-grouped app grid with recent history

### 🎛️ Floating In-Browser Remote
- Slide up from the bottom edge of any web page to reveal a compact remote panel
- Controls: `Vol-` · `CH-` · **OK** · `CH+` · `Vol+` · `Mute` · `Exit`
- Smooth slide animation, dismisses by swiping down
- Works while a video is playing — no need to leave the browser

---

## 🏗️ Architecture

```
doff_remote/
├── lib/
│   ├── main.dart           # App entry, theme, navigation, connection badge
│   ├── lucky_stb.dart      # STB API client + heartbeat + auto-reconnect
│   ├── scraper.dart        # UniversalVideoScraper (13-phase pipeline)
│   ├── web_hub_tab.dart    # Browser UI + floating remote panel
│   ├── remote_tab.dart     # Mini & Full remote UIs
│   ├── scan_tab.dart       # Network scanner + device manager
│   └── about_tab.dart      # Developer info
├── assets/
│   ├── apps.json           # Fallback app list
│   └── app_icon.png
└── pubspec.yaml
```

### STB Communication Protocol

DoffRemote communicates with the STB over **HTTP on port 8000**:

```http
# Send key press
POST http://{stb-ip}:8000/api/v1/key
Content-Type: application/json
{"key": "WEBK_OK"}

# Cast video
POST http://{stb-ip}:8000/api/v1/play
Content-Type: application/json
{
  "stream_type": "net",
  "media_type": "video",
  "action": "play",
  "uri": "https://...",
  "time": 0
}
```

---

## 🚀 Installation

### Option A — Download APK
1. Go to the [Releases](https://github.com/doffn/doffremote/releases) page
2. Download the latest `doff_remote.apk`
3. Enable "Install from unknown sources" on your Android device
4. Install and launch

### Option B — Build from Source

**Requirements:**
- Flutter SDK 3.x+
- Android SDK
- A physical or emulated Android device

```bash
# 1. Clone the repository
git clone https://github.com/doffn/doffremote.git
cd doffremote

# 2. Install dependencies
flutter pub get

# 3. Run on device
flutter run

# 4. Build release APK
flutter build apk --release
```

---

## 🔧 Configuration

### Adding Custom Apps
Edit `assets/apps.json` to add streaming sites to the Web Hub:

```json
[
  {
    "name": "YouTube",
    "url": "https://m.youtube.com",
    "logo": "https://...",
    "category": "Video"
  },
  {
    "name": "HDToday",
    "url": "https://hdtoday.tr",
    "logo": "https://...",
    "category": "Movies"
  }
]
```

Or serve a remote list from your own server — DoffRemote fetches from `https://videoprocessor.vercel.app/apps` first, falling back to the local file.

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_inappwebview` | WebView engine with native network interception |
| `youtube_explode_dart` | YouTube stream extraction |
| `http` | HTTP client for STB API & web scraping |
| `network_info_plus` | Local subnet discovery |
| `shared_preferences` | Persistent connection & settings storage |
| `url_launcher` | External link handling |

---

## 🤝 Contributing

Contributions are welcome! Here's how to get started:

1. **Fork** the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a **Pull Request**

### Ideas for contributions
- [ ] iOS support (requires `WKWebView` adapter for native sniffing)
- [ ] More streaming site extractors (Twitch, Facebook Video, etc.)
- [ ] Subtitle support for casted videos
- [ ] Scheduled recordings via STB API
- [ ] Widget / quick-tile for fast key sending

---

## 🐛 Known Limitations

| Issue | Status |
|-------|--------|
| YouTube SABR streams (new format) | Handled — filtered & fallback chain applied |
| Blob URLs from MSE players | Blocked by design — cannot be cast externally |
| DRM-protected streams (Netflix, etc.) | Not supported — DRM keys are device-bound |
| Cross-origin iframe extraction | Limited to same-origin by browser security |
| iOS native sniffing | Not available — `flutter_inappwebview` limitation on iOS |

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 👤 Developer

<div align="center">

<img src="https://raw.githubusercontent.com/doffn/doffneri/refs/heads/main/staticfiles/fevi.ico" width="70" height="70" style="border-radius: 50%;" />

### Dawit Neri

*Full-stack developer passionate about building tools that bridge software and hardware*

[![Gmail](https://img.shields.io/badge/Gmail-dawitneri888@gmail.com-EA4335?logo=gmail&logoColor=white)](mailto:dawitneri888@gmail.com)
[![Telegram](https://img.shields.io/badge/Telegram-@doffn-26A5E4?logo=telegram&logoColor=white)](https://t.me/doffn)
[![GitHub](https://img.shields.io/badge/GitHub-doffn-181717?logo=github&logoColor=white)](https://github.com/doffn)
[![Website](https://img.shields.io/badge/Website-doffneri.vercel.app-000000?logo=vercel&logoColor=white)](https://doffneri.vercel.app)

</div>

---

<div align="center">

**If DoffRemote saved you from buying a Bluetooth remote — give it a ⭐**

Made with ❤️ in Ethiopia · © 2026 Dawit Neri

</div>
