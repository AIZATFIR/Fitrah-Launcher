# AI chat privacy disclosure — owner preview v8122

## Change

AI chat now says, beside the message field, that the app does not retain the transcript after close; the user's message and selected Home goal (if any) are sent to the configured provider, whose retention policy applies. This makes the existing ephemeral-transcript decision visible before the user sends a message. At 320 dp with 200% text, the empty chat view can scroll instead of overflowing.

## Verification

- The new widget test failed before the change because no privacy disclosure existed and the empty state overflowed at 200% text. It passes after the change and checks the disclosure is visible before a message is sent and that the layout has no framework exception.
- `flutter test --no-pub test/ai_chat_approval_widget_test.dart test/ai_action_proposal_test.dart test/ai_provider_probe_test.dart test/goal_plan_application_test.dart --concurrency=1 --reporter expanded`: **43 passed**.
- `flutter analyze --no-pub lib/features/ai_chat/ai_chat_sheet.dart test/ai_chat_approval_widget_test.dart`: clean.
- `git diff --check`: clean.
- Release APK v8122 upgraded over v8121 on the API 36 emulator at 1080 × 2400 and 200% font scale. Existing goal, activity and timer data remained visible. The AI chat sheet showed the complete privacy disclosure; see the QA image in the preview package.
- APK metadata: `com.aizatfir.fitrah_launcher`, versionCode `8122`, min API `24`, target API `35`. APK v2 signature verifies and uses the same local Android Debug certificate as v8121, allowing an in-place preview upgrade.
- Flutter web build is pinned to `--pwa-strategy=offline-first`; without it, Flutter 3.41 emitted JavaScript while omitting runtime/PWA assets. `scripts/verify_web_bundle.sh` now rejects that incomplete output. The Focus Clock web page was opened locally, rendered the goal-first Home, and exposed the same privacy disclosure in the chat accessibility tree and screenshot.
- Vercel production deployment `dpl_GqVwfikggysU96zvKA46GJXoWF3y` reached `READY` on `https://focus-clock-web.vercel.app/`. The live `/version.json` reports `8122`, and the asset manifest, Material font, background, icon, web manifest, Drift worker/WASM and service worker each return HTTP 200.

Artifacts and install details: [v8122 owner preview](../../../release_dist/2026-11-21-focus-clock-ai-privacy-v8122/INSTALL.md).

## Limits

This is an Android owner preview, not a production-signed/public release. A live provider request was not made. Provider-specific retention depends on the provider. Physical-device/OEM behavior, TalkBack, sustained use, and all remaining E0–E11 ecosystem gates remain open. The web build still uses browser-profile local storage and does not sync with Android.
