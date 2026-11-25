# Focus Clock daily-use checkpoint v8100

**Date:** 20 November 2026
**Version:** 0.5.21 (versionCode 8100)
**Purpose:** A personal preview checkpoint for planning, saving, and reopening real activities in Focus Clock.

## What changed

- Kept the Bookpaper clock palette and localized the activity editor and preset picker into Indonesian.
- Made duration controls wrap on narrow screens and raised the plus/minus touch targets to 48 dp.
- Fixed a save crash affecting newly created activities from paths that did not initialize `createdAt` and `updatedAt`. Activity timestamps now have defaults, so all creation paths can serialize safely.
- Added a native Isar regression test that saves a new activity without manually assigning timestamps.

## Verification

- Full randomized Flutter suite: **438 passed, 0 failed**.
- Native Isar regression: a new activity without explicit timestamps saves and reads back successfully.
- `flutter analyze --no-pub`: five existing info-level diagnostics in unrelated files; no warning/error diagnostics.
- Universal Android APK and Flutter Web static release build succeeded.
- Fresh production web bundle opened in Chrome 150: Home and analog clock rendered, navigation worked, and the app drawer displayed its Android-only availability message. Five browser storage journeys and 12 drawer capability tests passed.
- API 36 x86_64 QA AVD: installed 0.5.21+8100, opened the Indonesian create sheet, saved `QA_v8100`, saw it on the analog clock as the 09:15–09:30 block, reopened its detail, and opened edit mode. No Flutter fatal/Unhandled Exception appeared after save. Notification permission was denied in this QA run.
- API 36 x86_64 AVD: update-in-place, current HOME role launch, Chrome handoff, and Home return verified. Fitrah was already the role holder before this check; chooser and physical/OEM behavior remain unverified.
- Captures are in `release_dist/2026-11-20-focus-clock-activity-save-v8100/`.

## Install and limits

Install `Fitrah_Launcher_0.5.21_universal_v8100.apk` on Android 7.0/API 24 or newer. Update an existing installation in place to keep local data. Do not uninstall first. This is a personal preview signed with the local Android Debug certificate, not a Play Store release. The QA activity is emulator-only; the APK has no sample goal or activity.

The owner's physical phone/OEM, TalkBack, prolonged daily use, and live AI provider calls were not verified. Sync, WhatsApp, MCP, production signing, and remaining E0–E11 ecosystem work remain open. This checkpoint is ready for owner trial; it does not claim the full ecosystem is finished.
