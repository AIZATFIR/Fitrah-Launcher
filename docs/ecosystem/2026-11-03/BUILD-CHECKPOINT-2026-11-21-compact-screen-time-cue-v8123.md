# Fitrah screen-time cue compact sizing — v8123

**Date:** 21 November 2026  
**Package:** `com.aizatfir.fitrah_launcher` 0.5.32 / versionCode 8123  
**Environment:** Android API 36 x86_64 AVD, 1080 × 2400, 420 dpi, system font scale 2.0

## Change

The floating screen-time cue now uses a fixed 11 dp visual text size instead of 11 sp. Android font scaling no longer expands this deliberately compact overlay. Its full `contentDescription` still announces the measured minutes and the action to return to goals. Cue and gentle limit remain opt-in; no defaults or permission behavior changed.

## Verified

- Release APK built as a universal package; metadata reports min API 24 and target API 35.
- APK v2 signature verifies with the existing local Android Debug certificate (SHA-256 `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`), so it upgrades the prior owner preview.
- Installed over v8122 on the API 36 AVD. Android still assigns Fitrah the HOME role; the saved QA goal and daily choice remain visible after upgrade.
- Enabled the cue on the release package at 200% font scale. The pill remains compact and displays measured minutes plus **Tujuan**; screenshot: [QA_Screen_Time_Cue_200pct_v8123.png](../../../release_dist/2026-11-21-fitrah-screen-time-compact-v8123/QA_Screen_Time_Cue_200pct_v8123.png).
- Disabled the cue after QA. The captured Home has no overlay; screenshot: [QA_Home_200pct_v8123.png](../../../release_dist/2026-11-21-fitrah-screen-time-compact-v8123/QA_Home_200pct_v8123.png).
- Started a QA timer, force-stopped the app in the same device boot, and reopened it through Android Home. The saved session returned to Home and then to its timer view; the countdown had continued in real time and **Jeda** was available. The QA session was canceled afterward, and the Home duration remained at its prior 35 seconds. Screenshots: [before process stop](../../../release_dist/2026-11-21-fitrah-screen-time-compact-v8123/QA_Timer_Before_Process_Stop_200pct_v8123.png) and [recovered session](../../../release_dist/2026-11-21-fitrah-screen-time-compact-v8123/QA_Timer_Recovered_200pct_v8123.png).
- Sampled logcat after the timer and cue checks contained no app `FATAL EXCEPTION`, Flutter error, or ANR.

## Artifact

Owner preview APK: [Fitrah_Launcher_0.5.32_universal_v8123.apk](../../../release_dist/2026-11-21-fitrah-screen-time-compact-v8123/Fitrah_Launcher_0.5.32_universal_v8123.apk). Install over the previous preview; do not uninstall first. This local debug-signed build is not a public Play release.

## Limits

The runtime check used one emulator and synthetic UsageStats. It does not establish physical-device/OEM behavior, TalkBack, real screen-time accuracy, reboot recovery, or sustained daily use. The full test suite was not rerun for this native text-size change; verification here is release compilation, signature verification, install/upgrade, and emulator interaction.

