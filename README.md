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

- 🌐 **Full Bilingual Support (French & Arabic)**: Seamless language switching across all screens (Home, Invocations, Prayers, Sijil tracker, Settings, and Dialogs).
- 🔤 **Phonetic Latin Transliteration**: Clear pronunciation aid in Latin script beneath every Dhikr, designed for learners and non-Arabic speakers.
- 🔊 **Voice Audio Recitation**: Natural pronunciation audio for each Dhikr with independent toggles in Settings and on cards.
- 🚀 **First-Launch Onboarding**: Guided modal on first open allowing users to immediately configure their preferred language and assistance options.
- 📖 **Authentic Adhkar Library**: Morning, Evening, After Prayer (5 daily prayers), and dedicated supplications for Gaza and Palestine.
- ⚡ **Offline-First PWA Architecture**: Operates completely offline without an internet connection via a custom Service Worker and local Cache API.
- 🔥 **Daily Streak & Habit Tracker (Sijil al-Moudawama)**: Interactive calendar and consistency dashboard tracking consecutive days and daily completed sessions.
- 🔔 **Smart Web Push Notifications**: Cloudflare Workers background cron engine sending prayer and remembrance reminders with VAPID web-push encryption.
- 🎨 **Glassmorphic Islamic Aesthetics**: Responsive Dark & Light themes, fluid animations, and sacred Arabic typography (*Amiri* & *Cairo*).
- 📳 **Interactive Counter & Feedback**: Single-tap count incrementation, milestone completions, haptic feedback, and auto-progression.
- 📱 **Installable Anywhere**: Install directly onto iOS, Android, macOS, or Windows as a standalone PWA right from the browser.

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
