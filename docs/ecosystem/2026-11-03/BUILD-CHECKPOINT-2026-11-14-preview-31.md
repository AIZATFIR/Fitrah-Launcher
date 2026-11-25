# Focus Clock preview 31 — 14 November 2026

Source revision: `c3578ae`.

The shared timer uses monotonic elapsed time while the process is alive. Android persists `BOOT_COUNT` and `SystemClock.elapsedRealtime()` with the timer checkpoint. A process restart in the same boot restores elapsed duration without consulting the calendar clock. Legacy sessions and sessions restored after a reboot use a guarded wall-clock fallback; time changes while the device is off can still make that estimate inaccurate.

## Verification

- Full Flutter suite: **309 passed** using the serial runner.
- `flutter analyze --no-pub`: **No issues found**.
- Android arm64 release APK: compiled in 130.1 seconds; versionName `0.5.3`, versionCode `31`, minSDK `24`, targetSDK `35`, compileSDK `36`.
- Web JavaScript release: compiled in 49.1 seconds. Wasm is not supported by the current dependency set.
- APK signature verified. It uses the existing Android Debug certificate, SHA-256 `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`.
- Controlled same-boot restore test, backward-wall-clock test and Isar reopen tests pass.
- APK install on physical hardware and web interaction/storage were not tested.

## Local preview artifacts

Ignored generated files are under `release_dist/2026-11-14-focus-clock-preview-31/`: arm64 APK, web JS ZIP, `BUILD-MANIFEST.json`, `CHECKPOINT-NOTES.md` and `SHA256SUMS`. Both artifact hashes passed `sha256sum -c`.

This is a local preview, not a public release or deployment. Reboot recovery after clock changes, operation receipts, per-session ledger, reminder reconciliation, physical Android verification, browser storage, AI agent planning, WhatsApp and MCP remain open. Continue from [BUILD-ROADMAP](BUILD-ROADMAP.md).
