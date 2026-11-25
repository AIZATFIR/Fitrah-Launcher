# Checkpoint: timer start reservation — 17 November 2026

Source includes a shared start reservation in `SadarTimerEngine`. It closes the async race where two different requests both observed an idle timer before Android clock snapshot retrieval completed. Different concurrent sessions now accept only one active start; an identical concurrent habit start joins the same session.

Verification:

- `flutter test --no-pub test/sadar_timer_state_machine_test.dart test/focus_session_shared_timer_test.dart test/quick_timer_hub_shared_session_test.dart --reporter expanded` — 38 passed.
- `flutter analyze --no-pub lib/services/sadar_timer_engine.dart test/sadar_timer_state_machine_test.dart` — no issues.
- `git diff --check` — clean.
- `flutter build apk --release --no-pub` — passed in 152.8 seconds.
- APK metadata reports package `com.aizatfir.fitrah_launcher`, version 0.5.3, versionCode 8069, minSDK24, targetSDK35, compileSDK36. APK signature verified; universal archive contains arm64-v8a, armeabi-v7a and x86_64.
- SHA-256: `e452a312f75008d9997e5b9f26f6156f94accde254b70d7db83c91e899bbbb56`.

Personal preview package: `release_dist/2026-11-17-fitrah-launcher-timer-race-preview-v8069/`.

VersionCode8069 has not been run on an emulator or physical Android device. The APK uses the local Android Debug certificate, so this is not a public production release. E2 is not complete: reboot/time uncertainty, durable history and reconciliation, notifications, cross-screen handoff, and physical-device behavior remain open. The larger ecosystem goal (Sadar/Focus Clock/Launcher cohesion, robust AI goal companion, BYOK, WhatsApp, MCP, open-source publication) remains a multi-phase project.
