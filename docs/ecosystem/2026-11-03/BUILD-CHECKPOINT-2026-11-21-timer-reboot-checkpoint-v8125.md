# Timer work survives reboot — v8125

**Date:** 21 November 2026  
**Package:** `com.aizatfir.fitrah_launcher` 0.5.34 / versionCode 8125  
**Environment:** Android API 36 x86_64 AVD, 1080 × 2400, 420 dpi, system font scale 2.0

## Finding and change

On v8124, a running timer only wrote its accumulated duration when paused or completed. Same-boot process restoration could use Android elapsed realtime, but a full reboot invalidated that clock snapshot and recovery had only the stale duration from when the timer began. The app correctly paused with an uncertainty notice, but showed 30:00 and lost already measured work.

The timer now durably checkpoints the current accumulated duration every 15 seconds while running, alongside a fresh Android boot/elapsed-realtime snapshot. A reboot still converts the session to a paused, uncertain session, so time while powered off is not counted. Pause, finish, and cancel suppress new checkpoints and wait for an in-flight checkpoint before persisting their own state.

## Verified

- `dart format lib/services/sadar_timer_engine.dart` made no further changes; `git diff --check` clean.
- Universal release APK built as 0.5.34 / versionCode 8125 (74.9 MB), min API 24, target API 35. APK v2 signature verifies with the owner-preview Android Debug certificate SHA-256 `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`.
- Installed over the prior v8124 build. Fitrah remained Android HOME role holder; saved goal and 35-second daily focus total remained intact.
- Started a Home-attributed 30-minute timer, waited through a durable checkpoint, force-stopped and relaunched the app. Home showed the active session and **Buka sesi**; the same-boot timer continued running.
- Rebooted the AVD. Home showed “Waktu sejak aplikasi terakhir berjalan belum dihitung. Lanjutkan untuk menghitung lagi.” Opening the timer showed **29:09 / Lanjut**, preserving the accumulated duration from the checkpoint rather than resetting to 30:00.
- Left the restored timer untouched for 12 seconds; it remained **29:09**, confirming that time after reboot was not silently counted. Canceled the QA session; Home returned to **Mulai fokus** and retained **35 detik** daily focus.
- Sampled logcat showed no app fatal, Flutter error or ANR. Automated tests were not run.
- After origin reconciliation, rebuilt the release APK from the merged v8125 worktree, verified the APK v2 signature, installed it over the existing AVD app, and confirmed storage opened and the Home screen resumed with the saved QA goal and 35-second total. No fatal/FlutterError/ANR in the launch log. Final artifact is the APK in the package folder below; SHA-256 is recorded in `SHA256SUMS`.

Screenshots: [same-boot force-stop restore](../../../release_dist/2026-11-21-timer-reboot-checkpoint-v8125/QA_Home_Force_Stop_Restore_v8125.png), [Home after reboot](../../../release_dist/2026-11-21-timer-reboot-checkpoint-v8125/QA_Home_Reboot_Recovery_v8125.png), [preserved timer duration](../../../release_dist/2026-11-21-timer-reboot-checkpoint-v8125/QA_Timer_Reboot_Preserved_Duration_v8125.png), [paused timer remains unchanged](../../../release_dist/2026-11-21-timer-reboot-checkpoint-v8125/QA_Timer_Remains_Paused_v8125.png), [Home after cancellation](../../../release_dist/2026-11-21-timer-reboot-checkpoint-v8125/QA_Home_After_QA_Cancel_v8125.png).

## Artifact

Owner preview APK: [Fitrah_Launcher_0.5.34_universal_v8125.apk](../../../release_dist/2026-11-21-timer-reboot-checkpoint-v8125/Fitrah_Launcher_0.5.34_universal_v8125.apk). Install over the previous preview; do not uninstall first. See the package folder's `INSTALL.md` and `SHA256SUMS`. This local debug-signed build is not a Play Store release.

## Limits

A normal reboot now restores work recorded by the latest checkpoint. If power is lost before a checkpoint is durable, up to roughly 15 seconds of the current running segment may be lost. This was verified on one API36 x86_64 AVD; physical-phone/OEM behavior, clock edge cases, notification/reconciliation, TalkBack and sustained daily use remain open.
