---
title: Keep uncertain timer recovery honest after restart
type: bugfix
ticket: ''
created: '2026-11-14'
status: built
baseline_revision: '3261e4a6f419ed9d4ae1c16bd4fc063c22551ef6'
route: 'full'
route_source: 'auto'
risk: 'high'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 0
context:
  - docs/ecosystem/2026-11-03/BUILD-ROADMAP.md
  - docs/ecosystem/2026-11-03/ARCHITECTURE.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** When a running session is restored without a matching Android boot/elapsed-realtime checkpoint, the engine estimates time from the calendar clock. A reboot, unavailable bridge, or clock correction can silently add unmeasured focus time or auto-complete the session. The UI does not tell the user that the restored time is uncertain.

**Approach:** Keep only the last durably measured seconds, restore the session paused with a visible uncertainty cue, and require the user to press Continue before a new monotonic segment starts. Same-boot restores keep their exact elapsed-realtime behavior.

**Always:** Preserve source, activity/habit attribution, original session date, target snapshot, and saved measured seconds. Never auto-complete or credit time inferred across an unverified clock boundary. Make the recovery notice visible on Home and each timer surface, with the ordinary pause/resume/finish controls usable.

**Never:** Do not add a new database field or migrate existing data for a transient recovery condition. Do not change same-boot accounting, target semantics, or timer ownership. Do not claim physical reboot verification when no device is available.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Same boot | Saved boot count matches and elapsed realtime is nondecreasing | Restore exact elapsed duration and continue running as today | No warning |
| Reboot or clock unavailable | Saved running session lacks a valid same-boot snapshot | Restore paused at saved accumulated seconds; show an uncertainty cue; do not auto-complete | Keep existing session/source intact |
| Wall clock jumps forward | Same uncertain state, calendar delta exceeds target | Do not add guessed time or mark complete | User may continue from saved seconds or finish with those seconds |
| User continues | Uncertain paused session | Start a fresh monotonic segment, persist it, and clear the uncertainty cue | On write failure, preserve paused state and warning |

</frozen-after-approval>

## Code Map

- `lib/services/sadar_timer_engine.dart::_restoreSavedSession` -- current matching-snapshot check and unsafe wall-clock fallback; `_persistState`, `_buildSession`, and `resume` already persist a new running segment with a fresh native snapshot.
- `lib/services/sadar_timer_engine.dart::TimerState` -- presentation state can carry a transient `recoveryUncertain` flag without changing Isar schema.
- `lib/features/launcher/widgets/home_intent_cue.dart` -- Home's shared-session cue; extend its selected provider tuple so the user sees why a paused session needs attention.
- `lib/features/sadar/widgets/sadar_timer_view.dart`, `lib/features/focusclock/widgets/focus_session_view.dart`, and `lib/features/sadar/widgets/sadar_ypt_focus_view.dart` -- shared timer consumers; retain existing controls and add the same short warning while paused.
- `lib/features/sadar/widgets/desktop_floating_timer.dart` and `SadarTimerEngine.extendBy/makeFloatingWindow/restoreNormalWindow` -- preserve the warning through floating/window changes; require explicit Continue before target extension.
- `test/sadar_timer_state_machine_test.dart` -- injectable clock reader already supports deterministic same-boot cases; add reboot, unavailable-reader, forward-wall-jump, and resume assertions.
- `test/sadar_timer_view_session_test.dart`, `test/focus_session_shared_timer_test.dart`, and `test/home_intent_cue_test.dart` -- existing widget harnesses for timer and Home cues.
- `test/scheduled_habit_evidence_test.dart` -- existing floating-window state preservation coverage.

## Tasks & Acceptance

**Execution:**
- [x] `lib/services/sadar_timer_engine.dart` and `test/sadar_timer_state_machine_test.dart` -- fail closed when the persisted Android clock identity cannot be matched; test no guessed credit, no auto-completion, preserved source/date/seconds, and explicit resume from the saved checkpoint.
- [x] `lib/features/launcher/widgets/home_intent_cue.dart`, `lib/features/sadar/widgets/sadar_timer_view.dart`, `lib/features/focusclock/widgets/focus_session_view.dart`, and `lib/features/sadar/widgets/sadar_ypt_focus_view.dart` -- surface the same localized recovery notice wherever the shared paused session is shown; add widget coverage to Home and representative timer surfaces.
- [x] `lib/features/sadar/widgets/desktop_floating_timer.dart` and `lib/services/sadar_timer_engine.dart` -- keep the warning visible through floating/window-mode state copies until Continue; block target extension until Continue.
- [x] `docs/ecosystem/2026-11-03/BUILD-ROADMAP.md` -- record the slice and retain physical restart/reboot as an open runtime gate.

**Acceptance Criteria:**
- Given a saved running session with a missing or mismatched boot snapshot, when restore sees any calendar-clock delta, then state is paused, measured duration equals only the saved checkpoint, and no completion/history write occurs.
- Given a matching boot snapshot with 60 seconds elapsed, when restored, then the current same-boot behavior remains running with exactly 60 seconds credited.
- Given an uncertain paused session, when the user opens Home or the owning timer surface, then the UI explains that time since restart was not counted and offers the existing Continue and Finish actions.
- Given the user chooses Continue, when the save succeeds, then a new same-boot segment starts and subsequent process recovery counts only its monotonic elapsed time; on save failure the warning and paused session remain.

## Implementation Notes

Implementation expanded the notice to the desktop floating timer after diff review found that floating/window and paused target-extension state copies could otherwise clear the transient warning before the user chose Continue. Target extension now reports why it is unavailable until Continue; QuickTimerHub disables those actions during uncertain recovery and handles persistence errors in the UI.

## Plan Change Log

## Review Triage Log

- patch — Recovery notice only said time was uncertain, not that time since the app last ran was excluded. Updated the shared copy to say that interval has not been counted; targeted UI tests and full verification rerun.

## Verification

**Commands:**
- `flutter test --no-pub test/sadar_timer_state_machine_test.dart test/sadar_timer_view_session_test.dart test/focus_session_shared_timer_test.dart test/home_intent_cue_test.dart` -- expected: recovery regressions and existing timer/Home behavior pass.
- `flutter analyze --no-pub` -- expected: no issues.
- `git diff --check` -- expected: clean.

**Completed:** focused timer/Home/QuickTimerHub suite: 54 passed; full Flutter suite: 318 passed; analyzer: no issues; diff check: clean. APK arm64 and web JavaScript compiled; APK signature/metadata and web ZIP integrity passed. Physical Android reboot QA and browser interaction remain open.

**Manual checks:**
- Inspect Home and timer surfaces at narrow width to confirm the notice does not hide the saved duration or existing controls. No physical device was available during planning; Android reboot QA remains open.
