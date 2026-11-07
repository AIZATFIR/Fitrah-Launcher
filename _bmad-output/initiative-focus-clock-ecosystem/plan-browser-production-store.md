---
title: Durable browser storage for the app
type: feature
created: '2026-11-06'
status: built
baseline_revision: a3bc57e79340063d2cec3655d3a469775288609b
route: full
route_source: auto
risk: high
review: quick
review_source: pinned
lenses_ran: [quick]
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="owner authorized autonomous continuation through finish">

## Intent

The production web app stops at storage recovery because Isar Community cannot open a browser database. Connect the proven Drift WASM backend to all persisted app data and existing repository/session logic, while Android continues opening its current Isar database unchanged. Browser users must be able to save goals/settings, habits, schedules, tasks, reflections and sessions, reopen them, complete a session once, and export/restore data with an accessible recovery copy.

Always preserve the eight native collection names/schema/path, portable backup v1 compatibility, exact seconds, session attribution date, all live fields, IDs and singleton IDs (AppSettings 0, TimerSession 1). Production startup failure must remain visible with retry; unsafe/in-memory browser modes never become silent production fallback. Existing explicit test/demo memory behavior may remain. Keep current approved Home/theme/clock design; only storage capability/error and recovery controls need UI changes. User authorizes implementation and local commits without renewed approval. Preserve unrelated dirty `build/web/` and `_bmad/render/` outputs.

Do not migrate installed Android data, add cloud sync/AI features, clear unsupported/newer databases, or call this the entire ecosystem finished. Full offline cache startup, production deploy, Safari/mobile, native physical-device upgrade and the later product roadmap remain separate gates.

## I/O Matrix

| Scenario | Expected outcome |
|---|---|
| All eight model types plus launcher goal saved, store reopened | IDs, live credential configuration, dates, lists, nullable/raw source fields, statuses and seconds unchanged; no demo seeding in production |
| Two connections/tabs start or complete a session | One active singleton, no orphan Activity or duplicate completion evidence |
| Exception during cross-collection write | No partial durable mutation and no partial watcher state |
| Failed/unsupported browser storage or newer schema | Visible error/retry, no successful memory write or destructive recreation |
| Backup restore, including preference-write failure | Preview unchanged; recovery persisted before replacement; database/preferences compensated on failure; secrets retained and imported running session paused as portable format specifies |
| Corrupt live row or unsafe numeric ID | Explicit read/write failure; never silently coerce data or round IDs |

</frozen-after-approval>

## Code Map and Design

- `lib/data/isar_service.dart` and eight `lib/models/*.dart`: native bootstrap/schema remain intact. Models use Isar's autoIncrement sentinel; only that sentinel allocates IDs. Preserve explicit 0/1, import IDs and monotonic allocation through deletion/reload. Computed getters need not be persisted independently.
- `lib/data/store/`: add a small shared FocusStore contract: typed all/get/put/delete/clear, consistent read and atomic write callbacks, post-commit watch, durability and close. Native adapter delegates to existing Isar; browser adapter uses Drift. Collections can be filtered/sorted in shared repositories initially; measure indexed query needs later. Returned rows must be detached copies. Writes return only after commit. Do not accidentally nest transactions through helper calls.
- Browser backend can use a versioned SQL records table (collection, ID, payload) and persistent counters, plus recovery journal. Keep all related writes inside the same Drift transaction. Use supported `notifyUpdates`/`tableUpdates` for committed cross-connection signals; remote Drift stream stores forward these notifications. Add explicit transaction guards. IDs beyond JavaScript's exact integer range must reject before writes, not round.
- New neutral live model codec must cover writable fields of all eight models. Backup field maps are references; **never live-roundtrip through FocusClockBackupCodec**: it removes aiApiKey/aiBaseUrl, sanitizes wallpaper URLs and pauses running timers. Live codec preserves raw nullable sourceKindIndex, runningSince/status, all 27 AppSettings fields, lists and zero/false/null. Encode instants with timezone-safe timestamps; preserve local calendar dates as calendar dates. Validate types and record/schema version at storage boundaries. Keep backup v1 exports/imports compatible if extracting shared mapping helpers.
- Five existing repositories in `lib/data/repositories/`: route durable operations through FocusStore and keep recurrence, sorting, grouping, archive/count logic, target snapshots and timer atomicity shared. Keep old Isar constructors as adapters for existing callers/tests and add store constructors. Sadar's `putTimerSessionInTxn` is a tested fault injection hook; preserve its semantics.
- `lib/providers/providers.dart`, `sadar_providers.dart`: add shared store provider; existing isarProvider test overrides can adapt to native store. `lib/widgets/quick_timer_hub.dart` must check durable capability rather than Isar presence.
- `lib/main.dart`, `main_fitrah.dart`, `main_sadar.dart`: platform store factory opens native Isar or safe browser store, seeds only missing AppSettings, and supplies shared provider. Keep recovery UI on failure. Browser database identity must be consistent across these views on the same origin, distinct from test names.
- `lib/data/focus_clock_backup_service.dart`: adapt snapshot/replace to store transactions, preserving its existing `isar:` and supportDirectory test seams. Browser recovery must be durably committed before replace and downloadable from Settings after restart. A narrow optional recovery-journal interface on the browser store is acceptable; native retains file recovery. Maintain separate launcher preferences compensation, and preserve current installation credentials.
- `lib/features/settings/settings_screen.dart`: use shared store for backup, web-compatible file bytes and latest recovery export. Show actionable unavailable capability errors without exposing implementation details or claiming persistent/cloud success early.
- `pubspec.yaml`/lock and `web/`: add pinned Drift 2.35.3 runtime and matching official worker/WASM assets from the verified spike, with reproducible checksum acquisition/build setup. Do not add incompatible drift_dev to the app generator graph; custom SQL via GeneratedDatabase avoids a second generator. Root analyzer remains clean. Assets must be present in source web build output, local, correctly served as JS/WASM. Inspect `scripts/vercel_build.sh` and `vercel.json` so source builds include assets; do not deploy yet.

## Tasks and Acceptance

- [x] Implement shared store, native/browser adapters and lossless live codec; add focused contract/codec coverage for all matrix rows and all eight real model types.
- [x] Migrate repositories/providers, timer capability checks and three bootstraps; preserve existing native behavior, tests and fallback/demo boundaries. No duplicate web business logic.
- [x] Integrate native/browser backup/restore and accessible browser recovery export, with failure compensation.
- [x] Prepare matching local assets and build setup. Add isolated browser journey entrypoint/runner using actual app repositories and models (not synthetic spike tables), unique test database and synthetic credentials. Reuse the existing CDP runner where practical. Verify reopen/reload, two clients, exact 67-second aggregation, recurrence/exclusions, settings/goal, backup roundtrip, failure rollback and recovery download bytes. Test injected preference failure through the existing service seam.
- [x] Run focused checks, full Flutter suite, analyzer, standard production web compile to `/tmp`, browser journeys, and arm64 release build. Inspect new native assets/alignment if Drift/sqlite3 changes Android packaging. Update ADR/roadmap with measured evidence and remaining gates.

Given a standard production web build, when opened in supported Chromium, then Home opens from durable storage and actual repository records survive reload rather than landing at the unsupported-Isar recovery screen.

Given the existing native fixtures and constructor callers, when the full suite and native reopen checks run, then prior data/session/backup guarantees remain intact without any installed-data migration.

Given browser backup and restore, when a user restarts after replacement or compensation, then the current data is correct and the pre-restore recovery JSON can be exported from Settings.

## Implementation Notes

## Review Triage Log

## Verification

Use appropriate focused tests during implementation, then one full native suite/analyzer after changes settle. Compile standard web to a unique `/tmp/focus-clock-browser-production-*` output, never default `build/web`. Run actual browser repository journeys against that candidate or a separate test entrypoint; inspect standard Home startup too. Build arm64 release and record artifact checksum. Do not claim browser eviction/offline/mobile/deploy gates from desktop-local evidence.

- Full native Flutter suite: 124 passed; added storage unavailable/retry widget test: 1 passed.
- `flutter analyze --no-pub`: clean.
- Production browser journey: all five groups passed in Chromium 150, `sharedIndexedDb`; covers all eight models, live credentials/session fields, reload, recurrence/exclusions, repository writes, rollback/watchers/ID safety, two-tab Habit and Activity session lifecycle, exact 67-second aggregation, backup compensation, and recovery export after reload.
- Production Home JS build: `/tmp/focus-clock-browser-production-home-20261107`; visual startup shows goal cue above the analog clock. Drift worker/WASM checksums match pinned release 2.35.3.
- Arm64 release APK: `build/app/outputs/flutter-apk/app-release.apk`, SHA-256 `329954a9300e810233e531ba9dd4d842b15939aae4d121094ac1041a5c8fcd47`; `libisar.so` LOAD segments are aligned to 0x4000.
- Quick code review: no findings.
- Still open outside this slice: offline startup from cache, quota/eviction recovery, Safari/mobile, deployment, physical Android upgrade/reopen, and the later E2–E11 ecosystem roadmap.
