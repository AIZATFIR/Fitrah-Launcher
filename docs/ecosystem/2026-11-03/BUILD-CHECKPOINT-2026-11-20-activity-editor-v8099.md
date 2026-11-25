# Focus Clock activity editor checkpoint v8099

**Date:** 20 November 2026
**Version:** 0.5.20 (versionCode 8099)
**Purpose:** Make time-block creation and recurring edits clearer in Indonesian and usable on narrow phone screens.

## Changes

- Localized the activity detail/editor and clock's preset picker into Indonesian.
- Changed recurrence choices to **Sekali**, **Setiap hari**, **Hari kerja**, and **Setiap minggu**; the read-only summary now accurately identifies each recurrence type.
- Removed the duplicate time-range text from the duration stepper. Duration adjustment wraps on narrow screens; plus/minus controls have 48 dp touch targets and screen-reader tooltips.
- A regression test caught the previous copy mismatch and horizontal overflows. Editor copy and layout tests now pass at 320 dp.

## Verification

- Full serial Flutter suite: **437 passed, 0 failed**.
- `flutter analyze --no-pub`: five info-level diagnostics in existing unrelated files; no warning/error diagnostics.
- Android universal and web release builds: pending final package verification.
- API 36 x86_64 AVD update, create/edit recurring block, Home return, and no-fatal log check: pending final device smoke.

## Limits

This is a personal preview signed with the local Android Debug certificate. Owner phone/OEM, TalkBack, a live AI provider request, browser runtime/storage, and sustained daily use remain unverified. Full ecosystem gates (including sync, WhatsApp, MCP and production distribution) remain open.

## Status

This v8099 candidate was not distributed. Its first manual create/save smoke exposed an uninitialized Activity timestamp and led to v8100. Use [the v8100 checkpoint](BUILD-CHECKPOINT-2026-11-20-activity-save-v8100.md) and its packaged APK for owner trial.
