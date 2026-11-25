# Build checkpoint — provider-compatible goal planning v8076

**Date:** 17 November 2026
**Artifact:** [Android + web preview bundle](../../release_dist/2026-11-17-fitrah-launcher-provider-compatible-preview-v8076/INSTALL.md)
**Version:** 0.5.6+8076

## Delivered

Configured OpenAI-compatible BYOK endpoints can now still support the Focus Clock goal-planning flow when the selected model/API explicitly rejects function calling. On a qualifying HTTP 400 or 422, the app retries once without `tools` and `tool_choice`, with a request-local JSON envelope instruction. The provider can return supportive conversation and a clarifying question with `goal_plan: null`, or a validated goal-plan draft. The domain `PlanProposal` remains provider-neutral, retains provider/model attribution, and enters the existing editable review card. Nothing is persisted until explicit approval; the existing atomic/idempotent application service is unchanged. HTTP 500 and unrelated errors do not trigger the compatibility retry.

## Verification

- Red/green AI behavior tests prove supported-tool fallback, no-plan conversational response, and no retry on server 500.
- `test/ai_action_proposal_test.dart`, `test/ai_chat_approval_widget_test.dart`, `test/goal_plan_application_test.dart`: **24 passed**.
- Targeted analyzer on the changed AI service/tests: no issues.
- Android universal APK built for armv7, arm64, x86_64. `aapt` confirms version 0.5.6, code 8076, min API 24, target API 35. `apksigner` verifies v2; local Android Debug signer.
- Flutter web JavaScript release build passed, loaded Focus Clock Home at a local static server, and zipped output integrity check passed.
- v8076 installed over v8075 and launched on disposable API36 x86_64 AVD; saved LKS goal and linked action survived the upgrade, with no fatal Flutter/Android log. Screenshot: `.dart_tool/android-qa/v8076-home.png`.
- `git diff --check` passed.

## Limits and next gate

This supports OpenAI-compatible chat-completions endpoints, not every native provider protocol or every model's ability to follow a JSON-only instruction. Model behavior was tested through a mock endpoint, not a live external provider; API key, cost/consent, invalid key, timeout and quota journeys remain open. v8076 runtime install, actual AI flow in app, static web runtime/storage, physical/OEM Android, TalkBack, daily-use E6 and the wider E0–E6 ecosystem gates remain open. The v8075 APK remains available as a rollback preview.
