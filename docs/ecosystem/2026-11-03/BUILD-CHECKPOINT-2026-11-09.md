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
