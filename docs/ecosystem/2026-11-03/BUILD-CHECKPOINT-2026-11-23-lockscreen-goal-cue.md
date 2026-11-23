# Android lock-screen pinned-goal cue — 23 November 2026 · `0.5.52+8144`

## Implemented

- Added a durable launcher preference for the lock-screen goal cue. It defaults off and older saved settings continue to decode with it off.
- Added an Android-only setting with a privacy explanation and actual notification permission status. Notification permission is requested only when the user turns the cue on; a denied request leaves the preference off.
- Added one stable notification ID on its own low-importance channel with public visibility. It is ongoing, updates with the canonical pinned goal, and is canceled when the cue is disabled or the goal is absent/archived.
- Reconciled notification state from the launcher settings and pinned-goal stream at startup, on changes, and when the app resumes. Notification actions open Hari Ini, including when Android cold-starts the app from the notification.
- Kept the timer notification ID and private visibility unchanged.

## Verification

- `flutter build apk --release --no-pub` — succeeded after final settings fix; Android package metadata reports `com.aizatfir.fitrah_launcher`, version `0.5.52` / build `8144`. APK signature verified as local Android Debug.
- Fitrah, Focus Clock and Sadar JavaScript web bundles built and passed the existing bundle verification script. Flutter reports existing Wasm-incompatible dependencies during its optional Wasm dry run; the JS bundles built successfully.
- One focused Android settings widget test passed. Broader test suites were not run.
- `git diff --check` — clean. Reviewed notification permission, dedicated channel, stable ID, pinned-goal updates, cold-start tap routing and timer privacy.
- [Download package](../../../release_dist/2026-11-23-lockscreen-goal-v8144/START_HERE.md) includes Android APK, all three web bundles and SHA-256 checksums. Windows/Linux installers are being built by the GitHub release workflow.

## Open device checks

No Android device was attached during this build (`adb devices` returned no devices). Notification permission grant/denial, lock-screen visibility, system privacy settings, notification channel behavior and OEM-specific presentation still need physical-device verification. Android may hide notification content according to the user's lock-screen privacy settings. The release APK remains a local owner-preview build; this checkpoint does not claim a phone or OEM validation.
