# Focus Clock ecosystem usable owner preview v8152

**Date:** 24 November 2026  
**Version:** 0.5.60 / build 8152  
**Source:** `e06bb34` (`fix: remove duplicate clock AI prompt`)  
**Release:** [v0.5.60-v8152](https://github.com/AIZATFIR/Fitrah-Launcher/releases/tag/v0.5.60-v8152)  
**One-file package:** [Download the ecosystem ZIP](https://github.com/AIZATFIR/Fitrah-Launcher/releases/download/v0.5.60-v8152/Focus_Clock_Ecosystem_0.5.60_v8152.zip)  
**Install notes and checksums:** included in the ZIP and on the [release page](https://github.com/AIZATFIR/Fitrah-Launcher/releases/tag/v0.5.60-v8152)

## What changed

- App drawer alphabet scrubbing previews one letter while held and, on release, restores the full list at the selected app section (commit `ebaaaeb`, release v8151).
- Removed the floating “Gemini AI Focus” free-text prompt from the full Focus Clock page because it duplicated the main AI chat and natural-language schedule entry. The scheduling input, main AI conversation surface, and Simple Mode quick command remain available.

## Verification

- Focused Dart analysis passed for the changed clock page; `git diff --check` passed. No automated tests were run.
- The local v8151 Android APK and GitHub v8152 APK passed v2 signature verification; the release APK has the established owner-preview SHA-256 certificate fingerprint `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`.
- GitHub Actions run [45426062483](https://github.com/AIZATFIR/Fitrah-Launcher/actions/runs/45426062483) completed successfully for Android, Linux, Windows, and web. The release publishes six platform files plus `SHA256SUMS.txt`; every artifact checksum passed.
- Production deployments report v0.5.60 / 8152 and return HTTP 200 for `main.dart.js`:
  - Fitrah: `dpl_37jeunjhyzWowxBZs8oATLB3R7Vu`
  - Focus Clock: `dpl_BsK6RicphCTHk2X78zppY9nMDqPk`
  - Sadar: `dpl_PFGpJBwrNRLoZsFybQhrGUjseb7n`
- Opened the deployed Focus Clock page in the browser and confirmed the clock rendered without the floating free-text prompt.
- The six-artifact bundle checksums and combined ZIP checksum were verified. GitHub's uploaded asset SHA-256 digest matches the local ZIP checksum. Package details are included in the ZIP's `BUILD-MANIFEST.json`.
- A temporary Android 16/API 36 x86_64 AVD at 1080x2400 installed the release APK. RoleManager reported Fitrah as HOME, and pressing HOME opened `MainActivity`. The role was assigned through shell, not Android's chooser. The drawer showed actual installed apps; holding the scrubber at S showed only Safety and Settings, then release restored the full list with S still selected and visible. Launching Android Settings from the drawer and pressing HOME returned to Fitrah. The sampled logcat tail had no FATAL EXCEPTION, FlutterError, ANR, or PlatformException match. Captures are in the local release folder and the updated one-file package.

## Limits still open

No physical/OEM phone was available. The emulator run does not verify the Android Home chooser, vendor launcher restrictions, TalkBack, or long-term reliability. Android/browser data remain separate; real-provider behavior and a sustained daily-use trial are still open. This is an owner preview, not a Play Store build or completion of ecosystem milestones E0–E11.
