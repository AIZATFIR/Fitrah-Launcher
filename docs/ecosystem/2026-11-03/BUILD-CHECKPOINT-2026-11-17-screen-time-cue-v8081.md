# Build checkpoint — screen-time cue and dialog v8081

**Date:** 18 November 2026
**Version:** 0.5.6+8081
**Artifact:** [Android and web preview bundle](../../../release_dist/2026-11-18-fitrah-launcher-screen-time-preview-v8081/INSTALL.md)

## Delivered

The small Android screen-time cue remains opt-in and can be tucked to the screen edge. The daily limit remains opt-in and adds a short wait before launching an app from Fitrah's app drawer, with a direct return to the goal. When both options are on, the native overlay used to cover the Flutter limit prompt because Android renders application overlays above app dialogs. The drawer now hides the overlay while the prompt is open and restores the user's saved cue setting in `finally`, even when they return to the goal or the route closes during the wait.

## Verification

- Regression test was observed red before the fix because no cue-suspend call occurred before showing the prompt.
- App drawer capability suite: **12 passed**, including suspend/restore on wait-and-continue and return-to-goal flows. Targeted analyzer: no issues; `git diff --check` passed.
- API 36 x86_64 QA emulator: v8081 upgraded the existing install; the saved goal remained visible after process restart. UsageStats displayed 71 minutes; cue opt-in displayed `71 mnt · Tujuan`; tapping it returned to Home; dragging it tucked the cue to the screen edge and tapping restored it. With a 30-minute limit, opening Chrome from the app drawer showed the 20-second wait and both choices. Tapping **Lihat tujuan** returned to Home and restored the cue. The post-upgrade screenshot confirmed the cue is absent from the dialog. Initial cue/limit settings were observed off before enabling them for this journey. No fatal Android/Flutter log entries appeared in the inspected log tail.
- Universal APK metadata, v2 signature, web archive and checksums were verified. No current-date action was selected on 18 November.
- Android RoleManager selected Fitrah as the API 36 emulator's Home role. Pressing Home opened Fitrah; launching Chrome and pressing Home returned to Fitrah, with the saved goal still visible. Screenshot: `QA_Default_Home_Return_v8081.png`.
- Full Flutter suite after correcting obsolete UI assumptions in launcher, note, inbox, habit-save and icon-key tests: **406 passed** (`flutter test --no-pub --concurrency=1 --reporter expanded`). `git diff --check` passes. Full-project `flutter analyze --no-pub` reports five pre-existing `info` lints in untouched files and no warnings/errors; see the command output in the working session. No product source changed after v8081 packaging in this verification pass.

## Remaining gates

Debug-signed personal preview only. Physical/OEM permissions and overlay policy, TalkBack, real-device permission journey, long-day UsageStats behavior, production signing, real-provider, web persistence, daily use, E0–E6 and future sync/WhatsApp/MCP/open-source distribution remain open.
