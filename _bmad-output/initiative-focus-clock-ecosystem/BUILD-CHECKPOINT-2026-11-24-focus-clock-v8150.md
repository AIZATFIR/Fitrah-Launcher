# Focus Clock clarity and ecosystem preview v8150

**Version:** 0.5.58 / versionCode 8150  
**Source commit:** `ee04b5eff0928d2f82b385001f2e4b8927a89e80`  
**Tag:** [`v0.5.58-v8150`](https://github.com/AIZATFIR/Fitrah-Launcher/releases/tag/v0.5.58-v8150)  
**One-file download:** [Focus Clock Ecosystem 0.5.58 v8150](https://github.com/AIZATFIR/Fitrah-Launcher/releases/download/v0.5.58-v8150/Focus_Clock_Ecosystem_0.5.58_v8150.zip) · [SHA-256](https://github.com/AIZATFIR/Fitrah-Launcher/releases/download/v0.5.58-v8150/Focus_Clock_Ecosystem_0.5.58_v8150.zip.sha256)

**Install notes and platform files:** [release folder](../../release_dist/2026-11-24-focus-clock-v0.5.58-8150/INSTALL.md)

## What changed

- Timer copy now says where the completed duration goes for a scheduled block, a preset, or free focus. Free focus adds to today's focus total; it does not pretend to create a schedule item.
- The AI panel's small disclosure now says plainly that messages and goals are sent to the chosen AI provider and that chat history is not saved in the app.
- The earlier Home/Jam chat shortcut under **TUJUAN UTAMA** remains removed; AI is still available from its separate assistant screen.

## Evidence

- Focused Dart analyzer and `git diff --check` passed.
- Android release APK built locally and through CI; APK reports v0.5.58 / 8150 and its v2 signature uses the stable owner-preview certificate.
- API 36 x86_64 `Fitrah_Clean_Install_QA` upgraded from v8149. Fitrah kept the Android HOME role, the saved daily choice and 1:21 focus total remained, and the timer displayed the new free-focus explanation. Cancel returned Home without changing the existing focus total. Sampled logcat had no app fatal, FlutterError, or ANR.
- GitHub Actions [release workflow 45414831872](https://github.com/AIZATFIR/Fitrah-Launcher/actions/runs/45414831872) succeeded for Android, Linux, Windows, all three web bundles, and release publication. All six published assets passed the release SHA-256 check; web bundles contain `main.dart.js`, `version.json`, and the service worker.
- Production web aliases were redeployed and return HTTP 200 for the home page and `main.dart.js`; each `version.json` reports 0.5.58 / 8150:
  - [Fitrah](https://fitrah-web-three.vercel.app/) — deployment `dpl_5wRN8cwGaGnxZb6fgspYC4AwKjPN`
  - [Focus Clock](https://focus-clock-web.vercel.app/) — deployment `dpl_ChLgp9PQboVBGC6ckPGpaLkbGvKJ`
  - [Sadar](https://sadar-web.vercel.app/) — deployment `dpl_2xLWtCSpnKCBAuULLBCtpPJmZjwN`
- The Flutter JavaScript builds succeeded and offline bundle checks passed. Flutter also printed existing Wasm compatibility dry-run warnings from `isar_community`, `flutter_secure_storage_web`, and `flutter_tts`; these did not block JavaScript output or deployment.
- A combined ecosystem ZIP and its checksum sidecar were added to the GitHub release after the six platform assets. The public download URL responds HTTP 200; `unzip -t` and the local sidecar checksum pass.
- [Checksums](../../release_dist/2026-11-24-focus-clock-v0.5.58-8150/SHA256SUMS.txt), [manifest](../../release_dist/2026-11-24-focus-clock-v0.5.58-8150/BUILD-MANIFEST.json), [Home screenshot](../../release_dist/2026-11-24-focus-clock-v0.5.58-8150/QA_Fitrah_Home_v8150.png), and [timer screenshot](../../release_dist/2026-11-24-focus-clock-v0.5.58-8150/QA_Fitrah_Timer_v8150.png) record the package and emulator smoke.

## Still open

This is a usable owner-preview checkpoint, not completion of the ecosystem. No physical/OEM phone was available; Android and web data still do not sync; and the long-run daily-use, TalkBack, and real AI-provider flows remain unverified. The APK is not a Play Store release. QA screenshots, manifest, and install folder are local workspace artifacts; the full platform assets and combined ZIP are attached to the GitHub release.
