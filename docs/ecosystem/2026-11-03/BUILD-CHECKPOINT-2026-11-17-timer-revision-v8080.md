# Build checkpoint — timer revision safety v8080

**Date:** 17 November 2026
**Version:** 0.5.6+8080
**Artifact:** [Android and web preview bundle](../../../release_dist/2026-11-17-fitrah-launcher-timer-revision-preview-v8080/INSTALL.md)

## Delivered

Durable timer checkpoints now use a monotonically increasing revision. A repository instance can update only the revision it observed, so a stale writer cannot replace a newer saved timer state. Retrying a completion receipt for an old session no longer clears a different active session. The engine carries revisions through start, pause, restore/resume, and resets the revision when a session ends or is cancelled. Live-model and backup codecs preserve the revision; older records without it decode as revision zero. Isar retains the existing property IDs and assigns the additive revision field ID 23.

## Verification

- The two repository regressions were observed failing before the fix: stale durable writes were accepted, and retrying an old completion removed the newer active timer.
- Focused persistence, repository, terminal-session, timer engine, timer view, live codec, and backup codec suites: **91 passed**.
- Targeted analyzer: no issues; `git diff --check` passed.
- Universal Android APK and Flutter Web JavaScript build completed. APK metadata reports versionCode 8080, its v2 signature verifies, and the web ZIP passes integrity validation.
- v8080 installed and opened Home on the disposable `FocusClock_UI_QA` API 36 x86_64 emulator; the saved LKS goal and Home action were visible. The inspected log tail had no fatal Android/Flutter error. Screenshot: `.dart_tool/android-qa/v8080-home.png` (also packaged as `Preview_Home_v8080.png`). Timer concurrency regressions are covered by automated tests, not manually exercised on the emulator.

## Remaining gates

Debug-signed personal preview only. Physical/OEM Android, TalkBack, production signing, real-provider behavior, complete web persistence, daily use, E0–E6 and later sync/WhatsApp/MCP/open-source distribution remain open.
