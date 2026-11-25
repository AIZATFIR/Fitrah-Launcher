# Empty input fields and v8132 owner preview — 23 November 2026

Removed illustrative sample values from empty AI provider and wallpaper URL fields. A weekly schedule row created during plan review now starts with blank time and duration fields; partial typing no longer displays a format error before the row is complete. Existing saved values and AI-generated plan values remain intact. Search fields retain short action labels because those describe the control rather than provide sample content.

## Verification

- `flutter build apk --release --no-pub` succeeded: universal APK 0.5.41 / build 8132, package `com.aizatfir.fitrah_launcher`, min API 24, target API 35. APK v2 signature verified with the established owner-preview certificate SHA-256 `b8af9d95…34fe3e`.
- `npm run build:focus` succeeded and the JS bundle passed required-asset verification. The Wasm dry-run reports existing Isar, secure-storage and TTS incompatibilities.
- `flutter analyze --no-pub` reports no errors or warnings; eight info-level notices remain (several in pre-existing files, including three formatting notices in the launcher customization file).
- Web production deployment `dpl_AMUnUKuvwi4faVKuLUtWP61twCty` is READY. Production root and `main.dart.js` return HTTP 200; `/version.json` reports 0.5.41 / 8132.
- APK signature, web ZIP integrity, `SHA256SUMS`, and `git diff --check` verified.
- API36 x86_64 AVD `FocusClock_UI_QA` installed v8132 over the existing owner preview. Fitrah remained Android HOME, first-install time stayed `2026-11-16 10:41:54`, the QA goal and clock remained visible at 1080×2400 / 200% font scale, and force-stop/cold launch had no sampled fatal, ANR or Flutter error. Screenshot: `.dart_tool/android-qa/v8132/home.png`.
- Automated tests and physical-device checks were not run for this copy/empty-field slice.

This is a personal owner preview. Android and browser data do not sync. Physical OEM, TalkBack, live provider and sustained-use checks remain open.

[Download and install notes](../../../release_dist/2026-11-23-empty-inputs-v8132/INSTALL.md).
