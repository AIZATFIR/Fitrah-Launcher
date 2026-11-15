---
title: 'AI goal conversation continuity and Bookpaper UI'
type: 'feature'
ticket: ''
created: '2026-11-15'
status: 'built'
baseline_revision: '3bee6bf'
route: 'full'
route_source: 'auto'
risk: 'medium'
review: 'quick'
review_source: 'pinned'
lenses_ran: [quick]
review_loop_iteration: 0
context:
  - 'Fitrah-Launcher/docs/ecosystem/2026-11-03/PRD.md'
  - 'Fitrah-Launcher/docs/ecosystem/2026-11-03/ARCHITECTURE.md'
  - 'Fitrah-Launcher/docs/ecosystem/2026-11-03/DESIGN.md'
  - 'Fitrah-Launcher/docs/ecosystem/2026-11-03/BUILD-ROADMAP.md'
---

<frozen-after-approval reason="Owner approved ongoing Focus Clock ecosystem build in this session">

## Intent

**Problem:** The Home and assistant UI drifted from the approved Focus Clock Bookpaper identity. The AI prompt forces a secretary persona and fixed productivity advice; the direct Gemini path also drops earlier turns, so a user's goal or vent does not carry into the next reply.

**Approach:** Keep the warm charcoal and amber Bookpaper system and Outfit typography, make the Home dial more visible, and make the assistant's first contact goal-first without decorative emoji or sparkle. Give Gemini the actual prior conversation and set flexible guidance for listening to a vent, understanding intent, and helping choose a user-owned next step.

## Boundaries & Constraints

**Always:** Conversation history may guide replies but does not authorize schedule writes. Keep approval-first proposals, existing goals and schedule data intact, and let the user choose whether to plan or act. Preserve responsive layout and the existing Bookpaper palette and clock face.

**Never:** Do not promise competition outcomes, force a rigid work/rest formula, apply any schedule change from this slice, or claim this completes the model-independent `GoalUnderstanding` / `PlanProposal` architecture.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| First Gemini turn | User describes a goal or shares a concern | Request contains current turn once plus system guidance; assistant responds in context | Provider error follows existing fallback and does not write schedule data |
| Follow-up Gemini turn | Prior user message and assistant reply exist | Request includes prior turns in order and current user turn once | Malformed or empty reply uses existing fallback; history remains recoverable |
| Schedule request | User asks to change or plan schedule | Existing explicit proposal/apply flow remains the only write route | No proposal or approval means no schedule mutation |

</frozen-after-approval>

## Code Map

- `lib/services/ai_service.dart` -- `_history`, `_buildAuraSystemPrompt`, `_ensureInit`, `send`, and `_sendGeminiDirect`; keep provider action handlers and proposal approval gate unchanged.
- `lib/features/ai_chat/ai_chat_sheet.dart` -- assistant header and empty state; retain existing Bookpaper theme and functionality while removing secretary/emoji decoration.
- `lib/features/launcher/widgets/focus_clock_home_view.dart` -- compact Home clock dial; enlarge responsively without changing its selected clock-face theme.
- `test/ai_action_proposal_test.dart` -- mock HTTP client, repositories, and secure-storage test doubles; extend to assert Gemini request history and schedule safety.

## Tasks & Acceptance

**Execution:**
- [x] `lib/features/ai_chat/ai_chat_sheet.dart` and `lib/features/launcher/widgets/focus_clock_home_view.dart` -- align the goal-first UI with Bookpaper, remove decorative emoji/sparkle treatment, and give the dial responsive prominence.
- [x] `lib/services/ai_service.dart` -- replace rigid persona advice with user-led goal support and pass prior user/model turns through Gemini's chat API.
- [x] `test/ai_action_proposal_test.dart` -- verify first-turn and follow-up request contents, system guidance, fallback, and no unapproved writes.

**Acceptance Criteria:**
- Given a user shares a long-term goal or vents, when the assistant replies, then its guidance listens first, asks only useful clarifying questions, and helps identify a realistic next step without prescribing a fixed routine.
- Given a follow-up message on Gemini BYOK, when the request is sent, then prior user and assistant turns appear in order and the current message appears once.
- Given a request that would change a schedule, when the user has not approved a proposal, then no schedule mutation occurs.
- Given the Home is rendered on a narrow or wide viewport, when the compact dial appears, then it remains legible, fits its layout, and retains the active Bookpaper/clock-face choices.
- Given the AI chat opens without messages, when the empty state appears, then it invites a goal or concern in plain language and uses the Focus Clock palette without emoji or sparkle decoration.

## Implementation Notes

- This plan includes the currently uncommitted UI corrections from the prior goal turn; preserve them. The full E6a provider-neutral proposal/apply architecture remains a later roadmap gate.

## Verification

**Commands:**
- `flutter test test/ai_action_proposal_test.dart` -- targeted behavior tests pass.
- `flutter analyze lib/services/ai_service.dart lib/features/ai_chat/ai_chat_sheet.dart lib/features/launcher/widgets/focus_clock_home_view.dart test/ai_action_proposal_test.dart` -- no issues.
- `flutter build web --release --no-wasm-dry-run --no-pub --build-name=0.5.5 --build-number=2055 --output=/tmp/focus-clock-ui-review-2055` -- preview build succeeds.

**Manual checks:**
- Inspect the local Home preview beside the already running Focus Clock web reference; confirm the larger dial and warm Bookpaper look.
- Inspect AI chat empty state for clear goal-first wording and consistent non-emoji Material icons.

## Review Triage Log

- **medium — accepted and fixed:** Switching to Gemini after an OpenRouter tool interaction could pass tool rows or null assistant content into Gemini's text history and trigger fallback. `_sendGeminiDirect` now forwards only non-empty user/assistant text turns in order, maps assistant to Gemini's `model` role, and excludes tool records. Regression case `Gemini history skips tool records and empty assistant content` passed; the full focused file passed 8/8 afterward.
