---
title: 'Simpan tujuan pada sesi fokus dan histori'
type: feature
ticket: ''
created: '2026-11-16'
status: 'built'
baseline_revision: '75b393d3382564e7f332be4a3574e0510dd4cffb'
route: 'full'
route_source: 'auto'
risk: 'high'
review: 'none'
review_source: 'pinned'
lenses_ran: []
review_loop_iteration: 0
context:
  - 'docs/ecosystem/2026-11-03/ARCHITECTURE.md'
  - 'docs/ecosystem/2026-11-03/BUILD-ROADMAP.md'
  - 'docs/ecosystem/2026-11-03/PRD.md'
  - '_bmad-output/initiative-focus-clock-ecosystem/plan-goals-and-today-selection.md'
  - '_bmad-output/initiative-focus-clock-ecosystem/plan-per-session-focus-history.md'
---

<frozen-after-approval reason="human-approved ecosystem build; captured goal attribution intent">

## Intent

**Problem:** Home can select a timed habit for a goal, but the active timer and durable session history lose that goal association. This breaks the user's ability to see whether their time supported the intention they chose.

**Approach:** Snapshot the linked goal ID and title when Home starts a timed habit, carry them through active timer persistence and terminal history, and show the title in Home's active/history cues.

## Boundaries & Constraints

**Always:** Direct timer starts remain valid with no goal; existing sessions and old browser/backup data decode with null goal fields; copy attribution from the selected persisted link only; preserve idempotent terminal writes and all existing Isar schema identities.

**Never:** Infer or backfill goal links, alter historical data, change timer ownership, or change the selected Bookpaper/clock design.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Goal-linked Home start | Today choice links timed habit to goal | Active timer and terminal history retain goal ID/title; Home cues display goal | Existing start/commit failures remain visible and retryable |
| Direct or legacy session | Start without goal; restore old active/browser/backup record | Session works with null attribution and no decode failure | Missing optional fields default to null |
| Completion/cancel/retry | Attributed timer completes, cancels, or retries commit | One immutable history row keeps attribution; retry does not duplicate it | Existing transactional/idempotent guarantees remain |

</frozen-after-approval>

## Code Map

- `lib/models/timer_session.dart`, `terminal_focus_session.dart` -- durable active and terminal session records.
- `lib/services/sadar_timer_engine.dart` -- timer start, restore, transitions and state.
- `lib/features/launcher/widgets/home_intent_cue.dart`, `focus_clock_home_view.dart`, `lib/features/sadar/widgets/sadar_timer_view.dart` -- chosen-goal dispatch, Home cues and timer route.
- `lib/data/repositories/sadar_repository.dart` -- terminal session conversion and commit.
- `lib/data/store/live_model_codec.dart`, `lib/data/focus_clock_backup.dart` -- browser persistence and portable backup compatibility.
- `lib/models/timer_session.g.dart`, `terminal_focus_session.g.dart` -- generated Isar schema definitions.

## Tasks & Acceptance

**Execution:**
- [x] Add nullable goal snapshots to active/terminal models and propagate them through start, restore, state transitions and terminal commit.
- [x] Pass the selected linked goal from Home to timer and show it in active/history cues.
- [x] Extend browser codec and portable backup writer while decoding legacy records without goal fields.
- [x] Generate Isar schema changes without changing existing collection/property IDs and cover the matrix with focused tests.

**Acceptance Criteria:**
- A timed habit started from a goal-linked Home selection remains attributed after app restart and in its terminal history.
- Sessions started elsewhere remain usable and unlinked; legacy data remains readable.

## Implementation Notes

Implementation adds goal snapshots to the active timer and terminal session models, carries them through timer restore/state transitions and repository commits, and serializes them in browser and portable backups. Home resolves the explicitly linked goal for its selected timed habit and shows the snapshot with active/history cues. Isar generated schemas preserve prior property IDs; the schema fixer now reapplies that mapping after generation.

Verification at implementation: 63 focused timer/repository/session/backup tests, Home goal-dispatch test, native Isar reopen test, scoped code generation, analyzer, web release build and `git diff --check` passed. The two Home widget failures seen during that intermediate run (stale palette action label and 3.8 px narrow-layout overflow) were subsequently resolved; the full randomized v8100 suite passed **438 tests**. Full analyzer retains five info-only lints in unrelated files.


## Plan Change Log


## Review Triage Log


## Verification

**Commands:**
- Full randomized v8100 suite -- **438 passed**; includes goal attribution, Home layout and feature regressions.
- Native Isar persistence and schema IDs were verified in the focused suites; the repository generator still needs its unrelated annotation-resolution cleanup for a clean whole-command exit.
- Production web build, fresh Chrome runtime, five browser storage journeys, `git diff --check`, and release checksums passed for v8100.
