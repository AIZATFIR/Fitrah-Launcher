---
title: 'Percakapan tujuan menjadi rencana harian yang bisa disetujui'
type: feature
ticket: ''
created: '2026-11-16'
status: 'built'
baseline_revision: '99ba894d2595a18179b17cc576cc18460db7bae6'
route: 'full'
route_source: 'pinned'
risk: 'high'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 0
context:
  - 'docs/ecosystem/2026-11-03/PRD.md'
  - 'docs/ecosystem/2026-11-03/ARCHITECTURE.md'
  - 'docs/ecosystem/2026-11-03/BUILD-ROADMAP.md'
  - '_bmad-output/initiative-focus-clock-ecosystem/plan-secure-ai-provider-settings.md'
---

<frozen-after-approval reason="Owner authorized continued Focus Clock ecosystem development">

## Intent

**Problem:** Users can talk to the assistant about a goal, but the app cannot turn that conversation into a correctable, editable schedule plan that feeds the real Home, habit, and session loop. Existing bulk schedule tools are blocked and single-action proposals lack goal context and atomic application.

**Approach:** Add provider-neutral `GoalUnderstanding` and `PlanProposal` domain contracts, return a structured review card from compatible configured providers, and let the user edit assumptions and weekly practice blocks before one durable, idempotent application writes the goal, linked practice habit, and conflict-free schedule batch.

## Boundaries & Constraints

**Always:** Keep conversation advisory until explicit approval. Preserve all existing activities, habits, tasks, completions, and sessions. Surface assumptions and schedule conflicts; never move or delete existing commitments automatically. Use one durable `FocusStore.writeTxn` for goal, habit, links, and activities. Keep manual scheduling and offline use available. Provider/model selection remains user-controlled and prompt content stays out of logs.

**Never:** Promise competition results, infer completion, force a work/rest ratio, use a provider tool schema as the domain contract, or apply a proposal from chat text alone. Do not claim opaque custom-backend replies can produce structured plans.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Vent and clarify | User shares a goal and constraints | Assistant listens, returns corrected goal understanding, and asks only for missing facts that change the plan | Keep conversation and let user continue or switch to manual planning |
| Review plan | Provider returns goal, assumptions, and weekly blocks | Editable preview shows times, recurrence, and conflicts; existing schedule stays untouched | Invalid fields remain editable with a direct explanation |
| Approve plan | User approves a valid edited proposal | One idempotent transaction creates/updates the goal, timed habit, source link, and schedule batch | Conflict, stale revision, or storage failure writes nothing and retains the draft |
| Cancel or provider failure | User declines, times out, or provider returns malformed data | No durable changes; manual Goal/Home path remains available | Explain recovery without losing conversation draft |

</frozen-after-approval>

## Code Map

- `lib/services/ai_service.dart` -- provider routing, tool decoding, history, and pending approval objects; add adapter decoding while preserving the existing single-action gate.
- `lib/services/ai_action_proposal.dart` -- inert approval state; extend or pair with typed goal-plan proposal state without letting UI callbacks mutate repositories directly.
- `lib/domain/focus_intent.dart` and `lib/data/repositories/intent_repository.dart` -- versioned goal/source/link singleton and optimistic revisions; preserve its existing validation and identity rules.
- `lib/data/store/focus_store.dart`, `native_focus_store.dart`, `browser_focus_store.dart` -- shared transaction contract; collection writes belong inside caller-owned transaction.
- `lib/services/home_schedule_service.dart` -- durable-only schedule validation, recurrence-aware conflict detection, and cross-midnight segmentation; reuse these rules in a batch path, avoiding nested transactions.
- `lib/features/ai_chat/ai_chat_sheet.dart` -- empty-state and proposal-card UI; add editable typed preview with explicit apply/cancel.
- `lib/models/{activity,habit,focus_intent_document}.dart` and `lib/data/store/live_model_codec.dart` -- records and browser encoding; reuse existing fields, including `Activity.habitId`.
- `lib/providers/providers.dart` -- service construction and store injection for the planning/apply use case.
- `test/ai_action_proposal_test.dart`, `test/home_schedule_service_test.dart`, `test/intent_repository_test.dart` -- provider output, no-write-before-approval, atomic conflict/failure and idempotency coverage.

## Tasks & Acceptance

**Execution:**
- [x] Add validated, provider-neutral goal understanding and weekly plan models with limits for dates, block duration/count, recurrence, and required assumptions.
- [x] Decode a structured proposal from configured compatible provider responses; keep plain chat, history order, BYOK endpoint/model, and single-action proposals working.
- [x] Add a durable batch application use case that validates goal revision, timed habit inputs, recurring conflicts, and intra-proposal overlaps before one transaction writes goal, habit, source/link, and split activities. Return the same result for an identical operation ID; reject reuse with different input.
- [x] Add an editable Bookpaper review card for goal, assumptions, weekly time blocks and conflicts. Only the explicit apply action invokes the use case; cancel and provider/storage errors preserve the draft.
- [x] Cover model validation, conflict/rollback/idempotency, provider malformed output/history, and UI approval/cancel. Build Android and web entry points without changing release identity.

**Acceptance Criteria:**
- Given a user shares an ambitious goal with school or work constraints, when planning begins, then the assistant reflects the goal accurately and asks only for information required to make a useful schedule.
- Given a structured plan conflicts with an existing commitment, when the preview opens, then it names the conflict and leaves the existing schedule unchanged until the user edits or cancels.
- Given a user edits and approves a valid plan, when storage commits, then the goal and its linked timed practice schedule appear in Home and can start a correctly attributed session.
- Given storage fails, a proposal is malformed, or the user cancels, when the operation ends, then no partial goal/habit/activity records exist and the manual flow remains usable.
- Given the same approval is retried, when its operation ID and payload match, then records are not duplicated; changed payload with the same ID is rejected.

## Implementation Notes

- Focused suite: 34 tests passed across goal-plan application, AI provider proposals, schedule service, and intent repository.
- Focused analyzer: no issues across the 10 changed feature files.
- Android release APK and web release build both completed. App identity remains `0.5.3+7`.
- Manual install/session persistence check deferred: `adb devices -l` reported no connected Android device.


## Plan Change Log


## Review Triage Log


## Verification

**Commands:**
- `flutter test --no-pub test/ai_action_proposal_test.dart test/home_schedule_service_test.dart test/intent_repository_test.dart` -- typed preview, approval gate, transaction rollback, conflict and retry cases pass.
- `flutter analyze` on changed files -- no errors; all new lints fixed.
- `flutter build apk --release` and `flutter build web --release --no-wasm-dry-run` -- correct Fitrah entry point compiles for both targets.
- `git diff --check` -- clean.

**Manual checks:**
- From the Android Home, tell the assistant “I want to win national LKS IT Software Solution; school takes most mornings.” Correct the summary, edit one practice time, review a surfaced conflict, approve, and start the Home practice timer. Confirm linked goal and session history survive force-stop/reopen. Repeat with cancel and malformed/provider-offline cases; no schedule write should occur.

### Quick review findings (2026-11-16)

- **patch — medium** (`lib/services/goal_plan_application_service.dart:296`): excluded occurrences still conflict because `sameDate` bypasses the exclusion. `HomeScheduleService` applies exclusions before checking both same-date and recurring activity conflicts. Fix: honor the excluded date for both checks and add a regression test.
- **patch — medium** (`lib/services/goal_plan_application_service.dart:269`): the proposal checks only its first upcoming occurrence against one-time future commitments. Since the approved block repeats weekly, a one-time event on the same future weekday can be silently overlapped. Fix: check future same-weekday commitments against the recurring proposal and add a regression test.
- **patch — medium** (`lib/services/ai_service.dart:522`): Gemini-compatible `requestHistory` is copied once before the agent loop and filters out tool-call assistant messages/tool results. Later loop requests therefore cannot observe tool outputs. Fix: prepare the compatible history from current `_history` on each loop iteration, retaining valid tool-call/result pairs; cover a tool-result-dependent follow-up.
- **patch — medium** (`test/goal_plan_application_test.dart:1`): current changes cover malformed provider output and text history in `test/ai_action_proposal_test.dart`, but do not exercise the goal-plan review card's explicit apply/cancel controls. Fix: add focused review-card approval and cancellation coverage; provider/history coverage already exists.
