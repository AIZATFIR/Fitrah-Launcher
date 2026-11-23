# Sadar habit editor starts clear — v8136 (23 November 2026)

The Home habit create/edit shortcut now opens the same Sadar editor used elsewhere, removing the duplicate modal and its silent fixed 20-minute target. New timed/count targets, hybrid set/duration values and progression schedules begin blank. The progression editor adds a blank step only when the owner asks for one. Missing or invalid inputs now show an inline explanation in the open editor. Home action labels and weekday labels were adjusted for large text.

## Verification

- `flutter analyze --no-pub` on the four changed Dart files: no issues.
- Universal APK 0.5.45 / 8136 built and installed over prior data on API 36 x86_64 AVD. Package reports versionCode 8136, versionName 0.5.45 and preserved first-install timestamp. Cold launch at 200% font scale retained the QA goal and displayed the Home layout. Screenshot: [Home at 200%](../../../release_dist/2026-11-23-habit-editor-empty-inputs-v8136/QA_Home_v8136.png).
- Focus Clock JavaScript web bundle built; Wasm dry run continues to report existing Isar, secure-storage and TTS incompatibilities. Production deployment `dpl_7ix3452MK53VvhCfHg1jSKS858qY` is READY; version endpoint reports 0.5.45 / 8136 and production root responds HTTP 200.
- APK signing metadata, package version, web ZIP integrity and package checksums verified.
- Automated tests were not run. The missing-target inline message is enforced by source validation but was not manually tapped through in this verification.

## Still open

This checkpoint advances the owner preview; it does not finish the full ecosystem. Physical/OEM behavior, TalkBack, real BYOK providers, seven-day use, cross-device sync, WhatsApp/MCP and open-source distribution remain open. Android and browser data remain separate. The APK uses a local owner-preview certificate.

[Install and download notes](../../../release_dist/2026-11-23-habit-editor-empty-inputs-v8136/INSTALL.md).
