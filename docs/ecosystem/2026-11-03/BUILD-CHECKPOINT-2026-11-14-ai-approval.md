# AI approval gate checkpoint — 14 November 2026

## Change

OpenAI-compatible tool calls that create, update, delete, prioritize, or generate schedule entries now remain inert proposals after the model response. The Focus Clock chat shows a short action summary with **Terapkan** and **Batal**. Read-only activity lookup may still run directly. Failed applications remain retryable; dismissed proposals cannot later be applied. Resetting a conversation dismisses its pending proposals so their action closures cannot be applied after the transcript is cleared.

The model response text is replaced with app-controlled copy when a proposal is pending, so a model cannot claim that an unapplied change is already done. Bulk blueprint and adaptive-goal tools are withheld from the provider and rejected if an unadvertised call still arrives. The assistant can still discuss a plan or propose individual time blocks.

The custom secretary backend and Gemini text-only path do not create local schedule entries through these tool handlers. In action-enabled chat, text-only replies are checked for completed-action claims and replaced with app copy when they say a schedule was already applied. This checkpoint does not claim to control side effects in a separately operated custom server.

Approved updates now work on a detached copy of the stored activity until conflict validation succeeds. This prevents the in-memory repository's shared object reference from leaking a partial title/date edit when approval fails. Starting a new chat dismisses pending proposals as well as clearing the service list.

## Verification

- Focused approval tests: 6 passed, including proposal-without-write, explicit approval, dismissal, retry after failure, conflict rollback in the in-memory repository, reset cancellation, false-claim suppression for the text-only backend, and a 320dp chat widget flow that cancels then approves a block.
- Full serial Flutter suite after final changes: **336 passed** (`flutter test --concurrency=1`).
- Full `flutter analyze`: no issues.
- `git diff --check` on changed source/test files: clean.
- No APK/web artifact was built or released for this slice; no device runtime test was run.

## Known limits / next work

- This is an interim UI gate, not the domain `GoalUnderstanding` / `PlanProposal` contract in AD-17.
- The approval summary does not yet show a full schedule diff, assumptions, detected conflicts, or an editable plan. Multi-entry blueprint and adaptive-goal handlers can still make several sequential writes after one approval; they are not an atomic batch.
- Provider behavior is not uniform: Gemini and the custom secretary endpoint currently provide text only, while OpenAI-compatible tool calls generate these proposal cards.
- Adaptive-goal recurrence still maps 6 days/week to daily and 1–5 days/week to weekdays; the schedule logic must be corrected before describing it as reliable.
- Extend widget coverage to larger text scales, TalkBack order, and proposal reset while an action is in flight.
- The architecture's approval-first requirements and E6a gate remain open. No release claim follows from this checkpoint.

## Workspace

Pre-existing generated changes in `build/web/` and `_bmad/render/` were preserved and left out of this slice. The current implementation files are limited to the AI service/chat proposal flow and its tests.
