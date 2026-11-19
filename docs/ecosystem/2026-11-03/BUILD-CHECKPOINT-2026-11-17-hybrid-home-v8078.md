# Build checkpoint — hybrid habit from Home v8078

**Date:** 17 November 2026
**Version:** 0.5.6+8078
**Artifact:** [Android and web preview bundle](../../../release_dist/2026-11-17-fitrah-launcher-hybrid-home-preview-v8078/INSTALL.md)

## Delivered

The Home habit grid now offers its existing Focus Clock action for valid hybrid habits, routing through the same `SadarTimerView` and shared `SadarTimerEngine` as the other habit timer entry points. The hybrid's saved work/rest/set configuration is carried by the existing Habit record. Manual completion, skip and count/status controls remain hidden for hybrid because the timer must record actual focused work and completed sets. Progression habits retain the honest explanation and have no misleading Play action in this grid.

## Verification

- Added a Home regression test first; it failed because hybrid had no Play affordance. After the fix, it verifies the callback receives the same hybrid Habit and the expanded row offers focus without manual completion.
- Related Home actions, Sadar timer state machine/view and Home habit repository suites: **71 passed**.
- Targeted analyzer: no issues; `git diff --check` passed.
- Universal Android release APK and web JavaScript release bundle built; web ZIP integrity, SHA256 checksums, and APK signature verified.
- v8078 upgraded on the disposable API36 x86_64 AVD and opened Home as `MainActivity`; the saved LKS goal and Home action remained visible. No fatal Android/Flutter error appeared in the inspected log tail. Screenshot: `.dart_tool/android-qa/v8078-home.png` (also packaged as `Preview_Home_v8078.png`).

## Remaining gates

This is a debug-signed personal preview. The hybrid timer was verified through the Home callback regression and timer suites, but was not manually run end-to-end on the AVD or a physical phone. Physical/OEM Android, TalkBack, production signing, real-provider behavior, browser persistence, daily use and full E0–E6 remain open. Ecosystem sync, WhatsApp, MCP and open-source publication remain later work.
