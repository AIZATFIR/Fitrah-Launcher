---
title: Real and durable drawer settings
created: 2026-11-09
type: bugfix
status: complete
baseline_revision: 4ee413cfdba0d4528ad44fb4601bca6de5314378
route: full
route_source: auto
risk: medium
review: quick
review_source: pinned
lenses_ran: [quick]
context:
  - lib/features/launcher/models/launcher_settings.dart
  - lib/features/launcher/providers/launcher_settings_provider.dart
  - lib/features/launcher/widgets/fitrah_settings_screen.dart
  - lib/features/launcher/widgets/launcher_customization_sheet.dart
  - lib/features/launcher/widgets/minimalist_app_drawer.dart
  - lib/features/launcher/widgets/niagara_unified_stream_view.dart
  - test/launcher_drawer_preferences_test.dart
  - test/launcher_drawer_preferences_widget_test.dart
---

<frozen-after-approval>
## Intent
Make the existing app-icon and automatic-search-keyboard controls do what they say, persist their state, and report failed saves. The current icon control is local-only while drawer icons always render. A stored auto-search choice may be missed before hydration. Owner has approved autonomous implementation/affected verification; no approval pause required.

## Constraints
Reuse LauncherSettings JSON and serialized commit-before-publish _mutate queue. Preserve all prior fields, favorites/hidden IDs, goals, clock/palette, sessions, app dispatch and HOME handling. New showAppIcons defaults true when absent, preserving actual current icon-visible behavior; explicit false survives. Scope is app-list icons, not pinned icon-only Home shortcuts or selection dialogs. No new dependency, storage fallback, redesign, platform build, public release, browser runtime access, or remote Git operation. Protect existing dirty build/web files and untracked _bmad/render. Other Settings issues remain separately tracked; do not erase requested functionality as a substitute for implementation.

## I/O & edge-case matrix
| Given / when | Then |
| --- | --- |
| Legacy JSON without showAppIcons | true, existing app rows stay visually unchanged |
| Explicit false / true serialized | Immutable settings copies and fresh hydration retain the exact boolean |
| Malformed new field (null/string/number/list) | Load fails visibly; no fallback write overwrites saved data |
| Icon choice changes successfully | Normal, favorite and search rows in active and legacy drawers show/hide icons and their gap; text labels remain actionable and >=48dp |
| Icon hidden | No AppIconWidget/icon-fetch request for hidden row icon; app launch/options remain intact |
| Save delayed/fails/retries | Pending visible; controls disabled while committing; prior switch state retained until commit; error/retry preserve requested value |
| Concurrent icon/keyboard/note/favorite changes | Queue retains all independent committed changes, fresh hydration matches |
| Initial preference hydration pending or failed | No editable assumed values; loading/error/retry explicit; app privacy gate retained |
| Auto-search true loaded after delayed hydration, drawer active | Search opens and keyboard focuses only after hydration |
| Drawer becomes inactive / preference turned off / disposed before pending focus | No late search opening or focus stealing |
| Ordinary entry with auto-search false | Existing manual search remains unchanged |
| Multiple Settings/customization controls | Same persisted values and same save/error semantics, no local duplicate state |
| 320dp / 200% text | Changed controls and sheet scroll without overflow, >=48dp actions |

## Acceptance
Given icon visibility changed in Settings, when the drawer is reopened or preferences recreated, then actual app rows follow the saved choice.
Given a failed write, when a user retries, then UI changes only after successful persistence, with no false success or lost unrelated settings.
Given delayed hydration, when automatic keyboard is enabled and drawer is active, then the intended search behavior occurs without focusing an inactive page.
</frozen-after-approval>

## Design decision
Rejected keeping the local toggle (no effect) and adding a separate settings store (duplicate truth). Use one small shared reactive control for the two existing drawer preferences across existing settings surfaces. Keep current dark surface/type/palette. SwitchListTile or equivalent wrapping labels, 48dp controls, inline pending/failure/retry, scrollable sheet. Android conventions apply; Apple HIG principles used: settings.md Best practices (avoid redundant controls), toggles.md Best practices (state matches actual view), feedback.md Best practices (status near action), typography.md Supporting Dynamic Type (wrapping at large text). No visual redesign.

## Code map
- LauncherSettings lacks showAppIcons; add validated JSON field/copy/constructor. autoFocusSearch already durable but setter Future<void> swallows outcome; return Future<bool> and add matching icon setter through _mutate.
- FitrahSettingsScreen local _showAppIcons and duplicate app-drawer sheet must share reactive controls. Existing unrelated wallpaper/other settings behavior stays for later repair; if changed switch-row helper needs Expanded text for compact width, do so narrowly.
- LauncherCustomizationSheet and Niagara legacy quick keyboard toggle also call setAutoFocusSearch; make every touched write await/save-aware rather than leaving silent failure paths.
- MinimalistAppDrawer _buildAppRow always builds AppIconWidget and16px gap. Niagara _buildAppRow same42px icon/14px gap. Conditional render both together, retain row minHeight48 when icon absent.
- Minimalist _checkAutoFocus reads defaults immediately and starts delayed focus; legacy init reads after fixed delay. Await actual hydration and check active/mounted/current preference again before focus. Cancel stale pending focus on transitions; do not use timers as a hydration substitute.
- Existing daily-note storage fakes support delayed/failing read/write. Explicit test fixtures only; no production memory fallback.

## Tasks / verification
- [ ] Write focused failing model/provider/widget regression tests, then add durable model/API changes.
- [ ] Shared controls and all write callers; real icon behavior and hydration-aware focus.
- [x] Test every matrix row using affected tests plus relevant launcher/notes tests; run analyzer and diff check. No full repository suite was run.
- [x] Record exact tests/results/limitations in implementation notes. Affected checks and local commit completed.

## Implementation notes
- Added validated `showAppIcons` to LauncherSettings (absent = true; explicit false persists), and boolean save results for both drawer preferences through the existing serialized commit-before-publish queue.
- Shared reactive controls now serve Settings, App Drawer settings, customization and legacy keyboard quick settings. Pending/error/requested retry state is owned by the settings notifier, so surfaces agree and controls retain committed values until writes succeed. Later successful same-setting writes clear stale retry state.
- Both drawer row builders omit the icon widget and its gap when disabled, including favorite/search rows, while retaining 48dp row targets. Home shortcuts and selection dialogs are unchanged.
- Automatic search now awaits actual hydration and rechecks mounted/active/current-route/current-preference state around scheduled frame work. Preference changes, deactivation and disposal cancel stale requests. Legacy drawer also exposes explicit preference loading/failure/retry while retaining its Sadar content and app privacy gate.
- Added narrow wrapping/height adjustments in the existing customization sheet after the 320dp/200% regression exposed overflow in its containing rows/presets/prayer chips. No dependencies, platform build, browser access or remote Git operations were used; pre-existing dirty build/web and untracked render artifacts were not touched.
- Final combined affected verification: **84 tests passed** across `launcher_drawer_preferences_test.dart`, `launcher_drawer_preferences_widget_test.dart`, `launcher_daily_note_test.dart`, `launcher_daily_note_widget_test.dart`, `focus_clock_backup_codec_test.dart`, `focus_clock_backup_service_test.dart`, `features/launcher/minimalist_app_drawer_capabilities_test.dart`, `features/launcher/niagara_touch_targets_test.dart`, and `launcher_system_home_test.dart`. Logs: `/tmp/real_drawer_final_tests.log` (local temporary evidence).
- Analyzer: all 10 changed source/test files checked, **No issues found**. `git diff --check` passed. Explicit backup false/legacy-absent field regressions are included.
- Process limitation: new model/provider/widget regressions were added after the initial implementation rather than obtaining a baseline red run first. Subsequent failing compact-sheet regression was reproduced and fixed. A subsequent owner request expanded scope to build local previews. Android arm64 release APK compiled in 264.8s with Gradle limited to Xmx3G, MaxMetaspaceSize=1G and two workers; web JavaScript release compiled in 83.1s. APK metadata confirms applicationId com.aizatfir.fitrah_launcher, versionName 0.5.3, versionCode 16, arm64-v8a, minSDK 24, targetSDK 35, compileSDK 36, and existing debug signing certificate. APK signature verified. WebAssembly dry-run reports existing dart:ffi/dart:html/JS interop incompatibilities; JavaScript build succeeded. Local preview artifacts and checksums are under release_dist/2026-11-14-drawer-settings-4ee413c/. Device/browser runtime, full repository suite and public release remain unverified.
- Parent review and final affected checks/local commit remain with the parent task.

## Review Triage Log

## Follow-up session preset repair (14 Nov 2026)

- Root cause: Settings made an unsaved transient Habit and opened `SadarYptFocusView`, which always used the `yptHabit` source. The timer engine correctly clears unsupported nonpositive YPT habit IDs on completion instead of creating an Activity.
- Fix: focus screen accepts an explicit session source; Settings presets use the existing `preset` path and identity. Durable save, measured completion, atomic Activity creation and retry remain in `SadarTimerEngine`/`SadarRepository`.
- Regression added first; it failed to compile because no preset source API existed, then passed after implementation. 32 tests passed across `sadar_ypt_shared_timer_test.dart`, `sadar_timer_state_machine_test.dart`, `isar_service_persistence_test.dart`, `launcher_system_home_test.dart`; analyzer clean for the three changed Dart files.
- New local preview built after fix: arm64 APK versionCode 17 (142.1s) and JavaScript web (100.2s). Runtime device/browser not checked.

## Follow-up active wallpaper repair (14 Nov 2026)

- Active launcher shell now renders the saved preset backdrop or valid custom HTTP(S) image and applies dimming/blur, with the existing subtle overlay retained. Invalid/custom-image load failures fall back to the selected base color.
- Widget regression verifies a committed preset changes the active shell background. `fitrah_launcher_test.dart`: 6 passed; analyzer clean for shell/test.
- Remaining: the separate `Use device wallpaper` switch still writes unsupported placeholder values and Android wallpaper retrieval is not implemented; wallpaper save failure feedback remains open.

## Follow-up Settings honesty and palette persistence (14 Nov 2026)

- Removed the nonfunctional device-wallpaper toggle; the supported preset/custom background is managed in Customization.
- Replaced claims of notification filtering with clear status and an accurately labeled Android access-settings action. Corrected help text to match active horizontal launcher navigation.
- Font reports current Inter with no fictional picker; rating action explains that no Play Store listing is configured; More opens the framework license viewer; version label matches source version 0.5.3.
- Theme palette writes now return commit success. Both palette sheets close/show success only after commit; failure preserves the selection sheet and reports retry.
- Regression proves a failed theme write keeps the sheet open and never reports success. Settings-focused group: 59 tests passed; analyzer clean.
