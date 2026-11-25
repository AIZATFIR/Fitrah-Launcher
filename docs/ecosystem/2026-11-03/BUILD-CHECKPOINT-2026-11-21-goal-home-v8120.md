# First goal shown on Home — owner preview v8120

## Change

When a user adds a goal and no active goal is pinned, **Sematkan di Home** now starts checked. Saving that first goal makes it the visible Home direction. When a goal is already pinned, a newly added goal stays unpinned by default. Existing goals and daily activity selection are unchanged.

## Verified behavior

- Regression test failed before the code change because the first goal's pin checkbox was off; it passes after the change.
- `flutter test --no-pub test/home_intent_cue_test.dart test/focus_clock_home_persisted_data_test.dart --concurrency=1 --reporter expanded`: 34 tests passed.
- Scoped Flutter analyzer for the changed widget and test: no issues.
- API 36 `FocusClock_UI_QA` at 1080×2400 with 200% text: created and pinned a goal, created an inbox task, attached it to the goal, scheduled it at 14:30–15:00, started and finished its timer, and saw 35 seconds recorded on Home. After force-stop/relaunch, goal, task, schedule, and session evidence remained visible.
- Release APK installed as an update on the QA emulator. `aapt` reports package `com.aizatfir.fitrah_launcher`, versionCode 8120, versionName 0.5.31, min API 24. APK Signature Scheme v2 verifies and certificate SHA-256 matches prior owner previews: `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`.
- Focus Clock JavaScript build succeeded and Vercel deployment `dpl_Hq6ZxnPEyHeNrz5tR9YLM2Es22Kz` reached READY. `https://focus-clock-web.vercel.app/` returned HTTP 200. The optional Wasm dry run still identifies unsupported dependencies; this does not block the JavaScript build.

## Owner preview

Artifacts and SHA-256 checksums are in [`release_dist/2026-11-21-focus-clock-goal-home-v8120/`](../../../release_dist/2026-11-21-focus-clock-goal-home-v8120/INSTALL.md). APK signing uses the local Android Debug certificate, so this is a personal sideload preview, not a Play Store or public GitHub release.

## Still open

This fixes first-goal visibility and verifies one end-to-end Home journey. It does not establish physical-phone/OEM behavior, daily-use quality, production signing, or completion of the wider Focus Clock ecosystem.
