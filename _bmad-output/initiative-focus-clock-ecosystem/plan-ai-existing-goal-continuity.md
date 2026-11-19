---
title: 'AI melanjutkan goal tersimpan tanpa membuat duplikat'
type: feature
ticket: ''
created: '2026-11-19'
status: 'built'
baseline_revision: 'working-tree'
route: 'full'
route_source: 'owner-authorized-ecosystem-build'
risk: 'high'
review: 'quick'
review_source: 'owner-authorized-ecosystem-build'
lenses_ran: ['systematic-debugging', 'ponytail']
review_loop_iteration: 0
context:
  - 'docs/ecosystem/2026-11-03/BUILD-ROADMAP.md'
  - '_bmad-output/initiative-focus-clock-ecosystem/plan-ai-goal-planning.md'
---

## Intent

When a user opens AI from an existing pinned goal, the proposal must retain that goal's stable ID and revision through either supported provider decoder. Approval updates that goal and its AI-owned practice schedule once. It must not silently create a second goal, habit, or schedule. Stale drafts fail without writes. Existing completed work and focus-session evidence remain intact.

## Boundaries

- Preserve the existing approval card and manual/offline flows.
- Scope updates to the source plan receipt for the targeted goal; never modify unrelated activities.
- Keep completed activity evidence and any activity referenced by terminal focus history.
- On apply, atomically update goal metadata, reuse its linked practice habit/source, replace only uncompleted AI-plan schedule rows, and append an idempotency receipt.
- If an update cannot be safely reconciled, fail with no writes and leave the editable proposal available.

## Acceptance

- Home → AI carries pinned goal ID, revision, and title.
- Tool-call and JSON-envelope proposals both apply against the captured goal revision.
- A successful replan keeps one goal, one linked practice habit/source, and one active AI-owned schedule; unrelated activities remain unchanged.
- Replanning preserves completed/session evidence; an identical retry creates nothing; stale revision/conflict writes nothing.
- Focused tests cover both provider decoders, application, and approval UI behavior. Build and runtime claims are recorded only when executed.

## Execution

- [x] Add goal identity to Home → chat → AiService proposal callbacks.
- [x] Make GoalPlanApplicationService update the prior AI plan safely and atomically.
- [x] Add regression coverage for update, evidence preservation, stale draft, idempotency, and provider paths.
- [x] Run focused tests/analyzer and record evidence in the ecosystem roadmap.

## Verification

- `flutter test test/goal_plan_application_test.dart test/ai_action_proposal_test.dart --no-pub` — passed (26 tests); includes replan evidence preservation and target identity through tool-call and JSON-envelope adapters.
- `flutter test test/ai_chat_approval_widget_test.dart --no-pub` — passed (3 tests).
- Scoped `flutter analyze --no-pub` — no issues in 8 touched Dart/test files.
- `flutter build apk --release --no-pub` — succeeded as 0.5.17+8093. APK v2 signature and package metadata verified; certificate matches v8092.
- API36 x86_64 AVD install and Home → goal → focus timer smoke passed; notification permission remained denied and no prompt appeared. Live provider calls and physical-device use remain unverified.
