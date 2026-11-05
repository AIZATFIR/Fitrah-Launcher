---
title: 'YPT fokus memakai timer bersama'
type: 'feature'
ticket: ''
created: '2026-11-05'
status: 'built'
baseline_revision: 'c450fc4'
route: 'full'
route_source: 'pinned'
risk: 'high'
review: 'none'
review_source: 'none'
lenses_ran: []
review_loop_iteration: 0
context:
  - docs/ecosystem/2026-11-03/BUILD-ROADMAP.md
  - docs/ecosystem/2026-11-03/ARCHITECTURE.md
---

## Intent

**Problem:** `SadarYptFocusView` owned a local countdown and wrote HabitEntry outside the shared timer owner, so YPT could overlap another timer and lose recovery state.

**Approach:** Route YPT start, pause, resume, overtime, finish and retry through `SadarTimerEngine`. Preserve YPT's allowed-app foreground guard, immersive screen, target notification and emergency hold exit.

## Boundaries & Constraints

**Always:** Persist YPT's session source before claiming start; restore a session past target as running overtime; continue counting actual duration until the user finishes; record through the existing atomic habit completion transaction; retain failed completion for retry. Append the new source enum value so stored indexes keep their meaning.

**Never:** Auto-complete YPT at target; bypass the shared active-session guard; remove the allowed-app guard or emergency exit; create a separate YPT history ledger in this slice.

## Implementation and Verification

- [x] Add a widget test proving YPT starts and pauses via the shared owner; observed expected RED before implementation.
- [x] Add a restore test proving overdue YPT stays active; observed expected RED when the overtime restore path was removed.
- [x] Add a write-failure/retry widget test proving the same saved session survives and the view closes only after commit.
- [x] `flutter test --no-pub` -- 105 tests pass.
- [x] `flutter analyze --no-pub` -- no issues.
- [x] `flutter build apk --debug --no-pub --split-per-abi` -- armeabi-v7a, arm64-v8a and x86_64 APKs build. Arm64 SHA-256: `4188b0901862f44b766612e02f8aed1fe2da49429d8dc3a9f6cc5c6a11e665a4`.
- [x] `git diff --check` -- no whitespace errors.

**Manual gate:** No Android device is attached. YPT app switching, lock-screen/immersive behavior and emergency exit require device verification. Timer clock/reboot/recovery and notification reconciliation gates remain open under E2.
