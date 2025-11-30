# OpenIPTV Migration & Enhancement Plan

## 1. Executive Summary

This document outlines the strategy to elevate the current **OpenIPTV** repository by integrating the superior UI/UX and feature set of the reference "Flutter IPTV Player" repository. The goal is to merge the robust, "flawless" Xtream implementation and desktop-optimized layout of the reference project with the advanced Stalker integration, secure authentication (Device ID/User-Agent), and architectural strengths (Riverpod/Drift) of OpenIPTV.

**Core Objective:** Create a unified, feature-rich IPTV client that supports Xtream, Stalker, and M3U with a modern, TV-friendly interface.

---

## 2. Deep Analytic Comparison

| Feature Domain | Reference Repo (Target UX) | OpenIPTV (Current State) | Gap Analysis & Action Plan |
| :--- | :--- | :--- | :--- |
| **Architecture** | **Provider + Isar**. Simple, effective, but less scalable for complex state. | **Riverpod + Drift**. Modern, type-safe, robust state management. | **Strategy:** Retain Riverpod/Drift. Port the *logic* of the reference Providers into Riverpod Notifiers. Map Isar schemas to Drift tables. |
| **Navigation** | **Navigator 1.0**. Simple push/pop. | **GoRouter**. Declarative, deep-linking capable. | **Strategy:** Retain GoRouter. Adapt the reference's "Dashboard" navigation to GoRouter's shell route pattern. |
| **Main Layout** | **Dashboard Hub**. Central screen linking to Live, VOD, Series, Settings. | **Login -> Player Shell**. Linear flow, lacks a central hub. | **Critical Gap.** Must implement a `DashboardScreen` as the post-login home. |
| **Live TV UI** | **3-Column Layout**. Categories -> Channels -> Preview. TV-optimized. | **Basic List/Player**. Functional but minimal. | **Critical Gap.** Port the 3-column layout widget tree. This is the "signature" look to adopt. |
| **VOD/Series UI** | **Grid View**. Poster-centric with metadata. | **N/A**. | **Critical Gap.** Implement `ContentGridScreen` and `SeriesGridScreen` using the reference's grid logic. |
| **Xtream Logic** | **"Flawless" Service**. Lazy loading, auto-categorization, robust error handling. | **HttpClient Wrapper**. Good low-level connection, but lacks high-level content management. | **Upgrade Required.** Refactor `XtreamHttpClient` to include the "Service" layer logic: lazy loading episodes and smart categorization. |
| **Stalker** | **None**. | **Full Integration**. | **Asset.** Integrate Stalker content into the new Grid/3-Column layouts seamlessly. |
| **Player** | **MediaKit + Overlays**. Custom controls, audio/sub tracks. | **MediaKit**. Basic integration. | **Enhancement.** Adopt the reference's player overlay UI (seeking, tracks, aspect ratio) into `player_shell.dart`. |

---

## 3. Detailed Implementation Roadmap

### Phase 1: Foundation & Data Layer (The "Flawless" Xtream Upgrade)
*Goal: Ensure the backend logic can support the rich UI before building it.*

1.  **Database Expansion (Drift)**: ✅ **DONE**
    *   Expand the Drift schema to support **EPG**, **Favorites**, and **Watch History** (mirroring the reference's Isar models).
    *   Create tables for `Movies`, `Series`, and `Episodes` to support caching and lazy loading.
2.  **Xtream Service Upgrade**: ✅ **DONE** (via `PlayableResolver`)
    *   Create a `XtreamRepository` (Riverpod provider) that mimics the reference's `xtream_service.dart`.
    *   **Lazy Loading**: Implement pagination for Series Episodes. Don't fetch all episodes at login; fetch on demand when a series is selected.
    *   **Categorization**: Implement logic to parse and group streams into "Live", "Movies", and "Series" buckets if the API returns a flat list.

### Phase 2: UI/UX Overhaul (The "Layout" Transplant)
*Goal: Make OpenIPTV look and feel like the reference app.*

1.  **Dashboard Implementation**:
    *   Create `lib/src/ui/dashboard/dashboard_screen.dart`.
    *   Design: Large cards/tiles for "Live TV", "Movies", "Series", "Settings".
2.  **Live TV 3-Column Interface**: ✅ **DONE** (Basic Implementation)
    *   Create `lib/src/ui/live/live_tv_screen.dart`.
    *   **Column 1 (Groups)**: Vertical list of categories.
    *   **Column 2 (Channels)**: Vertical list of channels in selected group.
    *   **Column 3 (Preview)**: Mini-player (using MediaKit) and program info (EPG).
    *   *Integration*: Ensure this screen works for **both** Xtream and Stalker sources.
3.  **VOD & Series Grids**: ✅ **DONE**
    *   Create `lib/src/ui/vod/vod_grid_screen.dart`.
    *   Implement a responsive grid (using `SliverGrid`) that scales with window size.
    *   Cards should show the poster (from Xtream/Stalker) and title.
4.  **Player UI Refinement**: ✅ **DONE** (via `MiniPlayer` refactor)
    *   Enhance `player_shell.dart`.
    *   Add the "Overlay" layer from the reference repo:
        *   Channel list overlay (slide from left).
        *   Audio/Subtitle track selector dialog.
        *   "Real Fullscreen" toggle.

### Phase 3: Feature Injection
*Goal: Add the "Extra Features" that make the app complete.*

1.  **EPG (Electronic Program Guide)**:
    *   Port `epg_service.dart` logic.
    *   Parse XMLTV or Xtream EPG data.
    *   Display current/next program in the Channel List and Player Overlay.
2.  **Favorites System**:
    *   Add "Heart" icon to UI.
    *   Persist favorite IDs in Drift.
    *   Create a "Favorites" category in the Live TV Group list.
3.  **Search**:
    *   Implement a global search provider that queries the local Drift database for channels/movies matching the query.

---

## 4. Technical Guidelines for the Transplant

### Preserving "Advanced Options" & "Stalker"
*   **Login Flow**: Keep the current `login_screen.dart` as the gatekeeper. It already handles the complex `DeviceIdentity` and `User-Agent` logic.
*   **Headers**: Ensure the `XtreamRepository` continues to use the `XtreamHttpClient` we fixed (with `X-Device-Id` and `okhttp` headers). **Do not** replace the HTTP client with a generic one; just layer the new logic *on top* of it.
*   **Stalker Adaptation**: The Stalker protocol returns content differently. Map Stalker's "Genres" to "Groups" and "VOD" to "Movies" so they fit into the new 3-Column and Grid UIs. The UI should be agnostic to the protocol.

### Redaction & Privacy
*   The reference repository is a public source. We are adopting its *design patterns* and *logic*, but implementing them within our own architecture.
*   No proprietary names or identifiers from the reference author should be present in the code.

## 5. Immediate Next Steps
1.  **Analyze** the reference `xtream_service.dart` to understand the exact lazy-loading mechanism.
2.  **Scaffold** the `DashboardScreen` to replace the direct jump to `player_shell.dart`.
3.  **Refactor** `XtreamHttpClient` to return structured data (Groups/Channels) compatible with the new UI.
