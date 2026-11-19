# Checkpoint — focus timer starts without notification prompt v8092

**Date:** 19 Nov 2026
**Version:** 0.5.17+8092
**Download:** [Android install notes and evidence](../../../release_dist/2026-11-19-focus-timer-no-prompt-v8092/INSTALL.md)

## Change

The timer reminder is optional. When Android notifications are disabled, starting a focus session now skips only the timer reminder and does not request permission. Activity reminders keep their separate permission request in the explicit schedule flow. Timer state and recording are unchanged.

## Verification

- Regression-first: the focused notification test failed before the implementation because it observed `requestNotificationsPermission` during `scheduleTimerCompletion`.
- Notification service suite after the fix: **4 passed**, including denied and enabled notification paths and explicit activity scheduling.
- Flutter Android release build succeeded as 0.5.17+8092. APK v2 signature verified; certificate fingerprint matches v8090/v8091.
- On the API36 x86_64 AVD, v8092 installed over v8085 and retained the saved LKS goal. `POST_NOTIFICATION` remained denied (`appops: ignore`). Selecting **Latihan LKS 30 menit**, linking it to the LKS goal, and pressing **Mulai fokus** opened the timer at 29:57 with no permission prompt. AVD cleanup canceled the QA session and restored Nexus Launcher as HOME.
- Screen-time cue follow-up on that AVD: enabled Usage Access and overlay permission through the explained opt-in flow; verified the cue over Chrome, tuck/restore, and return to Fitrah's goal when tapped. Evidence is packaged in the release folder. Emulator usage minutes are synthetic and do not show phone accuracy.

## Remaining

This confirms one API36 emulator path only. Physical/OEM behavior, permission settings for scheduled activity reminders, TalkBack and sustained owner use remain open. The wider E0–E11 ecosystem objective remains active.
