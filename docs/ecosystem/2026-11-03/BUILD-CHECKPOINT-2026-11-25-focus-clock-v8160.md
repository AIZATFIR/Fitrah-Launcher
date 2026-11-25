# Focus Clock / Fitrah owner preview v8160

**Date:** 25 November 2026  
**Version:** 0.5.68 / build 8160

## Clock face adjustment

The existing clock face theme and colors remain intact. The 12-hour numerals sit outside the bezel, with the repeated 00/05 minute labels removed. A small dial inset now keeps 3 and 9 inside the viewport. The current-time chip is clamped to the canvas so it stays readable at the edge. Drawing and gesture hit testing share the same inset scale.

## Evidence

- Scoped `flutter analyze lib/features/focusclock/analog_clock_face.dart`: no issues.
- Release APK built and installed over the existing owner-preview APK on API 36 emulator. Upgrade signature matched the stable owner-preview signing certificate. Screenshot review confirmed all dial numerals and the current-time chip remain within the screen.
- Focus Clock, Fitrah, and Sadar web bundles built and passed `verify_web_bundle.sh`.
- Production deployments reached READY:
  - Fitrah: `dpl_4gSFHouCuqyEFmkAC7ccYx1PqMoC`
  - Focus Clock: `dpl_HuFcuKMCaZp3DaYfTz2VjwPXHq3A`
  - Sadar: `dpl_3J8pTV48zLAFXG9kaWmBURH6Y9MY`
- All three production `/version.json` endpoints returned 0.5.68 / 8160.
- Automated test suites were not run. Physical-device/OEM and TalkBack behavior remain unverified.

## Remaining ecosystem gates

This is an owner preview, not ecosystem completion. Physical/OEM behavior, TalkBack, sustained daily use, public distribution signing, complete web/offline coverage, cross-device sync, a live AI provider call, and later agent/WhatsApp/MCP milestones remain open. Android device data and each browser profile remain separate.

## Downloads

The tagged GitHub release is `v0.5.68-v8160`; CI publishes the Android APK, Windows/Linux builds, all three web exports, install notes, checksums, and one all-platform ZIP.
