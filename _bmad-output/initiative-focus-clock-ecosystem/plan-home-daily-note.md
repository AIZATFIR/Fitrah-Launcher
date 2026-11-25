---
title: 'Save Home daily notes'
type: feature
created: '2026-11-07'
status: built
baseline_revision: fa36e527772afbd02a4fbd740b894a1855df6387
route: full
route_source: auto
risk: high
review: quick
review_source: pinned
lenses_ran: [quick]
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="owner authorized continuing the approved ecosystem build">

## Intent

Home's daily note accepts text but loses it when the screen is recreated. Make the existing scratchpad a durable note for the local calendar day, separate from Sadar reflection, without changing the approved Home clock or theme. Notes must be included in portable backup and restore. Editing should be low friction, with explicit saving/error feedback and retry on failure; never silently claim a failed write was saved.

## Boundaries & Constraints

Preserve current Android Isar schema and database, existing launcher settings and goal, prior backup v1 import, and Sadar reflection. Existing production web and Android paths use the same behavior. No new backend or cloud sync. Preserve dirty pre-existing build/web outputs and `_bmad/render`.

## I/O & Edge-Case Matrix

| Scenario | Expected behavior |
|---|---|
| Write today's note, reopen Home/app | Exact text is restored for the same local date; other dates remain separate. |
| Storage load or write fails | No silent data loss or success; preserve visible draft, show retry, and do not overwrite the existing stored settings with defaults. |
| Rapid typing, other launcher setting changes, and delayed writes | Serialize local writes; latest note and unrelated setting changes survive without old writes overwriting new ones. |
| Midnight or resume on another local date | Flush or retain pending old-day draft before switching; do not attribute old text to new day. |
| Backup export/restore | Notes round-trip alongside settings, old v1 files import, and older builds reject the new format rather than silently dropping notes. |
| Restore or settings reload while a draft exists | Avoid silently overwriting the draft; show/retain its unsaved state until the user saves or resolves it. |

</frozen-after-approval>

## Code Map

- `lib/features/launcher/widgets/focus_clock_home_view.dart`: `_dailyNoteController` and `_buildObsidianDailyNoteCard` are currently widget-only; `_currentTime` ticks each second. Hydrate without replacing live edits, track date, avoid losing pending edits on widget/lifecycle transitions, and provide unobtrusive status/retry. Preview mode remains usable.
- `lib/features/launcher/models/launcher_settings.dart`: existing JSON-backed preferences include `focusGoal`; add an immutable dated note map with defaults for old data and strict decoding. This is the smallest backup-compatible existing store and avoids conflating Sadar reflection; document the scaling limit.
- `lib/features/launcher/providers/launcher_settings_provider.dart`: initial read is asynchronous, `_saveSettings` currently swallows failures and writes whole snapshots concurrently. Queue all mutations against the latest loaded state; preserve existing public calls and ensure failed initial reads prevent destructive writes. Surface save errors to the note while keeping input for retry. `reload()` after restore must not race pending writes or discard a draft.
- `lib/data/focus_clock_backup.dart`: portable backup currently v1, exports launcher `toMap` and validates checksum. Export v2 with notes; accept verified v1 and v2, reject future versions; default v1 missing notes to empty. Validate date keys/types and avoid exposing credential fields. Existing fixtures and backup restore must keep working.
- Existing tests `test/focus_clock_backup_codec_test.dart`, `test/focus_clock_backup_service_test.dart`, launcher provider and Home tests supply fixtures. Add focused tests for note persistence/reload, failure/retry, ordering, date rollover, v1 compatibility and v2 backup roundtrip. Use controlled fakes or Isar as appropriate; no schema regeneration needed.

## Tasks & Acceptance

- [x] Persist per-local-day Home note with safe async hydration, saving/error/retry and correct date transitions.
- [x] Serialize local preference writes without breaking existing settings or silently writing over an unsuccessful read.
- [x] Add backward-compatible v1 import and v2 export with note validation and preservation through restore.
- [x] Run focused meaningful tests, analyzer and one appropriate web or native integration check. Capture remaining multi-tab and physical-device limits honestly.

Given Home is reopened on the same day, the saved note appears. Given a write failure, the unsaved text remains visible and retry saves it. Given different local dates, notes remain distinct. Given a v1 backup, import succeeds without notes; given a v2 backup, its notes restore exactly.

## Implementation Notes

Settings changes, note saves and restore/export share one local operation queue. Failed drafts remain accessible across Home recreation, including across midnight. Format v2 adds dated notes; v1 remains readable and a v2 file is rejected by older apps. Notes are stored in launcher preferences as a bounded-scope choice; move to a database if note volume grows large.

## Review Triage Log

- High, patch: after midnight, a failed prior-day draft remains in the notifier but Home initialization reads only today's date, making retry inaccessible and blocking export. Keep the unresolved draft accessible on remount.
- Medium, patch: Home remounted during an in-flight write labels its draft as failed; the old widget owns the completion callback and the notifier clears the draft without a subsequent notification. Surface pending/completed status to the new widget.

## Verification

After review fixes, `flutter test --no-pub test/launcher_daily_note_test.dart test/launcher_daily_note_widget_test.dart test/focus_clock_backup_codec_test.dart test/focus_clock_backup_service_test.dart` passed all 24 tests, including native Isar backup restore with dated notes. `flutter analyze --no-pub` reported no issues. Concurrent preferences in separate browser tabs and physical-device behavior remain unverified.
