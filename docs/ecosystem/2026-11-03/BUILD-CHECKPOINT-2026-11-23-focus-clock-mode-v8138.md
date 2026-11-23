# Focus Clock web opens on Jam — v8138

**23 November 2026 · Fitrah Launcher 0.5.46 / build 8138**

`build:focus` already selected `APP_MODE=focus`, but the shared Fitrah shell always started at Hari Ini. The shell now reads that mode: Focus Clock opens on **Jam**; Fitrah/default still opens on **Hari Ini**. Both remain in the same four-destination Bookpaper UI and use the same local store implementation.

The new shell regression failed before the fix (selected index 1 instead of 0). All 13 tests in `test/fitrah_launcher_test.dart` pass afterward; scoped analyzer and `git diff --check` are clean. APK 0.5.46 / 8138 built and its package/version and APK v2 signature verified. Fitrah, Focus Clock and Sadar JavaScript web bundles built and passed the bundle verifier; each production deployment reached READY and each public alias returned HTTP 200 with version 8138. The Focus Clock production page was opened in a browser: the analog Bookpaper dial renders and **Jam** is selected.

Artifacts and checksums: [v8138 owner package](../../../release_dist/2026-11-23-focus-clock-web-entry-v8138/INSTALL.md).

This is still a debug-signed owner preview. It does not close physical/OEM, TalkBack or seven-day use gates. Android and each web origin keep separate local data; cross-device sync remains unimplemented. Flutter's Wasm dry run still reports existing Isar, secure-storage and TTS incompatibilities; the JavaScript web target is the deployed build.
