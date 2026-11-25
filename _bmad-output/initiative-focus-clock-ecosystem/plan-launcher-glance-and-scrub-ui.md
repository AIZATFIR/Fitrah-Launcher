---
title: 'Keep the launcher glanceable and make app scrubbing direct'
type: 'feature'
ticket: ''
created: '2026-11-23'
status: 'built'
baseline_revision: '41b4febb5d16863833281e1b736792efb0c546b7'
route: 'full'
route_source: 'auto'
risk: 'medium'
review: 'quick'
review_source: 'pinned'
lenses_ran: [quick]
review_loop_iteration: 0
context:
  - docs/ecosystem/2026-11-03/EXPERIENCE.md
  - docs/ecosystem/2026-11-03/DESIGN.md
---

<frozen-after-approval reason="Owner directed the launcher UI changes and asked to continue the ecosystem build">

## Intent

**Problem:** The launcher shows a bottom tab bar despite the owner's requested left/right swipe navigation, the Home clock is visually buried, and app-index scrubbing scrolls a long list instead of temporarily focusing the selected letter. The full clock page also contains a second, ambiguous natural-language scheduling card.

**Approach:** Keep the Home clock first, use the existing horizontal PageView as navigation, and make alphabet scrubbing temporarily show only the selected section while held. Remove the redundant clock-page card, keep hidden-app access as an icon, and leave user-created goal fields empty without goal examples in AI tool descriptions.

## Boundaries & Constraints

**Always:** Preserve saved data, existing palette/clock face, A–Z haptics and scroll behavior, keyboard/screen-reader access, and existing scheduling paths. Letter filtering is temporary and must clear on release/cancel.

**Never:** Add sample goals, replace PageView gestures, remove the actual schedule editor, or add a new bottom navigation bar.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Alphabet scrub | Hold/drag over a letter | Only apps in that letter remain visible while the rail selection and list motion track the finger | Empty sections show a quiet empty state; list remains operable |
| Release/cancel | Lift finger or cancel gesture | Full app list returns and normal scrolling remains available | Scrubber always clears temporary selection |
| First run | No saved goal, habits, or schedule | Goal and prepared text fields are blank; AI does not seed a specific aspiration | Core pages remain usable |
| Swipe navigation | Home, clock, habits, or app drawer visible | Horizontal PageView changes destination; no tab bar is shown | Android Back returns to Home |

</frozen-after-approval>

## Code Map

- `lib/features/launcher/fitrah_launcher_shell.dart` -- four-page horizontal PageView; remove only the bottom NavigationBar.
- `lib/features/launcher/widgets/focus_clock_home_view.dart` -- Home list and compact analog dial; put dial first while retaining existing goal/date/habit content and empty user fields.
- `lib/features/launcher/widgets/minimalist_app_drawer.dart` -- real installed-app list, hidden-app management, and filtering. Apply a temporary letter filter only during rail drag; keep favorites, search, and footer behavior outside the temporary state.
- `lib/features/launcher/widgets/niagara_wave_scrubber.dart` -- shared A–Z gestures and callbacks. Force the initial selection callback when drag starts on the already-highlighted letter; preserve haptics and accessible adjustments.
- `lib/features/focusclock/focusclock_tab.dart` -- remove the bottom NowNextCard; keep clock tap/drag and schedule-list entry points intact.
- `lib/services/ai_service.dart` -- keep goal schedule tool descriptions neutral and explicitly prevent inventing an aspiration.

## Tasks & Acceptance

**Execution:**
- [x] `fitrah_launcher_shell.dart`, `focus_clock_home_view.dart`, `focusclock_tab.dart` -- align clock/navigation hierarchy and remove the redundant card.
- [x] `minimalist_app_drawer.dart`, `niagara_wave_scrubber.dart` -- implement temporary selected-letter focus with release recovery and icon-only hidden-app access.
- [x] `ai_service.dart` -- remove specific default-goal examples.
- [x] Build and inspect Android APK and three web entry points; confirm existing release workflow supports portable desktop artifacts.

**Acceptance Criteria:**
- Given Home is open, when the user scrolls its first view, then the analog clock appears before goal, date, and supporting tools.
- Given the launcher is open, when the user swipes horizontally, then adjacent destinations remain reachable with no bottom tabs.
- Given the user drags the app index, when they pause on a letter, then only apps in that section appear until release; release restores the complete list.
- Given a new installation, when Home or AI goal planning is first opened, then no specific goal is prefilled or suggested by tool metadata.
- Given the full clock page is open, when the user plans time, then the dial and schedule-list actions remain available without the redundant text-entry card.

## Implementation Notes

Source changes implemented. Focused `dart analyze` on the six edited Dart files and `git diff --check` passed; no test suite was run. Built Android APK v0.5.54+8146 (74.6 MB), verified its v2 signature, installed it on the available emulator, opened the Jam page, and confirmed the removed text-entry card is absent. Large Home status text wraps without ellipsis at 200%. Emulator QA data already contains a saved goal, so no user data was cleared for first-run verification. Built and bundle-verified Fitrah, Focus Clock, and Sadar web entry points; all three deployed to Vercel production and returned HTTP 200 with version.json 0.5.53 / 8145. Flutter emitted non-blocking Wasm dry-run compatibility warnings from existing dependencies. Confirmed `.github/workflows/release.yml` provides Linux and Windows package jobs. Local Linux packaging is blocked by the host clang++ loader missing `libLLVM.so.23.1`; Windows packaging requires its configured Windows CI runner. No test suite was run.

## Plan Change Log

## Review Triage Log

Quick review: no findings.

## Verification

Production deployments: [Fitrah](https://fitrah-web-three.vercel.app), [Focus Clock](https://focus-clock-web.vercel.app), [Sadar](https://sadar-web.vercel.app). Current download bundle: `release_dist/2026-11-23-focus-clock-v0.5.54-8146`.

**Commands:**
- `dart analyze` on six changed Dart files -- passed.
- `git diff --check` -- passed.
- `flutter build apk --release --no-pub` -- passed; APK metadata is 0.5.53 / 8145 and v2 signature verified.
- Fitrah, Focus Clock, and Sadar production web builds plus `scripts/verify_web_bundle.sh` -- passed.
- Production URLs -- HTTP 200; each deployed `version.json` reports 0.5.53 / 8145.
- `flutter build linux --release --no-pub` -- blocked by host `clang++` dependency (`libLLVM.so.23.1` missing). Windows package workflow is configured on `windows-latest` CI.

**Manual checks:**
- Installed the Android APK in the available emulator, launched Home, opened Jam, and confirmed the clock page no longer shows the ambiguous natural-language card. No fatal Flutter exception or ANR was present in sampled logs.
- Existing emulator data was preserved; it contains an old saved QA goal. First-run goal defaults were checked in source and remain blank.
- The Android screenshot showed the retained clock-face palette and dial. Selected-letter scrub behavior is implemented with release/cancel recovery; no clean-state device scrub session was run.
