# Checkpoint: hybrid habit timer and v8072 preview — 17 November 2026

## Hybrid execution

Sadar Today previously started a normal `target × 60` YPT timer for hybrid habits. It now starts one shared session whose total countdown contains all work intervals and only the rests between sets. The timer session persists the set count, work seconds and rest seconds. The focus screen presents the active set, work/rest phase and phase countdown. Pause/reopen retains the plan.

At completion, the engine converts total elapsed session time into actual focused seconds and fully completed sets. Rest time is excluded. Sadar records set progress in `valueCompleted`, stores the target-set snapshot, and marks the dated habit complete only after the target set count is met. A partial early finish keeps its completed-set evidence. Existing timer schema property IDs remain stable; hybrid properties use IDs 20–22. Live model and backup codecs serialize the new fields; imports without them default to a non-hybrid session.

## Verification

- `flutter test --no-pub --concurrency=1 test/sadar_timer_state_machine_test.dart test/sadar_ypt_shared_timer_test.dart test/sadar_timer_view_session_test.dart test/sadar_repository_test.dart test/live_model_codec_test.dart test/focus_clock_backup_codec_test.dart --reporter expanded` — **78 passed**.
- `flutter test --no-pub test/isar_service_persistence_test.dart --reporter expanded` — **10 passed**; hybrid plan/session data and partial set contribution survive native Isar close/reopen.
- `flutter analyze --no-pub` — no errors; 5 info diagnostics remain in unrelated files: one async BuildContext lint, three missing-braces lints, and one missing-braces lint in preset editor.
- `git diff --check` — clean at the time of the check.
- `dart run build_runner build` emitted generated files but exited nonzero on the existing annotation resolution error in `tool/web_storage_spike/test/storage_test.dart`. `tool/fix_isar_schema_ids.dart` was updated and run; generated unrelated model files were restored because they were clean before generation. The TimerSession generated serializer/property switch and existing IDs were checked by the native persistence test.

## Personal Android preview

Release APK version `0.5.3+8072`, package `com.aizatfir.fitrah_launcher`, min SDK 24, target SDK 35, universal ABI set. Flutter release build completed in 171.9 seconds. APK v2 signature verified; SHA-256:

`1ad533ae7bee4c828ee38a204a18127978c76226bab2710131ff1ea94ba2a8fc`

Artifact directory: `release_dist/2026-11-17-fitrah-launcher-hybrid-timer-preview-v8072/`.

Installed and launched on the disposable Android 36 x86_64 AVD. MainActivity was resumed and the checked Flutter/AndroidRuntime log window had no errors. Screenshot: `.dart_tool/android-qa/v8072-home.png`. This verifies APK installation/startup, not the hybrid screen interaction; hybrid behavior is covered by automated tests. The APK uses the Android Debug certificate and is a personal preview only. No physical phone, TalkBack, OEM behavior or extended daily-use verification.

## Remaining scope

The Fitrah Home projection still reports hybrid as unsupported. The next compatible slice is Home's hybrid action/finish flow using this same shared timer and saved set contract. Progression undo/history, screen-time overlay on real launchers, Android accessibility/OEM checks, broader E0–E6 gates, cross-device sync, AI provider paths, WhatsApp/MCP integrations, licensing and public release remain open. This checkpoint does not close the ecosystem goal.
