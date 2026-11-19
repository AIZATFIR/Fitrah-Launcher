# Build checkpoint — narrow Home cue and v8086 preview

**Date:** 18 November 2026
**Version:** 0.5.11+8086
**Artifact:** [Android/web preview and install guide](../../../release_dist/2026-11-18-fitrah-home-cue-preview-v8086/INSTALL.md)

## Delivered

The pinned-goal header's title now takes only the available width; on 320 dp phones it truncates safely while retaining the **Tanya AI** action. The AI setup route still opens Settings directly at provider controls. This keeps the goal and its next useful action reachable in Home layouts.

## Verification

- A new 320 dp widget test reproduced the overflow before the change and passed after it.
- Home intent and Home integration suites: **41 passed**.
- Full Flutter suite: **411 passed, 0 failed**.
- Scoped analyzer clean; Android release APK and web JavaScript release builds succeeded.
- v8085 AVD had previously confirmed the saved LKS goal and direct AI settings navigation. It shut down during the v8086 QA attempt, so the v8086 artifact itself has no fresh emulator screenshot or interaction claim.

## Still open

The ecosystem remains incomplete. Real provider response and approval-to-session journey, timer/reboot uncertainty, physical/OEM behavior, full browser persistence, seven-day daily use, production signing, cross-device sync, optional WhatsApp/MCP, and public open-source release remain open.
