# Checkpoint: progression evidence and v8071 Home preview — 17 November 2026

## Habit progression

Sadar previously recorded a progression completion and advanced its mutable cursor in separate writes. Duplicate taps could advance the routine more than once and the entry used the general habit target instead of the selected step target. `SadarRepository.completeProgressionStep` now checks the dated entry and, inside one Isar transaction, stores the step's target, marks the entry complete, and advances the cursor once. The explicit preview backend mirrors the rule.

`TodayView` calls this shared operation for progression completion. A repeated request for the same habit/date returns without a second cursor advance. The existing standalone `advanceProgression` API remains for legacy/editor test paths; production UI no longer uses it.

- `flutter test --no-pub test/home_habit_repository_test.dart test/home_habit_actions_test.dart test/sadar_repository_test.dart --reporter expanded` — **44 passed** across preview, native Isar, Home habit actions and Sadar repository.
- The native Isar test closes and reopens the database before asserting the entry target snapshot and progression cursor.
- `flutter analyze --no-pub` on the changed repository, Today view and relevant test files — no issues.
- `git diff --check` — clean.

The stale Home habit test expected English weekday labels although the app renders Indonesian; its fixture now uses `Sen/Sel/Rab/Kam/Jum/Sab/Min` and asserts the intended date behavior. Hybrid set execution and progression undo/history remain open.

## Android personal preview

VersionCode8071 contains the progression fix and the v8070 R8/Gson TypeToken retention rules. It upgraded v8070 on the disposable API36 x86_64 AVD, survived a full reboot with an empty crash buffer, retained `com.aizatfir.fitrah_launcher` as HOME role holder, and returned to Fitrah MainActivity when Home was pressed from Android Settings. Screenshot: `.dart_tool/android-qa/v8071-home-key-after-settings.png`.

Artifact folder: `release_dist/2026-11-17-fitrah-launcher-progression-fix-preview-v8071/`.

- APK: `Fitrah_Launcher_0.5.3_universal_v8071.apk`
- SHA-256: `48d31bedf240d62793e637e49520c73cfee9bf87c380842c8fd25cb4bfa8ae8b`
- Package `com.aizatfir.fitrah_launcher`, versionCode8071, minSDK24, targetSDK35, compileSDK36; universal ABIs arm64-v8a, armeabi-v7a, x86_64.
- Android Debug certificate, same local identity as v8070; no production signing key.

This remains a personal emulator-verified preview, not a public release. Physical phone/OEM, TalkBack and seven-day owner use remain open, as do E3 hybrid execution, E4 accessibility/glance, and the broader E6 release gate.
