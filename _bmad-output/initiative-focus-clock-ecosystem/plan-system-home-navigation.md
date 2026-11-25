---
title: System Home returns to the goal screen
created: 2026-11-09
type: bugfix
status: built
baseline_revision: 3e240892921120e14f1193100159c5f4325f0ad4
route: full
route_source: auto
risk: medium
review: quick
review_source: pinned
lenses_ran: [quick]
context:
  - lib/features/launcher/fitrah_launcher_shell.dart
  - lib/features/launcher/widgets/minimalist_app_drawer.dart
  - android/app/src/main/kotlin/com/aizatfir/fitrah_launcher/MainActivity.kt
  - lib/main.dart
  - lib/main_fitrah.dart
  - test/fitrah_launcher_test.dart
---

<frozen-after-approval>
## Intent
Pressing Android Home must show the user's goal Home, even when Fitrah previously displayed its settings or app drawer. It currently resumes the existing Flutter route. A launcher that leaves the user in settings defeats the central visual cue. Owner approved autonomous continuation and affected verification.

## Boundaries & constraints
Keep the existing shell and central page1, themes, goals, shared session and persistence. React only to actual ACTION_MAIN + CATEGORY_HOME intents, not every resume: returning from a permission picker, external app or settings should otherwise retain context. Cold launch already starts at Home; don't introduce a second navigator, app restart or storage reset. Never cancel/finish/reset timers on navigation. Respect route PopScope guards for pending writes; no unbounded popUntil loops against blocked routes. No new dependencies, broad redesign, permissions audit, unrelated app changes, browser access or Git push. Protect existing dirty build/web files and untracked _bmad/render.

## I/O & edge-case matrix
| Given / when | Then |
| --- | --- |
| Settings/detail route over shell, real HOME intent | Pop dismissible routes safely and show central goal Home |
| Drawer or clock page, HOME intent | Select central Home and dismiss keyboard; selected date/half reflects now as normal Home entry does |
| Plain resume or MAIN/LAUNCHER intent | Do not reset current route merely because app resumes |
| Cold process HOME launch | Existing initial central Home works; bridge setup has no race exception |
| Repeated HOME callbacks or disposed shell | Safe idempotent behavior; handler cleaned up, no stale setState/ref access |
| Route blocks pop for pending commit | Do not bypass guard or loop forever; no false saved state, data mutation or timer cancellation |
| Active/paused shared timer | Home navigation preserves same session and measured state |
| Non-Android host | No platform-only call errors; normal shell behavior retained |

## Acceptance
Given a real default-Home selection, when Android Home is pressed from Android Settings or an external app, then the visible screen is the goal Home with the saved QA goal, rather than Fitrah Settings or drawer.
Given a pending guarded editor, when HOME arrives, then navigation terminates safely and respects its commit guard without discarding or pretending to save work.
Given an ordinary lifecycle resume, when no HOME intent occurs, then current navigation remains unchanged.
</frozen-after-approval>

## Root cause / code map
Reproduced on disposable API36 versionCode12: real ROLE_HOME holder is Fitrah, Android Home from Android Default home app Settings resumes Fitrah Settings. Current MainActivity has no onNewIntent bridge, and FitrahLauncherShell only changes pages through local controls/Back. Android routing is correct; missing native-to-Flutter navigation event is the failing boundary. Evidence .dart_tool/android-qa/home-key-from-android-settings.xml.
- MainActivity: add a small distinct HOME-event channel, forward only matching onNewIntent after super, safely handle engine/channel lifetime. Existing cold startup defaults Home.
- FitrahLauncherShell: register/dispose the corresponding event handler, return safely to its own root and page1; reuse normal date/half behavior and keyboard dismissal. Do not consume unrelated service MethodChannel handlers.
- Pending save sheets use PopScope; a naive popUntil(route.isFirst) can loop when a route refuses pop. Stop at a nonpoppable guard instead of forcing it. Prevent route/page callbacks running after disposal.
- Both main and main_fitrah use same shell; avoid entrypoint duplication. App drawer currently unfocuses when inactive. Keep widget tests on explicit fake storage/store as existing fixtures require.

## Tasks & acceptance
- [x] First reproduce missing Flutter HOME event behavior with a focused failing widget/bridge test, then implement narrow native event + shell handler.
- [x] Test settings pop, page reset, repeated callbacks, ordinary resume preserved, guarded route stops safely, disposal/unknown method, shared timer preserved where existing fixture supports it.
- [x] Run affected launcher/session tests and analyzer; record exact evidence, no full repeated suite. Implementer must not build Android.
- [x] Parent then builds x64 once and performs real Home-from-settings/app plus restart test on existing disposable API36. No physical-device/pre29/reboot claim from mocked tests.

## Verification
Focused Flutter tests, flutter analyze --no-pub, git diff --check. Parent-owned native build/runtime verification required before claiming this bug fixed.

## Implementation notes
- Added distinct `fitrah_launcher/home` native channel; `onNewIntent` forwards only MAIN + HOME after superclass delivery, and engine cleanup clears the channel reference. Cold launch stays on the existing initial center page.
- Shared shell owns handler registration/cleanup and coalesces concurrent HOME requests. It unfocuses, uses `maybePop` toward its own route, and stops immediately if a guard or local history retains the top route. Center-page navigation refreshes date/half without touching the shared timer.
- Added `test/launcher_system_home_test.dart` with fake secure storage and explicit null store fixture. Pre-change focused run failed both tests (settings remained, guarded callback absent); post-change affected launcher/session run passed 14 tests. Extended focused run passed 2 tests with active persisted session ID and identical paused state assertions.
- Verification commands: `flutter test test/launcher_system_home_test.dart test/fitrah_launcher_test.dart test/focus_session_shared_timer_test.dart test/quick_timer_hub_shared_session_test.dart --reporter compact` (14 passed); `flutter test test/launcher_system_home_test.dart --reporter compact` after timer assertions (2 passed); `flutter analyze --no-pub` (No issues found, 6.8s); `git diff --check` (clean).
- Temporary execution logs: `/tmp/home-red.log`, `/tmp/home-green.log`, `/tmp/home-final.log`, `/tmp/home-analyze-final.log`. Android build and real HOME/default-role/restart QA remain parent-owned and unverified here. Existing dirty build/web files and `_bmad/render` were left intact.

## Review Triage Log

## Parent verification / acceptance
- Full changed source/test diff inspected. Quick reviewer found no actionable issue; no review finding deferred. Parent affected test run passed 14 tests (3 seconds); analyzer clean (8.5 seconds).
- Android x64 release versionCode14 compiled successfully in141.9 seconds and upgraded the disposable API36 installation.
- Reproduced original exact journey: Fitrah Settings → Android Default home app settings → system Home. New build showed central goal Home with QA-LKS-Nasional, rather than retained settings.
- Favorite Clock remained available after upgrade. Actual favorite launched foreground Android DeskClock; system Home returned to central goal Home with saved QA goal. Native UI XML and foreground evidence in ignored .dart_tool/android-qa/fixed-home-from-android-settings.xml, fixed-home-from-clock.xml, clock-before-home.txt.
- Earlier versionCode12 on this same API36 AVD retained role, goal and favorite through actual emulator reboot. This new navigation checkpoint has upgrade/cold launch and Home routing proof, not a separate reboot test. Physical device/pre29/TalkBack remain unverified.
