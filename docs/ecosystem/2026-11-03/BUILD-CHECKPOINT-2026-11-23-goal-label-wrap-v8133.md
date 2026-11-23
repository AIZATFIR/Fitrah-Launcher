# Large-text Home action labels and v8133 owner preview — 23 November 2026

At 200% Android text scale, the Home action dialog clipped “Hubungkan tujuan (opsional)” and the selected long goal. Shortened the field label to **Tujuan** and allowed both dropdowns to grow to their content; long selected goal values now wrap. The Home visual style and goal remain unchanged.

## Verification

- Targeted `flutter analyze --no-pub lib/features/launcher/widgets/home_intent_cue.dart`: no issues.
- Universal Android release APK built as 0.5.42 / 8133; package `com.aizatfir.fitrah_launcher`, min API 24, target API 35. APK v2 signature verifies under the established owner-preview certificate SHA-256 `b8af9d95…34fe3e`.
- API36 x86_64 `FocusClock_UI_QA` upgraded in place with Fitrah still Android HOME and font scale 2.0. The action picker displays the selected goal `Menang LKS Nasional QA` fully on two lines, and its field label is complete.
- Runtime Home loop: selected `Latihan LKS` linked to the QA goal; started the 30-minute focus timer; force-stopped and relaunched Fitrah; Home restored the active session; **Buka sesi** returned to the running timer at 29:22. Canceled the QA session and restored the prior empty daily selection. Sampled logs showed no fatal exception, ANR or Flutter error.
- `npm run build:focus` and required offline asset verification passed. Wasm dry run continues to flag existing Isar, secure-storage and TTS incompatibilities.
- Production deployment `dpl_E6SwD5uuBS8kd6mW1WdiStwpwrSt` is READY. Root and `main.dart.js` return HTTP 200; `/version.json` reports 0.5.42 / 8133. APK signature, web ZIP integrity, hashes and `git diff --check` verified.
- Automated tests and physical phone/OEM checks were not run for this slice.

Runtime screenshots are retained locally under `.dart_tool/android-qa/v8132/goal-field-v8133-steady.png` and `timer-return-v8133.png`.

This is a personal owner preview. Physical device, TalkBack, live provider and sustained-use gates remain open. Android and browser data still do not sync.

[Download and install notes](../../../release_dist/2026-11-23-goal-label-wrap-v8133/INSTALL.md).
