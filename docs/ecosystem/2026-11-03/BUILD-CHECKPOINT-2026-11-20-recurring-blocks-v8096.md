# Focus Clock checkpoint v8096 — recurring block integrity

**Date:** 20 November 2026
**Version:** 0.5.17 (versionCode 8096)
**Purpose:** Continue the personal goal-first Android preview with recurring schedule editing that keeps linked activity history intact.

## Changes

- Recurring cross-midnight blocks project their continuation on the correct following day, including weekday series that start Friday and continue Saturday.
- Editing/deleting one occurrence updates all source segments that belong to that date's logical block. Editing from a projected tail moves the entire block to the selected occurrence before asking scope.
- A one-date edit saves standalone replacement segments and excludes the matching occurrence from the recurring source. Other dates keep the source series.
- Whole-series edits retain existing segment IDs, measured seconds, completion state, creation time and excluded dates. Removing a segment with completion, measured time or linked timer history is refused with a recoverable message.
- Direct and projected activities are deduplicated by source ID, so separate activities with identical names and times remain distinct.

## Verification

- Regression tests: **7 passed** across projected Friday/Saturday tails, edit/delete scope, same-title identity, series history preservation and refusing to drop history.
- Schedule service tests: **5 passed**.
- Full serial Flutter suite: **435 passed, 0 failed**.
- Scoped analyzer: clean; `git diff --check`: clean.
- Universal release APK build, install over the prior APK and app launch on API 36 x86_64 AVD passed. VersionCode 8096 was confirmed; `MainActivity` remained resumed and the captured log window had no fatal exception. Android's default Home remained Nexus Launcher. Screenshot: `QA_Home_v8096.png` in the download folder.

## Limits

Physical/OEM device behavior, TalkBack, real AI provider calls and sustained daily use remain unverified. The active series editor interaction was not manually exercised on a device; automated repository tests cover its storage and projection rules. Web persistence, sync, WhatsApp/MCP, production signing and the remaining E0–E11 ecosystem gates remain open.
