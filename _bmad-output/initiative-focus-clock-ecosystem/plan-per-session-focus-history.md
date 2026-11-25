---
title: 'Catat sesi fokus per sesi dan tampilkan histori hari ini'
type: feature
ticket: ''
created: '2026-11-14'
status: 'built'
baseline_revision: '6fa41829a508af1ca748c167ebdd88efb2de4f36'
route: 'full'
route_source: 'auto'
risk: 'high'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 0
context:
  - 'docs/ecosystem/2026-11-03/ARCHITECTURE.md'
  - 'docs/ecosystem/2026-11-03/BUILD-ROADMAP.md'
  - 'docs/ecosystem/2026-11-03/PRD.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Timer yang selesai hanya menambah total habit atau jadwal, lalu sesi aktif dihapus. User tidak bisa melihat bukti konkret hari ini diisi apa, dan retry pada batas commit tertentu berisiko menggandakan kontribusi di adapter memory.

**Approach:** Simpan satu catatan per sesi terminal dengan ID stabil, sumber dan judul snapshot, waktu mulai/selesai, durasi aktual, serta hasil selesai/dibatalkan. Commit catatan, kontribusi yang sesuai, receipt/idempotency, dan penghapusan sesi aktif secara atomik; tampilkan ringkasan sederhana sesi selesai hari ini pada Home. Ekspor dan restore membawa histori baru tanpa mengarang data lama.

**Always:** Batalkan tidak memberi kredit; sesi lama tetap retryable saat write gagal; finish awal mencatat durasi terukur; identitas dan snapshot historis tidak berubah bila nama sumber diedit; histori Android dan web sama-sama durable; impor backup lama tetap didukung.

**Never:** Mengubah Activity sebagai ledger generik, membuat histori sintetis dari agregat lama, menambah streak/gamifikasi, atau mengubah tema/jam Home.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Successful finish | Active free/habit/activity/preset timer, early or natural end | Exactly one terminal record with measured seconds; applicable habit/activity contribution and active-session removal commit together | If transaction fails, active session remains retryable and no success is shown |
| Cancel | Active session cancelled | One cancelled record may be retained for history/audit; no habit credit or completed-time total | Storage failure preserves active session |
| Retry after ambiguous commit | Completion repeated for same session ID | Existing ledger/receipt prevents duplicate history or contribution | Return existing committed result |
| Legacy backup | Backup versions 1–4 without ledger | Restore existing data and an empty session history | Existing validation and recovery compensation remain active |

</frozen-after-approval>

## Code Map

- `lib/models/timer_session.dart` -- active singleton; source and timing fields, preserve singleton ID contract.
- `lib/data/repositories/sadar_repository.dart` -- terminal transactions currently update contributions then remove active timer; add ledger and idempotent memory parity here.
- `lib/services/sadar_timer_engine.dart` -- routes finish, cancel and retry by source; keep its one-owner and retry semantics.
- `lib/data/store/focus_store.dart`, `native_focus_store.dart`, `live_model_codec.dart` -- typed model registry, native watch fanout and browser record serialization.
- `lib/data/isar_service.dart` and generated Isar model schema -- schema registration and migration validation.
- `lib/data/focus_clock_backup.dart`, `focus_clock_backup_service.dart` -- versioned JSON payload, restore replacement and rollback must include new history.
- `lib/features/launcher/widgets/focus_clock_home_view.dart` -- render compact day history using durable repository data and current palette.
- `test/isar_service_persistence_test.dart`, `test/focus_clock_backup_test.dart`, codec/repository/Home tests -- established migration, round-trip, transaction and Home conventions.

## Tasks & Acceptance

**Execution:**
- [x] Add a durable terminal-session model with stable UUID, source snapshot, actual timing, status, and validation; register it in Isar and browser store codec/watch.
- [x] Update terminal repository paths (habit, scheduled activity, preset, free, cancel) to atomically store the terminal row and contribution, clear active session, and deduplicate retries by stable ID in durable and memory stores.
- [x] Extend backup to v5, validate and export/import ledger, and retain v1–v4 compatibility and recovery rollback.
- [x] Show today's completed sessions and total measured time in Home with an empty state; refresh from store updates and preserve selected palette/accessibility.
- [x] Add tests for each source, finish early, cancel, duplicate retry, transaction failure/reopen, browser codec/watch, backup v1–v5, and Home history.
- [x] Update E2 evidence and roadmap based only on verified gates; keep unrelated E2 gaps open.

**Acceptance Criteria:**
- Given a completed timer, when Home is reopened, then one truthful session appears with actual measured duration and source snapshot.
- Given any terminal write failure, when the user retries, then the active session is retained until commit and the contribution/history appear once.
- Given a cancelled session, when today's history is shown, then it is clearly marked cancelled and contributes zero completed focus time.
- Given a v1–v4 backup, when restored, then its existing records remain intact and new history starts empty.
- Given browser reload or native database reopen, when history is queried, then saved session rows remain durable and ordered by completion time.

## Implementation Notes

- Active TimerSession now carries a stable UUID, including through backup; legacy rows are assigned a terminal fallback source from habit linkage. The Home history card sits after the analog clock so it does not push the primary cue/actions down; its header wraps at narrow widths. Full-suite QA caught and fixed a 320 px overflow and adjusted the Home history test to scroll to the below-fold card.
- Full verification passed: 329 tests with serial concurrency and `flutter analyze --no-pub`. `build_runner` emitted the new model but exited nonzero on the unrelated annotation error in `tool/web_storage_spike/test/storage_test.dart`; `tool/fix_isar_schema_ids.dart` completed. Real browser reload/storage and upgrading an existing personal database remain unverified.
- Follow-up v8100 verification closed the browser portion of this slice: five production-browser storage journeys passed, including reload/recovery and two-tab session exclusivity/completion. Native Isar save/reopen and backup compatibility remain covered by the focused persistence/backup suites and the 438-test v8100 full-suite run. User-device upgrade and physical/OEM behavior still require owner/device verification. The full `build_runner` command still reports the unrelated annotation error noted above; generated schema and the bounded-ID transformer are present, but a clean generator exit remains a tooling cleanup item.

## Plan Change Log


## Review Triage Log

- `medium / patch` -- A legacy active TimerSession with `habitId > 0` and no source kind was restored as a habit by the engine but the new terminal row labeled it free; repository now preserves the same habit fallback and `test/terminal_focus_session_test.dart` covers it.

## Design Notes

The session ledger is the source of historical evidence; HabitEntry and Activity remain useful projections/occurrences. Store snapshot title and source identity at session start so later edits do not rewrite the past. Cancel records aid honest reflection but remain outside completed focus totals.

## Verification

**Commands:**
- `flutter test --no-pub --concurrency=1` -- full suite passes without parallel memory pressure.
- `flutter analyze --no-pub` -- no issues.
- `dart run build_runner build --delete-conflicting-outputs` -- generates the model; currently exits nonzero on unrelated existing `tool/web_storage_spike/test/storage_test.dart` annotation resolution. `dart run tool/fix_isar_schema_ids.dart` completes.
