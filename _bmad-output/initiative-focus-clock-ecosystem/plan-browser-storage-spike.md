---
title: Browser storage transaction spike
type: chore
ticket: ''
created: '2026-11-06'
status: built
baseline_revision: 1b630a24a754df8b47135b24b29785b7c1bc1f8e
route: full
route_source: auto
risk: medium
review: quick
review_source: pinned
lenses_ran: [quick]
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="continuation authorized by owner: lanjut terus, all plans approved through finish">

## Intent

**Problem:** Focus Clock cannot open production storage in browsers. Isar Community 3.4.1 explicitly rejects web open, so successful Flutter compilation does not make the deployed app usable. Existing repositories need atomic changes across activities, habit evidence and the singleton timer; a replacement cannot merely persist independent objects.

**Approach:** Build an executable, isolated Dart browser storage spike under `tool/web_storage_spike/`, using pinned Drift 2.35.3 and matching SQLite WASM/worker assets. Prove the transaction and persistence behavior needed by the app before connecting an adapter to production repositories. The user has authorized the long build and autonomous continuation; this is the bounded E1 research slice required by ARCHITECTURE, not a new product feature or a native migration.

## Boundaries & Constraints

**Always:** Isolate package dependencies, generated artifacts, database names and synthetic fixtures from the app and user storage. Use browser execution, not a native SQLite test masquerading as browser evidence. Check the selected storage implementation before opening for writes; reject `inMemory` and `unsafeIndexedDb` with actionable errors. Carry only safe small integers or text identifiers; preserve exact seconds, LocalDate strings and goal content. Pin asset versions and verify SHA-256 on acquisition. Use separate live-store semantics: the backup codec removes credentials and pauses running timers, so it is unsuitable as a live serializer.

**Never:** Change Android's Isar path, migrate user data, touch existing `build/web/` or `_bmad/render/` changes, ship the spike as the production app, or claim an app/browser/release gate passed from the spike. No provider keys, cloud services or real-user fixtures.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Durable session | Representative Activity, Habit/Entry, AppSettings and running TimerSession | Close and reopen the named browser store; IDs, goal, status, LocalDate and exact seconds remain | Fail test on unavailable storage; do not silently use memory |
| Completion | Active session and matching activity | Activity completion/evidence and timer deletion commit together; re-execution cannot duplicate evidence | Failed transaction retains previous records |
| Injected failure | Throw between completion writes | Activity, contribution and timer all remain at pre-transaction values after reopen | Exception visible to caller |
| Competing clients | Two independent database connections race to start singleton session | Exactly one wins; losing start leaves no orphan activity | Constraint/conflict is observable |
| Commit observation | Watching committed data before successful and failed writes | Watcher sees committed completion, no partial failure state | Listener errors fail verification |
| Unsafe capability | in-memory or unsafe IndexedDB selected | Open rejected before a data write | Stable explanatory exception |

</frozen-after-approval>

## Code Map

- `lib/data/isar_service.dart`: current eight schemas and native bootstrap; leave production unchanged during this spike.
- `lib/data/repositories/sadar_repository.dart`: actual transaction boundaries combine Activity/session creation, completion with HabitEntry, and timer deletion. Model the same atomicity in representative spike tables.
- `lib/data/repositories/activity_repository.dart`: recurrence and grouped writes live in shared domain logic; do not copy them into a separate web repository.
- `lib/data/focus_clock_backup.dart`: explicit portable mappings are a migration reference, not a live storage serializer.
- `lib/providers/providers.dart`, `providers/sadar_providers.dart`, `lib/widgets/quick_timer_hub.dart`: later adapter integration must replace direct Isar durability checks and repository dependencies.
- `docs/ecosystem/2026-11-03/decisions/ADR-E1-storage.md`: record measured browser evidence, exact versions and next production seam.
- Chromium available at `/usr/bin/chromium`; Flutter 3.41.9 / Dart 3.11.5.

## Tasks & Acceptance

**Execution:**
- [x] `tool/web_storage_spike/pubspec.yaml`, lockfile, `.gitignore`: create an isolated reproducible Dart package using Drift 2.35.3, package:web and browser test tooling. Prefer generated Drift tables if required for reliable watched queries.
- [x] `tool/web_storage_spike/lib/`: implement representative tables, browser opener with a safe-mode guard, atomic start/completion and exact fixture reads. Keep table/domain surface narrowly limited to the matrix.
- [x] `tool/web_storage_spike/tool/`: acquire matching release assets with checksum verification and compile worker if necessary. Asset hashes from official release: worker `a54b81412d4c4ab56653bb9e4c02912b0820bb37e2bba00722ddef4d78083d4a`; WASM `efd308be92a34f3aa15f289a37f213b0230fd80888a1364326ee29579d892d37`. Generated assets stay ignored and reproducible.
- [x] `tool/web_storage_spike/test/`: execute all matrix rows in real Chromium via Dart browser tests. Assert a durable storage mode and print it. Use unique database names per test, cleanup and time bounds. If two connections are same-page clients, label that accurately; do not call it a two-tab proof.
- [x] `tool/web_storage_spike/README.md`: document exact setup/run commands, observed modes, fixtures, security headers, supported claims and remaining reload/offline/two-tab/deployment gates. Do not invent unexecuted evidence.
- [x] Update ADR E1 and roadmap from observed results after verification. Record the smallest next integration seam and preserve all open product gates.

**Acceptance Criteria:**
- Given a fresh checkout and the documented setup, when dependencies/assets are prepared and the Chromium suite is run, then all matrix behaviors are proved in a persistent browser backend.
- Given a network-independent local runtime after dependencies/assets are prepared, when databases reopen, then storage uses local WASM/worker assets rather than a CDN request.
- Given the completed spike, when a maintainer reads its report, then measured backend results, same-page concurrency and outstanding real-tab/reload/offline/production integration are distinguishable.

## Implementation Notes

- Initial Chromium execution rejected inMemory because the Dart test host inserts a randomized URL path prefix and root-relative worker URLs lost that prefix. Relative asset resolution fixed worker loading; safe-mode rejection remained intact.
- Runtime Drift 2.35.3 and matching official assets are pinned; available generator is drift_dev 2.35.2. Generated code and downloaded assets stay ignored; setup/codegen commands reproduce them. Root Flutter dependencies and production source were not changed.
- All six browser matrix tests passed in Chromium 150.0.7871.186 with sharedIndexedDb, including watcher updates from an independent connection. `dart analyze` is clean; both asset SHA-256 values match official release metadata.
- Added a Node 22 built-in CDP harness and compiled Dart probe to prove two actual tabs plus navigation reload. Both normal hosting (sharedIndexedDb) and COOP/COEP hosting (opfsLocks) passed: goal/running timer persistence, cross-tab rollback, one winning start/no orphan, concurrent idempotent completion and exact 67-second entries after reload. Remote DNS is blocked except loopback, with all runtime files served locally.
- Matrix coverage: durable session → running fixture reopen test; completion → completion/idempotency test; injected failure → rollback/reopen test; competing clients → race test plus real-tab journey; commit observation → cross-connection watcher test; unsafe capability → guard rejection test.
- Root Flutter analysis passes with the optional package metadata/generated file absent; package-level analysis remains clean after setup. `dart pub get --enforce-lockfile` succeeded. The root analyzer exclusion keeps the spike optional for Android developers.
- Full offline page cache startup, production eight-model mapping/migration, quota/eviction and backup/recovery remain integration gates. README and ADR distinguish prototype evidence from app readiness. Android and the previously dirty generated web/render files are outside this diff.

## Plan Change Log

## Review Triage Log

- Quick independent inspection: no findings.
- Self-review — medium / patch: a fresh Android checkout without the spike's ignored package metadata/generated file made root Flutter analysis report 179 unresolved prototype symbols. Added `tool/web_storage_spike/**` to root analyzer exclusions; with those artifacts temporarily removed again, root `flutter analyze --no-pub` passed. The standalone package retains its own analyzer and documented preparation checks. No production source or dependency change was needed.

## Design Notes

Keep native Isar and evaluate a browser adapter first. A unified Drift migration would additionally require converting installed Android databases and proving rollback. A JSON snapshot saved on a timer cannot satisfy atomic completion or concurrent ownership. This isolated Drift spike tests the candidate without selecting a database through library popularity alone. Provider-facing repository contracts and their business rules should stay shared during subsequent integration.

## Verification

- In `tool/web_storage_spike/`, run `dart pub get`, documented asset setup, any required code generation, `dart analyze`, and Chromium browser tests. Record final actual commands and results here/README.
- Inspect root `git diff --check` and changed paths to confirm no application source or generated user build output was modified by the spike.
