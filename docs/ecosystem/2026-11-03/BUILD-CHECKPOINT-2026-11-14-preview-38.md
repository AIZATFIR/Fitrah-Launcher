# Focus Clock preview 38 — 14 November 2026

Source revision: `dab45ba6a9d90ba212f241486d4218bdee16c1ed`.

This personal preview adds a per-session focus ledger, atomic terminal records, a Home summary of today's completed/cancelled sessions, and backup format v5 with v1–v4 compatibility.

## Verification

- Full Flutter suite: **329 passed** with `--concurrency=1`.
- `flutter analyze --no-pub`: no issues.
- Independent quick review: one legacy-session source fallback issue found and fixed; focused regression passes.
- Android arm64 release APK built as versionName `0.5.3`, versionCode `38`, minSDK `24`, targetSDK `35`, compileSDK `36`.
- APK signature verified with the existing Android Debug certificate (SHA-256 `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`). This is suitable for a personal preview only, not a public store release.
- Web JavaScript release bundle compiled and ZIP integrity passed.
- `build_runner` generated the Isar model but exits nonzero on an unrelated annotation-resolution error in `tool/web_storage_spike/test/storage_test.dart`; schema ID fixer completed.
- No physical phone install, personal database upgrade, browser interaction/reload, or TalkBack navigation was verified.

## Artifacts

- `release_dist/2026-11-14-focus-clock-preview-38/Focus-Clock-Ecosystem-Android-arm64-preview.apk`
- `release_dist/2026-11-14-focus-clock-preview-38/Focus-Clock-Ecosystem-Web-JS-preview.zip`
- `release_dist/2026-11-14-focus-clock-preview-38/BUILD-MANIFEST.json`
- `release_dist/2026-11-14-focus-clock-preview-38/SHA256SUMS`

The app artifacts are local previews and are intentionally excluded from Git. E2 stays open for browser storage/reload, real-device database upgrade, clock/reboot uncertainty, reminders and field use. Sync, AI, WhatsApp, MCP and public publication remain later roadmap goals.
