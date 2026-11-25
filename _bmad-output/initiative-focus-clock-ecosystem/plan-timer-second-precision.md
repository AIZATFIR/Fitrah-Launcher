---
title: 'Habit timer keeps exact measured seconds'
type: 'feature'
ticket: ''
created: '2026-11-05'
status: 'built'
baseline_revision: '1d21eb2'
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

Habit timer completions currently truncate each session to whole minutes, losing short sessions and repeated remainders. Persist exact aggregate timer seconds while keeping existing minute-based UI and legacy records usable.

## Implementation

- Add `HabitEntry.actualDurationSeconds` as exact measured timer contribution.
- Pass actual seconds from the shared timer engine into the atomic completion transaction.
- Aggregate sub-minute sessions before projecting whole minutes to existing `actualDurationMinutes` and `valueCompleted` fields.
- Recover older timer totals from saved whole minutes; manual status does not become measured seconds.
- Keep this as a daily aggregate. Per-session immutable history remains an E2 gap.

## Verification

- Regression test failed to compile before the new field/API existed, then passed.
- Repository tests cover two sub-minute sessions totaling 90 seconds and migration from a legacy 10-minute timer total.
- Isar reopen fixture verifies the exact-second aggregate survives persistence.
- `flutter test --no-pub` — 108 tests passed.
- `flutter analyze --no-pub` — no issues.
- `flutter build apk --debug --no-pub --split-per-abi` — all three ABIs built; arm64 SHA-256 `525d207281a590eb25e76a7dd3980de625486d73e50b7725ca9113cbe3dbc1f5`.
- `git diff --check` — clean.

## Remaining limits

No individual session ledger or correction receipts are added here. Device migration, reboot recovery and cross-device sync remain open.
