# Android Home setup beside the goal — v8141

23 November 2026 · `0.5.49+8141` · source `e1af3af`

Fitrah now shows a compact **Jadikan layar utama** action inside the Home goal card when Android confirms Fitrah is not the default Home app. It calls the existing Android system chooser. Canceling or choosing another launcher does not claim success; the action hides only when status reports Fitrah as Home. It is omitted off Android and while status is unknown. Detailed status remains in Launcher Settings.

## Verification

- Focused CTA, default-Home control, and Home intent widget suites: **38 passed**.
- CTA remains visible and usable at 320dp / 200% text; 48dp minimum tap target.
- Analyzer: no errors or warnings; 5 existing info diagnostics in unrelated files. `git diff --check` clean.
- Release APK: `com.aizatfir.fitrah_launcher`, version `0.5.49`, code `8141`, min API 24. APK v2 signature verified; owner-preview Debug certificate SHA-256 `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`.
- Fitrah, Focus Clock, and Sadar JavaScript bundles each pass `scripts/verify_web_bundle.sh` and carry `0.5.49 / 8141`.
- Clean API36 x86_64 AVD: installed v8141, saw the CTA, opened Android's “Set Fitrah Launcher as your default home app?” chooser, selected Fitrah, confirmed `android.app.role.HOME` holder is `com.aizatfir.fitrah_launcher`, and Android HOME returned to `MainActivity`. After selection, the CTA disappeared. Sampled logcat had no fatal exception, FlutterError, or ANR.
- Screenshots: [CTA before selection](../../../release_dist/2026-11-23-home-default-cta-v8141/QA_Fitrah_Home_v8141_setup.png), [Home after Fitrah selection](../../../release_dist/2026-11-23-home-default-cta-v8141/QA_Fitrah_Home_v8141_default.png).

## Production deployments

- Fitrah: `dpl_44eANQDVnvw5eGSJPfrx1o7aDNqB` — [fitrah-web-three.vercel.app](https://fitrah-web-three.vercel.app/)
- Focus Clock: `dpl_BWpveaNPv69CrwLCi2daWbGjPgAX` — [focus-clock-web.vercel.app](https://focus-clock-web.vercel.app/)
- Sadar: `dpl_GhpgWD3jb2TSWM6s2wfb6QttP9it` — [sadar-web.vercel.app](https://sadar-web.vercel.app/)

All three production aliases, `/main.dart.js`, and `/sqlite3.wasm` return HTTP 200; each `/version.json` reports `0.5.49 / 8141`.

## Downloads and limits

- [Complete ecosystem bundle](../../../release_dist/2026-11-23-home-default-cta-v8141/Focus_Clock_Ecosystem_0.5.49_v8141.zip)
- [Android APK](../../../release_dist/2026-11-23-home-default-cta-v8141/Fitrah_Launcher_0.5.49_universal_v8141.apk)
- [Install guide](../../../release_dist/2026-11-23-home-default-cta-v8141/INSTALL.md) · [APK/web SHA-256 list](../../../release_dist/2026-11-23-home-default-cta-v8141/SHA256SUMS) · [bundle SHA-256](../../../release_dist/2026-11-23-home-default-cta-v8141/BUNDLE.SHA256)

The APK uses a local debug key and is for owner preview, not Play Store distribution. Physical/OEM behavior, TalkBack, live AI provider use, sustained owner use, and cross-device sync remain unverified or unimplemented. Android and web keep separate local data.
