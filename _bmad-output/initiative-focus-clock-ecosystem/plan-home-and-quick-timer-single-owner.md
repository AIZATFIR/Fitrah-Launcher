---
title: 'Satu owner untuk timer Home dan QuickTimerHub'
type: 'feature'
ticket: ''
created: '2026-11-04'
status: 'built'
baseline_revision: '1709e1bf3fd32e2f7f73a19e648141cbb362484a'
route: 'full'
route_source: 'pinned'
risk: 'high'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 0
context:
  - docs/ecosystem/2026-11-03/BUILD-ROADMAP.md
  - docs/ecosystem/2026-11-03/ARCHITECTURE.md
  - docs/ecosystem/2026-11-03/decisions/ADR-E1-storage.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Focus Clock Home and QuickTimerHub each own volatile timer state, so one can replace the other and neither consistently survives app restart. Home completion also has source-specific behavior for a free timer, preset and scheduled Activity.

**Approach:** Extend the existing persisted timer owner to represent free, preset and scheduled-Activity sessions, then route Home and QuickTimerHub through that owner. Persist source identity with the active session so resume and completion act on the same Activity and record actual elapsed time.

## Boundaries & Constraints

**Always:** One active timer across these entry points; persist start/pause/resume/end before reporting success; reject a second active session; use the Activity ID rather than title matching; retain actual elapsed seconds and avoid granting the full target on early finish; keep existing approved Home dial, palette and timer screen styling.

**Never:** Replace habit timer behavior; change YPT app guarding or FocusSessionView; add AI, notification scheduling or a per-session history ledger in this slice; report data as saved before its repository transaction succeeds; erase or silently rewrite existing TimerSession or Activity data.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Home timer active | Home starts free, preset or scheduled Activity session | QuickTimerHub and Home observe the same label, remaining time and pause state | A second start is refused with the active session retained |
| Restart while active | Persisted session has a valid running or paused checkpoint | Shared owner restores the same source and remaining duration | Invalid/failed restore remains visible and does not start a replacement |
| Early finish | User ends before target | Actual elapsed time is retained and only linked Activity is updated according to its source behavior | Failed write remains pending and can be retried |
| Storage failure | Start/pause/resume/cancel write fails | Prior durable session remains authoritative | UI rolls back or shows pending error; no false success |

</frozen-after-approval>

## Code Map

- `lib/services/sadar_timer_engine.dart` -- existing restore-first owner, single-active guard, durable pause/resume/cancel and completion retry; currently assumes each session belongs to a Habit.
- `lib/models/timer_session.dart` -- singleton persisted record has only `habitId`, title, target, timestamps, accumulated seconds and status; source type/Activity identity must be added compatibly.
- `lib/data/repositories/sadar_repository.dart` -- owns timer session save/clear and atomic HabitEntry completion; extend the transaction boundary for Activity-backed completion without breaking habit completion.
- `lib/features/launcher/widgets/focus_clock_home_view.dart` -- local `ActiveTimer`, local ticker and `_finishTimer` handle free/preset/block side effects; its start/pause/finish callers include timer screen, mini bar, preset rows and free-time chips.
- `lib/widgets/quick_timer_hub.dart` and `lib/providers/providers.dart` -- separate title/total/paused/deadline StateProviders; QuickTimerHub creates an Activity at start and owns pause/reschedule/stop behavior.
- `test/sadar_timer_state_machine_test.dart`, `test/sadar_repository_test.dart`, `test/focus_clock_home_persisted_data_test.dart` -- reuse repository failure/recovery and widget provider patterns; add coverage for shared non-habit sessions.
- Do not replace `AnalogClockFace`, HabitEntry aggregation rules, or the distinct YPT and Focus Activity timer flows in this slice.

## Tasks & Acceptance

**Execution:**
- [x] `lib/models/timer_session.dart` and generated schema -- add nullable source kind and Activity identity fields with stable existing collection identity; existing habit-only rows must restore as habits.
- [x] `lib/data/repositories/sadar_repository.dart` and `lib/services/sadar_timer_engine.dart` -- add non-habit start/restore/completion paths while retaining one active session and transactional retry semantics.
- [x] `lib/features/launcher/widgets/focus_clock_home_view.dart`, `lib/widgets/quick_timer_hub.dart`, and `lib/providers/providers.dart` -- remove their independent countdown owners and consume the shared timer state; preserve each entry point's activity creation/update behavior.
- [x] `test/sadar_repository_test.dart`, `test/sadar_timer_state_machine_test.dart`, `test/focus_clock_home_persisted_data_test.dart`, new `test/quick_timer_hub_shared_session_test.dart`, and `test/isar_service_persistence_test.dart` -- cover restore, duplicate starts, exact Activity association, early finish and injected write failures.
- [x] `docs/ecosystem/2026-11-03/{BUILD-ROADMAP,EVIDENCE}.md` -- record only verified integration and leave YPT/Focus Activity owners open.

**Acceptance Criteria:**
- Given any Home or QuickTimerHub timer is running, when another entry point opens, then it shows the same session and cannot start an overlapping one.
- Given a non-habit timer is paused and the process restarts, when storage is available, then it restores paused with the same source association and remaining duration.
- Given an Activity-backed timer finishes early, when completion commits, then only the referenced Activity is updated and actual elapsed time is preserved.
- Given a start or completion write fails, when the user retries or reopens, then the app never claims success and does not lose the active session.
- Given an existing Habit TimerSession, when the new build opens it, then it resumes through the existing habit completion path.

## Implementation Notes

## Plan Change Log

## Review Triage Log

| Finding | Verdict | Route | Action / Evidence |
|---------|---------|-------|------------------|
| Home cancel hid the timer locally without clearing the persisted shared session. | Valid, medium | patch | Home now waits for `engine.cancel()` before hiding; on failure it keeps the session visible with a retry message. Regression coverage added in `test/focus_clock_home_persisted_data_test.dart`. |
| QuickTimerHub could leave an Activity without a timer if session persistence failed, and retry could duplicate it. | Valid, medium | patch | Activity creation and timer start now share a repository transaction. Failure injection proves rollback; retry creates one linked Activity in `test/quick_timer_hub_shared_session_test.dart` and `test/isar_service_persistence_test.dart`. |
| An out-of-range persisted source kind could throw during restore and strand the saved session. | Valid, medium | patch | Source decoding is bounds-safe; invalid records surface a restore error and block replacement/actions without deleting the record. Regression coverage added in `test/sadar_timer_state_machine_test.dart`. |

## Design Notes

`TimerSession` remains the active-session record; this slice does not create a history ledger. New source fields must be additive and nullable/default-safe for previously stored habit sessions. Home preset timers currently create a schedule block on finish, while QuickTimerHub writes its Activity on start; preserve each visible behavior and prevent retries from creating duplicate rows.

## Verification

**Commands:**
- `flutter test --no-pub test/sadar_repository_test.dart test/sadar_timer_state_machine_test.dart test/focus_clock_home_persisted_data_test.dart test/quick_timer_hub_shared_session_test.dart test/isar_service_persistence_test.dart` -- 48 tests pass.
- `flutter analyze --no-pub` -- no issues after replacing a protected StateNotifier member access with the engine's public getter.
- `flutter build apk --debug --no-pub --split-per-abi` -- armeabi-v7a, arm64-v8a and x86_64 debug APKs build; arm64 SHA-256 `5a0d670ba587f13019c825376ddf3db84e5d1cb31fe83eff02fe77fe712fa866`.
- `git diff --check` -- no whitespace errors.

**Manual checks:** A disposable x64 API36 AVD verified a free Home timer after force-stop/reopen: the same session returned and its remaining time continued from the saved same-boot monotonic checkpoint. Home's Timer sheet then showed the active session and opened it without offering a competing start. Screenshot: `.dart_tool/android-qa/2026-11-14-v33/v36-active-timer-hub.png`. This does not close the gate: QuickTimerHub handoff, pause/restart, exactly one Activity updated on finish, reboot/timezone uncertainty, and physical-device confirmation remain open.
