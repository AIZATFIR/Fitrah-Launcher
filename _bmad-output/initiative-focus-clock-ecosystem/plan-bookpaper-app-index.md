---
title: 'Make the app index calm, branded, and accessible'
type: 'feature'
ticket: ''
created: '2026-11-15'
status: 'built'
baseline_revision: '34f7b48b20740cd59e2b6db26ad057312eee4543'
route: 'full'
route_source: 'pinned'
risk: 'low'
review: 'quick'
review_source: 'pinned'
lenses_ran: [quick]
review_loop_iteration: 0
context:
  - 'docs/ecosystem/2026-11-03/BUILD-ROADMAP.md'
  - 'docs/ecosystem/2026-11-03/DESIGN.md'
---

<frozen-after-approval reason="Owner has approved autonomous Focus Clock ecosystem build and Bookpaper branding">

## Intent

**Problem:** The launcher app index uses a bright blue, oversized wave bubble and tiny white text that clash with the approved Focus Clock charcoal-and-amber Bookpaper identity. Its alphabet gesture has no adjustable screen-reader control and the 44dp rail is narrower than the launcher’s own minimum target size.

**Approach:** Keep alphabet scrubbing and real section navigation, but bring the shared scrubber into the Bookpaper palette, make its hit area at least 48dp, replace decorative glyphs with familiar Material icons, and expose the current letter with screen-reader increment/decrement actions.

## Boundaries & Constraints

**Always:** Keep the actual A–Z section jump, favorites shortcut, haptics, and scroll implementation. Use the existing AppPalette and Flutter Semantics. Apply the same calm treatment to the active drawer and legacy unified stream, which share this widget. Preserve app rows, favorites, search, settings, package choices, and launcher data.

**Never:** Add dependencies, replace the drawer/navigation, change installed-app listing or launch behavior, introduce emoji, or imply that emulator-only checks prove physical-device behavior.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Gesture scrub | Drag across the rail | Current section follows the selected real letter with restrained amber feedback | Empty letters remain harmless and do not break scrolling |
| Screen reader | Increment/decrement adjustable control | Announces current letter and navigates to the corresponding section | First/last letter clamps; no out-of-range callback |
| Narrow display | 320dp viewport | Rail remains at least 48dp and does not cover the search field or app actions | Layout remains scrollable without overflow |

</frozen-after-approval>

## Code Map

- `lib/features/launcher/widgets/niagara_wave_scrubber.dart` -- shared animation, drag selection, haptics, and current unbranded bubble; reuse its callbacks and add adjustable Semantics around the existing gesture surface.
- `lib/features/launcher/widgets/minimalist_app_drawer.dart` -- active Bookpaper app index and actual A–Z header scrolling; widen only the positioned rail and keep app filtering unchanged.
- `lib/features/launcher/widgets/niagara_unified_stream_view.dart` -- legacy consumer of the shared scrubber; keep its wider-on-drag affordance while updating the idle touch width.
- `lib/core/theme.dart` -- canonical `AppPalette` charcoal, amber, and muted text colors.
- `test/features/launcher/niagara_wave_scrubber_test.dart` -- new behavior tests for semantic adjustment, bounds, color, and minimum hit area.

## Tasks & Acceptance

**Execution:**
- [x] `test/features/launcher/niagara_wave_scrubber_test.dart` -- first prove adjustable letter selection, bounded endpoints, amber feedback, Material favorite/end icons, and a 48dp rail.
- [x] `niagara_wave_scrubber.dart`, `minimalist_app_drawer.dart`, `niagara_unified_stream_view.dart` -- use Bookpaper styling, add screen-reader adjustment, replace glyph markers with Material icons, and widen the existing rail.
- [x] Verify focused launcher regression tests, analyzer on changed Dart files, and whitespace diff.

**Acceptance Criteria:**
- Given the app drawer is visible, when the user drags the index, then section navigation still targets the real A–Z headers and the selection uses the Focus Clock amber palette.
- Given TalkBack or another screen reader focuses the index, when the user increments or decrements it, then the selected letter is announced and the same section navigation runs without requiring a drag gesture.
- Given a narrow phone viewport, when the drawer is open, then the index offers at least a 48dp touch width and remains inside the viewport.

## Implementation Notes

- Replaced the exaggerated blue wave treatment with a compact charcoal-and-amber index, legible A–Z labels, Material favorite/end icons, and adjustable Semantics. The real section callbacks and haptic feedback remain shared by both drawer consumers.
- Both rail containers are now 48dp; the active drawer reserves the matching 48dp list gutter. Legacy primary focus action now has a 48dp minimum as caught while validating its touch-target regression.
- Repaired the legacy touch-target test to assert against the current action controls; its earlier expected emoji/habit label no longer existed in the UI. Kept icon-only secondary action verified through its semantic bounds.
- Red/green evidence: new scrubber tests initially failed because semantics, icons, and themed colors were missing; the legacy action test exposed its primary button's 40dp minimum before the fix.
- Focused verification: `flutter test test/features/launcher/niagara_wave_scrubber_test.dart test/features/launcher/minimalist_app_drawer_capabilities_test.dart test/features/launcher/niagara_touch_targets_test.dart --reporter compact` passed 16 tests. Analyzer on six affected Dart files reported no issues; `git diff --check` passed.

## Plan Change Log

- Owner asked for the active launcher UI to use the approved Focus Clock Bookpaper branding and remove repeated Android-only copy. Expanded this slice to clean up the settings header, desktop content width, Indonesian labels, unavailable-platform message, and drawer preference grouping.

## Review Triage Log

- Quick review found the active alphabet rail could overlap the floating search action on 320dp screens. **Medium, patched.** Added a 320dp overlap assertion; it failed before the rail bottom inset changed from 30dp to 84dp and passed afterward.

## Verification

**Commands:**
- `flutter test test/features/launcher/screen_time_settings_test.dart test/features/launcher/niagara_wave_scrubber_test.dart test/features/launcher/minimalist_app_drawer_capabilities_test.dart test/features/launcher/niagara_touch_targets_test.dart --reporter compact` -- 27 focused launcher and settings tests pass.
- `flutter analyze --no-pub lib/features/launcher/widgets/fitrah_settings_screen.dart lib/features/launcher/widgets/drawer_preferences_controls.dart lib/features/launcher/widgets/niagara_wave_scrubber.dart lib/features/launcher/widgets/minimalist_app_drawer.dart lib/features/launcher/widgets/niagara_unified_stream_view.dart test/features/launcher/screen_time_settings_test.dart test/features/launcher/niagara_wave_scrubber_test.dart test/features/launcher/minimalist_app_drawer_capabilities_test.dart test/features/launcher/niagara_touch_targets_test.dart` -- no issues.
- `git diff --check` -- no whitespace errors.
- `flutter build web --release --no-wasm-dry-run --no-pub --build-name=0.5.5 --build-number=2055 --output=/tmp/focus-clock-ui-review-2055` -- release preview built and inspected at desktop width; 320dp layout verified by widget test.

**Manual checks:**
- Inspected the Bookpaper Home and launcher settings in the local preview. Settings now show one Android-only message, Indonesian controls, and a centered 680dp content column. No Android device was attached for native overlay inspection.
