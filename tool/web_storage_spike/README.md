# Focus Clock browser storage spike

Isolated, synthetic proof for the E1 storage decision. This package does not open the app's database, import user data, or replace production repositories. Database names must begin with `focus_clock_spike_`. The browser journeys use a temporary Chromium profile and remove it when finished.

## Run

Requires Dart 3.11+, Node 22+ (built-in WebSocket), Chromium, Bash, curl and sha256sum. Run from this directory:

```sh
dart pub get --enforce-lockfile
bash tool/prepare_assets.sh
dart run build_runner build
dart analyze
CHROME_EXECUTABLE=/usr/bin/chromium dart test --platform chrome --reporter expanded
dart compile js -O2 web/probe.dart -o web/probe.dart.js
CHROME_EXECUTABLE=/usr/bin/chromium node tool/browser_journeys.mjs
CHROME_EXECUTABLE=/usr/bin/chromium STORAGE_ISOLATION=1 node tool/browser_journeys.mjs
```

Set `CHROME_EXECUTABLE` to your installed Chrome/Chromium executable. Generated Dart, JavaScript, WASM and compiler caches are ignored. The lockfile is committed. The root Flutter app's dependencies and build outputs are independent. Root Flutter analysis excludes this standalone package so an Android checkout does not require its optional browser dependencies/code generation; run its own `dart analyze` after setup.

`prepare_assets.sh` downloads worker and SQLite WASM from the official Drift 2.35.3 release and checks these SHA-256 hashes before replacing local assets:

| Asset | SHA-256 |
|---|---|
| `drift_worker.js` | `a54b81412d4c4ab56653bb9e4c02912b0820bb37e2bba00722ddef4d78083d4a` |
| `sqlite3.wasm` | `efd308be92a34f3aa15f289a37f213b0230fd80888a1364326ee29579d892d37` |

## Measured on 6 November 2026

Environment: Dart 3.11.5, Chromium 150.0.7871.186 on Linux, Node 22.23.2. Runtime `drift` is pinned to 2.35.3. The available `drift_dev` generator is 2.35.2; `build_runner` is 2.15.0, `test` 1.31.1, `web` 1.1.1, and resolved `sqlite3` 3.9.0. The generator/runtime patch difference compiled and passed the checks below.

Six real Chromium tests passed:

- A running session, activity, habit and goal survive closing and reopening connections; status, LocalDate and 67 exact seconds remain unchanged. A contribution then survives another reopen. AppSettings uses singleton ID 0; session uses singleton ID 1.
- Completion atomically records evidence, marks the activity and removes the active session. Repeated completion does not duplicate evidence.
- An exception between writes leaves all previous rows unchanged after reopen.
- Two independent connections on one page race for the singleton session; exactly one wins, and the losing transaction creates no orphan activity.
- A watcher sees committed changes from another connection and no partially committed failure state.
- Unsafe IndexedDB and in-memory modes are rejected by the capability guard before database creation/data writes.

The separate Node journeys opened two actual tabs and verified reload persistence of a running timer and Unicode goal, visibility from the other tab, rollback visibility, competing starts with one winner, and concurrent completion with one contribution per session after reload. Both local hosting configurations passed:

| Local response headers | Observed storage mode |
|---|---|
| No COOP/COEP | `sharedIndexedDb` |
| COOP `same-origin`, COEP `require-corp` | `opfsLocks` |

All runtime files were served locally. The Node journeys block remote DNS resolution while permitting loopback; they do not use a CDN. Their reload check waits for a new page loader before reading state, preventing a read from the previous page from masquerading as reload proof. Chrome is driven through its debugging protocol; the script adds no npm dependencies.

The same-page multi-connection tests intentionally instantiate separate Drift connections. Drift emits its generic multiple-database debug warning; these clients do not reuse one executor. The real-tab tests independently exercise the shared-worker/OPFS synchronization.

## Limits and integration work

These are representative relational fixtures, not the app's complete eight-collection schema or live codec. The synthetic credential string only proves that a live row is not transformed by the portable backup codec. It is not a credential-storage design. Production backup decoding deliberately removes credentials and pauses running timers, so it must not be reused unchanged for live records.

Full offline page startup after caching, browser eviction recovery, schema upgrades, backup/import recovery, storage quota exhaustion, Safari/Firefox, mobile browsers, deployed hosting/auth and the production Flutter UI remain unverified. Denied-storage verification covers the mode guard; it does not simulate every browser permission/quota failure. The local journeys do not prove offline startup when the HTTP server is unavailable.

The next step is a transaction-scoped store contract shared by existing repositories: consistent reads, typed collections, durable writes, post-commit change streams and a capability flag. Keep recurrence, habit measures and timer lifecycle logic in the shared repositories. Preserve native Isar and installed Android data. A browser adapter must separately prove all live fields, stable ID allocation, backup recovery and migration before production release.

Reference: [Drift's web storage and setup documentation](https://drift.simonbinder.eu/platforms/web/), [matching release assets](https://github.com/simolus3/drift/releases/tag/drift-2.35.3).
