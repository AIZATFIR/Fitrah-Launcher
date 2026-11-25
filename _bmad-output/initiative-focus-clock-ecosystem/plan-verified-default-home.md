---
title: Verified Android default Home status
created: 2026-11-09
type: feature
status: built
baseline_revision: 8512ffe4226fc0f05b6c4476e22c92de2b037db1
route: full
route_source: auto
risk: medium
review: quick
review_source: pinned
lenses_ran: [quick]
context:
  - lib/features/launcher/services/app_launcher_service.dart
  - lib/features/launcher/widgets/fitrah_settings_screen.dart
  - lib/features/launcher/widgets/launcher_action_feedback.dart
  - android/app/src/main/kotlin/com/aizatfir/fitrah_launcher/MainActivity.kt
  - android/app/src/main/AndroidManifest.xml
  - test/features/launcher/app_launcher_service_test.dart
---

<frozen-after-approval>
## Intent
Fitrah must tell the user whether Android actually uses it as the default Home application and offer the system-controlled choice. Opening Settings alone is not success. Keep the approved clock, themes and Home content. Owner has already approved autonomous continuation and affected verification.

## Boundaries & constraints
Reuse existing MethodChannel, platform-support checks, lifecycle refresh pattern and settings screen. Android selection remains entirely the user's choice in the system picker. Never silently assign a role, request on startup, assume dispatch means selected, or invent success off Android. No new dependencies, storage/schema changes, generic redesign, permission overhaul, AI, or unrelated settings repair. Do not touch pre-existing dirty build/web outputs or untracked _bmad/render; no push/remote ops. Browser runtime access remains disallowed after prior URL-policy rejection. Existing API36 disposable emulator is available for parent verification, not the owner's Medium_Phone AVD. No physical-device claims.

## I/O & edge-case matrix
| Scenario | Given / when | Then | Failure handling |
| --- | --- | --- | --- |
| Default Home held | Android29+ RoleManager reports ROLE_HOME held | UI states Fitrah is default | No optimistic derivation |
| Not default | Another or no Home holder | UI says not default and offers system choice | Other app remains valid until user selects |
| Older supported Android | API24–28 | Native resolves actual default HOME component to own package | Unresolved/chooser does not count as held |
| System choice dispatch | User explicitly presses choose | Native opens ROLE_HOME request when available; older/unavailable role uses Home Settings fallback | Dispatch bool only; re-read actual status on return |
| Cancel / decline / other launcher | Picker returns without selecting Fitrah | Status stays not default; retry possible | No success toast |
| Return / external change | App resumes after system change | Status refreshes from native | Old in-flight status cannot overwrite fresh result |
| Read error or malformed/null native result | Status query fails | Visible unknown/error with retry | Never display false as if known |
| Request error/false | System action unavailable/fails | Inline feedback; pending clears and retry remains possible | No unhandled exception |
| Unsupported host | Web/desktop | Explain Android-only capability; no fake selected state | Native channel not invoked |
| Pending / repeated taps | Slow query or action | Correct loading/disabled state, no duplicate action | Mounted-safe completion/disposal |
| Compact text | 320dp / 200% scale | Status/control readable and scrollable with >=48dp targets | No layout overflow |

## Acceptance
Given settings, when user checks launcher status, then it describes the current OS state distinctly from query loading/failure/unsupported.
Given the system chooser, when the user cancels or selects a different launcher, then returning to Fitrah does not claim selection succeeded.
Given Fitrah was selected, when Home is pressed in the disposable emulator, then Fitrah receives Home, with prior synthetic goal/preferences intact. Native runtime evidence is parent-owned after implementation; mocks alone cannot prove this.
</frozen-after-approval>

## Code map
- Existing app service uses strict native list decoding and bool action dispatch, guarded with isSupported. Reuse conventions; add explicit status query and request API.
- MainActivity has openHomeSettings with ACTION_SETTINGS fallback but no role query. Use RoleManager on API29+; pre29 resolve ACTION_MAIN/CATEGORY_HOME with MATCH_DEFAULT_ONLY. Only actual own package/held role counts as selected.
- FitrahSettingsScreen has blind Change Default Launcher tile. Replace it with a small focused reusable status/control widget, preserving list structure. Other simulated settings are future work. Avoid formatting the whole screen.
- installedAppsFutureProvider already has a disposed AppLifecycleListener; follow its lifecycle pattern for status, with stale result protection through provider recomputation.
- Main manifest declares MainActivity HOME/DEFAULT/LAUNCHER. Do not alter identity or lockscreen behavior. src/fitrah manifest is not the current configured flavor.

## Tasks & acceptance
- [x] Native query/request methods, Dart strict service wrappers and lifecycle status provider.
- [x] Settings status component: loading/known/not-known/unsupported, explicit request, pending/failure and return refresh.
- [x] Focused service/provider/widget tests for every matrix row that can be proven under mocks. Test current true/false, bad payload/errors, request failure and cancellation, lifecycle requery, disposal, compact size. For pre29 native behavior record source inspection and compile limitation rather than pretend Dart proves it.
- [x] Run new and impacted launcher tests plus analyzer. Parent later compiles a single x64 checkpoint and performs actual role-choice/Home/restart and preferences journeys. Do not build platforms inside implementer.

## Verification
`flutter test` with explicit affected file paths; `flutter analyze --no-pub`; `git diff --check`. Record commands/counts and remaining native gates. No broad repeated full-suite runs.

## Implementation notes

- Added strict `isDefaultHome` query and dispatch-only `requestDefaultHome` wrappers, plus an auto-disposed provider that invalidates on resume. Provider recomputation prevents an older status read from replacing a fresh result.
- Native API29+ reads `RoleManager.ROLE_HOME`; API24–28 and unavailable-role fallback resolve MAIN/HOME with MATCH_DEFAULT_ONLY and compare the resolved package with this application. Chooser/unresolved results cannot match the application package. This path has source inspection only; no pre29 runtime claim.
- Replaced only the blind default-launcher settings tile with a focused status/control component. It supports unknown/read retry, unsupported, pending request, inline dispatch failure, and >=48dp controls. Already-held status opens Home Settings so changing away from Fitrah remains possible; unheld status requests the system Home role.
- Verification: `flutter test test/features/launcher/app_launcher_service_test.dart test/features/launcher/default_home_status_control_test.dart test/features/launcher/launcher_action_feedback_test.dart` passed 22 tests. `flutter analyze --no-pub` reported no issues. `git diff --check` passed. Focused mocks cover status true/false, malformed/null/error reads, unsupported native guards, cancellation/other choice, held/unheld dispatch, request failures, slow/duplicate action, resume/stale read/disposal, and 320dp/200% component layout.
- Native compilation, actual role-choice/Home/restart and goal/preferences persistence journeys remain parent-owned gates on the disposable API36 x64 emulator. Implementer did not build platforms, access browser runtime, or modify pre-existing dirty build/web outputs or `_bmad/render`.

## Review Triage Log

## Parent verification and acceptance
- Final parent run: app_launcher_service_test.dart and default_home_status_control_test.dart, all 18 passed in 1 second. Analyzer clean (5.0 seconds). Reviewer: no actionable findings.
- Android x64 release compile succeeded (204.7 seconds), QA override versionCode12, same debug certificate SHA256 b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e. Upgraded disposable API36 installation successfully.
- Actual system UI: initial Pixel Home matched Fitrah not-default state; cancel preserved Pixel and not-default state. Selecting Fitrah changed OS ROLE_HOME holder to com.aizatfir.fitrah_launcher; Fitrah Settings subsequently showed default held. Held-state action opened Android Default home app settings.
- Upgrade retained QA-LKS-Nasional. Actual Clock favorite survived cold restart; committed hidden Clock survived cold restart; unhide restored favorite shortcut. Native hierarchy evidence under ignored .dart_tool/android-qa/.
- Pre-existing issue discovered: pressing system Home from Android Settings resumes Fitrah Settings instead of root goal screen. Android routing reaches the correct app, but Flutter navigation does not reset. Immediate next slice required before calling launcher usable. No physical-device, pre29 runtime, reboot or broad feature claims.
- Follow-up verified on 20 Nov with v8107 after AVD app data reset: Fitrah's settings reported it was not the Android default, the button opened the actual Android Home chooser, selecting Fitrah changed `ROLE_HOME` to `com.aizatfir.fitrah_launcher`, and system Home displayed Hari Ini. A QA goal (`QA_HOME_LKS`) was added and pinned; Home sent the AVD to Android Settings, then a physical Home key returned to Hari Ini with the pinned goal visible. Force-stop followed by Home relaunched Fitrah with the same goal. Screenshots are in ignored `.dart_tool/android-qa/v8107/current-default-home.png`, `current-home-from-system-settings.png`, and `home-after-force-stop.png`. Nexus Launcher was restored as the role holder and Fitrah QA data cleared. This verifies the clean-install role chooser and Home route on API36 AVD only; physical/OEM and reboot behavior remain open.
