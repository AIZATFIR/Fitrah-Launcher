---
title: 'Tanggal atribusi timer tidak berubah saat restore'
type: 'feature'
ticket: ''
created: '2026-11-05'
status: 'built'
baseline_revision: '52ea191'
route: 'full'
route_source: 'pinned'
risk: 'medium'
review: 'none'
review_source: 'none'
lenses_ran: []
review_loop_iteration: 0
context:
  - docs/ecosystem/2026-11-03/BUILD-ROADMAP.md
  - docs/ecosystem/2026-11-03/ARCHITECTURE.md
---

## Intent

Habit timer credit must keep the local calendar date selected when the session began, including after pause, process restore, or a device timezone change.

## Implementation

- Persist nullable `attributionLocalDate` on the active `TimerSession` singleton.
- Capture it once at timer start, preserve through pause/resume/restore, and use it when writing the completed `HabitEntry`.
- Legacy sessions without the new field fall back to the saved `startedAt` date.
- Add state-machine coverage where the restored `startedAt` date differs from the immutable attribution date, plus Isar close/reopen coverage.

## Verification

- Regression test failed to compile before the field existed, then passed after implementation.
- `flutter test --no-pub` — 106 tests passed.
- `flutter analyze --no-pub` — no issues.
- `flutter test --no-pub test/isar_service_persistence_test.dart` — 7 tests passed after schema ID normalization.
- `git diff --check` — clean.

## Remaining E2 limits

This stores the local date string, not an IANA timezone ID or offset snapshot. It does not solve wall-clock changes, reboot uncertainty, monotonic interval recovery, terminal session history, or Android device behavior.
