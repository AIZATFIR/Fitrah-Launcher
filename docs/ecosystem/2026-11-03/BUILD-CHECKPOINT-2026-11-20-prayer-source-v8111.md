# Truthful prayer schedule and owner-use checkpoint v8111

**Date:** 20 November 2026  
**Version:** 0.5.28 (versionCode 8111)

## Change

- New installs open to the goal-first Focus Clock Home.
- Example prayer times are no longer presented as if they were confirmed for the user's location. Prayer mode shows an `Atur jadwal salat` cue until the user manually checks all six values and confirms them.
- Existing settings that used the old prayer mode remain in prayer mode, but their values start unverified; no location permission or location lookup is implied.
- The current activity is not repeated in the upcoming schedule carousel.
- Existing Bookpaper colors, analog clock, and large-text wrapping are retained.

## Verification

- Full serial Flutter suite: **444 passed**. This includes regression coverage for legacy unverified prayer times and the 200% Home date/title wrapping.
- Full analyzer: five info-level lints in existing files; no warning/error diagnostics.
- `git diff --check` passed.
- Fresh Android release APK and Flutter Web JavaScript release build produced for version 0.5.28+8111.
- API36 x86_64 AVD installed v8111; package metadata reported 0.5.28 / 8111 and Fitrah remained the HOME handler. A 200% font-scale visual capture was inconclusive: Android displayed a System UI not-responding dialog and logcat reported low-memory pressure. The widget regression test passes, but this turn does not claim visual device proof at 200%.

## Limits

This is a local owner-use preview, not completion of the Focus Clock ecosystem or a public Android release. No physical phone was available. Live AI provider behavior, accessibility/TalkBack on real hardware, OEM behavior, sustained owner use, production signing/deployment, and future sync, WhatsApp/MCP, and open-source packaging remain open.
