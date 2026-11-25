# Quick capture lifecycle repair — v8131

Updated Home quick-capture so its text controller remains alive through the dialog route's closing animation. The field still opens empty, preserves its current save/retry/cancel behavior, and no longer triggers Flutter's “TextEditingController was used after being disposed” exception. Added stable keys for the Home note and task input; tests now locate those fields without relying on example placeholder text, and the obsolete expectation for the old Home banner/title was aligned to the approved goal cue and unobstructed dial.

## Verification

- Full Flutter suite: **456 tests passed**.
- `flutter analyze --no-pub`: no errors or warnings; five existing info notices remain in untouched files.
- Universal Android release APK built as 0.5.40 / build 8131. Package `com.aizatfir.fitrah_launcher`, min API 24, target API 35. APK v2 signature verifies with the same local owner-preview certificate (`b8af9d95…34fe3e`) used by v8130.
- API 36 x86_64 `FocusClock_UI_QA` upgraded in place from v8130. First-install time remained `2026-11-16 10:41:54`; Fitrah remained Android HOME. At font scale 2.0, the saved QA goal and clock face were visible. Sampled logcat had no fatal exception, ANR or Flutter error.
- `npm run build:focus` produced and verified the standard JavaScript web bundle. The Wasm dry-run still reports the known Isar, secure-storage and TTS incompatibilities.
- Production deployment `dpl_FTmnyQ4aRyzeiQWRUS6dpyGfssEJ` is READY at [focus-clock-web.vercel.app](https://focus-clock-web.vercel.app/). Root HTTP response is 200; `/version.json` reports 0.5.40 / 8131.
- APK/web ZIP/screenshot checksums verify; the web ZIP passes archive integrity.

## Limits

No physical handset/OEM, TalkBack, live AI provider, or multi-device sync test was available. Android and browser data remain separate. This is an owner preview, not a Play Store release or completion of the ecosystem.

[Owner-preview download and install instructions](../../../release_dist/2026-11-23-quick-capture-v8131/INSTALL.md).
