# Build checkpoint — Focus Clock timer reminder v8087

**Date:** 18 Nov 2026
**Version:** 0.5.12+8087
**Artifact:** [Android and web preview bundle](../../../release_dist/2026-11-18-focus-clock-timer-reminder-preview-v8087/INSTALL.md)

## Change

Durable focus timer sessions now schedule a generic Android OS reminder for the saved remaining time. Start/resume schedules; pause, extension replacement, cancel, completion, and stale/uncertain restore reconcile it. Valid same-boot restore reschedules from the verified remaining time. A missing active session clears an orphaned reminder. Notification errors are contained and do not roll back timer state. Notification content avoids private habit/goal titles. YPT's open-ended timer does not schedule a fixed completion cue.

## Verification

- Notification and Sadar timer state-machine suites: **41 passed**.
- Scoped analyzer: clean; `git diff --check`: clean.
- Universal Android release APK and Flutter JavaScript web release build succeeded.
- APK v2 signature/package/version metadata, SHA-256 checksums, and web ZIP integrity verified.
- No emulator or physical device was connected for this build, so screen-off/Doze delivery is not claimed as runtime verified. Android uses an inexact alarm and power-saving modes may delay it.

## Finish boundary

This is an installable personal preview to start using the goal → schedule → timer → recorded time loop. It does not finish the whole ecosystem. A live AI answer still needs the user's provider setup; real phone/OEM, accessibility and repeated daily use remain validation gates. Web persistence, production signing and the later WhatsApp/MCP work are future scope. Use this build and report friction from an actual day; fixes should follow those concrete misses.
