---
title: Prevent timer mutations from racing startup restore
type: bugfix
created: '2026-11-14'
status: built
risk: medium
review: focused-regression
---

## Intent

Do not let a user timer command mutate storage before the persisted active session has been read. A cancel issued during a delayed startup read could clear the row, after which restore would publish that already-deleted session as active.

## Implementation

- Gate start, pause, resume, extend, finish, retry and cancel behind the engine's startup restore future.
- Preserve existing per-command validation and write/retry behavior.
- Add a delayed repository regression proving cancel remains pending and storage remains untouched until the persisted session is read.
- Keep UI widget teardown deterministic under Flutter fake async; dispose isolated containers rather than issuing duplicate timer commands after the tested action.

## Verification

- Regression observed failing before the production guard and passing after it.
- State machine: 27 tests passed.
- Home persisted-data and QuickTimerHub widget suites passed; FocusSession and YPT shared-timer suites passed.
- Full suite: 330 passed serially; `flutter analyze --no-pub`: no issues.

## Limits

This startup ordering guard does not provide cross-process atomic operation receipts, revisions, or global single-active locking. Physical restart, reminders and device migration remain unverified.
