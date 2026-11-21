# Focus Clock schedule-list owner preview v8118

**Date:** 21 November 2026  
**Version:** 0.5.31 (versionCode 8118)  
**Source:** `2af3b25`

## Download

The maintainer's local preview package is at [INSTALL.md](../../../release_dist/2026-11-21-focus-clock-schedule-list-v8118/INSTALL.md). It contains a universal Android APK, a static web ZIP, install notes, manifest and checksums. This is a personal preview signed with the local Android Debug certificate, not a public GitHub or Play Store release.

## Changes

- The Jam menu opens an accessible chronological schedule list. Tapping an activity opens its existing detail sheet. Loading, error and empty states are explicit.
- Jam header controls wrap on narrow screens; Indonesian menu labels are concise enough for a 390 dp phone width.
- AI conversation transcript remains ephemeral in process memory and is not written to app storage, backups or the app backend. See the [owner decision](OWNER-INTENT.md) and [PRD FR-04a](PRD.md).

## Verification

- `flutter test --no-pub test/focus_clock_schedule_list_test.dart --reporter expanded` passed at 390×844 logical pixels. The regression asserts schedule text, button semantics and the activity detail entry.
- Scoped `flutter analyze --no-pub` found no issues in the clock screen and its regression test.
- `flutter build apk --release --no-pub` succeeded. `aapt` confirms package `com.aizatfir.fitrah_launcher`, versionCode 8118, versionName 0.5.31, min API 24 and target API 35.
- `apksigner verify` confirms APK Signature Scheme v2; certificate SHA-256 matches v8117: `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`.
- `npm run build:focus` produced the Flutter JavaScript web build. Its optional Wasm dry run still reports existing dependency incompatibilities.
- Vercel deployment `dpl_7R5gyjRAfxfqQLBTzuxc11V8gvHU` reached READY and `https://focus-clock-web.vercel.app/` returned HTTP 200.
- APK and web ZIP passed SHA-256 checks; ZIP integrity passed.

**Follow-up:** installing v8118 on the API36 QA emulator at 200% text exposed a clipped “Tidak ada jadwal tersisa” summary in Jam. The text-wrap fix is included and verified in [v8119](BUILD-CHECKPOINT-2026-11-21-jam-large-text-v8119.md); use v8119 for the current preview.

## Limits

No Android device or emulator was connected. This build has not been installed or exercised as the default Home app; Android TalkBack and OEM behavior remain unverified. The full Flutter suite, live AI provider and sustained daily use were not rerun. The web app stores data in the current browser profile and does not sync with Android. This checkpoint does not close E0–E11 or complete the ecosystem.
