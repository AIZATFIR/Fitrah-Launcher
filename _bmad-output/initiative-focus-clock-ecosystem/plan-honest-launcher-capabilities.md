---
title: 'Make launcher listing and app actions truthful'
type: bugfix
created: '2026-11-09'
status: built
baseline_revision: 6bdb3278fd2652f6ec6f35b793143bbe8113c3de
route: full
route_source: auto
risk: medium
review: quick
review_source: pinned
lenses_ran: [quick]
review_loop_iteration: 0
context: []
---

<frozen-after-approval>

## Intent

Opening apps from Fitrah must use real device capabilities and visibly report failure. The drawer must distinguish unavailable platform, loading, real empty data, failed listing and search with no matches. Preserve the approved Home/dial/themes; remove production simulation rather than redesign navigation.

## Boundaries & Constraints

Always await platform action results before claiming dispatch. Android listing failure must surface for retry, never become sample apps. Unsupported web/desktop operations must return failure or explicit unsupported state, never pretend to launch or provide installed apps. Preserve stored allowed-app choices on list failure. Refresh listing/icons after resume and explicit retry so installation/uninstallation or temporary failures recover. Keep existing native method names, package identity, timer ownership, data and signing.

Never claim a successful dispatch proves an app became visible, permissions were granted, an uninstall completed, or default Home was selected. No permissions added, new dependencies, hardcoded package substitutions, schema changes or UI replacement. Favorites/hidden/order persistence, default-role confirmation, full launcher accessibility/scrubber audit, native device verification and wider ecosystem work remain required subsequent work. Protect dirty build/web files and _bmad/render; do not bypass the prior browser-access rejection.

## I/O & Edge-Case Matrix

| Scenario | Input/state | Expected behavior | Failure handling |
|---|---|---|---|
| Real listing | Android channel returns valid apps/aliases | Show real distinct package rows sorted by label; empty list is valid | Null/malformed payload is visible failure, not demos |
| Platform unavailable | Web or desktop | Explain device app capability is Android-only; no demo apps or successful launch | No impossible retry requirement |
| Listing failure/retry | Channel throws then succeeds | Show retry; retry loads actual list | Preserve allowed package selection and core Home/timer |
| Launch outcome | true, false, null or PlatformException | true means accepted dispatch only; other outcomes show useful error | No unhandled async exception or silent dead tap |
| Utilities/options | Clock/calendar/dialer/camera/settings/details/uninstall | Same truthful awaited result and feedback as app row | Unsupported platform/failure clearly explained |
| Refresh | Resume after app install/uninstall/permission change | Reload actual list and clear stale icon failure cache | Failed refresh remains recoverable; no duplicate listeners |
| Async navigation | Action completes after widget disposal or sheet closes | No invalid context/ref access or feedback in a disposed widget | Parent page context is used for sheet actions |
| Layout | Failure/unavailable at320dp and200% text | Message/retry accessible without overflow | Changed controls have >=48dp hit targets |

</frozen-after-approval>

## Code Map

- `lib/features/launcher/services/app_launcher_service.dart`: `getInstalledApps` catches channel errors/null and returns hardcoded `_getDesktopOrWebApps`; `launchApp` returns true off Android. Remove sample production fallback. Make platform support explicit and testable with Flutter defaultTargetPlatform (kIsWeb still gates web); no need dart:io. Strictly decode/validate list, deduplicate aliases by package, preserve actual labels. Native Kotlin already returns bool/error for every action; convert void wrappers to Future<bool> using one private invocation helper. Keep launchSadar/FocusClock wrappers truthful. Icon exceptions should not be permanently cached; clear cache on refresh. Do not persist provider favorites in this slice.
- `installedAppsFutureProvider` in same file: own a lifecycle listener with proper disposal, invalidate on resume and explicit retry, clear icon cache. Avoid per-row listeners. Riverpod should discard stale async fetch results.
- New small `lib/features/launcher/widgets/launcher_action_feedback.dart`: reuse a single awaited UI action helper and a shared app-list failure/unavailable widget. Show concise Indonesian user copy, not raw platform traces. Parent context must survive sheet dismissal; check mounted after await.
- `minimalist_app_drawer.dart`: active production drawer; `_launchApp` ignores bool, options details/uninstall and utility clock/calendar ignore results; error branch raw Error text. Replace with shared feedback, list retry/unavailable state. Preserve search/Back/layout. Verify retry can replace error with real data.
- `niagara_unified_stream_view.dart` and `fitrah_home_view.dart`: legacy components still call the same service; update action callsites coherently (including launchSadar), not their navigation/design. They are not the current shell Home. `fitrah_launcher_shell.dart` uses FocusClockHomeView and MinimalistAppDrawer.
- `fitrah_settings_screen.dart`, `launcher_customization_sheet.dart`: Home settings/notification settings actions also ignore errors. Use the same feedback helper; list chooser should show recoverable/unavailable state rather than simulated rows.
- `lib/features/sadar/widgets/{sadar_ypt_focus_view,allowed_apps_selector_dialog}.dart`: allowed app launch and list error states. Keep stored selection intact; explain unavailable capabilities, await launch and show failure. No changes to strict-mode semantics or session state.
- `android/app/src/main/kotlin/com/aizatfir/fitrah_launcher/MainActivity.kt`: inspected native getInstalledApps/getLaunchIntent/utility intents already returns success(bool)/error. No Kotlin change is needed unless tests/source prove a concrete defect.

## Tasks & Acceptance

- [x] Service/provider tests first: mock channel and platform; prove no fake app list, strict payload handling, sorted dedupe, unsupported false, true/false/null/error outcomes, retry/resume refresh and icon recovery. Implement minimal shared service/provider fixes.
- [x] UI integration: await every action consumer listed above with shared feedback; replace app-list error states with retry/unsupported copy. Preserve existing allowed selection and core features. Add drawer and shared-feedback widget tests for failure/retry, unsupported, disposed context and compact large-text layout.
- [x] Run focused launcher/provider/widget and affected existing regressions; analyzer; inspect callsite search so no result is silently ignored. Update BUILD-ROADMAP with evidence and remaining E5 limits. No builder commit; parent reviews and commits locally.

Given a listing exception, when user retries after the platform recovers, then only real app rows appear. Given a missing app or unsupported platform, when tapped, then the user receives a clear failure instead of simulated success. Given resume after app changes, when the drawer is visible again, then its list is refreshed without changing the active session or stored allowlist.

## Implementation Notes

Owner has authorized continuing approved UX/build without repeated approval questions. Existing dirty artifacts are protected. A previous coding agent hit a usage limit; if delegation is unavailable, parent implements directly. This slice advances E5 and does not close the full ecosystem goal.

Service and consumers were saved before the prior worker/runtime stopped. Parent took over and inspected current source. Native MainActivity additionally evicts its LruCache when a real listing refreshes: clearing only Dart's cache cannot recover a changed icon retained by Android. No method/permission changes.

The old drawer smoke test relied on production demo app fallback. It now provides an explicit test app fixture and asserts both its real fixture row and search result. The original timeout was reproduced, then this deterministic fixture passed. Added an in-flight icon-generation test and cleaned test-only unused imports.

Focused verification: 23 launcher/service/provider/feedback/allowlist/drawer and existing smoke tests passed in 5 seconds. Logs are retained under `.dart_tool/verification/launcher-20261109/` rather than ephemeral /tmp. Matrix coverage includes true/false/null/errors, malformed/empty listing, sorted dedupe, unsupported platform, failure/retry, actual resume and listener disposal, provider icon recovery, old icon completion fencing, dismissed sheet/parent disposal, preserved allowlist, and 320dp/200% failure controls. Analyzer initially reported only two unused test imports, removed before final rerun. Native emulator is a separate disposable QA AVD, not the owner's existing Medium_Phone; no runtime success claimed yet.

## Review Triage Log

- Medium / patch — Quick review identified the app-list failure inside YPT's unbounded non-scrollable content Column. Parent reproduced compact/200% overflow and added a bounded outer scroll viewport preserving the normal minimum-height layout; wrapped the header and made button labels flexible. The same test exposed existing horizontal button/exit overflow, corrected without changing timer logic. All 3 YPT cases pass, including failed listing with a live shared session.
- Medium / patch — Quick review measured changed legacy Sadar pills/status/chips below 48dp. Added explicit minimum interactive dimensions and alignment at those controls (matching Clock pill included for consistent layout); a widget test measures the actual three Sadar targets at >=48dp width/height and passes.
- Low / patch — Quick review found the required roadmap evidence missing. Added the E5 slice findings, coverage and remaining limits, with baseline native runtime evidence clearly labelled c8b1087 rather than attributing it to this change.

Native QA: the API37.1 disposable AVD remained unauthorized despite the documented emulator option; stopped only that QA process and created a separate installed stable API36 AVD. API36 booted and accepted ADB. Installed c8b1087 x64 QA APK and observed Home after denying notification permission. Source screenshot and logs remain under `.dart_tool/android-qa/`; the existing Medium_Phone was untouched. These checks do not validate the current uncommitted native cache change or the full launcher gate.

## Final evidence

- After review patches: 29 affected launcher/provider/widget/session tests passed in 9 seconds; analyzer clean in 12.5 seconds; JavaScript web release compiled in 51.7 seconds. Logs: `.dart_tool/verification/launcher-20261109/post-review-tests.log`, `post-review-analyzer.log`, `web-build.log`. Whitespace check passed.
- Native Android x64 release compiled in 183.8 seconds, including MainActivity's cache eviction. The initial attempt rejected a 92-byte HTTP504 HTML response. Fresh download from the package's release URL matched expected SHA-256 `949965f0eba976f707ae364cdcb42c342b5f0626081f8d7f0378fb7b52848772`; only the verified ELF entered generated cache. No hash/lock/dependency/source validation was bypassed.
- Verified current x64 APK ID `com.aizatfir.fitrah_launcher`, versionName0.5.3/versionCode10 QA override, same signing certificate as c8b1087/versionCode9. APK SHA-256 `91b29f28232fe503a94ff6ea04524cca309400690dc2fa3ad6dbb4095cc50565`. `adb install -r` succeeded on disposable API36.
- Through real UI, created/pinned QA-LKS-Nasional on version9, observed it after force-stop/cold restart, then verified a fresh UI hierarchy retained it after upgrade to10. Swiped to actual drawer, opened Clock, confirmed foreground `com.google.android.deskclock`, pressed Back and confirmed foreground Fitrah plus real Calendar/Clock/Drive rows. The native integration demonstrates dispatch and return for this device; mocks cover failure paths. It does not prove default Home role, physical-device/vendor behavior, complete history migration, all permissions or the full E5 gate.

## Verification

Run affected tests only after source changes; no repeated unrelated full suite. Analyzer and whitespace check. Native device and browser runtime are separate gates, not proved by channel mocks or compile. Compile fresh web only after reviewed source stabilizes, output to /tmp rather than build/web.
