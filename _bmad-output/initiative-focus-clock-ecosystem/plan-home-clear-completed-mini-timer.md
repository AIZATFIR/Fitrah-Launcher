---
title: 'Mini timer Home hilang setelah sesi selesai'
type: bugfix
ticket: ''
created: '2026-11-19'
status: 'built'
baseline_revision: 'working-tree'
route: 'oneshot'
route_source: 'runtime-repro-and-owner-authorized-ecosystem-build'
risk: 'medium'
review: 'quick'
review_source: 'runtime-repro-and-owner-authorized-ecosystem-build'
lenses_ran: ['systematic-debugging', 'test-driven-development']
review_loop_iteration: 0
context:
  - 'docs/ecosystem/2026-11-03/BUILD-ROADMAP.md'
  - '_bmad-output/initiative-focus-clock-ecosystem/plan-home-and-quick-timer-single-owner.md'
---

## Intent

When a shared focus session completes and the user returns to Fitrah Home, remove the mini timer. Keep it visible while active or while completion is waiting to be saved. A stable `completed` state must never produce a persistent `00:00` control that covers the Home content.

## Implementation

- The Home listener shows the mini timer for active/pending sessions, plus the transient completed event that follows a pending save and still needs Home's completion handling.
- A completed state observed after Home is rebuilt or resumed is treated as history, not a running control.
- Keep the session ledger and measured history unchanged.

## Verification

- Regression-first widget test: completed shared timer state no longer renders Home's keyed mini timer.
- Persisted-data suite and Sadar session-view suite pass; scoped analyzer clean.
- Release preview v8094 installed over v8093 on API36 x86_64 AVD. Fitrah remained Android HOME; the linked LKS action started with notifications denied, completed and showed `Fokus hari ini · 1 menit`; returning Home did not leave the `00:00` overlay. QA session history remains visible.
- Physical/OEM and extended owner use remain open.
