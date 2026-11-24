# Home goal cue simplification and ecosystem preview v8149

**Release:** [Fitrah Launcher v0.5.57-v8149](https://github.com/AIZATFIR/Fitrah-Launcher/releases/tag/v0.5.57-v8149)  
**One-file download:** [Focus Clock Ecosystem 0.5.57 v8149](../../../release_dist/Focus_Clock_Ecosystem_0.5.57_v8149.zip)  
**Install guide and individual files:** [release package folder](../../../release_dist/2026-11-24-focus-clock-v0.5.57-8149/INSTALL.md)

The ambiguous chat shortcut under **TUJUAN UTAMA** was removed from the Home/Jam cue. It only opened an AI chat and distracted from the goal; the goal editor and direct schedule/activity actions remain. Other AI entry points in the app remain available.

## Evidence

- Focused Dart analyzer passed for `home_intent_cue.dart` and `focus_clock_home_view.dart`; `git diff --check` passed. Automated tests were not run.
- Release APK built, v2 signature verified, and installed over the API 36 x86_64 QA emulator's v0.5.54 / 8146. The saved Home goal remained visible, Android still reports Fitrah as the HOME role holder, and Home opened to `MainActivity` after upgrade. Screenshot: [`QA_Fitrah_Home_v8149.png`](../../../release_dist/2026-11-24-focus-clock-v0.5.57-8149/QA_Fitrah_Home_v8149.png).
- A second API 36 x86_64 AVD was already on v0.5.49 / 8141 with Fitrah as HOME. Installing 8149 over it preserved the HOME role; after force-stop, the Android HOME intent resumed Fitrah `MainActivity`. Its goal/action view used neutral empty-state copy, and **Tambah kegiatan** opened a focused, blank text field without a preset example. No activity was saved. Screenshot: [`QA_Fitrah_AddActivity_v8149.png`](../../../release_dist/2026-11-24-focus-clock-v0.5.57-8149/QA_Fitrah_AddActivity_v8149.png). This was an upgrade smoke, not a fresh-install test.
- All three JavaScript web bundles built and passed the required-asset verifier. The tagged GitHub release workflow passed Android, Linux, Windows, and web jobs; it published six platform artifacts and the release SHA-256 list.
- Production domains report v0.5.57 / 8149 and return HTTP 200 for `main.dart.js`: [Fitrah](https://fitrah-web-three.vercel.app/), [Focus Clock](https://focus-clock-web.vercel.app/), and [Sadar](https://sadar-web.vercel.app/).
- [Build manifest](../../../release_dist/2026-11-24-focus-clock-v0.5.57-8149/BUILD-MANIFEST.json) and [local package checksums](../../../release_dist/2026-11-24-focus-clock-v0.5.57-8149/LOCAL_SHA256SUMS.txt) record this build.

## Limits still open

The APK is a personal owner-preview build, not a Play Store release. QA used an emulator, not a physical/OEM handset. Browser and Android data do not sync. Real-provider AI behavior, TalkBack, reboot/Home behavior on the owner's phone, and sustained daily use remain to be checked before claiming the ecosystem is fully done.
