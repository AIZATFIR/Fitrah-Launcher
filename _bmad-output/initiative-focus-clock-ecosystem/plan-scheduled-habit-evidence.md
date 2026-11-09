---
title: 'Keep scheduled habit sessions connected to their evidence'
type: feature
created: '2026-11-08'
status: built
baseline_revision: 4e20c9024c349af8779c292536f50caf949edcda
route: full
route_source: auto
risk: high
review: quick
review_source: pinned
lenses_ran: [quick]
review_loop_iteration: 0
context:
  - /home/aizatfir/Project/Fitrah-Launcher/docs/ecosystem/2026-11-03/ARCHITECTURE.md
---

<frozen-after-approval>

## Intent

A user must be able to schedule an existing timed habit, start its exact clock block, end early, and see the same measured evidence on the habit and schedule. Completing 8 minutes of a 45-minute habit is partial progress, not fulfillment. Reuse the established Home/dial/session rather than another local timer or matching by title.

## Boundaries

Keep chosen palettes/dial and UUID goal/choice relationships. Persist explicit optional Activity-to-habit linkage and immutable start-time habit target in the active session. Preserve old schema collection/index identities and old data. No inference from titles/descriptions, no memory fallback success, no fictitious unit credit, no duplicate timer owner. New scheduling path supports timed/minute habits; binary/count keep manual actions and progression/hybrid are not reinterpreted as minutes. Archive/rename/target edit after start must not redirect the already started session. Protect pre-existing dirty build/web files and _bmad/render. Finish this slice without claiming the whole ecosystem done.

## I/O & Edge-Case Matrix

| Scenario | State/input | Expected behavior | Failure handling |
|---|---|---|---|
| Schedule | Two same-name timed habits; choose one; span noon/midnight | Every Activity segment links exact chosen habit; full requested duration; shared group retained | Validate source and conflicts atomically; failure leaves no orphan block |
| Start | Open block from Home/dial; linked habit | One durable session snapshots original habit ID and target while retaining Activity ID; all consumers see same session | Missing/archived/unsupported source at start is visible; active session never replaced |
| Partial | Target 45 min, stop at 480 seconds | Habit records 480 seconds and remains unfulfilled; schedule records actual time, not 45 min credit | Same outcome after pause/reopen; zero seconds creates no fulfillment |
| Aggregate | Additional sessions and sub-minute contributions | Accumulate exact seconds once; fulfill only when frozen daily target is reached | Duplicate finish/retry adds no second contribution |
| Snapshot | Rename/archive/change target or schedule linkage after start | Original source and target remain bound to active session; existing daily target snapshot retained | No attribution to replacement habit; missing Activity cannot falsely report success |
| Atomicity | Inject failure after one completion write | Activity, HabitEntry and session deletion commit together or all roll back | Pending session survives and retry credits exactly once |
| Compatibility | Open baseline native fixture; v1-v3 backup/live payloads | Existing IDs, values, paused session and relationships preserved; absent new fields are null | New portable version prevents old readers silently dropping linkage |

</frozen-after-approval>

## Code Map

- `lib/services/home_schedule_service.dart`: add optional habitId, exclusive with taskId, validate real timed/min habit inside writeTxn, attach to every split segment. Existing sample path remains explicit.
- `lib/features/launcher/widgets/focus_clock_home_view.dart`: `_openScheduleToClockSheet` currently uses local `_habits` (empty in production); show real persisted eligible habits and preserve selected ID. `_scheduleInboxTask` forwards it; custom/preset/task selection clears habit identity. Preserve error/busy behavior. `home_intent_cue.dart` can expose secondary Atur waktu for selected eligible habit via parent callback, letting goal→choice→habit→schedule be reachable.
- `lib/models/activity.dart`: nullable habitId; `timer_session.dart`: nullable habitTargetSnapshot (minutes) frozen at start. Generate only affected serializers then run `dart tool/fix_isar_schema_ids.dart`; generator may delete other .g.dart files, restore untouched outputs from baseline. Never modify existing collection/index identities.
- Activity clones must preserve linkage: `activity_repository.dart` recurring projection/duplicate/clone; `features/activity_detail/activity_detail_sheet.dart` segmentation; `features/focusclock/focusclock_tab.dart` copy day; `services/ai_service.dart` replacement segments; `services/firebase_sync_service.dart` serialization; `sadar_repository.dart` recurring occurrence clone. Search all Activity constructors for preservation.
- `lib/services/sadar_timer_engine.dart`: startNonHabit Activity starts must resolve and persist linked habit metadata, retain it through every TimerState copy/pause/resume/restore/buildSession. Validate the source again in initial durable start transaction to avoid racing edits. Existing Home/FocusSessionView/QuickTimerHub starts must share this behavior. Completion currently routes habit first and loses Activity update; route linked schedule through atomic combined completion.
- `lib/data/repositories/sadar_repository.dart`: completeTimerSession currently unconditionally sets status yes; fix timed contribution calculation to compare accumulated actual seconds against retained daily target. Reuse a shared contribution helper in atomic Activity+Habit completion; no nested transactions. Session's saved metadata governs attribution, not edited Activity. Preserve exact subminute aggregation and non-timed manual evidence.
- `lib/data/store/live_model_codec.dart`, `focus_clock_backup.dart`, `focus_clock_backup_service.dart`: preserve nullable fields, bump portable version to 4, read v1-v3. Update fixture/harness version assertions and validate refs without inventing missing legacy links.
- Synthetic old-schema fixture already produced from baseline before edits: `test/fixtures/migrations/pre_habit_schedule_4e20c90.isar.gz` and metadata JSON. Decompress/copy to temporary directory and open with new schema; do not regenerate/replace fixture. Contains habit17 target45, Activity23 actual42, entry31 seconds480, paused session seconds480. This proves upgrade against actual previous serializer output.

## Tasks & Acceptance

- [x] Implement explicit scheduling/clone/codec fields and frozen session target.
- [x] Connect real habit selection to schedule and make action reachable from selected Home habit.
- [x] Implement shared atomic completion with unit-safe partial/aggregate evidence and start-time attribution.
- [x] Cover every matrix row with focused native/repository/engine/widget checks; verify old native fixture and backup roundtrip; run analyzer and relevant regressions. Update roadmap with limits.

Given goal-linked LKS habit45, when scheduled and started from its dial block and ended at8min, then the same habit/Activity IDs retain480 measured seconds, daily goal remains incomplete, and reopening shows the same evidence. Given write failure, retry does not double credit. Given a legacy database, adding these nullable fields preserves previous values.

## Implementation Notes

Owner has authorized continuing across slices without new approval questions. Code/identity continuity is the priority. Browser UI access was previously rejected; do not bypass it. Fixture is synthetic and ready to use.

## Verification

Focused schedule, engine, repository, Home and backup tests. Native fixture upgrade and failed-transaction tests. Analyzer; compile fresh web to /tmp after fixes, never build/web. Do not repeat passing checks without relevant changes.

## Review Triage Log

- High / patch — floating/normal window transitions dropped Activity identity, source kind, measured seconds and pending/error state. Preserved every TimerState field in both transitions. Native scheduled-habit floating → normal → resume/pause → finish regression proves the original Activity and habit receive 480 seconds once.
- Medium / patch — backup source-existence checks rejected valid stale references following permanent habit deletion. Removed existence requirements while retaining positive ID and target validation. Export → recovery → restore regression retains the deleted source ID, frozen target, active session and unlinked Activity without recreating the habit.
- Analyzer info / patch — enclosed the window mock conditional in braces; no behavior change.

## Final regression evidence (9 Nov 2026)

- Full Flutter suite: 193 tests passed in 28 seconds after both review patches (`/tmp/focus-clock-scheduled-full-test.log`). Review findings addressed; device and browser runtime checks remain unverified.
- Final analyzer: no issues (7.9 seconds). Final JavaScript web release compile: passed (65.2 seconds), output `/tmp/fitrah-scheduled-habit-final-web`. Wasm dry-run reports existing unsupported native/interop dependencies; this release is JavaScript, not Wasm. `git diff --check` passed.

## Execution evidence (9 Nov 2026)

- Added nullable Activity habit linkage and active-session habit target snapshot; regenerated only their serializers and reapplied schema-ID compatibility. Existing collection and index identities match baseline.
- Real persisted timed/min habits are reachable from Home choice → Atur waktu and the schedule picker. Task/custom/preset selection clears habit identity. Schedule validation and all split writes are atomic.
- Durable start resolves source inside the transaction. Completion uses saved identity/target; daily target snapshot wins if already present. Partial/zero time remains unfulfilled, exact seconds aggregate without unit conversion for count/binary. Manual evidence is retained without turning old manual target minutes into measurement.
- Combined completion rolls back after an injected HabitEntry write failure and retry contributes once. Unchanged Activity keeps its ID and accumulates seconds; edited source creates an actual occurrence with original attribution while retaining the edited plan.
- Native fixture upgrade and checksum passed; backup v4 roundtrip/restore, v1–v3 missing fields and live v1 missing fields passed. Focused regression batch: 80 passed. Home/FocusSession widget batch: 18 passed. Latest relevant subset after final source edits: 29 passed. Analyzer: no issues.
- Browser UI was not accessed. Native fixture, pre-existing build/web changes and _bmad/render were preserved. Fresh web compile passed to `/tmp/fitrah-scheduled-habit-evidence-web`.
