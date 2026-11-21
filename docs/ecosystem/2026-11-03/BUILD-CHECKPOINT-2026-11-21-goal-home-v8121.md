# Goal selection on Home — owner preview v8121

## Change

The first new goal is selected on Home by default when no goal is pinned. Tapping a saved goal selects it as the Home direction in one step; editing remains a separate, labeled control. Adding another goal does not replace the active one.

## Verification

- Both goal-flow regressions were observed failing before their fixes.
- `flutter test --no-pub test/home_intent_cue_test.dart test/focus_clock_home_persisted_data_test.dart --concurrency=1 --reporter expanded`: **35 passed**.
- Scoped analyzer and `git diff --check`: clean.
- On API 36 `FocusClock_UI_QA` at 1080×2400 and 200% text, v8120 completed the Home goal → inbox activity → linked daily action → scheduled block → timer → saved duration path. After force-stop/relaunch, the data remained visible. Release APK v8121 was installed as an update over that data; the same records remained visible and tapping an existing unpinned goal changed the Home direction without opening the editor.
- APK metadata reports package `com.aizatfir.fitrah_launcher`, versionCode 8121, versionName 0.5.31, min API 24, target API 35. APK Signature Scheme v2 verifies; SHA-256 certificate `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e` matches earlier owner previews. Checksums and ZIP integrity pass in the owner package.
- Focus Clock JavaScript build succeeded. Vercel deployment `dpl_4evYQyJiYvgaYjrZzzHQeULdmbkn` reached READY; `https://focus-clock-web.vercel.app/` returned HTTP 200. Optional Wasm dry run still reports unsupported dependencies and is separate from the JavaScript deployment.

Artifacts and install details: [v8121 owner preview](../../../release_dist/2026-11-21-focus-clock-goal-home-v8121/INSTALL.md).

## Limits

This proves the Home goal selection and focus loop on an API 36 emulator. Physical-device/OEM behavior, TalkBack, live AI calls, extended daily use, production signing, and the wider ecosystem are not verified. Web storage is local to each browser profile and does not sync with Android.
