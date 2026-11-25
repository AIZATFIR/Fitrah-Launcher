# Focus Clock daily-use checkpoint v8097

**Date:** 20 November 2026
**Version:** 0.5.18 (versionCode 8097)
**Purpose:** A personal Android checkpoint for using the goal → today's action → focus timer → recorded activity loop from Fitrah Home.

## What is ready to try

- Goal-first Home with an explicit action for today, a shared analog clock face, visible three-destination navigation, today's habit/schedule list, and the actual Android app drawer.
- Select an existing habit or task, optionally link it to the saved goal, and start its timer from Home. The shared Sadar timer records completed activity against the saved item.
- Recurring agenda edits preserve occurrence identity and recorded session history, including overnight blocks.
- Manual use works without an AI key. The assistant can use a provider configured by the user; goal plans remain editable proposals until the user applies them. The checkpoint does not include a verified live provider request.
- A static web build is included for previewing the same Focus Clock UI in a browser.

## Verification

- Full serial Flutter suite: **435 passed, 0 failed**.
- `flutter analyze --no-pub`: five info-level lints in existing unrelated files; no warning/error diagnostics.
- Universal Android release APK and Flutter web release build succeeded.
- APK package `com.aizatfir.fitrah_launcher`, minSdk 24, targetSdk 35, versionCode 8097. APK v2 signature matches the previous personal preview's local Android Debug certificate.
- API 36 x86_64 QA AVD: installed over the prior preview; Fitrah was selected as HOME during the check; goal and selected action were present. Selected **Latihan LKS 30 menit**, linked it to **Menang LKS National IT Software Solution**, started the 30-minute timer while notification access was denied, saw 29:57 with no permission dialog, canceled, and navigated Jam → Aplikasi → Hari Ini. Home retained the goal/action and the app returned to MainActivity on Home. Nexus Launcher was restored as the AVD default afterward.
- `git diff --check`, APK signature/metadata check, web ZIP integrity, and SHA-256 checks passed.
- Screenshots: `release_dist/2026-11-20-focus-clock-daily-use-v8097/`.

## Install and limits

Install `Fitrah_Launcher_0.5.18_universal_v8097.apk` on Android 7.0/API 24 or newer. To preserve current app data, install it over the existing Fitrah preview and do not uninstall first. Android may ask you to choose Fitrah as the Home app; that choice can be changed later in Android's Default apps settings. The APK contains no sample data; the LKS example appears only in QA screenshots. A fresh install starts with the user's own setup.

This is a personal preview signed with the local debug certificate, not a Play Store release. The owner's physical phone/OEM, TalkBack, extended daily use, browser runtime and web persistence were not checked. Live AI calls require the owner's provider configuration and were not exercised. Sync, WhatsApp, MCP and the remaining E0–E11 ecosystem gates remain open; this checkpoint does not claim the full ecosystem is finished.

Downloads and installation steps are in [the v8097 release folder](../../../release_dist/2026-11-20-focus-clock-daily-use-v8097/INSTALL.md).
