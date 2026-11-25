# Empty agenda at large text + owner preview v8117

**Date:** 20 November 2026
**Version:** 0.5.31 (versionCode 8117)

## Change

The empty Home agenda message used to sit in a fixed 44 dp container. At 200% text scale, “Belum ada jadwal hari ini” wrapped into several lines and the container clipped it. The container now keeps 44 dp as its minimum and grows with its text. Normal-size layout stays the same.

## Verification

- The 200% regression test failed before the fix: the agenda container measured 44 dp while its text needed 50 dp. It passed after the container became minimum-height constrained.
- All 21 tests in `focus_clock_home_lampiran1_test.dart` passed, including the existing Gregorian/Hijri wrap test at 200%.
- Final full Flutter suite: 449 tests passed. One pre-existing large-text assertion was corrected to check the icon button's “Tanya AI tentang tujuan” tooltip, which is the visible control's accessible label.
- Scoped `flutter analyze` found no issues; `git diff --check` passed.
- Universal Android release APK and Flutter Web JavaScript release build succeeded. APK metadata is package `com.aizatfir.fitrah_launcher`, min API 24, target API 35; APK v2 signature verifies with the local Android Debug certificate. Web ZIP integrity passed. Flutter's optional Wasm dry run reported existing unsupported dependencies, while the JavaScript release completed successfully.
- On the API36 x86_64 AVD, v8117 installed and ran as the HOME app at 200% text scale on the native 1080×2400 / 420 dpi profile (about 411 dp wide). The full empty-agenda sentence, “TUJUAN UTAMA”, and Gregorian/Hijri date are visible without clipping; the Home key returned to `MainActivity`. Accessibility hierarchy exposes the complete goal and date labels. No app fatal, FlutterError, or app ANR matched the sampled log.
- Screen-time settings on v8117 show both opt-in switches off, with initial values of 120 minutes and 20 seconds. Android Usage Access and overlay app-ops were already allowed from prior QA; I did not change them or enable either feature.
- The QA screenshot is included as `QA_Home_200pct.png` in the owner package.

## Limits

Physical/OEM launcher behavior, TalkBack, live AI providers, production signing/deployment, sustained owner use, and the remaining ecosystem requirements are still open. This preview does not finish the ecosystem.
