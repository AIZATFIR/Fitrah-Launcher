# Focus Clock ecosystem usable owner preview v8153

**Date:** 24 November 2026  
**Version:** 0.5.61 / build 8153  
**Source:** `db7cf5a3` (`fix: remove redundant quick AI prompt everywhere`)
**Release:** [v0.5.61-v8153](https://github.com/AIZATFIR/Fitrah-Launcher/releases/tag/v0.5.61-v8153)  
**One-file package:** [Download the ecosystem ZIP](https://github.com/AIZATFIR/Fitrah-Launcher/releases/download/v0.5.61-v8153/Focus_Clock_Ecosystem_0.5.61_v8153.zip)  
**Install notes and checksums:** included in the ZIP and on the [release page](https://github.com/AIZATFIR/Fitrah-Launcher/releases/tag/v0.5.61-v8153)

## What changed

- App drawer alphabet scrubbing previews one letter while held and, on release, restores the full list at the selected app section (commit `ebaaaeb`, release v8151).
- Removed the floating free-text “Tanya AI” prompt from both the full clock page and Simple Mode. It routed text through voice-command handling and duplicated the dedicated AI chat and activity scheduling input. The scheduling input, full AI conversation surface, and clock screen's dedicated AI chat shortcut remain available.
- Clarified the AI Assistant setting subtitle so it describes the remaining chat shortcut.

## Verification

- Fresh scoped analyzer passed for the changed Simple Mode and Settings files; `git diff --check` passed. No automated tests were run for this deletion-only UI change.
- GitHub Actions release run [45434240365](https://github.com/AIZATFIR/Fitrah-Launcher/actions/runs/45434240365) passed Android, Linux, Windows, and all three web bundles. Android v2 signature verification passed and retained the owner-preview certificate fingerprint `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`. The release has six platform assets, `SHA256SUMS.txt`, the all-platform ZIP, and its sidecar checksum. All six platform checksums passed locally; ZIP integrity passed, and the uploaded asset digest `9e8733608b004fd839264de69080aefd59b3c2f52ae9e7fc1b2529a1fd197e91` matches the local ZIP.
- Production deployments reached READY; authenticated production requests returned HTTP 200 for each `main.dart.js`: Fitrah `dpl_AoWDwP6HM6ecXwrwHmSJ5N1v18kx`, Focus Clock `dpl_3TfQTmwr94aKofyXC8T5VKwGx8N4`, and Sadar `dpl_9ofEFqYjLBQMAXvvCUjYiEJKLPBw`.
- The three bundled QA screenshots and HOME/app-drawer observations are from the v8152 AVD run. No fresh AVD smoke was run for v8153; this slice removes a floating prompt and does not change launcher behavior.

## Limits still open

No physical/OEM phone was available. The earlier v8152 emulator run does not verify the Android Home chooser, vendor launcher restrictions, TalkBack, or long-term reliability. Android/browser data remain separate; real-provider behavior and a sustained daily-use trial are still open. This is an owner preview, not a Play Store build or completion of ecosystem milestones E0–E11.
