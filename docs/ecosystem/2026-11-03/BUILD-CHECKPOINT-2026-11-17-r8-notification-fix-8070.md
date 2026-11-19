# Checkpoint: release boot receiver and timer reservation — 17 November 2026

## Release-mode crash reproduced and fixed

First runtime installation of v8069 triggered repeated Android crash dialogs during cold boot. The crash buffer showed `ScheduledNotificationBootReceiver` failing in `FlutterLocalNotificationsPlugin.loadScheduledNotifications()` with Gson's `TypeToken must be created with a type argument`. The receiver is part of the release APK's boot path; this was a real release blocker.

Flutter release builds run R8 shrinking. The app now supplies a narrow `android/app/proguard-rules.pro` with Gson's required `Signature` and `TypeToken` retention rules, attached to the Android release build. The merged R8 configuration includes those rules, and the v8070 mapping preserves `TypeToken` and the plugin's anonymous subclass.

Validation on the disposable API36 x86_64 `FocusClock_UI_QA` AVD:

- v8069 crash captured in the crash buffer.
- v8070 installed with the existing app data and launched as `MainActivity`.
- A full AVD reboot after v8070 installation produced no app crash in the cleared crash buffer; the release package remained installed.
- v8070 was relaunched after reboot and `MainActivity` became top-resumed.
- Android's HOME role holder remained `com.aizatfir.fitrah_launcher` after reboot. Opening Android Settings, then pressing the device Home key returned to Fitrah `MainActivity` as top-resumed.
- The rendered Home screen after returning from Settings is `.dart_tool/android-qa/v8070-home-key-after-settings.png`; cold launch screenshot is `.dart_tool/android-qa/v8070-home.png`.

This AVD used a disposable QA profile. No owner-phone data was accessed. Home-role persistence and Home-key return are verified on this API36 emulator; physical devices and OEM boot behavior remain open.

## Timer start race

The shared `SadarTimerEngine` reserves its start path before awaiting the Android clock snapshot. Different concurrent start requests now accept only one active session; duplicate requests for the same habit attach to one session. Regression coverage exercises both cases.

- Focused timer/QuickTimerHub suites: **38 passed**.
- Targeted analyzer: clean.
- `git diff --check`: clean.

## Personal preview package

Folder: `release_dist/2026-11-17-fitrah-launcher-r8-notification-fix-preview-v8070/`.

- APK: `Fitrah_Launcher_0.5.3_universal_v8070.apk`
- SHA-256: `60bb4ca02e7845e69f6d4a1a5d9c03a314b2829eeb6fc70062030d64eec5ef18`
- Package `com.aizatfir.fitrah_launcher`; versionCode8070; minSDK24; targetSDK35; compileSDK36; ABIs arm64-v8a, armeabi-v7a, x86_64.
- APK v2 signature verified. Existing local Android Debug certificate; production signing is not configured.
- v8069 bundle is marked superseded and points to v8070 due to the captured boot crash.

This is not a public release and does not close the ecosystem goal. Physical install/default Home across reboots, TalkBack, real-provider AI use, browser persistence, long-term owner use, cross-app sync, WhatsApp/MCP and public open-source distribution remain open.
