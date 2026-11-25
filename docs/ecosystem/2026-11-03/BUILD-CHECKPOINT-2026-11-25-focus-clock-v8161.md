# Focus Clock / Fitrah owner preview v8161

**Date:** 25 November 2026  
**Version:** 0.5.69 / build 8161

## Home clock card at large text

At 320 dp width and 200% system text, the compact clock card split its small all-caps “SEKARANG” label and the redundant “Buka jam” action across lines. The analog dial itself is already an accessible tap target that opens Jam. Removed those two duplicates; kept the digital time, current activity/status, and Timer action. This shortens the card while preserving the selected dial, color, and type choices.

## Evidence

- `dart format lib/features/launcher/widgets/focus_clock_home_view.dart`: clean.
- `flutter analyze --no-pub lib/features/launcher/widgets/focus_clock_home_view.dart`: no issues.
- `git diff --check`: clean.
- Release APK built and installed over v8160 on API 36 emulator; package reports version 0.5.69 / code 8161.
- Manual screenshot review at 320 dp / 200% text shows digital time, schedule status, and Timer without clipped words. The emulator was returned to 1080×2400 and 100% text afterward.
- Fitrah (`dpl_Go8Xw8DF9X3hahBuQkw8c9bn1JXD`), Focus Clock (`dpl_Ffyz25M7nDC1vdVbE61FR1FKsd8b`), and Sadar (`dpl_Fb6K9RfaE9DLhsa4639wkgPFqipe`) production deployments reached READY; all three `/version.json` endpoints report 0.5.69 / 8161.
- Tagged workflow [45624718824](https://github.com/AIZATFIR/Fitrah-Launcher/actions/runs/45624718824) passed Android/signature, Windows, Linux, web, and publish jobs. The GitHub release contains the APK, desktop builds, web exports, checksums, and all-platform ZIP.
- Automated test suites were not run. Physical-device/OEM and TalkBack behavior remain unverified.

## Remaining ecosystem gates

This is an owner preview, not ecosystem completion. Physical/OEM behavior, TalkBack, sustained daily use, public distribution signing, complete web/offline coverage, cross-device sync, a live AI provider call, and later agent/WhatsApp/MCP milestones remain open. Android data and each browser profile remain separate.

## Downloads

The tagged GitHub release is `v0.5.69-v8161`; CI publishes the Android APK, Windows/Linux builds, all three web exports, install notes, checksums, and one all-platform ZIP.
