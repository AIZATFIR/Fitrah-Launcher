# Create a schedule block by tapping an empty clock time — v8139

23 November 2026 · owner preview `0.5.47+8139`

A tap on an empty part of the analog clock ring now opens the existing activity form at the snapped time with a 30-minute starting span. Title and notes remain blank. Existing activity taps, drag creation, instant mode and clock styling retain their existing paths. A snapped end-of-day time rolls into the next date.

## Verification

- Focused clock widget file: **2 passed**, including the empty-tap form/time regression.
- Scoped analyzer for the changed Flutter source and widget test: clean.
- Universal release APK: package/version `com.aizatfir.fitrah_launcher`, `0.5.47`, versionCode `8139`; APK v2 signature verifies with the established owner-preview certificate.
- Fitrah, Focus Clock and Sadar JavaScript release bundles pass required offline-asset checks. APK and all three web bundles are included in the [download package](../../../release_dist/2026-11-23-tap-empty-clock-v8139/INSTALL.md); checksums are in that folder.
- All production deployments reached READY. Each production alias returns HTTP 200 for `/`, `/version.json`, `/main.dart.js` and `/sqlite3.wasm`; version endpoint reports `0.5.47 / 8139`.

## Limits

API 36 x86_64 `FocusClock_UI_QA` AVD upgraded v8137 → v8139 at 200% font scale. Fitrah remained the system HOME handler and the saved QA goal survived. Home opened; the empty dial tap opened a blank 08:00–08:30 PM create form. Screenshots: [Home](../../../release_dist/2026-11-23-tap-empty-clock-v8139/QA_Home_200.png), [create form](../../../release_dist/2026-11-23-tap-empty-clock-v8139/QA_Empty_Clock_Create_Form_200.png). Sampled logcat had no app fatal, FlutterError or ANR. This APK is debug-signed for personal preview, not Play Store distribution. Android and browser data remain separate; physical/OEM, TalkBack, live provider and sustained daily-use checks remain open. Production web uses JavaScript; current Isar, secure-storage and TTS dependencies still fail Flutter's Wasm dry run.
