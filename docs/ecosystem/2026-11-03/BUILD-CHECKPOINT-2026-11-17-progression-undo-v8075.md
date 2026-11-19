# Build checkpoint — progression undo v8075

**Date:** 17 November 2026
**Artifact:** [personal preview bundle](../../release_dist/2026-11-17-fitrah-launcher-progression-undo-preview-v8075/INSTALL.md)
**APK:** `Fitrah_Launcher_0.5.6_universal_v8075.apk`
**Version:** 0.5.6+8075
**SHA-256:** `62f5906b31cdfd315a4c541e95cb66e222ff02b24c0b2c74ba2ac92409ddcbc5`

## Delivered

- Added a versioned progression completion snapshot containing the exact step and prior entry status/value/target/completion time/source.
- Added guarded transactional undo. It is allowed only for the latest completion while the current cursor and step still match. Undo restores the previous entry evidence and progression cursor, retaining notes and measured durations.
- Home confirms completion and undo, displays the recorded step after completion, and exposes undo. Sadar Today uses the same repository guard and displays historical step details.
- Persisted the new optional snapshot using Isar property ID 12, preserving prior property IDs. Live-model and backup codecs round-trip the field; backups without it remain compatible.

## Verification

- `flutter test --no-pub --concurrency=1 test/home_habit_repository_test.dart test/live_model_codec_test.dart test/focus_clock_backup_codec_test.dart test/isar_service_persistence_test.dart test/home_intent_cue_test.dart --reporter expanded`: **69 passed**.
- Extended native close/reopen progression coverage and reran `test/home_habit_repository_test.dart`: **22 passed**. `test/sadar_repository_test.dart` and `test/sadar_ui_test.dart`: **20 passed**.
- `flutter analyze --no-pub`: no errors; five existing info diagnostics in unrelated files.
- Release APK built for arm, arm64, and x86_64. `aapt` confirms package `com.aizatfir.fitrah_launcher`, version `0.5.6` / code `8075`, min API 24, target API 35. `apksigner` verifies v2 signature; signer is local Android Debug certificate.
- Installed/launched on the disposable API36 x86_64 AVD. Verified saved LKS goal, selected and goal-linked `Latihan LKS 30 menit` from Home, started its timer, ended early, and returned to Home. Home remained the Android HOME role holder; log tail contained no Flutter/Android fatal error. Screenshot: `.dart_tool/android-qa/v8075-home-action-session-smoke.png`.
- Physical Android/OEM, TalkBack and multi-day use remain unverified.

## Remaining

This checkpoint closes only progression history/undo. Physical Android/OEM behavior, TalkBack and other accessibility paths, production signing, extended personal use, full E0–E6 acceptance, and future ecosystem integrations (AI, sync, WhatsApp, MCP, open source/public release) remain open. Prior v8074 remains available as a rollback preview.
