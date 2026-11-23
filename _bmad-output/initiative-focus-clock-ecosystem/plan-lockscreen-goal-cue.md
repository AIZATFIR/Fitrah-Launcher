---
title: 'Show the active goal on the Android lock screen'
type: 'feature'
ticket: ''
created: '2026-11-23'
status: 'built'
baseline_revision: 'e8a19264def804daab2a571fc4c8cda844340c66'
route: 'full'
route_source: 'auto'
risk: 'medium'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 0
context:
  - 'docs/ecosystem/2026-11-03/EXPERIENCE.md'
  - 'docs/ecosystem/2026-11-03/OWNER-INTENT.md'
</frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The pinned goal is visible after the user opens Fitrah, but disappears from view when the phone is locked. The owner explicitly wants a simple goal cue on both the launcher and lock screen to help people remember what they chose.

**Approach:** Add an Android-only, off-by-default setting for one persistent notification containing the current pinned goal. Tapping it opens Fitrah Home. Update or cancel that notification when the pinned goal changes, is archived, or the setting is turned off.

## Boundaries & Constraints

**Always:** Ask for notification permission only after the user enables this cue. Use a dedicated, low-importance notification channel with public visibility so the goal can appear on the lock screen after explicit opt-in. Respect Android's notification permission and lock-screen settings; show a useful disabled/denied state. Keep the cue local to the device.

**Never:** Change the existing private focus-timer notification; request overlay, usage, exact-alarm, or lock-screen takeover permissions; show goal text on web/desktop; send goal text to a service; enable this cue by default.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Enable with a pinned goal | User enables cue and grants notification permission | One persistent notification shows the current goal; tap opens Fitrah Home | If OS notifications are disabled, leave the cue off and explain that Android notification access is needed |
| Goal changes or is archived | Cue is enabled | The same notification updates to the new pinned goal or is removed when none remains | Notification failure must not roll back the saved goal |
| Disable cue | Cue is enabled | Notification is removed immediately | Preference remains off even if cancellation fails; retry on next app start |

</frozen-after-approval>

## Code Map

- `lib/services/notification_service.dart` — existing timer/activity notification initialization and permission helper; add a dedicated goal cue ID/channel and update/cancel operations without changing timer privacy.
- `lib/domain/focus_intent.dart` and `lib/providers/intent_providers.dart` — `IntentState.pinnedGoal` is the canonical active goal; `intentStateProvider` streams initial state and goal mutations.
- `lib/features/launcher/models/launcher_settings.dart` and `lib/features/launcher/providers/launcher_settings_provider.dart` — durable launcher preference serialization and mutation methods.
- `lib/features/launcher/widgets/fitrah_settings_screen.dart` — existing Android launcher settings surface and opt-in screen-time switches.
- `lib/features/launcher/fitrah_launcher_shell.dart` — mounted launcher shell and current page controller; reconcile the notification from settings and the pinned-goal stream, and route its tap to Hari Ini.

## Tasks & Acceptance

**Execution:**
- [x] `lib/features/launcher/models/launcher_settings.dart`, `lib/features/launcher/providers/launcher_settings_provider.dart` — persist an off-by-default lock-screen goal-cue preference and setter.
- [x] `lib/services/notification_service.dart` — request notification permission only from explicit opt-in; post/update/cancel one ongoing goal notification using a separate public-visibility channel.
- [x] `lib/features/launcher/fitrah_launcher_shell.dart` — reconcile cue with the canonical pinned-goal stream and setting, including initial state, edits, archive/unpin, app resume, and tap routing to Hari Ini.
- [x] `lib/features/launcher/widgets/fitrah_settings_screen.dart` — add a compact Android-only switch with a short privacy and permission explanation; report denied permission without claiming the cue is active.
- [x] `docs/ecosystem/2026-11-03/BUILD-ROADMAP.md` and a dated checkpoint — record the Android build and device/permission limitations; keep physical/OEM verification open.

**Acceptance Criteria:**
- Given a pinned goal and notification access, when the user enables the setting, then a single persistent notification shows that goal and tapping it opens Fitrah Home.
- Given the setting is off, no pinned goal exists, or notification permission is denied, when Fitrah reconciles the cue, then no goal text is shown on the lock screen and the UI reports the actual state.
- Given the existing focus timer notification, when this feature is enabled or updated, then its private lock-screen visibility and behavior are unchanged.
- Given the app is built for web or desktop, when settings render, then the Android-only control is absent.

## Implementation Notes

The app uses `FitrahLauncherShell` as its mounted launcher surface; `FitrahHomeView` is not mounted. The shell owns startup/resume reconciliation and notification tap routing. Android owner-preview version bumped to 0.5.52 / build 8144. APK release build succeeded at 74.8 MB. No Android device was attached; physical permission/lock-screen/OEM behavior is not verified. No broad test suite was run. One focused Android settings widget test passed after avoiding a needless permission query while the cue remains off.

## Plan Change Log

## Review Triage Log

- **low / patch** — `fitrah_settings_screen.dart`: preference-save failures were labeled as notification-permission denial, which could send users to Android settings unnecessarily. Confirmed both enable and disable save paths set that state while the UI displayed permission guidance; separated save-failure status from permission denial.

## Design Notes

## Verification

**Commands:**
- `flutter build apk --release --no-pub` — passed for version 0.5.52 / build 8144.
- `scripts/vercel_build.sh -t lib/main.dart` — passed; Fitrah web bundle verified.
- `scripts/vercel_build.sh -t lib/main.dart --dart-define=APP_MODE=focus` — passed; Focus Clock web bundle verified.
- `scripts/vercel_build.sh -t lib/main_sadar.dart` — passed; Sadar web bundle verified. Flutter reported existing Wasm-incompatible dependencies during dry run; JavaScript web bundles built and verified.
- `flutter test test/features/launcher/screen_time_settings_test.dart --no-pub --plain-name 'first enable explains access and Later has no OS side effect'` — passed after guarding permission checks behind the persisted opt-in.
- `git diff --check` — passed.

**Manual checks:**
- Inspect Android notification permission handling, channel visibility, and the single stable notification ID; do not run a test suite.
- Physical lock-screen display depends on the owner's Android notification and privacy settings; verify on a phone when one is connected.
