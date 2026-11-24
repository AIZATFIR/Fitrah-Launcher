# Focus Clock ecosystem owner preview v8154

**Date:** 24 November 2026  
**Version:** 0.5.62 / build 8154  
**Source:** v8154 source commit (record after release)  
**Release:** [v0.5.62-v8154](https://github.com/AIZATFIR/Fitrah-Launcher/releases/tag/v0.5.62-v8154)  
**One-file package:** [Download the ecosystem ZIP](https://github.com/AIZATFIR/Fitrah-Launcher/releases/download/v0.5.62-v8154/Focus_Clock_Ecosystem_0.5.62_v8154.zip)

## What changed

- Removed the redundant “Aplikasi tersembunyi” title from the hidden-apps sheet; app names or the empty state provide the content. The drawer's icon retains its accessible tooltip.
- v8153 removed the ambiguous free-text AI prompt from the clock and Simple Mode while retaining the dedicated AI chat and schedule entry.
- Web builds now skip Flutter's Wasm dry-run, which reported unsupported native dependencies and spent roughly a minute per bundle before compiling the JavaScript web app.

## Verification

- Fresh scoped analyzer and shell syntax check: pending.
- v8153 Android HOME smoke on a clean API 36 AVD: installed the signed release APK, selected Fitrah through Android's Default Home settings, saw the empty goal cue without example text, opened the clock, opened the app drawer, launched Chrome, and returned to Fitrah with the Android Home key. RoleManager reported Fitrah as HOME; the sampled logcat had no app fatal, FlutterError, ANR, or PlatformException. Screenshots are included in the local release package when prepared.
- v8154 release workflow, APK signature, production web deployments, package checksums, and runtime check of the removed hidden-apps heading: pending.

## Limits still open

No physical/OEM phone or TalkBack walkthrough was available. Android/browser data remain separate; live-provider behavior, cross-device sync, and sustained daily use remain open. This owner preview does not close ecosystem milestones E0–E11.
