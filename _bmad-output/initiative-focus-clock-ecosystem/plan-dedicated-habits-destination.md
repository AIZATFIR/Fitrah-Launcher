---
title: 'Give habits a dedicated Fitrah destination'
type: 'feature'
ticket: ''
created: '2026-11-23'
status: 'built'
baseline_revision: '87ee7c327db6e18ce9e6195dc580d7eeca40ee00'
route: 'full'
route_source: 'auto'
risk: 'medium'
review: 'quick'
review_source: 'pinned'
lenses_ran:
  - quick
review_loop_iteration: 0
context:
  - docs/ecosystem/2026-11-03/DESIGN.md
  - docs/ecosystem/2026-11-03/EXPERIENCE.md
  - docs/ecosystem/2026-11-03/BUILD-ROADMAP.md
---

<frozen-after-approval reason="owner already approved the Focus Clock ecosystem and explicitly said habits are important">

## Intent

**Problem:** Fitrah has no dedicated Habits destination; all habit editing and weekly history are buried in the Hari Ini page. This makes the user's recurring actions hard to find and leaves Home carrying the full tracker.

**Approach:** Add a visible Habits destination that uses the existing durable habit grid/editor/history. Keep Home goal-first and compact by showing only the first three active habits plus a direct Semua route. Preserve Hari Ini at index 1 and move Aplikasi to the last page so the app's center Home and existing launch behavior remain stable.

## Boundaries & Constraints

**Always:** Read and write through existing Sadar repository/providers; keep the user's saved order, history, timer behavior, archived habits and current palette. Keep controls visible and usable at 320 dp and 200% font scale. A Home habit action must keep its existing behavior.

**Never:** Duplicate habit storage, add seeded habits, move or rewrite history, remove existing destinations, or make swipe the only navigation method.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Navigate to Habits | Tap Habits from Hari Ini | Full active habit list and weekly history appear from the shared store | Existing loading/error state stays visible |
| Home preview | More than three active habits | Home shows first three in saved order and a visible Semua action opens Habits | No data is changed |
| Empty habits | No active habits | Habits destination shows existing empty state and create action | Save failures remain in the existing editor |
| Large text | 320 dp viewport and 200% font | All four destinations and Home Semua action remain operable without overflow | Labels may wrap; no actions disappear |

</frozen-after-approval>

## Code Map

- `lib/features/launcher/fitrah_launcher_shell.dart` -- owns page indexes, PageView, visible NavigationBar, back-to-Home, Home return and app-drawer callback.
- `lib/features/launcher/widgets/focus_clock_home_view.dart` -- contains the Home habits section and accepts destination callbacks.
- `lib/features/launcher/widgets/loop_habit_grid_widget.dart` -- durable shared habit list, week history, editor, archive and check-in behavior; add an optional row limit for Home only.
- `lib/features/launcher/widgets/habit_library_view.dart` -- new dedicated full-list surface, composed from the existing grid and timer route.
- `test/fitrah_launcher_test.dart` -- existing shell navigation tests; extend for page order, selection, return-to-Home and large text.
- `test/loop_habit_save_test.dart` -- extend the existing grid/provider harness to verify Home limit and unbounded library behavior against persisted fixture records.

## Tasks & Acceptance

**Execution:**
- [x] Write failing widget tests first for four-destination page order, Home return, 320 dp/200% labels, and three-item Home preview versus full library list.
- [x] Add `HabitLibraryView` and wire it at page index 2; shift the app drawer to index 3, update all shell callbacks and preserve Hari Ini at index 1.
- [x] Add optional Home list limit and visible Semua action; do not change repository sorting, edit, check-in, archive or session behavior.
- [x] Update the roadmap with test/build/runtime evidence and remaining physical-device limits.

**Acceptance Criteria:**
- Given an active habit store with more than three habits, when Home loads, then it shows the first three in saved order and Semua opens a screen containing every active habit.
- Given any destination, when the user selects a NavigationBar label, then the matching page opens and the selected label reflects it; Android back from Habits returns to Hari Ini.
- Given 320 dp width and 200% text, when the shell and Habits page render, then no Flutter overflow occurs and all four destinations and Semua remain tappable.
- Given an existing habit with saved history, when it is viewed and edited from Habits, then edits are saved to the shared provider and its history stays intact.

## Implementation Notes

- Keep index 1 as the initial page and launcher return target. Destination order: Jam, Hari Ini, Habit, Aplikasi.
- Home's first-three preview is a glance surface; the full existing grid remains the management/history surface.

## Plan Change Log

## Review Triage Log

- Quick diff review: First review: 0 findings. Follow-up review found stale 14-test evidence after the new layout regression; updated the roadmap and plan to 15.

## Verification

- `flutter test test/fitrah_launcher_test.dart test/loop_habit_save_test.dart`: 15 passed.
- Scoped `flutter analyze` on seven changed Dart files: no issues.
- `git diff --check`: clean.
- API 36 x86_64 AVD upgraded in place at 200% text; Fitrah remains HOME, saved goal retained, and Habits opens at the top with saved habit data. Sampled logs contain no fatal exception, FlutterError, or ANR.
- Fitrah offline package ZIP integrity and SHA-256 checksums verify.

**Commands:**
- `flutter test test/fitrah_launcher_test.dart test/loop_habit_save_test.dart` -- all focused tests pass.
- `flutter analyze --no-pub <changed Dart files>` -- no issues.
- `flutter build apk --release --no-pub` -- universal release APK 0.5.46 / 8137 builds and its v2 signature/package metadata verify.
- `npm run deploy:fitrah`, `npm run deploy:focus`, and `npm run deploy:sadar` -- all dedicated JS bundles verify and deploy READY; each production root and `/version.json` returns HTTP 200 and version 0.5.46 / 8137.

**Manual checks:**
- Install as an in-place upgrade on API 36 x86_64 AVD at 200% text; verify Fitrah HOME and saved data remain, tap Habits, edit/check in existing data, navigate back and inspect log for overflow/fatal errors.
