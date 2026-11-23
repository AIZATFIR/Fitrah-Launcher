---
title: 'Make the goal companion concise across providers'
type: 'feature'
ticket: ''
created: '2026-11-23'
status: 'built'
baseline_revision: '3e4ead2da5fc684a75f2fd98580a1de193da7f34'
route: 'oneshot'
route_source: 'auto'
risk: 'low'
review: 'quick'
review_source: 'pinned'
lenses_ran: [quick]
review_loop_iteration: 0
context:
  - 'lib/services/ai_service.dart'
  - '_bmad-output/initiative-focus-clock-ecosystem/plan-ai-goal-planning.md'
---

<frozen-after-approval reason="Owner authorized continued Focus Clock ecosystem development">

## Intent

**Problem:** The goal companion has no consistent response-length or language guidance across normal and no-tool provider paths, which can produce generic or overlong replies.

**Approach:** Give both paths the same concise, user-led response rules so the companion reflects the specific goal, offers one practical next step, and asks only a necessary question.

</frozen-after-approval>

## Code Map

- `lib/services/ai_service.dart::_buildAuraSystemPrompt` defines the shared behavior for configured providers.
- `lib/services/ai_service.dart::_structuredFallbackMessages` separately instructs providers that reject tool calling; both paths must share the same concise, user-led style.

## Implementation Notes

Updated `lib/services/ai_service.dart` so the shared and no-tool fallback prompts match language, style, empathy, concise steps, and the one-necessary-question rule. Android v0.5.50+8142 release APK and all three JavaScript web targets build; all web bundles pass asset verification and deploy READY. Live production endpoints report 0.5.50 / 8142. Quick review found no issues. Tests were not run at the owner's request to prioritize builds and avoid repeated test cycles. The Android Debug signing identity and no-physical-phone limitation remain unchanged.
