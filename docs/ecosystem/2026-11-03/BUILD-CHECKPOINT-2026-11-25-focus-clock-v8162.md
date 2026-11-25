# Focus Clock / Fitrah owner preview v8162

**Date:** 25 November 2026  
**Version:** 0.5.70 / build 8162

## Clock labels and mobile settings

Kept the selected clock face and bookpaper palette. In the 12-hour dial, numerals `1`–`12` sit outside the bezel for every face theme; the repeated `00`/`05` minute labels stay removed while minute ticks remain. On phones, desktop keyboard-shortcut instructions are hidden from Settings; tablet and desktop layouts retain them.

## Evidence

- `dart format lib/features/focusclock/analog_clock_face.dart`: clean.
- `flutter analyze lib/features/focusclock/analog_clock_face.dart`: no issues.
- `git diff --check`: clean.
- Release APK built and installed over the existing API 36 emulator app; Android package metadata reports `0.5.70` / `8162`.
- Focus Clock, Fitrah, and Sadar JavaScript web bundles built and passed `verify_web_bundle.sh`.
- Production deployments reached READY: Focus Clock (`dpl_3xPdJgthN6PpHBgjVwqjm1ybP57i`), Fitrah (`dpl_Bn9YwgSAuew5bsJ9tegeDVBumuxs`), and Sadar (`dpl_2iUrQmr4MtvKYwEFbyP6QntwWzc6`). All three `/version.json` endpoints report `0.5.70` / `8162`. The Fitrah deployment has Vercel authentication protection enabled.
- Automated test suites and full UI walkthrough were not run. Physical/OEM and TalkBack behavior remain unverified.

## Remaining ecosystem gates

This is an owner preview, not ecosystem completion. The tagged all-platform release workflow, physical/OEM behavior, TalkBack, sustained daily use, public distribution signing, complete web/offline coverage, cross-device sync, a live AI provider call, and later agent/WhatsApp/MCP milestones remain open. Android data and each browser profile remain separate.

## Downloads

The tagged GitHub owner-preview release will publish the Android APK, Windows/Linux builds, all three web exports, checksums, and one all-platform ZIP after CI completes.
