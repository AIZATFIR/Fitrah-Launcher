# Home task quick start — v8128

Date: 21 November 2026

Source base: `6ac5261`; implementation is in the accompanying Git change.

## User change

When today's Home action is an unscheduled task, its primary action now starts a 25-minute focus session and attributes the session to the linked goal. **Atur waktu** remains available as a secondary action. A scheduled task keeps its schedule action; an active session offers **Buka sesi fokus**. The Bookpaper palette and clock face are unchanged.

## Verification

- `dart format` completed for the changed Dart files. `flutter analyze --no-pub` completed without diagnostics in changed files; five pre-existing `info` diagnostics remain in unrelated files.
- The JavaScript web build completed; offline bundle validation passed. Flutter's existing Wasm compatibility notices remain; the release uses the JavaScript target.
- Isolated local browser flow verified a pinned synthetic goal → selected unscheduled task → **Mulai fokus · 25 mnt** → active timer with pause/finish/cancel actions. Test data stayed on the isolated local origin.
- Universal APK built as 0.5.37 / versionCode 8128, package `com.aizatfir.fitrah_launcher`, min SDK 24 / target SDK 35. APK v2 signature verified with the existing Android Debug owner-preview certificate.
- Production Vercel deployment `dpl_SXmVsXP95TjygGKYyDdWS2RR39NR` is READY at [focus-clock-web.vercel.app](https://focus-clock-web.vercel.app/). `version.json` reports 0.5.37 / build 8128; root and `sqlite3.wasm` return HTTP 200.
- Package: [`release_dist/2026-11-21-focus-task-quick-start-v8128/INSTALL.md`](../../../release_dist/2026-11-21-focus-task-quick-start-v8128/INSTALL.md). SHA-256 verification is included.

## Limits

No Android device was attached, so this APK has not been installed or exercised as the system Home app. Automated tests were not run. Android and browser data still do not sync across devices; this checkpoint does not complete the ecosystem.
