---
title: 'Remove the duplicate empty-agenda cue from Home'
type: 'feature'
ticket: ''
created: '2026-11-23'
status: 'built'
baseline_revision: '3260044435578f2a2c37eed2c6e5a71048419457'
route: 'oneshot'
route_source: 'auto'
risk: 'low'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick-code-review']
review_loop_iteration: 1
context:
  - 'docs/ecosystem/2026-11-03/DESIGN.md'
  - 'docs/ecosystem/2026-11-03/EXPERIENCE.md'
  - 'test/focus_clock_home_lampiran1_test.dart'
---

<frozen-after-approval reason="Owner authorized continued Focus Clock ecosystem implementation and requested the whole UI stay clear and easy to use">

## Intent

**Problem:** A fresh Home with no scheduled activities repeats the same empty-day status in the top agenda strip and beside the clock, adding a second message without a new action or information.

**Approach:** Hide only the top agenda strip when its loaded schedule has no upcoming blocks; keep the clock's own status, and retain top-strip loading, error, prayer setup, and populated agenda states.

</frozen-after-approval>

## Implementation Notes

Oneshot is appropriate: one existing view and its focused widget test; no model, storage, navigation, or clock-face changes.

Red/green: the revised empty-agenda check failed before the UI change because the duplicate banner was rendered. A separate past-only fixture also failed before the future-only filter because the strip stayed 44 dp high. The support-tools test helper now ensures its tile is inside the 320×760 viewport before tapping.

## Verification

- Home empty-state/past-only/active schedule checks: `focus_clock_home_lampiran1_test.dart` 21 passed; `focus_clock_home_persisted_data_test.dart` 10 passed.
- `flutter analyze --no-pub lib/features/launcher/widgets/focus_clock_home_view.dart` -- no diagnostics in changed code.
- `git diff --check` -- clean.

## Review Triage Log

- Quick review v2: no findings. The earlier past-only agenda finding is resolved by filtering completed/current/past blocks and the deterministic past-only widget test.
- Final verification: `focus_clock_home_lampiran1_test.dart` 21 passed; `focus_clock_home_persisted_data_test.dart` 10 passed; scoped analyzer clean; Dart format check clean; `git diff --check` clean.
