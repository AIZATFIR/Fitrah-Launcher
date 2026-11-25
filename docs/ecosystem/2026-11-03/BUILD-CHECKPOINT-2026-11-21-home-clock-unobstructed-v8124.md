# Home dial unobstructed during an active session — v8124

**Date:** 21 November 2026  
**Package:** `com.aizatfir.fitrah_launcher` 0.5.33 / versionCode 8124  
**Environment:** Android API 36 x86_64 AVD, 1080 × 2400, 420 dpi, system font scale 2.0

## Finding and change

The active-session mini timer was pinned over the bottom of the Home content and covered the analog clock. The goal card already reports the active session and has a **Buka sesi** action, so the overlay duplicated that path while obscuring the clock. Removed the floating Home banner. **Buka sesi** remains the direct route to the timer and its remaining-time display.

## Verified

- Release universal APK built as 0.5.33 / versionCode 8124, min API 24, target API 35. APK v2 signature verifies with the same local Android Debug certificate as v8123 (SHA-256 `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`).
- Installed over v8123. Fitrah stayed the Android HOME role holder and the saved goal/daily choice remained visible.
- At 200% system font, started an attributed Home timer and returned Home. The goal card showed **Sesi berjalan: Latihan LKS**, its goal, and **Buka sesi**; the clock dial had no floating timer covering it. Screenshot: [QA_Home_Active_Session_200pct_v8124.png](../../../release_dist/2026-11-21-home-clock-unobstructed-v8124/QA_Home_Active_Session_200pct_v8124.png).
- Tapping **Buka sesi** returned to the running timer with **Jeda**, **Selesai sekarang**, and **Batalkan timer**. Screenshot: [QA_Timer_Open_From_Home_200pct_v8124.png](../../../release_dist/2026-11-21-home-clock-unobstructed-v8124/QA_Timer_Open_From_Home_200pct_v8124.png).
- Canceled the QA session afterward. Home returned to **Mulai fokus** and retained its previous **35 detik** daily total. Sampled logcat showed no app fatal, Flutter error or ANR.
- Dart formatter and `git diff --check` were clean. Automated tests were not run.

## Artifact

Owner preview APK: [Fitrah_Launcher_0.5.33_universal_v8124.apk](../../../release_dist/2026-11-21-home-clock-unobstructed-v8124/Fitrah_Launcher_0.5.33_universal_v8124.apk). Install over the previous preview; do not uninstall first. This local debug-signed build is not a Play Store release.

## Limits

This is a single AVD interaction at 200% text. Physical phone/OEM behavior, TalkBack, reboot, and sustained daily use remain open. The removed strip displayed the remaining time on Home; users now tap **Buka sesi** to see the live countdown.

