---
title: 'Focus Clock v8150 clarity and preview release'
type: 'chore'
ticket: ''
created: '2026-11-24'
status: 'built'
baseline_revision: 'd2d422927b88841ab207c39feec14557703420b7'
route: 'oneshot'
route_source: 'auto'
risk: 'low'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Focus timer copy implied every timer result became a scheduled item, while free focus is only added to today's focus total. The AI notice below chat was also too long to scan.

**Approach:** State the save destination based on the timer source and shorten the AI notice to the two facts users need: messages are sent to the AI provider, and app chat history is not retained after closing. Ship the current owner-preview build across the existing release targets.

</frozen-after-approval>

## Implementation Notes

- `lib/features/launcher/widgets/focus_clock_home_view.dart`: timer hint now distinguishes schedule blocks, presets, and free focus totals.
- `lib/features/ai_chat/ai_chat_sheet.dart`: privacy note shortened to provider transfer and app-history retention.
- `pubspec.yaml`: preview version set to 0.5.58+8150. No data model or timer behavior changed.
- Focused analyzer and `git diff --check` passed. Android release APK built at 72.9 MB; package reports versionCode 8150 / versionName 0.5.58 and v2 signature fingerprint matches the stable owner-preview certificate.
- API 36 x86_64 AVD upgraded from 8149 to 8150; Fitrah retained HOME, the saved daily choice and 1:21 focus total remained, the free-timer copy appeared, and cancel returned Home without changing the total. Sampled logcat had no app fatal/FlutterError/ANR.

## Review Triage Log

- medium — patch: at review time, the local v8150 package contained only APK and QA screenshots despite the plan requiring all existing targets. Resolve by collecting the tagged workflow's Android, Linux, Windows, and three web artifacts, then verify checksums and install instructions before marking built.
- resolution: release run 45414831872 completed successfully for Android, Linux, Windows, three web builds, and publication. All six downloaded platform artifacts passed the published SHA-256 list; the install guide, manifest, and combined ZIP are present.
- resolution: the combined ZIP and SHA-256 sidecar were uploaded to the tagged GitHub release; public download HEAD returned HTTP 200, and the ZIP integrity/checksum checks passed.

## Verification

- `flutter analyze --no-pub lib/features/ai_chat/ai_chat_sheet.dart lib/features/launcher/widgets/focus_clock_home_view.dart` — no diagnostics.
- Release APK reports versionCode 8150 / versionName 0.5.58 and passes v2 signature verification with the stable owner-preview certificate.
- API 36 AVD upgrade from 8149 retains HOME role, daily choice and focus total; timer copy is visible and cancel preserves the existing total.
- Release workflow 45414831872 passed all six platform builds and published six assets; every SHA-256 check passes.
- Production Fitrah, Focus Clock and Sadar domains return HTTP 200 for `/`, `/main.dart.js`, and `/version.json`; each reports v0.5.58 / 8150.
