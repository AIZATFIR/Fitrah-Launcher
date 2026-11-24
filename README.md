# Focus Clock · Fitrah Launcher

Focus Clock helps you keep a meaningful goal in view, see today's plan, and begin the next activity. Fitrah Launcher brings that flow to Android Home. The current app keeps the clock face and bookpaper themes alongside the goal-first **Hari Ini** screen.

## Current app

The main navigation has three destinations:

- **Jam** — plan and review the day on the analog clock.
- **Hari Ini** — see the pinned goal, current/next action, agenda, and habits.
- **Aplikasi** — search and open installed Android apps; favorites and hidden apps are managed here.

Focus sessions, goals, schedules, habits, and backup are available in the app. AI planning is optional and uses a provider/API key configured by the user. It can prepare a reviewable goal plan; applying it requires the user's approval. Screen-time overlay and waiting features are optional and off by default.

Try [Focus Clock](https://focus-clock-web.vercel.app/), [Fitrah](https://fitrah-web-three.vercel.app/), or [Sadar](https://sadar-web.vercel.app/). Android stores app data on-device. Web stores data in the current browser profile; this is not cloud sync or a backup. The installed-app drawer and default Home role are Android-only. See the [latest checkpoint](docs/ecosystem/2026-11-03/BUILD-CHECKPOINT-2026-11-24-focus-clock-v8154.md), the [owner-preview release downloads](https://github.com/AIZATFIR/Fitrah-Launcher/releases/tag/v0.5.62-v8154), the [single all-platform bundle](https://github.com/AIZATFIR/Fitrah-Launcher/releases/download/v0.5.62-v8154/Focus_Clock_Ecosystem_0.5.62_v8154.zip), and the [ecosystem plan](docs/ecosystem/2026-11-03/README.md) for verified behavior and remaining work.

## Try the owner preview

The current owner preview is v0.5.62 / 8154. Download the [single all-platform ZIP](https://github.com/AIZATFIR/Fitrah-Launcher/releases/download/v0.5.62-v8154/Focus_Clock_Ecosystem_0.5.62_v8154.zip) or choose individual files from the [GitHub release page](https://github.com/AIZATFIR/Fitrah-Launcher/releases/tag/v0.5.62-v8154). The ZIP includes install notes and checksums. The Android APK is signed with the stable owner-preview key, not a Play Store distribution key.

## Run from source

Requirements: Flutter 3.41.9 / Dart 3.11.5, Android SDK, and JDK 17 or newer for Android builds. The checked-in lockfile is the dependency source of truth.

```sh
git clone https://github.com/AIZATFIR/Fitrah-Launcher.git
cd Fitrah-Launcher
flutter pub get
flutter run
```

Useful release commands:

```sh
flutter build apk --release
flutter build web --release
```

The Android app ID is `com.aizatfir.fitrah_launcher` (minimum Android API 24). To make it the Home app, install and launch it, then select **Fitrah Launcher** in Android's Home app/default apps settings. You can use the app without making it the default launcher.

## Project status and license

This repository is under active development; v8154 is a usable owner preview, not completion of the ecosystem. Physical-device/OEM verification, sustained daily-use review, public distribution signing, complete web/offline coverage, cross-device sync, and later agent/WhatsApp/MCP milestones remain open. Track implementation gates in the [build roadmap](docs/ecosystem/2026-11-03/BUILD-ROADMAP.md).

There is currently no `LICENSE` file. Until the owner selects and adds a license, do not assume the source may be redistributed or reused under MIT or another open-source license.
