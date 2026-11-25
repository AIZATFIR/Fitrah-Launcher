# Home links a new daily action to the active goal — v8126

**Date:** 21 November 2026  
**Source revision:** `b67c993cd70cc1ab1eb5d515867259267ef98342`  
**Android package:** `com.aizatfir.fitrah_launcher`  
**Version:** 0.5.35 / versionCode 8126  
**Web deployment:** `dpl_F73MhppKnx7svtfjewJu2zHRputB`

## What changed

When the user makes a new daily choice, the existing “Hubungkan tujuan” field starts with the active pinned Home goal. “Tanpa tujuan” remains a clear option. Existing choices are not rewritten; a saved cleared choice stays cleared when reopened. The analog clock and Bookpaper colors/layout were not changed.

## Verification

- `flutter build apk --release --no-pub` succeeded. Universal APK v8126 was signed by the same Android Debug owner-preview certificate as v8125.
- API 36 x86_64 AVD upgraded v8125 to v8126. The Fitrah HOME role, QA goal, daily action, timer total, and storage remained present.
- Cleared the saved QA choice, reopened the action picker, and confirmed it stayed at “Kosongkan pilihan” / “Tanpa tujuan.” Restored the previous action and goal link afterward.
- On a fresh isolated web origin, added a synthetic pinned goal and quick-captured a task. The daily-action picker showed the pinned goal as selected, and its menu still offered “Tanpa tujuan.”
- `npm run build:focus` succeeded and verified the required web/offline assets. The production Vercel deployment is READY. The alias, `version.json`, service worker, and SQLite WASM returned HTTP 200; web version reports 0.5.35 / build 8126.
- No automated tests were run for this slice.

## Downloads and live web

- [Download the owner-preview APK](../../../release_dist/2026-11-21-focus-clock-home-goal-default-v8126/Fitrah_Launcher_0.5.35_universal_v8126.apk)
- [Install instructions](../../../release_dist/2026-11-21-focus-clock-home-goal-default-v8126/INSTALL.md)
- [APK checksum and manifest](../../../release_dist/2026-11-21-focus-clock-home-goal-default-v8126/SHA256SUMS)
- [Focus Clock web](https://focus-clock-web.vercel.app/)

APK SHA-256: `6c8301f888f3314fee4aa5bc1933e35109b4dac2ffecc7602710e5c3f01e5176`  
The APK is debug-signed for personal upgrade/testing, not a public Play Store release.

## Limits still open

The Android install was verified on one API 36 x86_64 emulator, not a physical handset/OEM. A daily-use trial and complete launcher/OEM verification remain open. The live web app uses browser-local storage; its data is not synced to the Android installation yet, so “web is deployed” does not mean ecosystem sync is complete. AI live-provider and other later roadmap gates also remain open.
