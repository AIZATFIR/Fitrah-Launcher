# Focus Clock preview 37 — 14 November 2026

Source revision: `bcba30309c8c4d2ca249067db879dc139f7c1d55`.

This personal preview includes palette-aware Home action dialogs, honest empty schedule-capture choices, a Home timer hub that opens the existing session instead of suggesting a competing timer, and a screen-reader label/action for the analog Home clock.

## Verification

- Full Flutter suite: **322 passed**.
- `flutter analyze --no-pub`: no issues.
- Android x64 debug versionCode37 installed and cold-started on disposable API36 AVD `FocusClock_QA_API36`.
- Android UIAutomator verified the clock semantic label; tapping the clock opened blank schedule capture.
- Android arm64 release APK built. Metadata: versionName `0.5.3`, versionCode `37`, minSDK `24`, targetSDK `35`, compileSDK `36`.
- APK signature verified with the existing Android Debug certificate; signer SHA-256 `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`.
- Web JavaScript release bundle compiled and ZIP integrity passed. Wasm dry-run still reports existing dependency incompatibilities.
- Release APK was not installed on a device; browser interaction/storage, TalkBack navigation, physical Android, reboot, and notification delivery were not tested.

## Artifacts

- `release_dist/2026-11-14-focus-clock-preview-37/Focus-Clock-Ecosystem-Android-arm64-preview.apk`
- `release_dist/2026-11-14-focus-clock-preview-37/Focus-Clock-Ecosystem-Web-JS-preview.zip`
- APK SHA-256: `8a08b32cc20070f0b420e7a4dff2099951e0a95b1f0cf8d61b2f7b3578872116`
- Web ZIP SHA-256: `24c4ab7701e0862b92caa784ccf7c4599e4a8a1e285a3d03dde37e19d61636e7`

This is a personal local preview, not a public release or production deployment. The artifact is signed with the Android Debug certificate. E0–E6 adoption/runtime gates and later cross-device sync, AI, WhatsApp, MCP, and open-source publication remain open.
