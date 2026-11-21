---
title: 'Make the Home add button start today’s action'
type: 'feature'
ticket: ''
created: '2026-11-21'
status: 'built'
baseline_revision: 'fb1df4f'
route: 'oneshot'
route_source: 'auto'
risk: 'low'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 0
context:
  - docs/ecosystem/2026-11-03/EXPERIENCE.md
  - _bmad-output/initiative-focus-clock-ecosystem/plan-home-default-goal-link.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The primary Home “Tambah kegiatan” button only saves a task to the inbox, leaving the user to find and choose it as today’s action. That extra navigation weakens the goal cue and delays starting.

**Approach:** From the empty Home action cue, let the user create a task and immediately select it for today, linking the active pinned goal by default. Keep inbox capture as a separate quick capture that does not replace today’s action.

</frozen-after-approval>

## Implementation Notes

- Two-file change, estimated 50–90 LOC; direct implementation is appropriate.
- Reuse `TaskRepository.add` returned ID and `IntentRepository.choose`; no schema or timer changes.
- On conflict/failure the task remains saved in the inbox, and Home must state that it was not selected. Respect widget disposal after the dialog.
- Preserve the Bookpaper palette, clock face, and existing inbox capture behavior.
- Do not run automated tests; verify with release builds and isolated/manual UI flows.

- Changed `home_intent_cue.dart` to await task creation, then select it with the original day's expected revision and pinned goal; surfaces a recovery message if selection fails.
- Changed `focus_clock_home_view.dart` so the Home dialog returns the persisted task ID; Inbox still uses ordinary capture.
- Versioned and packaged v0.5.36 / 8127 APK + web ZIP; web deployment is READY. No Android device was attached; tests were not run.
