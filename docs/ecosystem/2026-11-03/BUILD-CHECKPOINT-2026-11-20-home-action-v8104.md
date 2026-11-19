# Home action clarity checkpoint v8104

**Date:** 20 November 2026
**Version:** 0.5.25 (versionCode 8104)
**Purpose:** Make the already-selected next action's secondary control clear.

## Change

When a valid action is selected, Home labels its secondary control **Ganti tindakan**. Empty, completed, or unavailable choices continue to use **Pilih tindakan hari ini**. The primary action stays **Mulai fokus**. This removes the ambiguous second “Pilih” label while preserving the goal/action/timer layout.

## Verification

- Scoped analyzer and formatter checks for `home_intent_cue.dart`: clean.
- Universal release APK and Focus Clock web JavaScript bundle built. APK package/version and v2 signature verified.
- Disposable API36 x86_64 `FocusClock_UI_QA` AVD updated 8103→8104 in place. Cold launch succeeded in 2.47s. Saved goal and chosen action remained visible; the secondary label rendered **Ganti tindakan**. **Mulai fokus** opened the linked 30-minute timer (29:58 shown); cancel returned to Home. No Flutter/Android fatal was found in the sampled log.
- Favoriting Chrome displayed it once under Favorit; searching Chrome showed one result. QA favorite was removed. Nexus Launcher was restored as HOME role holder; the QA AVD was shut down.
- Automated tests were not run for this checkpoint.

QA captures and hierarchy are local under `.dart_tool/android-qa/v8104/`.

## Limits

This verifies one emulator path only. Physical/OEM launcher setup, reboot, TalkBack, large text, screen-time behavior, real provider response, and seven-day use remain open. This is not ecosystem completion or a production-signed release.

Download: [APK and web bundle](../../../release_dist/2026-11-20-focus-clock-home-action-v8104/Fitrah_FocusClock_Preview_v8104.zip).
