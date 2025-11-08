🎬 OpenIPTV — Modular IPTV Framework (Flutter)

OpenIPTV is a modern, modular IPTV client written in Flutter, supporting Stalker/Ministra, Xtream Codes, and M3U/XMLTV portals.
Built with clean architecture, secure storage, and a world-class login experience — entirely open source, and powered by community support.

🌍 Overview

OpenIPTV is an open-source initiative to modernize the IPTV ecosystem — focusing on speed, privacy, and elegance.
It’s a full-stack, cross-platform IPTV solution designed to be as robust for developers as it is friendly for users.

🚀 Core Features

🧩 Unified Discovery System
	•	One engine that detects, normalizes, and connects to Stalker, Xtream, or M3U portals automatically.
	•	Handles messy URLs, ports, and redirects with retry and HTTPS fallback logic.

🔍 Intelligent Portal Recognition
	•	Smart classification of user inputs.
	•	Auto-extracts credentials, reconstructs valid endpoints, and autofills forms.
	•	Seamlessly reclassifies Xtream-based M3U links.

⚙️ Protocol Support
	•	Stalker / Ministra: Token + MAC handshake, profile retrieval, and category lists.
	•	Xtream Codes: Player API integration with live, VOD, and series metadata counts.
	•	M3U/XMLTV: Tag-aware playlist parsing with heuristic grouping.

💾 Secure Storage & Persistence
	•	Drift database for non-secret configuration.
	•	Flutter Secure Storage for passwords and tokens.
	•	Cached discovery results with silent revalidation.

🧱 Modular Architecture
	•	Clean separation between adapters, services, and UI layers.
	•	Riverpod-driven state management and dependency injection.
	•	Dio-based unified network client with smart error handling.

🧠 Modern UI & UX
	•	Single Connect button with optional “Save for later” checkbox.
	•	Responsive layout with side-by-side panels on desktop and stacked mobile design.
	•	Animated feedback for success, retries, and errors.

🔐 Security First
	•	Secrets only built in memory.
	•	Redacted logs, configurable debug switch.
	•	Secure defaults with optional “allow self-signed” for advanced users.

🧪 Tested & Reliable
	•	Mocked portal adapters and end-to-end regression tests.
	•	Verified behaviors for redirects, UA blocking, and TLS fallback.
	•	Strict type safety and error taxonomy.



📡 Player Page (Preview)
	•	Displays grouped categories for Live TV, VOD, Series, and Radio — no bulk channel fetching.
	•	Fetches and shows portal metadata: user info, expiration, active connections, and counts.
	•	Built to evolve into a full player module for live and on-demand content.



✨ Highlights

Area	Description
Login Flow	Unified for all provider types with clear progress feedback.
Persistence	Only saves credentials when the user opts in.
Performance	Optimized discovery with adaptive retries and caching.
Code Quality	Modular, clean, and testable for long-term stability.



🧭 Roadmap — What’s Next

The groundwork is done. The next leap turns OpenIPTV into a fully-featured player.

🔮 Upcoming Milestones
	1.	Channel & EPG Database — build a scalable local database for storing categories, channels, and guide data.
	2.	Player Engine — implement adaptive streaming, playback controls, subtitles, and overlays.
	3.	Next-Gen UI — craft a sleek, immersive media experience that feels natively at home across platforms.



☕ Support the Project

OpenIPTV is 100% open source and built with passion.
If you love the idea of a free, privacy-respecting IPTV framework that keeps getting better — consider fueling it with a coffee.

Every donation helps fund:
	•	development time 🧠
	•	Advanced testing and player research 🧪
	•	UI/UX design improvements 🎨
	•	And yes, the real coffee ☕

👉 Support the project on Ko-fi: https://ko-fi.com/openiptv￼



🧩 Tech Stack

Component	Technology
Frontend	Flutter (Material 3)
State Management	Riverpod
Networking	Dio
Storage	Drift + Flutter Secure Storage
Testing	Flutter Test, Mocktail
Architecture	Clean, modular, DI-ready



🤝 Contributing

Contributions are welcome!
Whether it’s code, docs, testing, or design — your effort helps shape the future of open IPTV software.

Join in, open a PR, or share ideas — every bit of energy makes this project better.


🧡 Vision

OpenIPTV aims to redefine what free and open IPTV software can be: fast, secure, transparent, and beautiful.
No ads. No tracking. Just open innovation — built by the community, for the community.
