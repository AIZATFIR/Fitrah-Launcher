# Home agenda cue and owner preview — v8140

23 November 2026 · `0.5.48+8140` · source `0f9a40f65ff3676b94b34e953e65d5b27ce9c049`

Home no longer repeats the empty-day message in a second agenda strip. The upcoming strip is hidden when no unfinished future block exists; loading/error feedback and real upcoming blocks remain. Past-only activities stay in the dial and schedule list.

## Verification

- `focus_clock_home_lampiran1_test.dart`: 21 passed.
- `focus_clock_home_persisted_data_test.dart`: 10 passed, including fixed-clock past-only schedule coverage.
- Scoped analyzer, Dart format check and `git diff --check`: clean.
- Quick code review v2: no findings; the earlier past-only-strip finding is resolved.
- Universal APK reports package `com.aizatfir.fitrah_launcher`, versionName `0.5.48`, versionCode `8140`; APK v2 signature verifies with the existing owner-preview Debug certificate.
- Fitrah, Focus Clock and Sadar web bundles pass the asset verifier. Production aliases reached READY; `/`, `/version.json`, `/main.dart.js` and `/sqlite3.wasm` returned HTTP 200 and each version endpoint reports `0.5.48 / 8140`.
- API36 x86_64 `FocusClock_UI_QA` upgraded in place from v8139 to v8140 with font scale 2.0. Fitrah remained Android HOME, the saved QA goal was visible, and pressing Android HOME opened `MainActivity`. The sampled logcat filter found no app fatal, Flutter error or ANR. Screenshot: [Home at 200%](../../../release_dist/2026-11-23-home-agenda-clear-v8140/QA_Fitrah_Home_v8140_200.png).

## Production deployments

- Fitrah: `dpl_AFVrpWscE7fhA5K6rqK7Fqv6zx8h` — [fitrah-web-three.vercel.app](https://fitrah-web-three.vercel.app/)
- Focus Clock: `dpl_5jHLJYbuZg8rDayDwyxo49n9Xi3e` — [focus-clock-web.vercel.app](https://focus-clock-web.vercel.app/)
- Sadar: `dpl_2LSXUzhNg9prWWX5y5qkUPYUg8Ro` — [sadar-web.vercel.app](https://sadar-web.vercel.app/)

## Limits still open

This verifies one API36 emulator upgrade and Home return, not an owner's physical phone or OEM build. The owner preview uses a local Debug signing certificate, not Play Store signing. Cross-device sync, live BYOK provider use and seven-day personal use remain open. Android and each browser origin retain separate local data.

Downloadable files: [complete owner bundle](../../../release_dist/2026-11-23-home-agenda-clear-v8140/Focus_Clock_Ecosystem_0.5.48_v8140.zip), [APK](../../../release_dist/2026-11-23-home-agenda-clear-v8140/Fitrah_Launcher_0.5.48_universal_v8140.apk), [install guide](../../../release_dist/2026-11-23-home-agenda-clear-v8140/INSTALL.md).
