# AI No-Tool Plan Fallback Implementation Plan

> **For agentic workers:** Implement inline, one task at a time, preserving approval before writes.

**Goal:** Let configured OpenAI-compatible models that reject function/tool-calling still return ordinary supportive chat or a typed, editable goal-plan draft.

**Architecture:** Keep the existing tool path first. Retry once without tool fields only for a clear unsupported-tools 400/422 response. Add an ephemeral system instruction requesting a JSON envelope (`reply`, nullable `goal_plan`) and parse it through the existing validated `PlanProposal` domain model. Proposal creation remains inert until the existing approval card calls the transactional application service.

**Tech Stack:** Flutter/Dart, existing `http.Client`, OpenAI-compatible Chat Completions, `PlanProposal`, `AiGoalPlanProposal`, Flutter tests.

## Global Constraints

- No conversation is sent without the existing explicit user Send action.
- Never retry provider auth, quota, timeout, or unrelated errors as a capability fallback.
- No automatic schedule/goal/habit writes; require existing review and explicit approval.
- Keep the regular tool-calling path and custom server read-only path unchanged.
- Add no dependency and preserve provider/model attribution in plan drafts.

---

### Task 1: Prove unsupported-tool retry and inert plan parsing

**Files:**
- Modify: `test/ai_action_proposal_test.dart`
- Read: `lib/domain/goal_plan_proposal.dart`

**Interfaces:**
- Use existing `AiService.send(... allowActions: true)`, `pendingGoalPlan`, and `GoalPlanApplicationService` injection as-is.

- [ ] Add one test where the configured provider returns 400 with an explicit unsupported-tools error, then returns `{reply, goal_plan}` content on the retry. Assert second request omits `tools`/`tool_choice`, the reply is normal chat, the draft is validated and attributed to configured provider/model, and repositories remain unchanged before approval.
- [ ] Add one test where a provider rejects tools with 400 but returns ordinary `{reply, goal_plan: null}`. Assert user receives the reply and no draft or write appears.
- [ ] Run those tests and confirm they fail because no capability retry/parser exists.

### Task 2: Add narrow compatibility retry and envelope parser

**Files:**
- Modify: `lib/services/ai_service.dart`
- Modify: `test/ai_action_proposal_test.dart`

**Interfaces:**
- Extend `_callOpenAiFormatApi` with an optional `includeTools` flag defaulting to true.
- Keep the retry request local to the current `send`; do not persist the injected fallback instruction in `_history`.
- Reuse `PlanProposal.fromJson` and `AiGoalPlanProposal`; generate one operation ID per accepted draft and reuse existing durable applier closure.

- [ ] Detect explicit unsupported tool/function schema errors only for HTTP 400 or 422.
- [ ] Retry once without `tools`/`tool_choice`, adding the strict envelope instruction only to that request's copied messages.
- [ ] Decode a valid envelope; show its `reply`; create an inert plan draft only when `goal_plan` is non-null and passes `PlanProposal.fromJson`.
- [ ] Treat malformed envelopes as ordinary assistant text with a clear recoverable response and no write.
- [ ] Rerun AI proposal tests and the focused chat approval tests; run analyzer for changed files.

### Task 3: Record provider capability behavior

**Files:**
- Modify: `_bmad-output/initiative-focus-clock-ecosystem/plan-ai-goal-planning.md`
- Modify: `docs/ecosystem/2026-11-03/BUILD-ROADMAP.md`

- [ ] Mark unsupported-tool fallback only after tests pass; preserve the remaining real-provider/manual-device gates.
- [ ] Run `git diff --check`.
