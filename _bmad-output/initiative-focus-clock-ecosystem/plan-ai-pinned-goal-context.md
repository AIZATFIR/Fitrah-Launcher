---
title: 'Use the pinned Home goal in AI replies'
type: 'feature'
ticket: ''
created: '2026-11-20'
status: 'built'
baseline_revision: 'd3c5ca5c4c700b877efca82c7e6c8e5036800071'
route: 'oneshot'
route_source: 'auto'
risk: 'medium'
review: 'quick'
review_source: 'quick-review'
lenses_ran: ['quick-code-review']
review_loop_iteration: 0
context:
  - 'docs/ecosystem/2026-11-03/BUILD-ROADMAP.md'
  - 'lib/services/ai_service.dart'
  - 'lib/features/ai_chat/ai_chat_sheet.dart'
---

<frozen-after-approval reason="Owner authorized continued goal-first Focus Clock development">

## Intent

**Problem:** Home opens the assistant with the pinned goal visible, but only the suggestion chip sends that goal to the model. A user who types a natural follow-up can get an answer that ignores the goal they came to discuss.

**Approach:** Pass the Home goal as optional, clearly labeled request context for provider calls while keeping the user's displayed message untouched. Do not auto-send; keep all schedule proposals behind the existing edit and approval flow.

</frozen-after-approval>

## Implementation Notes

Oneshot is appropriate: the root cause was a missing context handoff across the existing chat panel and AI service; no storage schema or new dependency was needed. `AiChatPanel` passes the selected goal through `AiService.send`; the service applies it to a copied provider request turn, leaving conversation history and visible transcript unchanged. The goal suggestion no longer repeats the title in its prompt. Review caught and prevented the prior goal from leaking into a later context-free turn. The owner has already approved continued goal-first AI work.

## Verification

**Commands:**
- `flutter test --no-pub test/ai_chat_approval_widget_test.dart` -- 3 tests pass; a typed free-form message from the pinned-goal Home chat includes the goal in the provider request while the visible transcript remains only the user's text.
- `flutter test --no-pub test/ai_action_proposal_test.dart` -- 17 provider/proposal/approval tests pass, including that goal context is scoped to its current request and absent from later context-free turns.
- `flutter analyze --no-pub lib/services/ai_service.dart lib/features/ai_chat/ai_chat_sheet.dart test/ai_chat_approval_widget_test.dart test/ai_action_proposal_test.dart` -- no new diagnostics.
- `git diff --check` -- clean.

**Build/package checks:**
- `flutter build apk --release --no-pub` -- universal release APK built.
- `flutter build web --release --no-pub --dart-define=APP_MODE=focus --build-name=0.5.22 --build-number=8101 --output=/tmp/focus-clock-web-v8101` -- standard JavaScript web bundle built; Wasm dry-run reports existing dependency incompatibilities.
- APK metadata, v2 signature and signer fingerprint verified; web and combined download ZIP integrity and SHA-256 checks pass.
- No Android device/AVD was attached, so install and owner-device runtime check remain open.

**Review:**
- Quick reviewer re-review found no actionable findings after the provider-history leakage fix.
