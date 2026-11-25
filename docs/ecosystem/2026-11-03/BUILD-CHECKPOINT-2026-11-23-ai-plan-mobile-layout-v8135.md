# AI plan review fits mobile screens — v8135 (23 November 2026)

The AI plan review now switches to a two-line weekly block editor on narrow screens. Day selection gets a full-width row; time and duration sit beneath it. Full weekday names remain readable on phones, while wider layouts keep compact labels. This removes a 5.3 px overflow seen in the editable proposal on the API 36 emulator.

## Verification

- `flutter analyze lib/features/ai_chat/ai_chat_sheet.dart`: no issues.
- Manual Android flow used a local OpenAI-compatible mock only. A request with tool definitions received an unsupported-tools response; the app retried with its structured JSON fallback, displayed an editable goal and two weekly blocks, and applied the proposal. The goal and schedule appeared on Home. No real provider or API key was used.
- At 200% system font scale, the weekly day, time, duration, remove control, cancel and apply actions remained visible without a Flutter overflow. Screenshot: [AI plan review](../../../release_dist/2026-11-23-ai-plan-mobile-layout-v8135/QA_AI_Plan_v8135.png).
- Universal release APK 0.5.44 / 8135 built and installed over the prior app on the API 36 x86_64 AVD. Fitrah remains the default HOME handler; the saved QA goal remained visible at 200% font scale after upgrade. No fatal app exception or ANR appeared in the sampled log.
- APK v2 signature verifies and uses the existing owner-preview certificate (`b8af9d95…34fe3e`). Release manifest contains no debug cleartext permission. APK metadata reports package `com.aizatfir.fitrah_launcher`, min API 24, target API 35.
- Focus Clock web JavaScript bundle verified; production deployment `dpl_G8UspA94jZcCyzL2orAAr1nZDW3y` is READY. Production version endpoint reports 0.5.44 / 8135; root and `main.dart.js` return HTTP 200. Web ZIP integrity and package checksums pass.
- Automated tests were not run.

## Still open

This proves the app's local structured-fallback path, not a real BYOK provider response. The owner's physical handset/OEM, TalkBack, seven-day use, Android/browser data sync, and the wider WhatsApp/MCP/open-source ecosystem remain open. Android and browser data are separate. This is an owner preview signed with the local Android Debug certificate, not a Play Store release.

[Install and download notes](../../../release_dist/2026-11-23-ai-plan-mobile-layout-v8135/INSTALL.md).
