---
title: 'Opt-in screen-time cue and gentle daily limit'
type: feature
ticket: ''
created: '2026-11-14'
status: built
baseline_revision: b7ff628ca828630b740bf55ac3443bad9fd2a303
route: full
route_source: auto
risk: high
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 0
context:
  - docs/ecosystem/2026-11-03/ARCHITECTURE.md
  - docs/ecosystem/2026-11-03/BUILD-ROADMAP.md
---

<frozen-after-approval reason="human-owned intent; approval carried forward from explicit 'gas, lanjut terus' authorization">

## Intent

**Problem:** People lose track of time and forget what they meant to do after opening the phone. The launcher currently has Usage Access foundations, but no small screen-time cue that can gently bring the user back to their goal.

**Approach:** Add a small Android floating cue showing today's screen-time minutes and a clear action to return to the Fitrah goal screen. The user may tuck it to the screen edge. Enable it only after the user opts in and grants Android Usage Access plus overlay access. Add a separate, default-off gentle limit: after the selected daily limit, show a calm interruption with a short wait before continuing, while always keeping the path back to goals available.

## Boundaries & Constraints

**Always:** Preserve Bookpaper styling in Flutter settings and in-app states. Query Android usage totals instead of estimating from app-open timers. Refresh on resume and while the cue is active; reset against the device's current local day. Persist the feature and threshold choices with existing migration-safe launcher settings. Handle denied/revoked permissions and unsupported platforms honestly. Make the goal action return to the real Home screen and never count the bubble itself as foreground time. The limit is a gentle pause, not a hard lock: emergency/system surfaces remain usable and a user can continue after the displayed countdown.

**Never:** Ask for either permission at startup. Enable the feature or the daily limit by default. Claim to prevent app use after the cap or report unsupported platforms as working. Add Accessibility Service, VPN, or device-admin control. Replace existing launcher, timer, goal, or storage owners. Commit hidden accessibility blockers or broad package-visibility permissions.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| First enable | Both permissions absent | Explain why each is needed, request them only after the user's action, then show the cue after returning | Cancel/deny leaves feature off and offers retry |
| Usage unavailable | Permission revoked or stats unavailable | Keep the cue visible as unavailable; do not show zero as measured usage | Explain and link back to Usage Access settings |
| Daily threshold | Measured minutes meet configured limit | Show a calm wait screen on the next non-system app surface; “Lihat tujuan” returns Home; “Lanjut setelah …” unlocks only after the configured delay | If overlay/window fails, keep launcher usable and explain that the gentle limit is inactive |
| New local day | Date/timezone crosses a local midnight | Display the new day's usage and clear the previous day's delay state | Recompute after resume and avoid carrying yesterday's minutes forward |
| Disable or revoke | User turns feature off or removes overlay access | Remove the bubble/interruption promptly and keep saved threshold choices | No crash if permission changes while the launcher is backgrounded |

</frozen-after-approval>

## Code Map

- `android/app/src/main/AndroidManifest.xml` already declares `PACKAGE_USAGE_STATS`; it does not declare overlay permission.
- `android/app/src/main/kotlin/com/aizatfir/fitrah_launcher/MainActivity.kt` owns the `fitrah_launcher/apps` channel; it already checks Usage Access, opens its settings page, reads foreground app and brings Fitrah forward. Extend this native seam rather than adding another permission framework.
- `lib/features/launcher/models/launcher_settings.dart` and `providers/launcher_settings_provider.dart` own validated JSON settings and serialized writes. Add default-off cue/limit fields with backward-compatible defaults.
- `lib/features/launcher/widgets/fitrah_settings_screen.dart` is the current settings entry point. Add a Bookpaper screen-time settings section with explicit permission state and user-selected limit/wait.
- `lib/features/launcher/fitrah_launcher_shell.dart` handles the Android Home intent and returns to the goal/Home page through `fitrah_launcher/home`; reuse that route from the floating cue.
- `lib/features/launcher/widgets/minimalist_app_drawer.dart` is the existing launch surface. Use its app-launch action as the reliable point to check threshold and require wait before opening an app.
- Existing permission UX in `lib/features/sadar/widgets/sadar_ypt_focus_view.dart` is session-specific; do not reuse its focus-session state as daily screen-time data.

## Tasks & Acceptance

**Execution:**
- [x] `android/app/src/main/AndroidManifest.xml`, `MainActivity.kt` -- add explicit overlay capability checks/permission route, local-day usage query, native small edge-dock cue and threshold interruption with goal return -- platform behavior cannot be represented by Flutter widget layering.
- [x] `lib/features/launcher/models/launcher_settings.dart`, `providers/launcher_settings_provider.dart` -- persist opt-in, cap minutes and wait seconds with safe legacy defaults -- preserve user choice through upgrade.
- [x] `lib/features/launcher/services/screen_time_service.dart`, `fitrah_launcher_shell.dart` -- own method-channel contract and sync cue state/goal return on enable, disable and lifecycle resume -- keep Android effects behind one app-owned boundary.
- [x] `lib/features/launcher/widgets/fitrah_settings_screen.dart` -- provide clear permission status, default-off switches and editable limit/wait -- users control access and friction.
- [x] `lib/features/launcher/widgets/minimalist_app_drawer.dart` -- gate launcher-originated launches after the cap until the configured wait finishes -- no instant bypass through the primary launcher path.
- [x] Add focused settings/service/native-channel coverage for default-off migration, denial/revocation, threshold/day rollover and wait behavior -- guard the trust boundary.

**Acceptance Criteria:**
- Given a fresh install or legacy settings JSON, when settings load, then both screen-time controls are off and no permission page or overlay appears.
- Given the user enables the cue, when either Android permission is missing, then the app explains the permission, opens only the relevant OS page after an explicit tap, and does not claim the cue is active until Android confirms access.
- Given both permissions and cue enabled, when the user leaves Home, then a compact minute count and “Tujuan” action remain visible; the cue can be dragged to either edge and restored without blocking the app underneath.
- Given usage data reaches the configured cap, when the user attempts to open an app from Fitrah, then an interruption shows current minutes and a countdown; goal return works immediately and continue stays disabled until the countdown ends.
- Given the user disables the feature or revokes overlay access, when the launcher next observes the state, then its windows are removed and ordinary app launch remains available.
- Given the feature runs on web/desktop, when settings are opened, then Android-only behavior is labelled unavailable and no success is simulated.

## Design Notes

Android's `TYPE_APPLICATION_OVERLAY` requires a separately user-granted `SYSTEM_ALERT_WINDOW` capability, and Android may move or hide those windows. Usage Access is already declared but is special access granted in Settings; querying `UsageStats.totalTimeInForeground` is a device-provided daily total, not a precise live stopwatch. Keep the cue informational and make limit control fail open if its window or statistics are unavailable. The waiting step applies to app launches through Fitrah's drawer; system intents and third-party launch surfaces remain outside this launcher-owned friction path. No background foreground-service or notification is added in this slice unless current platform constraints prove it necessary.

## Verification

**Commands:**
- `flutter test test/features/launcher/screen_time_settings_test.dart test/features/launcher/minimalist_app_drawer_capabilities_test.dart` -- 20 tests passed.
- `flutter analyze --no-pub` -- no errors in changed Dart files.
- `flutter build apk --release --target-platform android-x64 --build-number 47` -- Android x64 release APK built.
- `adb install -r <apk>` on the disposable API 36 emulator -- Home still launches; cue stays hidden by default; permissions, bubble, hide/restore, limit wait, goal return and disable/revoke paths behave as specified.

**Manual checks:** Inspect the rendered Bookpaper settings and 320dp layout; confirm the dock remains small, text readable, and touches outside the bubble reach the app below.

## Implementation Notes

- Native Android reads local-day totals through UsageStatsManager, checks both Usage Access and overlay permission, creates a small non-modal edge cue, refreshes on resume and every minute, and removes the window when disabled or overlay access is revoked. The cue returns to the launcher Home and can be dragged to either edge, tucked, and restored.
- Launcher settings default both features off, preserve that default for legacy JSON, and clamp the threshold and wait. Gentle wait applies to app launches from the Fitrah drawer; missing usage data fails open without reporting zero. Non-Android settings label the capability as unavailable.
- Focused settings and drawer suite: 20 tests passed. Targeted analyzer: no issues. Android x64 release APK, versionCode 47, installed on isolated API 36 QA AVD; cold start and manual opt-in, cue, Home return, drag/tuck/restore, touch-through, and disable checks passed. The daily threshold countdown and unavailable-stats behavior were covered by widget/service tests rather than forced in the emulator.
- Follow-up on 15 Nov: API36 x64 builds 48–50 upgraded the isolated AVD in place. Runtime screenshot showed the compact amber cue (`13 mnt · Tujuan`) clear of goal text. Returning from Launcher Settings through the cue reused the existing HOME task; the old `NEW_TASK` launch had created a second standard activity task, so it was removed in favor of `CLEAR_TOP | SINGLE_TOP`. Cue-off and gentle-limit-off migration defaults were observed, then the cue was disabled and its overlay window disappeared. Daily countdown/unavailable-stats and physical-device behavior remain unverified in this follow-up; details: [NATIVE-QA](../../docs/ecosystem/2026-11-03/NATIVE-QA.md).
- No emulator device data outside the isolated QA AVD was changed.
- v53 verification: arm64 release package metadata and v2 signature verified; x86_64 release v53 upgraded on the isolated API36 AVD with the same Home role. Home and drawer were screenshot-checked. The 20 focused tests pass again; no physical device was used.

## Plan Change Log

- 2026-11-15: Completed the approved Android screen-time cue and gentle drawer limit. Added migration-safe opt-in settings, native permission and overlay behavior, honest unavailable states, and focused coverage; fixed the 320dp threshold-row overflow found during review.

## Review Triage Log

- 2026-11-15 quick review: no findings; nothing was deferred.
