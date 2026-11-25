---
title: 'Connect Home inbox tasks to the clock'
type: feature
created: '2026-11-07'
status: built
baseline_revision: 8a582d3af50cd7045f782509cb28ae4f0cc433ed
route: full
route_source: auto
risk: high
review: quick
review_source: pinned
lenses_ran: [quick]
review_loop_iteration: 0
context: []
---

# Connect Home inbox tasks to the clock

<frozen-after-approval>

## Intent

Make production Home's task inbox use actual persisted tasks, and schedule a selected existing task onto the clock without losing its identity. Keep the established clock, colors and theme. Preserve the sample preview fixture. Avoid unrelated refactors and generated build outputs. Existing dirty build/web files and _bmad/render are user-owned; do not alter or stage them.

## I/O and edge cases

- Creating an inbox task persists it; after Home recreation it remains. Two tasks with the same title have distinct identities; selecting or deleting one affects that exact task.
- Unscheduled incomplete tasks appear on Home. Loading and storage errors are visible instead of being presented as an empty inbox. Unavailable persistent storage must not silently report a successful write.
- Scheduling an existing inbox task atomically writes the activity segment(s) and updates the same task ID. A failed transaction leaves the original task and no new activity. Repeated submissions or an already scheduled/deleted task do not create duplicate activities.
- Honor the requested duration across noon and midnight using valid half-day segments; do not schedule a quick action in the past. Reject conflicts based on current persisted data where supported; clearly document any limitation.
- Notification failures after a committed write must not falsely imply that scheduling failed or cause duplicate retries.
- Save controls prevent duplicate submissions and report failures while retaining user input. Preview sample behavior remains usable.

## Code map and constraints

- `lib/features/launcher/widgets/focus_clock_home_view.dart`: `_dumpedTasks`, task dump, add dialog and schedule sheet are local-only; schedule selection currently matches/removes title. Replace production path with task IDs and persisted provider data. Preserve preview sample path where helpful. Clear selected task identity when selecting a custom title, habit or preset.
- `lib/providers/providers.dart`: `eisenhowerTasksProvider` exposes repository watchAll as AsyncValue. Filter incomplete unscheduled tasks without hiding loading/error.
- `lib/data/repositories/task_repository.dart`: exposes `FocusStore? isar` and task APIs. Memory ID allocation may reuse IDs after deletion; fix if relevant.
- `lib/models/task.dart`, `lib/models/activity.dart`, `lib/core/time_math.dart`: existing persisted schema and splitSpan; no migration needed. Create segments with a shared stable group ID as appropriate, link original Task to first activity, and maintain valid date/half/minutes.
- Schedule using one FocusStore transaction, re-read the exact task and validate it has not already been scheduled, recheck persisted conflicts, insert all activities and update task. Do not chain separately committed writes. Run any notification updates after commit without misreporting success as failure.
- Existing Home activity projections render the dial. Other task consumers may only link the first segment; document material limits.
- `test/focus_clock_home_lampiran1_test.dart`, `test/focus_clock_home_persisted_data_test.dart`, `test/isar_service_persistence_test.dart` and `test/widget_test.dart` provide relevant patterns.

## Tasks

1. Implement durable inbox read, add, delete and stable selection. Retain inputs on errors and prevent duplicate operations.
2. Implement atomic scheduling for the selected task, including valid split intervals and transaction conflict checks. Keep non-inbox scheduling behavior coherent.
3. Add focused coverage of the matrix, using actual native storage where feasible; verify affected Home preview and relevant storage behavior. Run analyzer. Document remaining practical limitations.
4. Do not claim the entire ecosystem or release is finished on completion of this slice.

## Acceptance

Home shows real tasks and accurately reflects loading and errors; task operations persist and target IDs; scheduling creates visible valid clock activity segments and binds the original task atomically; failures are recoverable and do not create duplicates. Existing theme and preview are preserved.

</frozen-after-approval>

## Execution notes

User previously approved continuing implementation without additional checkpoints.

- Task consumers that follow `activityId` see only the first segment of a schedule split across noon or midnight; later segments appear as activities but are not linked to the task by those consumers.

## Review triage log

- Default late start could be in the past: confirmed; fixed by choosing the next half-hour, including midnight.
- Sample scheduling truncated at midnight: confirmed; preview now rejects unsupported spans while retaining the task.
- First-segment task link limitation: confirmed and documented above.

## Verification

- Analyzer clean; 25 focused native scheduling and Home tests passed after review fixes.
- Five Home interaction tests passed with controlled storage, including persistence across widget recreation, failure and notification handling. Native transaction rollback and boundary splitting are covered separately with Isar.
- Browser and physical-device journeys remain to be verified before release.
