# Remove Google Calendar integration — v8129

Google Calendar connection was removed from the owner preview. Removed the launcher sign-in affordance, Settings tile, Agenda sync badge, OAuth dialog, Calendar API service and automatic activity upload. The Firebase Google sign-in scopes no longer request Calendar access. The unused `googleapis` dependency and stale fake Calendar sign-in check were removed.

## Build and deployment

- Version: 0.5.38 / build 8129.
- Flutter analyzer: no errors; five existing info-level lint notices remain in unrelated files.
- Focus Clock web: `npm run build:focus` succeeded. Flutter reports Wasm dry-run incompatibilities in existing storage/TTS dependencies and successfully built the JavaScript fallback.
- Android: universal release APK built; package metadata is `com.aizatfir.fitrah_launcher`, version 0.5.38 / 8129. APK v2 signature verified.
- Web deployment: `dpl_67n7tUv6SHDrBKEUbyrpmkQjyQEQ` is READY at [focus-clock-web.vercel.app](https://focus-clock-web.vercel.app/).
- Web ZIP integrity passed. Artifact SHA-256 values are in the [build manifest](../../../release_dist/2026-11-21-remove-google-calendar-v8129/BUILD-MANIFEST.json).

## Scope and limits

No Google Calendar OAuth prompt or Calendar API operation remains in the built app. Activity, goal and session data remain local; cross-device sync is not implemented by this slice. No automated test suite or physical device test was run. The owner APK is debug-signed.

[Install and download package](../../../release_dist/2026-11-21-remove-google-calendar-v8129/INSTALL.md).
