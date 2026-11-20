# Home goal-header large-text wrap — v8113

**Date:** 20 November 2026

**Version:** 0.5.28 (versionCode 8113)

**Base revision:** `479172525285a8af05441f63333e11a0eb71589e`

## Change

At 320 dp and 200% system text scale, the Home cue heading shared a fixed row with “Tanya AI” and measured 186 dp tall. The cue header now places the assistant action below the heading when text scale is at least 150% or available width is below 340 dp. Heading font size, colors, and clock face are unchanged.

## Verification

- Regression test was run before the production fix and failed as expected at 186 dp versus the 80 dp bound. It passes after the fix and verifies that “Tanya AI” sits below the heading.
- `flutter test test/home_intent_cue_test.dart`: 24 passed.
- `flutter analyze lib/features/launcher/widgets/home_intent_cue.dart test/home_intent_cue_test.dart`: no issues.
- `flutter build apk --release --no-pub`: succeeded. APK metadata: package `com.aizatfir.fitrah_launcher`, version `0.5.28`, versionCode `8113`, min API 24, target API 35.
- APK signature verification succeeded with APK Signature Scheme v2 and the existing local Android Debug certificate (SHA-256 `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`).
- `flutter build web --release --no-pub`: succeeded using Flutter's JavaScript target. The WebAssembly dry run reports existing incompatibilities in `flutter_secure_storage_web`, Isar FFI and `flutter_tts_web`; these warnings do not prevent the JavaScript build.
- Web ZIP integrity and artifact SHA-256 checks are recorded in the package.
- API36 x86_64 QA AVD installed the APK with system font scale at 200%. Fitrah launched; log scan found no app fatal/Flutter exception, and `dumpsys activity lastanr` reported no ANR since boot.

## Limits

AVD evidence is emulator-only. The entire Home screen at 200% still consumes most of the short viewport; this slice addresses the approved goal header wrap only. It does not establish physical-device/TalkBack behavior, live AI-provider behavior, production signing/deployment, sustained owner use, or ecosystem completion.

Artifacts and install instructions are in [the v8113 package](../../../release_dist/2026-11-20-focus-clock-readable-home-header-v8113/INSTALL.md).
