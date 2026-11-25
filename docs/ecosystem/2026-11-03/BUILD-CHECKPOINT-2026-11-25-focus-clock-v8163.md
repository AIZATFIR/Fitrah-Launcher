# Focus Clock / Fitrah owner preview v8163

**Date:** 25 November 2026  
**Version:** 0.5.71 / build 8163

## Timer reminder follows notification permission changes

When an Android user leaves the app to enable or disable notifications, the active timer now reconciles its completion reminder when the app resumes. This preserves the existing rule: focus timer reminders never request permission automatically; they schedule only when Android notifications are already allowed. Pause, completion, cancellation and uncertain-recovery behavior still cancel the reminder.

## Evidence

- `dart format lib/services/sadar_timer_engine.dart`: clean.
- `flutter analyze lib/services/sadar_timer_engine.dart`: no issues.
- `git diff --check`: clean.
- Release APK 0.5.71 / 8163 built successfully (74.6 MB). A device/emulator was not connected during this run, so install and permission round-trip could not be repeated.
- Follow-up API 36 `FocusClock_UI_QA` smoke installed the same APK without clearing its saved QA profile. Android reports `com.aizatfir.fitrah_launcher` as the HOME role holder; the Home key returned to Fitrah. With Android font scale at 2.0, the top clock card and saved goal/session remained visible without a sampled fatal, Flutter error, or ANR. The profile contains a synthetic LKS QA goal and paused QA session, not a clean-first-run state. Screenshot: `/tmp/fitrah-home-role.png`.
- Focus Clock production deployment `dpl_58iKGxitfzKC21W24U5vbaqUpyc7`, Fitrah `dpl_3rYTRTx8bCd8SYRT5VavHMvksWba`, and Sadar `dpl_Gb58L3DvJs23Z2c9gBhdWVfGs774` reached READY. Their production `/version.json` endpoints all report 0.5.71 / 8163. Fitrah deployment protection remains enabled.
- Tagged workflow [45636119802](https://github.com/AIZATFIR/Fitrah-Launcher/actions/runs/45636119802) passed Android signing/build, Windows, Linux, web bundle and release publishing. The [release page](https://github.com/AIZATFIR/Fitrah-Launcher/releases/tag/v0.5.71-v8163) lists all eight assets: APK, Windows/Linux archives, three web ZIPs, all-platform ZIP, and SHA256SUMS.
- Automated suites were not run.

## Remaining ecosystem gates

This remains an owner preview. Android physical/OEM behavior, TalkBack, notification behavior on physical devices, sustained daily use, Firebase sync implementation (owner chose Firebase with optional login; no sync/upload is active yet), a live AI provider call, public distribution signing, and later agent/WhatsApp/MCP milestones remain open.
