---
title: 'Start today’s unscheduled task from Home'
type: 'feature'
ticket: ''
created: '2026-11-21'
status: 'built'
baseline_revision: '6ac52617a495cd201a9ce3e775741dcaf1e8f57f'
route: 'oneshot'
route_source: 'auto'
risk: 'low'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 0
context:
  - docs/ecosystem/2026-11-03/EXPERIENCE.md
  - _bmad-output/initiative-focus-clock-ecosystem/plan-home-add-starts-today.md
---

<frozen-after-approval reason="human-owned intent — standing approval for the Focus Clock build">

## Intent

**Problem:** A task selected as today's action still opens the large scheduling sheet before focus can begin. This interrupts the Home cue's promised path from goal to action.

**Approach:** Start an unscheduled selected task as a goal-attributed 25-minute focus session from the primary Home button. Keep scheduling available as a smaller secondary action. Preserve existing behavior for tasks that already have a clock activity or scheduled time.

</frozen-after-approval>

## Implementation Notes

- Reuse the existing 25-minute quick-focus preset and `_startTimer` session engine; do not add settings or schema fields.
- Preserve goal attribution for the timer and the existing schedule sheet behind a secondary action.
- Preserve the Bookpaper palette and clock face.
- No automated tests per session instruction; use analyzer, release builds, and isolated web flow verification.

- Updated Home primary action to start the linked unscheduled task as a 25-minute goal-attributed timer; scheduling remains secondary.
- `flutter analyze --no-pub`, JS web/offline build, isolated web flow, universal v8128 APK build/signature, and production Vercel verification completed. Automated tests were not run.
- Android device is unavailable; no real-device Home-role smoke was possible.
