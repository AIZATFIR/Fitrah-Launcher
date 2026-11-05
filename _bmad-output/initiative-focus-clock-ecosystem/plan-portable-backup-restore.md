---
title: "Portable backup and restore"
initiative: "Focus Clock ecosystem"
route: full
status: built
risk: high
requirements: [FR-20, AD-14, E1]
baseline_revision: 6c0c9a1b2b281cacb6c7a40f48e23b50bf5ef4c9
review: thorough
review_source: auto
lenses_ran: [edge-case-hunter, verification-gap]
review_loop_iteration: 1
---

# Intent

Let a user protect and move their Focus Clock data through a versioned JSON backup. A restore is inspectable, rejects unsupported or malformed files before mutation, creates a local recovery copy, then replaces supported durable data while preserving IDs and measures. Backup is personal data, not encrypted. Provider credentials and OS tokens never enter the file. The launcher focus goal and non-secret launcher preferences are user data and must round-trip. A live timer must not falsely resume after restore.

## Scope and boundaries

- Include all eight Isar collections (Preset, Activity, AppSettings, Task, Habit, HabitEntry, DailyReflection, TimerSession) and serialized `LauncherSettings`.
- Use explicit JSON codecs with stable enum names and explicit legacy enum validation; never serialize Isar generated internals.
- Exclude `AppSettings.aiApiKey`, secure-storage credentials, and any endpoint that may embed a credential. Preserve current installation credentials when replacing AppSettings.
- Export TimerSession state; normalize a running session to paused at restore, accounting for its elapsed segment.
- Import is replace mode, never merge. Show counts and replacement warning before final confirmation.
- Reject corrupt checksum, newer version, oversize, invalid enum/date/required value, duplicate IDs, structurally invalid reference IDs, and invalid singleton IDs with no data changes. Positive stale IDs remain valid soft references because current delete paths do not cascade history.
- Isar transaction protects database replacement. Secure launcher preferences use a recovery journal/compensation; do not report success until both stores are updated.
- This is local file backup, not encryption/cloud sync. Web backup UI must report storage-unavailable if Isar cannot open; it must not imply browser durability.
- BlueprintRepository, volatile preview/demo data, notification state, Firebase cache, and OS state are outside persisted user data and are not exported.

## Data I/O

| Data | Read | Export | Import | Sensitive handling |
|---|---|---|---|---|
| Eight Isar collections | IsarService | Versioned JSON | Validate then transactional replace | Include private reflections; warn |
| LauncherSettings | SecureStorageService | JSON allowlist/model map | Restore with compensation journal | Include focusGoal; omit custom image URL |
| AI and OS credentials | Current install only | Never | Preserve existing values | Never serialize |
| TimerSession | Isar | Include exact record | Restore as paused if was running | No false running timer |

## Code map

- `lib/data/isar_service.dart`: injected active database seam.
- `lib/models/*.dart`: eight persisted model schemas; explicit codec must keep stable IDs and seconds.
- `lib/features/launcher/models/launcher_settings.dart` and provider: separate user preferences and focus goal.
- `lib/services/secure_storage_service.dart`: existing settings persistence; use narrowly scoped methods, no direct plugin calls in UI.
- `lib/features/settings/settings_screen.dart`: existing settings list is the entry point for Backup and Restore.
- Add backup codec/service/UI tests; do not alter existing generated web outputs or render files.

## Tasks

1. Write failing codec tests for exact round-trip, checksum, secret omission, duplicate IDs, unsupported versions, broken references and timer pause normalization.
2. Implement read-only collection lists around app model records and a deterministic canonical JSON SHA-256 envelope; cap file size and validate all fields/reference ID shapes before opening a write transaction. App model instances remain mutable Isar entities.
3. Implement injected backup service: read all stores, write selected JSON file, create automatic pre-restore recovery file, transactionally replace Isar data, coordinate LauncherSettings with compensation, preserve current credentials, and pause an imported running session.
4. Add Settings actions with selected file, personal-data warning, export result, import preview/counts, explicit replace confirmation and actionable errors.
5. Add dependency/platform setup only if needed, update E1 roadmap evidence, run targeted tests, full test suite, analyze and Android/web compile checks.

## Acceptance (Given / When / Then)

- Given durable records across all supported collections and a launcher goal, when exported and imported into an empty compatible store, then IDs, status, target snapshots, exact seconds, schedules, reflections and focus goal match; secrets are absent.
- Given a valid backup, when selected, then the app shows format/version, timestamp, record counts, personal-data notice and replace semantics before commit.
- Given malformed, oversized, checksum-invalid, unsupported-newer, duplicate-ID or structurally invalid reference ID backup, when selected, then import is rejected and every current record remains unchanged. Positive stale soft references are preserved.
- Given injected DB-write or preference-write failure, when restore is attempted, then the prior database and launcher preferences are restored and the UI does not report success.
- Given a running timer in the backup, when restored, then elapsed work is retained and the session is paused.
- Given a future format version, when selected, then no writes occur and user data remains available.

## Stop conditions

Stop this slice before claiming E1 complete if Isar transaction rollback, compensation, actual Android file save/open, or user data round-trip cannot be demonstrated. Keep unrelated dirty web build and `_bmad/render/` files untouched.

## Review Triage Log

- `edge-case-hunter` — Fixed: date-only validation now rejects impossible calendar dates, and Activity/Task bounds are validated against this app's half-day minute domain (`0..720`). Added invalid date and time coverage.
- `edge-case-hunter` — Fixed: import preview now displays the decoded format version, alongside timestamp, counts, and replacement semantics.
- `edge-case-hunter` — Fixed in scope: backup collection lists are unmodifiable. Model records remain mutable Isar entities; restore copies imported settings before applying installation credentials, so the decoded backup is not modified.
- `edge-case-hunter` — Rejected the suggestion to reject every dangling positive foreign key. Current hard-delete paths for Habit, Activity, and Preset do not cascade historical rows; these are intentional soft references in existing user data. Non-positive or structurally invalid IDs are rejected; positive IDs are preserved. Verified against `SadarRepository.deleteHabit`, `ActivityRepository.delete`, and `PresetRepository.delete`.
- `verification-gap` — Fixed: service test reloads `LauncherSettingsNotifier` after restore and observes the restored focus goal. Added native Isar transaction rollback test that throws after clearing the store and confirms the original record remains.
