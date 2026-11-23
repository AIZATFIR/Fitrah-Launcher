---
title: 'Create a schedule block by tapping an empty clock time'
type: 'feature'
ticket: ''
created: '2026-11-23'
status: 'built'
baseline_revision: 'fc202dc766b172581b94cad5c6dc911655d3ef29'
route: 'oneshot'
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

<frozen-after-approval reason="Owner explicitly approved a blank, easy-to-fill clock canvas and said precise dragging is difficult">

## Intent

**Problem:** Tapping an empty time on the analog clock currently does nothing, so making a block requires a precise drag or finding a separate add action. That makes the clock harder to use for the owner's book-like, low-friction planning model.

**Approach:** A tap on an empty clock ring opens the existing activity editor with that time snapped to five minutes and a 30-minute starting span. The activity name and notes remain empty; the user can adjust the span and save. Existing activity taps, drag-to-create, instant mode, task linking, and clock appearance keep their current behavior.

</frozen-after-approval>

## Implementation Notes

Reuse `FocusClockTab`'s ring hit geometry, existing time conversion helpers, and `showActivityDetailSheet(..., mode: DetailMode.create)`. Add one focused widget regression proving an empty dial tap opens the blank create form at the tapped time. Keep implementation in the clock gesture path; no new dependency or visual redesign.

## Verification

- Focused `flutter test` for the clock schedule interaction -- regression passes.
- Scoped `flutter analyze` for touched Dart files -- clean.
- `git diff --check` -- clean.
- Independent quick review -- no findings.
