# Build checkpoint — navigation stays clear of Home content v8089

**Date:** 19 Nov 2026
**Version:** 0.5.14+8089
**Downloads and screenshots:** [personal preview package](../../../release_dist/2026-11-19-focus-clock-navigation-inset-v8089/INSTALL.md)

## Fix

Runtime review of v8088 showed that the floating navigation covered the Home habit-week selector and bottom habit row. The navigation now lives in the Scaffold's bottom slot, so the scrollable Home ends above it. The Clock/Today/Apps labels and selected-state behavior stay visible; Bookpaper styling and the analog clock remain.

## Verification evidence

- Regression first failed against v8088: Scaffold had no bottom NavigationBar. After the fix, launcher and HOME-route widget suites passed **10/10**; navigation taps visited all three destinations, and selected index updated. Scoped analyzer: no issues; whitespace check clean.
- Built a universal Android APK and standard JavaScript web release. APK v2 signature/package/version, web ZIP, and SHA-256 hashes verified.
- API36 x86_64 AVD upgraded **v8088→v8089**. Fitrah remained the Android HOME role holder. Saved LKS goal remained. Through the actual UI, selected `Latihan LKS 30 menit`, linked it to `Menang LKS National IT Software Solution`, started the 30-minute focus session, navigated Jam→Aplikasi→Hari Ini while it was running, and confirmed Home showed the session and goal. Ended early and returned to Home. The home screenshot showed the weekday selector and habit row above the navigation. The inspected log window had no Flutter/FATAL error.
- Runtime evidence/snapshots: `release_dist/2026-11-19-focus-clock-navigation-inset-v8089/QA_*.png`; full XML in ignored `.dart_tool/android-qa/v8089-ui/`.

## Still open

This is a personal preview signed with the local debug certificate. Physical/OEM phone behavior, TalkBack/large text, all-day use, storage and upgrade gates remain open; a single emulator session does not verify seven-day use. AI requires a provider key. Web persistence, production signing, cross-device sync, WhatsApp/MCP, and the remaining E0–E11 roadmap are not complete.
