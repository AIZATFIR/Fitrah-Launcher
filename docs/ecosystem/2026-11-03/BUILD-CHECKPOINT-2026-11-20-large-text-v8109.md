# Checkpoint v8109: readable Home at large text sizes

**Date:** 20 November 2026  
**Build:** 0.5.28 (versionCode 8109)

## Owner-facing change

Hari Ini is the goal-first landing screen. Its goal label, date and agenda content now wrap at large Android text sizes rather than being clipped by single-line labels and a fixed-height agenda rail. Goal and next-action content remains the visual center.

## Evidence

- Reproduced the clipping and agenda overflow at 200% text scale before the fix.
- Added regressions for 320 dp / 200% goal heading and 360 dp / 200% Hijri date.
- 24 goal-cue tests and 19 Home tests passed; scoped analyzer, formatter and diff check were clean.
- Android universal release and Flutter Web JavaScript release builds succeeded. APK package/version/signature and web archive integrity were checked.
- APK installed on disposable API36 x86_64 emulator, versionCode 8109 confirmed. Android System UI raised a not-responding dialog during cold launch; full-screen visual confirmation is inconclusive. No phone was connected.

## Files

- Installable owner preview: [APK and web package](../../../release_dist/2026-11-20-focus-clock-readable-large-text-v8109/INSTALL.md)
- [Checkpoint details](../../../release_dist/2026-11-20-focus-clock-readable-large-text-v8109/BUILD-CHECKPOINT.md)

This is one usability checkpoint, not completion of the Focus Clock ecosystem. Continue from the ecosystem roadmap and close the physical-device, accessibility, AI, persistence and daily-use gates before calling the ecosystem finished.
