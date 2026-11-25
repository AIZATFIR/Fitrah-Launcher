# Home glance and app scrubber — v8146

23 November 2026 · `0.5.54+8146` · owner preview

## Change

The Home clock status now wraps to its full text at large system text sizes. Previously the compact dial row limited it to two lines and hid the end of “Tidak ada kegiatan terjadwal sekarang”. Font size, color, dial face and palette remain unchanged. The preceding v8145 launcher slice removed the redundant text-to-schedule card from the full Jam page, kept the actual schedule editor, placed the analog dial first on Home, removed bottom tabs in favor of horizontal paging, and made the app-index scrub show only the selected letter while held. AI schedule descriptions no longer inject a sample goal.

## Verification

- `dart analyze lib/features/launcher/widgets/focus_clock_home_view.dart` and `git diff --check` passed. No automated test suite was run.
- Android release APK built as `0.5.54 / 8146`; APK v2 signature verified, then installed over the API36 emulator without clearing its data. At 200% system text, the whole Home status text wraps visibly while the dial and actions remain present.
- Android HOME resolver selected `com.aizatfir.fitrah_launcher/.MainActivity`; pressing Home from the app drawer returned to the goal Home. Horizontal swipe reached Habits and the app drawer. Holding the index on C showed only Calendar, Camera, Chrome, Clock and Contacts; release restored the complete list. Sampled logcat had no fatal exception, FlutterError or ANR.
- Fitrah, Focus Clock and Sadar web builds passed `scripts/verify_web_bundle.sh`; all three Vercel production aliases returned HTTP 200 and `version.json` reports `0.5.54 / 8146`. Deployment IDs: Fitrah `dpl_33YJ4cXYa33NXCPDevQUhUR7CzWx`, Focus Clock `dpl_4VWmHTcQDVwAW5cxzT8BxD1ZrP5k`, Sadar `dpl_Hsd48EifciC8Y9KcMBgLDSkUCcbw`.
- Local APK and web ZIPs, install notes and checksums: [`release_dist/2026-11-23-focus-clock-v0.5.54-8146`](../../../release_dist/2026-11-23-focus-clock-v0.5.54-8146/INSTALL.md). The Android APK is signed with the local debug/owner-preview certificate, not a Play distribution key. GitHub owner-preview CI uses the same keystore from repository secret `ANDROID_PREVIEW_KEYSTORE_B64`; the step is skipped for pull requests. The release workflow now packages all three web entry points and creates SHA-256 checksums alongside Android/Linux/Windows artifacts.

## Still open

The emulator preserves old synthetic QA data, including a saved LKS goal; no data was erased, so it is not a clean-install proof. No physical/OEM handset or TalkBack run was available. Android and web data remain separate; provider-backed AI, seven-day owner use and a public signing/release remain open. Local Linux packaging failed because host `clang++` requires missing `libLLVM.so.23.1`; Windows packages require the configured Windows CI runner.
