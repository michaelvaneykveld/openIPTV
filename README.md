# openIPTV - A Modern, Cross-Platform IPTV Player

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/michaelvaneykveld/openiptv?style=social)](https://github.com/michaelvaneykveld/openiptv/stargazers)

A modern, open-source IPTV player built with Flutter, designed to support M3U, Xtream Codes, and Stalker Portals across all major platforms.

---

## ✨ Key Features

-   **Multi-Protocol Support**: Natively handles M3U playlists, Xtream Codes APIs, and Stalker/Ministra Portals.
-   **Truly Cross-Platform**: A single codebase for Mobile (iOS, Android), Desktop (Windows, macOS, Linux), and Web.
-   **Unified Content Library**: Seamlessly browse Live TV, Video on Demand (VOD), and TV Series from any source.
-   **Rich User Experience**: Full EPG (Electronic Program Guide) support, channel favoriting, powerful search, and catch-up functionality.
-   **High-Performance Playback**: Utilizes an adapter-based architecture to leverage the best native video players on each platform (VLC, ExoPlayer, AVPlayer).
-   **Clean, Modern UI**: Designed for intuitive navigation on both touch screens and with a remote control.

---

## 🏗️ Architecture Overview

The project follows a clean, scalable architecture that separates concerns, making it maintainable and easy to extend.

#### 1. Flutter App (Single Codebase)
```
┌─────────────────────────────────────────────┐
│ Presentation (UI Widgets)                   │
│ - Channel list, EPG timeline, player view   │
├─────────────────────────────────────────────┤
│ Application State (Riverpod)                │
│ - Manages state, triggers data fetching     │
├─────────────────────────────────────────────┤
│ Domain Logic / Repositories                 │
│ - Abstracts data sources from the UI        │
└─────────────────────────────────────────────┘
```

#### 2. Data Layer
-   **Protocol Providers**: Dedicated clients for M3U, Xtream, and Stalker that fetch and parse data.
-   **Normalization**: All incoming data is mapped to unified models (`Channel`, `EpgEvent`, `VodItem`).
-   **Caching**: A local database (Isar/Hive) caches EPG, playlists, and images for fast startup times and offline access.

#### 3. Player Adapter Layer
An abstract `PlayerAdapter` interface provides a uniform API (`play()`, `pause()`, `seek()`) to the application, while platform-specific implementations handle the native playback.

-   **Android/Windows/Linux** → `flutter_vlc_player`
-   **iOS/macOS/tvOS** → Native `AVPlayer`
-   **Web** → HTML5 `<video>` with `hls.js`

---

## 🚦 Project Roadmap

### ✅ Phase 1 – Core Functionality & Mobile MVP
- [x] Foundational architecture setup with Riverpod.
- [ ] M3U playlist parsing and playback.
- [ ] Xtream Codes login and content browsing (Live, VOD, Series).
- [ ] Basic Stalker Portal support for live channels.
- [ ] Core UI: Channel lists, EPG view, and player screen.
- [ ] User features: Favorites and Search.

### ⏳ Phase 2 – Desktop & Web
- [ ] Responsive layouts for Windows, macOS, and Linux.
- [ ] Keyboard shortcuts and window management features.
- [ ] Web version with a PWA manifest and service worker for caching.
- [ ] Backend proxy for CORS and stream transcoding (if needed).

### 🚀 Phase 3 – Advanced Features & Smart TV
- [ ] Local caching of EPG and playlists with Isar/Hive.
- [ ] Secure credential storage.
- [ ] UI optimized for 10-foot "Smart TV" experience.
- [ ] Player features: Picture-in-Picture, audio/subtitle track selection.
- [ ] Parental controls and profile management.

---

## 🔧 Tech Stack

-   **Framework**: Flutter
-   **State Management**: Riverpod
-   **Networking**: Dio
-   **Storage**: Isar / Hive (for caching) & flutter_secure_storage (for credentials)
-   **Navigation**: GoRouter
-   **Video Playback**: flutter_vlc_player, video_player

---

## 🤝 Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request.

## 📄 License

This project is licensed under the MIT License - see the `LICENSE.md` file for details.