---
title: 'FocusSessionView memakai timer bersama'
type: 'feature'
ticket: ''
created: '2026-11-04'
status: 'built'
baseline_revision: '9b9f672923986046c587badc4f341d2086931b8e'
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

**Problem:** The scheduled Activity fullscreen FocusSessionView has a local ticker and marks an Activity complete through ActivityRepository, separate from the shared persisted timer owner. This allows overlapping sessions and drops actual focus duration.

**Approach:** Preserve the existing screen and route start, pause, resume, early finish, completion and retry through `SadarTimerEngine` using the exact Activity ID.

## Boundaries & Constraints

**Always:** Keep the approved Focus Clock face/palette and reflection screen. Start one timer for the exact Activity, or show an active-session conflict. Persist pause/resume/finish before reporting success. Keep the Activity completion receipt tied to actual elapsed seconds.

**Never:** Change YPT app guarding, habit behavior, Home styling, notification scheduling, or add a session ledger. Do not silently complete an Activity from a local button state.

## Implementation and Verification

- [x] Add a widget regression that proves the view starts an Activity-linked shared session and durably pauses it; observed expected RED before implementation.
- [x] Replace the local countdown and completion write with shared engine state/actions; retain the existing visuals and reflection UI.
- [x] `flutter test --no-pub test/focus_session_shared_timer_test.dart test/quick_timer_hub_shared_session_test.dart test/focus_clock_home_persisted_data_test.dart test/sadar_timer_state_machine_test.dart test/isar_service_persistence_test.dart` -- 35 tests pass.
- [x] `flutter analyze --no-pub` -- clean.
- [x] `flutter build apk --debug --no-pub --split-per-abi` -- all three Android debug ABIs build; arm64 SHA-256 `db0abf74bc398419a20aeeb81422d467033bbb51ba51f1f103648e3560aacddd`.
- [x] `git diff --check` -- clean.

**Full suite:** `flutter test --no-pub` -- 102 tests pass. The legacy sample-Home timer test now asserts that a failed durable completion keeps the timer screen available for retry instead of assuming that empty test storage committed the Activity.

**Manual gate:** No Android device is attached. Process-death/reboot behavior is not claimed as verified.
