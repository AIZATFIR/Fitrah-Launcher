# Preview checkpoint — 9 November 2026

Source revision: `76c0c9cc4de66eafdc857748ab5f79cb719f1c2e`.

Scheduled timed habits now retain their explicit Activity/habit relationship through the shared timer. A 480-second contribution toward 45 minutes remains partial. Backup format 4 includes the relationship and start-time target, imports versions 1–3, and retains unavailable source references after permanent habit deletion. This checkpoint precedes the subsequent Home habit-action changes.

## Evidence

- Full Flutter suite: 193 tests passed in 28 seconds.
- Analyzer: no issues, 7.9 seconds.
- JavaScript web release: compiled in 65.2 seconds to `/tmp/fitrah-scheduled-habit-final-web`.
- Android release: compiled in 216.2 seconds from an isolated `git archive` of the exact revision at `/tmp/focus-clock-checkpoint-76c0c9c`. Dependency lock unchanged.
- Android package inspection: `com.aizatfir.fitrah_launcher`, versionName `0.5.3`, versionCode `8` (explicit build-number override; source remains `0.5.3+7`), minSDK 24, targetSDK 35, compileSDK 36. Application binary is arm64; other plugin ABIs in the ZIP do not make this a universal APK.
- APK signature verified. Existing Android Debug certificate SHA-256: `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`.
- All four arm64 `libisar.so` LOAD segments have alignment `0x4000`.

## Local downloads

Artifacts are generated outputs, ignored by Git, under `release_dist/2026-11-09-76c0c9c/` at the repository root:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `Focus-Clock-76c0c9c-Android-arm64-preview.apk` | 28,808,813 | `b3ba89396760a459f2e61473beb482a845602bd22acb988c7db540338a90a135` |
| `Focus-Clock-76c0c9c-Web-preview.zip` | 13,901,607 | `a5b71ea1d64987c8bc54dfe94f9ca31b64985215471f756e11fbf710677984a7` |

The directory also contains `BUILD-MANIFEST.json`, `SHA256SUMS`, and `CHECKPOINT-NOTES.md`. The web bundle contains `BUILD-INFO.json`. No GitHub release or production deployment was made for this checkpoint.

## Limits

Browser runtime, physical Android installation, TalkBack and daily-device upgrade were not verified. Native schema compatibility was exercised with a synthetic previous-schema database, not the owner's daily data. Android retains debug signing; this is a personal preview, not a stable public signing arrangement. Web is JavaScript, not Wasm, and must be served through a web server.

Terminal session history, complete progression/hybrid execution, launcher capability handling, cross-device handoff, AI planning, WhatsApp, MCP and public release remain open. Refer to [BUILD-ROADMAP](BUILD-ROADMAP.md); these artifacts do not prove completion of those requirements.

## Subsequent Home-actions checkpoint — c8b1087

The newer local preview uses source `c8b10871348b54d85e179b6c41b3160af8834b62`, including the Home habit-action fixes and both review corrections. A note no longer completes a habit; count totals retain the stored target and measured time. Failed editors keep input; all Play buttons check today's selected date. Unknown types receive generic details without invented hybrid sets.

Evidence: 76 affected tests passed after review, with a final expanded 9-test grid rerun. Analyzer clean (74.6 seconds); web JavaScript release compiled (75.7 seconds); arm64 Android release compiled (145.6 seconds) from the isolated exact archive. This revision's full suite was not rerun; the 193-test full result above belongs to `76c0c9c`. Package inspection confirms versionCode **9**, versionName **0.5.3**, the same application ID/SDKs and signing certificate, unchanged dependency lock, arm64 application binary and `libisar.so` LOAD alignment `0x4000`.

Latest local artifacts are under `release_dist/2026-11-09-c8b1087/`, with manifest, checksum list and checkpoint notes:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `Focus-Clock-c8b1087-Android-arm64-preview.apk` | 28,808,737 | `aa5e2e87b73b8c4b4032195cb4f74609c44dc5b70ff9f903daa3b1fd42bceebc` |
| `Focus-Clock-c8b1087-Web-preview.zip` | 13,902,649 | `9ec9a4e5ed97887b47b87782127581355f1a7a6ff76381ecd9a18c8be4450272` |

Local preview server serves `/tmp/focus-clock-home-actions-final-web` at `127.0.0.1:4174`; the listener was verified. This does not prove rendered browser behavior. No GitHub release or production deployment was made. The runtime/device/TalkBack and wider ecosystem limits above still apply.

## Launcher capability checkpoint — 3d463ce

Newer source: `3d463ce00e854a8cb68e5f53f566cd49a8843b33`. Production demo app fallback and simulated successful dispatch are removed; listing, retry/resume, icon refresh and app-action failure feedback are connected across their consumers. Review patches make YPT's app-list failure reachable at 320dp/200% and enlarge the changed legacy Sadar targets.

Evidence: 29 affected tests passed; analyzer clean (12.5 seconds); web JavaScript release compiled (51.7 seconds); Android x64 compiled (183.8 seconds) and arm64 compiled (137.2 seconds). The first x64 attempt rejected an HTTP504 page; a fresh download matched the package's exact SQLite hash before generated cache repair. No validation or dependency lock change was made.

Native API36 x64 QA upgraded versionCode9 to10 with the same signature, retained a goal created/pinned through the real UI, displayed the actual app list, opened Android Clock, and returned to Fitrah. This is a disposable emulator with 4096-byte pages, not a physical or arm64 runtime check. See [NATIVE-QA](NATIVE-QA.md). The phone APK uses versionCode11, with application binary arm64, minSDK24/targetSDK35/compileSDK36; signature and all arm64 Isar LOAD alignments (`0x4000`) verified. The existing debug signing identity remains.

Local artifacts under `release_dist/2026-11-09-3d463ce/` include the manifest, checksum list and preview limits. Both artifact checksums were rechecked successfully:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `Focus-Clock-3d463ce-Android-arm64-preview.apk` | 30,527,801 | `979b73af03751a52c7775e09096514efc662f370a8980885e38bd6aad60935f8` |
| `Focus-Clock-3d463ce-Web-preview.zip` | 13,903,163 | `03dd0ee7102c250fe4172069f924158a7363dcc24aac84ac32b8a62a94b5b8e8` |

The latest local server serves `/tmp/focus-clock-launcher-capabilities-web` at `127.0.0.1:4174`, with source revision in `BUILD-INFO.json`; listener verified. Browser runtime and physical-device behavior remain unverified. No GitHub release or production deployment was made; default Home, durable favorites/hidden/order and the remaining ecosystem gates are still open.
