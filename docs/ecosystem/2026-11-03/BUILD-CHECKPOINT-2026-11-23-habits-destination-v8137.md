# Dedicated Habits destination and web targets — v8137

23 November 2026 · version 0.5.46 · build 8137

Home now previews up to three habits in saved order; **Semua** opens a dedicated Habit destination with the full shared Sadar list, history, editor, and timer action. The destination is top-aligned, including at 200% text scale. Existing Hari Ini initial page and return behavior remain intact.

## Production web

- Fitrah: https://fitrah-web-three.vercel.app/ — deployment `dpl_Dr2S5i6g8AjLjSNvPB7xs9cDp8Qc`
- Focus Clock: https://focus-clock-web.vercel.app/ — deployment `dpl_Ht5rA3nfGHSQLLtRmgCniPr4HcZF`
- Sadar: https://sadar-web.vercel.app/ — deployment `dpl_3rBme3ZzorkZswwTRsb3V4irMDNG`

All three production roots returned HTTP 200. Their `/version.json` endpoints report 0.5.46 / 8137. They are separate apps and their local data do not sync across Android and browser.

## Verification

- `flutter test test/fitrah_launcher_test.dart test/loop_habit_save_test.dart`: 15 passed.
- Scoped `flutter analyze` over the changed Dart files: no issues.
- Quick diff review: stale test-count documentation corrected; no code findings.
- Universal APK v2 signature and package version verified. API 36 x86_64 AVD upgraded in place at 200% text. Fitrah remains HOME, the saved goal survives, and Habit opens at the top with the saved habit visible. Sampled logs contain no fatal exception, FlutterError, or ANR.
- Fitrah offline ZIP integrity and SHA-256 verified.
- All three web builds passed offline asset verification and deployed READY. Flutter's Wasm dry run still reports existing Isar, secure-storage, and TTS incompatibilities; JavaScript output is used.

## Downloads

[Fitrah APK and offline web package](../../../release_dist/2026-11-23-habits-destination-v8137/INSTALL.md).

This is an owner preview signed with the local Android Debug certificate, not Play Store signing. Physical/OEM behavior, TalkBack, long-term use, and cross-device sync remain open.
