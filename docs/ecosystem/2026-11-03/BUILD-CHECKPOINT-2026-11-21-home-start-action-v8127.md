# Home add starts today — v8127

Date: 21 November 2026
Source: `fb1df4f` before this slice; implementation commit recorded in Git history.

## User change

From an empty Home action cue, **Tambah kegiatan** now saves a task, selects that task as today's action, and links the active pinned goal when one exists. The task dialog says **Tambah tindakan hari ini**. Inbox **Catat Cepat ke Dump Inbox** remains a free capture and does not replace today's action. If the task saves but selection conflicts or fails, Home reports that it remains in Inbox and offers manual selection from the action list.

## Verification

- `flutter analyze --no-pub` completed. No diagnostics in the two changed Dart files; five existing `info` diagnostics remain in unrelated files.
- `npm run build:focus` succeeded for the JavaScript web target. Offline bundle assets passed `scripts/verify_web_bundle.sh`.
- `flutter build apk --release --no-pub` succeeded; APK signature v2 and package metadata verify as `com.aizatfir.fitrah_launcher`, version 0.5.36 / code 8127, min SDK 24 / target SDK 35. APK is universal and debug-signed for the owner's personal preview.
- Web production deployment `dpl_6udUmVPbqft2BKhnXqe6TRHQMqTf` is READY at [focus-clock-web.vercel.app](https://focus-clock-web.vercel.app/). `version.json` reports 0.5.36 / 8127, and root plus `sqlite3.wasm` return HTTP 200.
- APK and web ZIP SHA-256 checksums passed. Package: [`release_dist/2026-11-21-focus-clock-home-start-action-v8127/INSTALL.md`](../../../release_dist/2026-11-21-focus-clock-home-start-action-v8127/INSTALL.md).

## Limits

No emulator or physical Android device was attached for this build, so the APK's Home interaction was not installed or manually exercised. JavaScript web compilation succeeded, but Flutter reported current dependency incompatibilities with its WebAssembly dry-run; this release uses JavaScript. Android and browser data remain separate; this checkpoint does not deliver cross-device sync, public Play signing, or full ecosystem completion. Automated tests were not run.
