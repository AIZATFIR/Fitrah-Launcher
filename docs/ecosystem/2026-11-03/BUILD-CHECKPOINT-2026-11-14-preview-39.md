# Focus Clock preview 39 — 14 November 2026

Source revision: `107e0fb`.

This preview adds a startup-restore barrier to timer mutations. It prevents an early cancel or other command from changing storage before the persisted session has been read. Preview 38's session ledger and Home history remain included.

## Verification

- Full Flutter suite: **330 passed** with `--concurrency=1`.
- `flutter analyze --no-pub`: no issues.
- Android arm64 release APK built as versionName `0.5.3`, versionCode `39`, minSDK `24`, targetSDK `35`, compileSDK `36`.
- APK signature verified with the existing Android Debug certificate (SHA-256 `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`). Personal preview only; not suitable for Play/public release.
- A separate x86_64 versionCode `39` APK upgraded the dedicated API36 QA AVD from versionCode `34`. Install preserved the synthetic `QA-LKS-Nasional` goal; Home role remained Fitrah; cold launch returned `Status: ok` in 3.6 seconds; Android Home key returned to `MainActivity`; sampled logcat contained no `FATAL EXCEPTION`, `AndroidRuntime`, or `FlutterError`.
- Web JavaScript release bundle compiled and ZIP integrity passed.
- No physical phone install, personal database upgrade, browser interaction/reload, or TalkBack navigation was verified. The x86_64 QA run does not prove arm64 runtime behavior.

## Artifacts

- `release_dist/2026-11-14-focus-clock-preview-39/Focus-Clock-Ecosystem-Android-arm64-preview.apk`
- `release_dist/2026-11-14-focus-clock-preview-39/Focus-Clock-Ecosystem-Web-JS-preview.zip`
- `release_dist/2026-11-14-focus-clock-preview-39/BUILD-MANIFEST.json`
- `release_dist/2026-11-14-focus-clock-preview-39/SHA256SUMS`

The local artifacts are intentionally excluded from Git. E2 remains open for browser persistence/reload, real-device database upgrade, restart uncertainty and reminder reconciliation. Sync, AI, WhatsApp, MCP and public publication remain later roadmap goals.

QA screenshot: `.dart_tool/android-qa/2026-11-14-v39-home.png`; QA x86_64 APK: `.dart_tool/android-qa/Focus-Clock-107e0fb-v39-x64-QA.apk`. The dedicated `FocusClock_QA_API36` AVD was shut down after verification; `Medium_Phone` was not touched.
