# 🤲 Adhkar Gaza (أذكار غزة)

<div align="center">

[![Live Demo](https://img.shields.io/badge/Live_Demo-adhkar--gaza.pages.dev-0a6482?style=for-the-badge&logo=cloudflarepages&logoColor=white)](https://adhkar-gaza.pages.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![PWA Ready](https://img.shields.io/badge/PWA-Offline--First-5A0FC8?style=for-the-badge&logo=pwa&logoColor=white)](https://adhkar-gaza.pages.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

**A modern, lightweight, and offline-first Progressive Web App (PWA) for daily Islamic remembrances (Adhkar), prayers, and daily spiritual streak tracking.**

*Dedicated as an ongoing charity (Sadaqah Jariyah) for our people in Gaza.*

[Explore Live App](https://adhkar-gaza.pages.dev) · [Report Bug](https://github.com/wassimsn/adhkar-gaza/issues) · [Request Feature](https://github.com/wassimsn/adhkar-gaza/issues)

</div>

---

## ✨ Features

- 📖 **Comprehensive Adhkar Library**: Morning, Evening, After Prayer, Sleep, and dedicated supplications for Gaza and Palestine.
- ⚡ **Offline-First PWA Architecture**: Operates completely offline without an internet connection using a dedicated, high-performance custom Service Worker.
- 🔥 **Daily Streak & Habit Tracker**: Visual calendar dashboard tracking your consistency, streaks, and completed daily remembrance goals.
- 🔔 **Smart Web Push Notifications**: Cloudflare Workers background cron engine sending prayer and remembrance reminders with VAPID web-push encryption.
- 🎨 **Glassmorphic Islamic Aesthetics**: Custom-crafted UI with responsive Dark & Light themes, fluid animations, and typography powered by Arabic Google Fonts (*Cairo* & *Amiri*).
- 📳 **Interactive Counter & Feedback**: Single-tap count incrementation, milestone completions, haptic feedback, and auto-progression.
- 📱 **Installable Anywhere**: Install directly onto iOS, Android, macOS, or Windows as a standalone application right from the browser.

---

## 🛠️ Tech Stack & Architecture

### Frontend (Client App)
- **Framework**: [Flutter Web](https://flutter.dev) (Channel Stable)
- **Language**: [Dart](https://dart.dev)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Local Storage**: `shared_preferences` & Local Cache API
- **Calculations**: [Adhan Dart](https://pub.dev/packages/adhan) for accurate prayer times
- **Styling**: Custom Glassmorphism Theme, Responsive Layouts, Dynamic Dark/Light mode

### Backend & Infrastructure
- **Hosting**: [Cloudflare Pages](https://pages.cloudflare.com)
- **Serverless Worker**: [Cloudflare Workers](https://workers.cloudflare.com) (`worker/` directory)
- **Database / Cache**: Cloudflare KV (`PUSH_SUBSCRIPTIONS`)
- **Push Engine**: `web-push-neo`, `jose` for VAPID RFC8292 encryption & scheduled 5-minute crons

---

## 📁 Project Structure

```text
adhkar_gaza/
├── assets/
│   ├── data/adhkar.json      # Structured collection of prayers & adhkar
│   ├── fonts/                # Amiri & Cairo Arabic typefaces
│   └── icon.png              # App icon & branding
├── lib/
│   ├── models/               # Data structures (DailyTracker, Dhikr, etc.)
│   ├── providers/            # State management (Adhkar, Streak, Theme, Settings)
│   ├── screens/              # UI views (Home, Adhkar, Streak Dashboard, Prayer)
│   ├── services/             # Services (Adhkar, Notifications, PWA Install, Streak)
│   ├── theme/                # Glassmorphic themes & typography
│   └── widgets/              # Reusable UI widgets & glass cards
├── scripts/
│   └── generate_offline_worker.dart  # Custom Service Worker cache generator
├── web/                      # Web manifest, icons, headers & PWA config
├── worker/                   # Cloudflare Worker for automated push notifications
└── build.bat                 # One-click release build & deployment script
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.11.0` or higher)
- [Dart SDK](https://dart.dev/get-dart)
- Chrome / Edge or any modern browser

### Local Development

1. **Clone the repository:**
   ```bash
   git clone https://github.com/wassimsn/adhkar-gaza.git
   cd adhkar-gaza
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the development web server:**
   ```bash
   flutter run -d chrome
   ```

---

## 📦 Building & Deploying

To build the optimized production PWA and deploy directly to Cloudflare Pages:

```cmd
# Run the automated build and deployment script:
.\build.bat
```

The script will automatically:
1. Compile Flutter Web in release mode with offline-first strategy.
2. Run `scripts/generate_offline_worker.dart` to index all web assets into the offline cache.
3. Attach proper CSP & caching headers from `web/_headers`.
4. Deploy the build directory to **Cloudflare Pages**.

---

## 🤲 Dedication & Charity

This project is built and maintained as a continuous charity (**Sadaqah Jariyah** / صدقة جارية) for the innocent souls and resilient people of Gaza. 

Feel free to use, distribute, and contribute to this repository. May Allah accept it from everyone involved.

---

## 👤 Author

**Wassim Moussouni**
- GitHub: [@wassimsn](https://github.com/wassimmssn)
- Live Web App: [adhkar-gaza.pages.dev](https://adhkar-gaza.pages.dev)
