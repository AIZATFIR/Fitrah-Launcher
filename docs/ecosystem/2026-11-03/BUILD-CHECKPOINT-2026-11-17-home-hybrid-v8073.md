# Checkpoint Home hybrid and personal preview v8073

**Date:** 17 November 2026
**Version:** `0.5.4+8073`
**Package:** `com.aizatfir.fitrah_launcher`

## Delivered

Home now projects a selected hybrid habit as **Mulai rangkaian**. The action opens the shared `SadarTimerView` and passes the selected goal snapshot to the shared session. The timer shows the active set, focus/rest phase and phase countdown. Completion copy separates focused work from rest; only fully completed work sets count toward the habit target.

Screen-time settings, Android usage/overlay bridge and the opt-in soft drawer limit remain present. Both switches default off. They are covered here by settings/drawer tests; this checkpoint's device smoke exercised Home launch, not a fresh overlay permission journey.

## Verification

- 83 focused tests passed across intent projection/repository, Home cue, Sadar timer view/state machine, YPT shared timer and native Isar persistence/reopen.
- 23 screen-time settings and app-drawer tests passed.
- `flutter analyze --no-pub`: no errors; five info-level diagnostics remain in unrelated files (`app_preferences_sheet.dart`, `fitrah_home_view.dart`, `blueprint_editor_sheet.dart`).
- `git diff --check` passed.
- Release APK built in 201.5 seconds. Metadata: min SDK 24, target SDK 35, universal `arm64-v8a`/`armeabi-v7a`/`x86_64`; Android Debug certificate signature verified.
- APK installed on disposable Android 36 x86_64 AVD and `MainActivity` reached resumed state. Home screenshot: `.dart_tool/android-qa/v8073-home.png`.
- SHA-256: `eef65f092abf055971dac5865038a724f4dde70014022e409c4809056c552039`.

Download bundle: [v8073 install notes](../../../release_dist/2026-11-17-fitrah-launcher-home-hybrid-preview-v8073/INSTALL.md).

## Limits and next work

This is a personal preview, not a public release. Production signing, physical/OEM testing, TalkBack review, and extended daily-use evidence remain open. Home progression execution/history and broader E0–E6 persistence, session, scheduling and integration gates remain open; BYOK agent, cross-app sync, WhatsApp, MCP and public-source release are later milestones. The ecosystem is not complete.
