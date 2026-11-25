---
title: 'Retry a failed assistant turn without losing conversation context'
type: 'feature'
ticket: ''
created: '2026-11-20'
status: 'built'
baseline_revision: '96fd51e32d87a8ff898c4885d35863e379149eca'
route: 'full'
route_source: 'pinned'
risk: 'medium'
review: 'quick'
review_source: 'pinned'
lenses_ran: [quick]
review_loop_iteration: 0
context:
  - 'docs/ecosystem/2026-11-03/PRD.md'
  - 'docs/ecosystem/2026-11-03/ARCHITECTURE.md'
  - '_bmad-output/initiative-focus-clock-ecosystem/plan-ai-provider-failure-privacy.md'
  - '_bmad-output/initiative-focus-clock-ecosystem/plan-ai-goal-planning.md'
---

<frozen-after-approval reason="Owner authorized continued Focus Clock ecosystem development">

## Intent

**Problem:** When the selected AI provider fails, the user sees the error as an assistant reply while `AiService` retains the unanswered user turn. A later message then sends misleading, orphaned context; there is also no explicit way to retry the original turn.

**Approach:** Keep the configured-provider privacy boundary and add a user-triggered retry for the exact failed turn. Keep it out of committed model history until a reply arrives, and present the failure as delivery status rather than model speech.

## Boundaries & Constraints

**Always:** Retry only after an explicit tap, against the same configured endpoint/model and without automatic cross-provider fallback. Preserve all preceding successful turns and the user's exact failed text. The same failed turn may appear at most once in a successful provider context. New user input supersedes an older retry affordance rather than making the failed turn an orphan in provider history. Provider errors remain safe and must not expose response bodies or credentials. Existing proposal approval and durable schedule mutation rules remain unchanged.

**Never:** Add automatic retries for server errors, send failed chat to another endpoint, persist transcript/history in this slice, add a dependency/schema, or change provider selection and no-key fallback semantics.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Selected provider fails | A user turn receives a timeout or non-success response | UI marks the turn undelivered and offers Retry; failed turn is not committed as model history | Keep safe provider-specific message; no cross-endpoint request |
| Retry succeeds | User explicitly retries the latest undelivered turn | Same selected endpoint receives the exact text once with preceding successful context; one assistant reply is committed | Clear retry state and render the model reply/proposal normally |
| Retry fails again | Retry receives another provider error | Same safe undelivered state and retry action remain | No automatic loop and no duplicate history turn |
| User sends a different message | A retry affordance is still visible | Old retry is superseded and omitted from the next model context; new message uses only committed prior turns | Keep old UI message labeled undelivered, with retry disabled |

</frozen-after-approval>

## Code Map

- `lib/services/ai_service.dart` -- `send`, `_history`, configured-provider catch, `_sendServerFallback`, `_callOpenRouterDirect`, and `reset`. Reuse the configured-provider branch and history filtering. Add one pending retry record with the original user text/context; restore pre-turn history after failure. Keep existing string-returning `send` API for voice, weekly review and storytelling callers. Retry must bypass provider re-selection and fallback.
- `lib/features/ai_chat/ai_chat_sheet.dart` -- `_send`, `_replaceLast`, `ChatMessage`, and `_Bubble`. Reuse the existing Bookpaper message row; render retry status/action and replace that status on retry. Supersede older retry affordances before a new user send.
- `test/ai_action_proposal_test.dart` -- existing configured-provider privacy and 5xx tests; add fail→explicit-retry→follow-up request-body assertions using the existing HTTP client fixture.
- `test/ai_chat_approval_widget_test.dart` -- existing panel harness and service override; add failure status→Retry→success and retry supersession coverage.

## Tasks & Acceptance

**Execution:**
- [x] `lib/services/ai_service.dart` -- make each failed request history-neutral, retain only the latest retryable request metadata, and implement explicit same-provider retry without changing callers that expect `String`.
- [x] `lib/features/ai_chat/ai_chat_sheet.dart` -- show delivery failure with a clear Retry control; distinguish error status from assistant/model content and prevent stale retry actions after new input.
- [x] `test/ai_action_proposal_test.dart` and `test/ai_chat_approval_widget_test.dart` -- prove exact endpoint, exact-once user text, preserved successful context, repeated failure, and user-visible retry behavior.

**Acceptance Criteria:**
- Given the selected provider returns a timeout or non-success response, when the reply arrives, then the user sees that their message was not answered and can retry it without the app sending it elsewhere.
- Given the user taps Retry, when the provider succeeds, then the request includes the original text once after prior successful turns and the UI replaces the delivery status with the assistant reply.
- Given the user sends a different message instead, when that request is formed, then it contains no orphaned failed turn and the old Retry action cannot send messages out of order.
- Given the provider continues returning 5xx, when a request or explicit retry occurs, then there is no automatic retry loop, duplicate history entry, or leaked credential/body.

## Implementation Notes


## Plan Change Log


## Review Triage Log

- patch — Medium: retry success could expose literal `\\n\\n` text in guarded schedule replies; changed this to actual blank lines and added an assertion.
- patch — Medium: configured-provider requests could wait indefinitely and never reach retry handling; added an 8-second request timeout, which follows the same safe failure path.


## Verification

**Commands:**
- `flutter test --no-pub test/ai_action_proposal_test.dart test/ai_chat_approval_widget_test.dart` -- provider request bodies and chat Retry flow pass.
- `flutter analyze --no-pub lib/services/ai_service.dart lib/features/ai_chat/ai_chat_sheet.dart test/ai_action_proposal_test.dart test/ai_chat_approval_widget_test.dart` -- no new diagnostics.
- `flutter test --no-pub --reporter compact` -- all 448 tests pass.
- `git diff --check` -- clean.
