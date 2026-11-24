# Focus Clock ecosystem owner preview v8155

**Date:** 25 November 2026  
**Version:** 0.5.63 / build 8155  
**Tag:** `v0.5.63-v8155`  
**Release:** [GitHub owner-preview release](https://github.com/AIZATFIR/Fitrah-Launcher/releases/tag/v0.5.63-v8155)  
**All-platform ZIP:** [Download](https://github.com/AIZATFIR/Fitrah-Launcher/releases/download/v0.5.63-v8155/Focus_Clock_Ecosystem_0.5.63_v8155.zip)

## What changed

- Clarified privacy copy inside the legacy AI panel: the selected provider receives messages and goals; the app does not save the conversation.
- The legacy panel has no entry point from the current Fitrah Home or Focus Clock screen, so this copy change is not visible in the primary app. Reconnecting a useful, non-intrusive AI companion remains open. No transcript persistence or provider behavior changed.

## Verification

- Release workflow [45445264646](https://github.com/AIZATFIR/Fitrah-Launcher/actions/runs/45445264646) completed successfully: Android APK (including signature verification), Linux, Windows, and all three web bundles passed.
- All six platform files downloaded from GitHub and passed `SHA256SUMS.txt`. The one-file bundle passed ZIP integrity and local SHA-256 checks; GitHub reports the same bundle digest. The release has nine assets, including the all-platform ZIP and sidecar.
- Fitrah (`dpl_Cg9h9UyDH57sMUVEnJXUTGzPbLq5`), Focus Clock (`dpl_6Nt8t6s7AEVytN6ek9L3UFVowiHM`), and Sadar (`dpl_4EUApCCWaA5a4Rhhfbbo2NhoY5VJ`) production aliases reached READY. Each `/version.json` reports 0.5.63 / 8155.
- Upgraded the existing disposable API36 AVD from v8153 to v8155. Fitrah retained the Android HOME role, and pressing HOME resumed MainActivity with the blank goal and analog dial. The HOME role remained `com.aizatfir.fitrah_launcher`; 2,000 sampled logcat lines had no fatal, FlutterError, ANR, or PlatformException matches. Screenshot `QA_Fitrah_Home_v8155.png` is in the ZIP. No physical phone, AI panel, or live provider request was tested.

**All-platform ZIP SHA-256:** `ab984bebffe1ef7c2e1c450b78e1e0c4bf66ee0b11b02e1dee72ef194cbeb0e8`

## Limits still open

Physical/OEM launcher behavior, TalkBack, sustained daily use, cross-device synchronization, and live-provider conversation remain unverified. This owner preview does not complete ecosystem milestones E0–E11.
