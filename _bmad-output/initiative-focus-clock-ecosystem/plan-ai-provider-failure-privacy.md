---
title: 'Keep AI conversation private when the chosen provider fails'
type: bugfix
ticket: ''
created: '2026-11-20'
status: in-progress
baseline_revision: 'd3c5ca5c4c700b877efca82c7e6c8e5036800071'
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
  - '_bmad-output/initiative-focus-clock-ecosystem/plan-secure-ai-provider-settings.md'
  - '_bmad-output/initiative-focus-clock-ecosystem/plan-ai-goal-planning.md'
---

<frozen-after-approval reason="Owner approved autonomous Focus Clock ecosystem development through completion">

## Intent

**Problem:** When a user explicitly configures an AI provider, a request failure can fall through to the app's server-backend path. This can send private conversation and goal context to a different endpoint without making the provider change visible.

**Approach:** Keep a request on the provider the user selected. On provider failure, retain the conversation and return a safe, actionable message to retry or open provider settings; manual planning stays available.

## Boundaries & Constraints

**Always:** Never send a failed request's conversation to another endpoint implicitly. Keep API keys out of errors and logs. Preserve the user's chat turn/history, explicit proposal approval, provider/model attribution, and manual scheduling. A retry must be an explicit user action.

**Never:** Change the saved provider, clear the user's draft, expose raw provider response bodies, disable the manual goal/schedule flow, or add another backend/provider abstraction.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Configured provider unavailable | Provider times out or returns non-success | No request is sent to the fallback backend; the user sees a clear failure and can retry/configure | Keep the original user turn and existing schedule untouched |
| Malformed provider response | Configured endpoint returns invalid JSON/shape | No other endpoint receives the conversation | Show a safe provider-response message without body/key |
| Explicit unauthenticated local provider | User configures an endpoint without a key | Existing direct request behavior stays; failure stays on that endpoint | Keep the current actionable local-provider message |
| No provider configured | No secure key and demo endpoint unset | Existing first-run setup guidance remains | Manual goal and scheduling paths stay usable |

## Code Map

- `lib/services/ai_service.dart` -- `send` chooses the configured endpoint, catches failures, and currently calls `_sendServerFallback`; return a safe failure from this catch instead. Keep `_sendServerFallback` only for the existing no-config path.
- `lib/features/ai_chat/ai_chat_sheet.dart` -- `_send` appends the user turn before awaiting AI; preserve it and render the safe returned status without clearing the visible transcript.
- `test/ai_action_proposal_test.dart` -- existing custom/no-key failure case covers only `allowUnauthenticatedProvider`; add a configured-key failure regression that observes every outbound URI and proves no backend request.
- `test/ai_chat_approval_widget_test.dart` -- retain empty-state setup path and approval gate; extend only if the safe failure/action UI requires a visible control change.
- `_bmad-output/initiative-focus-clock-ecosystem/plan-secure-ai-provider-settings.md` -- existing provider contract expects the selected provider/model and visible errors; do not rewrite its frozen intent.

## Tasks & Acceptance

**Execution:**
- [ ] Add a failing regression for configured provider 5xx/timeout proving chat is not sent to the backend or demo endpoint.
- [ ] Change the configured-provider failure path to retain chat locally and return an actionable safe message; leave the keyless manual path intact.
- [ ] Verify affected provider/chat/approval tests, scoped analyzer, and diff; update the ecosystem roadmap with the privacy boundary.

**Acceptance Criteria:**
- Given the user sends a private message to a configured provider, when that provider fails, then no request containing the message or pinned goal reaches any other endpoint.
- Given a provider failure, when the user sees the result, then the chat remains readable, the error contains no key/raw body, and retry or provider settings are available.
- Given no key is configured, when the user opens the assistant, then existing setup guidance appears and manual goal/schedule use still works.

## Implementation Notes

- Configured-provider failures now return a safe retry/settings message and never call the app backend. No-key setup/manual planning path remains unchanged.
- Regression checks the exact outbound URI list and confirms chat + pinned goal stay on the selected provider; error body and credential are omitted from the user-visible result.
- Roadmap records the privacy boundary and states live provider/device failure remains unverified.
- Review: quick lens reported no findings.

## Plan Change Log

## Review Triage Log

- No findings — quick inspection review returned none.

## Verification

**Commands:**
- `flutter test --no-pub test/ai_action_proposal_test.dart test/ai_chat_approval_widget_test.dart --reporter compact` -- 21 tests passed.
- `flutter analyze --no-pub lib/services/ai_service.dart lib/features/ai_chat/ai_chat_sheet.dart test/ai_action_proposal_test.dart test/ai_chat_approval_widget_test.dart` -- no issues.
- `git diff --check` -- clean.
- `flutter build apk --release --no-pub` and `flutter build web --release --no-pub` -- succeeded; APK metadata/signature and package SHA-256 checks verified.
