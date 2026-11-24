# Focus Clock ecosystem usable owner preview v8153

**Date:** 24 November 2026  
**Version:** 0.5.61 / build 8153  
**Source:** v8153 source commit (to be recorded after release)
**Release:** [v0.5.61-v8153](https://github.com/AIZATFIR/Fitrah-Launcher/releases/tag/v0.5.61-v8153)  
**One-file package:** [Download the ecosystem ZIP](https://github.com/AIZATFIR/Fitrah-Launcher/releases/download/v0.5.61-v8153/Focus_Clock_Ecosystem_0.5.61_v8153.zip)  
**Install notes and checksums:** included in the ZIP and on the [release page](https://github.com/AIZATFIR/Fitrah-Launcher/releases/tag/v0.5.61-v8153)

## What changed

- App drawer alphabet scrubbing previews one letter while held and, on release, restores the full list at the selected app section (commit `ebaaaeb`, release v8151).
- Removed the floating free-text “Tanya AI” prompt from both the full clock page and Simple Mode. It routed text through voice-command handling and duplicated the dedicated AI chat and activity scheduling input. The scheduling input, full AI conversation surface, and clock screen's dedicated AI chat shortcut remain available.
- Clarified the AI Assistant setting subtitle so it describes the remaining chat shortcut.

## Verification

- Fresh scoped analyzer passed for the changed Simple Mode and Settings files; `git diff --check` passed. No automated tests were run for this deletion-only UI change.
- v8153 multiplatform release workflow, production web deployment, platform checksums, and all-platform ZIP verification will be recorded here after completion.

## Limits still open

No physical/OEM phone was available. The earlier v8152 emulator run does not verify the Android Home chooser, vendor launcher restrictions, TalkBack, or long-term reliability. Android/browser data remain separate; real-provider behavior and a sustained daily-use trial are still open. This is an owner preview, not a Play Store build or completion of ecosystem milestones E0–E11.
