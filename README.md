# Focus Clock · Fitrah Launcher

Focus Clock helps you keep a meaningful goal in view, see today's plan, and begin the next activity. Fitrah Launcher brings that flow to Android Home. The current app keeps the clock face and bookpaper themes alongside the goal-first **Hari Ini** screen.

## Current app

The main navigation has three destinations:

- **Jam** — plan and review the day on the analog clock.
- **Hari Ini** — see the pinned goal, current/next action, agenda, and habits.
- **Aplikasi** — search and open installed Android apps; favorites and hidden apps are managed here.

Focus sessions, goals, schedules, habits, and backup are available in the app. AI planning is optional and uses a provider/API key configured by the user. It can prepare a reviewable goal plan; applying it requires the user's approval. Screen-time overlay and waiting features are optional and off by default.

Try the [Focus Clock web app](https://focus-clock-web.vercel.app/). Android stores app data on-device. Web stores data in the current browser profile; this is not cloud sync or a backup. The installed-app drawer and Home role are Android-only. See the [latest v8118 Android preview](docs/ecosystem/2026-11-03/BUILD-CHECKPOINT-2026-11-21-schedule-list-v8118.md), the [web checkpoint](docs/ecosystem/2026-11-03/BUILD-CHECKPOINT-2026-11-21-focus-clock-web-vercel.md), and [ecosystem plan](docs/ecosystem/2026-11-03/README.md) for tested behavior and remaining work.

## Try the owner preview

The v8118 personal preview is in `release_dist/2026-11-21-focus-clock-schedule-list-v8118/` in the maintainer's local checkout. It is intentionally not presented as a public GitHub release. The Android APK is signed with a local Android Debug certificate, so it is a personal preview rather than a Play Store build. See that folder's `INSTALL.md` and `SHA256SUMS` before installing.

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

This repository is under active development; v8118 is a personal checkpoint, not completion of the ecosystem. Physical-device/OEM verification, sustained daily-use review, production signing, public releases, complete web/offline coverage, and later sync/WhatsApp/MCP milestones remain open. Track implementation gates in the [build roadmap](docs/ecosystem/2026-11-03/BUILD-ROADMAP.md).

There is currently no `LICENSE` file. Until the owner selects and adds a license, do not assume the source may be redistributed or reused under MIT or another open-source license.
