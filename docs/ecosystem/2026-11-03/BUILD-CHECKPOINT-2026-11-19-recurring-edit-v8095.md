# Focus Clock checkpoint v8095 — recurring schedule edit

**Date:** 19 November 2026
**Version:** 0.5.17 (versionCode 8095)
**Purpose:** Personal Android preview for trying the goal-first Home, shared focus timer, and safer recurring schedule editing.

## What changed

When editing a recurring activity, Focus Clock now asks whether to change the selected date only or the whole series. A one-date edit excludes that date from the old series and saves a standalone activity, leaving the series and its past completion/timer history in place. A whole-series edit preserves the original recurrence anchor when the editor was opened from a projected date. Cancel leaves the schedule unchanged.

If a recurring edit crosses midnight, the save is stopped with an explanation instead of risking removal or corruption of the series. Split recurring blocks need a dedicated occurrence-aware model before they can be edited safely.

## Evidence

- Regression test first failed because the repository had no occurrence-edit operation; it now verifies the standalone replacement, excluded source date, and neighboring weekday projections.
- Recurring-edit test: **1 passed**.
- Schedule service tests: **5 passed**.
- Full serial Flutter suite: **429 passed, 0 failed**.
- Scoped analyzer: clean; `git diff --check`: clean.
- Universal Android release APK built; package ID, version code, v2 signature and checksum verified.
- Installed on the API 36 x86_64 QA emulator and launched to `MainActivity`; no app crash appeared in the captured log window. The recurring-edit UI was not exercised on the emulator. No physical phone was attached.

## Install

Use the APK in the sibling download folder. Android may ask to allow installs from the app used to open the APK. This is a local personal preview signed with the Android Debug certificate; future builds signed with a different certificate cannot update it in place. Back up important data before replacing an existing install.

## Still open

Physical/OEM launcher behavior, TalkBack and device-level large-text navigation, real AI provider calls, owner daily-use observation, recurring cross-midnight occurrence editing, web persistence, sync, WhatsApp/MCP, production signing and the remaining E0–E11 ecosystem gates.
