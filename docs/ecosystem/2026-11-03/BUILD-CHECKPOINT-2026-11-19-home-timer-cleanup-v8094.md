# Checkpoint — completed session no longer covers Home v8094

**Date:** 19 Nov 2026
**Version:** 0.5.17+8094
**Download:** [APK and install notes](../../../release_dist/2026-11-19-focus-timer-home-cleanup-v8094/INSTALL.md)

## Finding and fix

The v8093 emulator journey showed that a completed focus session recorded **Fokus hari ini · 1 menit**, yet Home could retain a mini timer at `00:00` after returning from the timer. The Home timer listener treated every completed `TimerState` as still active. It now renders a mini timer only for active or save-pending sessions, plus the transient completed state that follows a pending save and still needs Home's auto-completion handling. A stable completed state no longer covers goal/history content.

## Verification

- Red/green widget regression: directly emitting a stable completed timer state reproduced the stale Home mini timer before the fix; the test now passes and asserts active session visibility plus completed session removal.
- `flutter test test/focus_clock_home_persisted_data_test.dart test/sadar_timer_view_session_test.dart --no-pub`: **13 passed**.
- Full Flutter suite on the current app source: **427 passed**; an additional full-Home widget test passes at **320 dp / 200% text**, with the pinned goal and add-activity action present and no layout exception. This is widget evidence, not TalkBack or physical-device verification.
- Scoped analyzer: **no issues** in Home and the affected test.
- `flutter build apk --release --no-pub`: succeeded. APK v2 verified, package `com.aizatfir.fitrah_launcher`, versionCode 8094, minSdk 24, targetSdk 35. Certificate matches v8093.
- API36 x86_64 AVD installed v8094 over v8093. Fitrah remained Android HOME; the saved LKS goal/action survived. With `POST_NOTIFICATION: ignore`, the linked focus action started at 29:56 without a permission prompt. After finishing, Home showed **Fokus hari ini · 1 menit** and no 00:00 overlay; the QA history remained visible. The emulator QA was synthetic. [Home/session screenshot](../../../release_dist/2026-11-19-focus-timer-home-cleanup-v8094/QA_Home_Session_v8094.png).
- APK SHA-256: `f66b3bcb3a0f8fee73aef2b4d63e8313d1356416b0c62770bb980326c449bcc4`.

## Remaining

This closes the stale completed-timer presentation bug and confirms one emulator goal → timer → history → Home loop. Physical/OEM reliability, accessibility, owner daily use, real provider quality, web persistence, sync, WhatsApp/MCP and the rest of E0–E11 remain open.
