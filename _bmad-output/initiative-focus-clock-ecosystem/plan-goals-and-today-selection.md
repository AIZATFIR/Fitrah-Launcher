---
title: 'Remember a goal and act on a durable daily choice'
type: feature
created: '2026-11-08'
status: built
baseline_revision: 25acf837b7150a7dee4af5f02924604a096af4b1
route: full
route_source: auto
risk: high
review: quick
review_source: pinned
lenses_ran: [quick]
review_loop_iteration: 0
context:
  - /home/aizatfir/Project/Fitrah-Launcher/docs/ecosystem/2026-11-03/ARCHITECTURE.md
  - /home/aizatfir/Project/Fitrah-Launcher/docs/ecosystem/2026-11-03/DESIGN.md
---

<frozen-after-approval>

## Intent

Home must remember the user's longer-term direction and a distinct action chosen for today. Replace production's single free-text goal cue with durable goals, explicit optional links to existing habits/tasks, and a dated TodaySelection. Make the choice actionable through existing session/scheduling/check-in paths. This is the next core slice toward the already authorized ecosystem build, not completion of the entire objective.

## Boundaries & Constraints

Preserve the chosen clock face and bookpaper/palettes. Keep habits close on Home. Empty goals are allowed; no onboarding wizard or inferred links from matching titles/descriptions. Archive a goal without deleting habits, choices or evidence. Use existing local FocusStore, one repository owner and transactions; no preferences-only parallel domain data or silent memory success. New goal IDs are UUIDs. Persist sourceStoreId and stable mappings keyed by sourceStoreId/type/legacy ID; same integer IDs from separate sources are distinct. Existing schema names and IDs remain unchanged. Preserve dirty build/web and _bmad/render files. Leave preview fixtures supported.

## I/O & Edge-Case Matrix

| Scenario | Input/state | Expected behavior | Failure handling |
|---|---|---|---|
| Goals | Create, rename, pin, archive; duplicate titles | Independent UUIDs; pin persists; archive preserves links/evidence | Retain draft and expose retry, block duplicate submissions |
| Legacy | Existing focusGoal; repeat initialization/reopen | Import once with stable source mapping; user edits/archive/clear never resurrect old text | Failed migration leaves original text intact |
| Source links | Existing habit/task, optional goal, missing/archived source | Explicit stable link; rename does not break it; unavailable source shows honest state | Validate references within mutation; never match title |
| Daily choice | Choose/change/clear action, reopen, midnight, historical date | Persist per actual local date; old choice retained; historical browsing cannot change today's cue | Date is controllable in tests; no completion writes by projection |
| Cue priority | Running/paused session, incomplete chosen action, current/next agenda | Session first, then chosen action, then agenda labelled as planned; completed choice not prompted again | Loading/errors distinct from empty; preserve user selection |
| Action | Timed habit, binary/count, task, unsupported habit mode | Use the same engine/ID or unit-correct check-in; task opens exact-ID scheduling; unsupported mode never claims fake completion | Await commit, actionable error and retry; never replace active session |
| Durability | Reopen, failed write, multi-repository latest writes, backup/restore | Native and browser codec preserve goals/links/choices; rollback leaves old state; no lost independent edits | v1/v2 backups remain readable; new format rejected by old readers |

</frozen-after-approval>

## Code Map

- `lib/features/launcher/widgets/focus_clock_home_view.dart`: production `_buildFocusGoalCue(settings.focusGoal)` is text only. `_openHabitFocusTimer`, `_openScheduleToClockSheet(inboxTask:)`, `_startTimer` and existing shared timer UI are reusable. Keep sample cue. Pass existing palette colors to a separate intent widget; avoid growing the 6k-line Home with editors.
- `lib/features/launcher/widgets/loop_habit_grid_widget.dart`, `lib/data/repositories/sadar_repository.dart`, `lib/services/sadar_timer_engine.dart`: reuse durable habit/unit commands and shared engine. Some grid callbacks ignore write failures; do not copy that behavior. Timed and binary/count primary actions must be unit-correct. Preserve progression/hybrid data and expose explicit unsupported/detail behavior where no safe existing action exists.
- `lib/providers/providers.dart`, `lib/providers/sadar_providers.dart`: currentDateProvider is browsed date, not today's date. New projection must use actual local date and persisted data/session. Select meaningful session state to avoid extra second-based rebuilds.
- `lib/data/store/focus_store.dart`, `native_focus_store.dart`, `live_model_codec.dart`, `lib/data/isar_service.dart`: add one `FocusIntentDocument` singleton collection containing a validated versioned aggregate (goals, source mappings/links, dated selections, sourceStoreId, migration marker). Typed immutable domain objects and IntentRepository own semantics. Browser records table can accept the new codec collection without a SQL migration. Add native watcher. Generate only necessary Isar code then run `dart tool/fix_isar_schema_ids.dart`; preserve all legacy schema identities.
- `lib/features/launcher/providers/launcher_settings_provider.dart`: legacy cue is loaded asynchronously; import only after successful hydration. Don't clear legacy storage before successful import. Do not restart import on unrelated note changes.
- `lib/data/focus_clock_backup.dart`, `focus_clock_backup_service.dart`: backup explicitly serializes/restores eight models. Add intent collection with optional empty default for old fixtures, bump version to 3, validate nested structure/references and preserve identity on replace/compensation. Include count in preview. Update browser harness format assertion.
- `test/home_inbox_interaction_test.dart`, `home_schedule_service_test.dart`, `isar_service_persistence_test.dart`, `focus_clock_backup*_test.dart`: patterns for controlled UI failures and native open/reopen/transaction checks.

## Tasks & Acceptance

- [x] Add typed intent domain, singleton native schema/browser codec, transactional repository with latest-row read and migration; reject malformed/unsupported payloads instead of overwriting them. Guard stale edits with revision where applicable.
- [x] Add provider and pure today projection, independent of browsed history. Keep optional relationships and missing-source handling.
- [x] Add compact Home cue plus accessible goal/choice editors with visible Save/Cancel, busy/error/loading states. Goals and daily action are distinct. Preserve other layout and clock palette.
- [x] Carry intent through backup v3, old imports, recovery compensation and browser harness.
- [x] Verify every matrix row with meaningful focused domain/native/widget tests and backup roundtrip. Run analyzer and one web compile after fixes. Record any remaining unsupported device/runtime behavior accurately.

Given saved goals and a linked habit/task, when Home reopens, then the pinned goal and today's choice retain identity and can reach the correct existing action. Given a failure, when saving/retrying, then no fake success or duplicate identity occurs. Given an active session, when another action is selected, then the same session stays authoritative.

## Implementation Notes

User has repeatedly approved continuing to completion without additional checkpoints. The immediately preceding report presented this design and order. Existing source test follow-up was committed as 25acf837b7150a7dee4af5f02924604a096af4b1 before this slice. Browser UI previously rejected access; do not circumvent that restriction.

## Review Triage Log

## Verification

Focused intent repository/projection/widget and backup tests; native schema reopen; browser live codec. Analyzer. Build JS web to a fresh /tmp directory, never build/web. Update roadmap with evidence, not full-milestone completion.

Additional investigation: `Habit.effectiveHabitType` does not recognize literal binary; dispatch must inspect unit/type correctly. `incrementHabitCount`/`recordEntryStatus` are reusable; `advanceProgression` is separate and unsafe to combine naively. Hybrid has no dedicated set/rest engine, so never reinterpret its target as ordinary minutes. Home task scheduling does not start a timer; label it accurately. Backup compensation must include the new collection as well as ordinary restore.


### Implementation evidence — 8 November 2026

- `flutter test test/intent_repository_test.dart test/home_intent_cue_test.dart test/isar_service_persistence_test.dart test/home_schedule_service_test.dart test/home_inbox_interaction_test.dart`: **36 passed**. Covers independent UUID goals, pin/archive/revision conflicts, hydration gating and migration failure preservation, repeat import/reopen, stable source mapping including separate stores, missing/archived sources, real-date midnight/history/clear behavior, active and paused session priority, exact timed/task dispatch, scheduled-task block reuse, binary/count units and retained measured evidence, unsupported modes, busy/error/retry drafts, native rollback and latest-owner writes.
- `flutter test test/home_intent_cue_test.dart test/intent_repository_test.dart test/focus_clock_backup_codec_test.dart test/focus_clock_backup_service_test.dart test/live_model_codec_test.dart test/sadar_repository_test.dart`: **52 passed** (overlapping focused coverage). Includes v3 aggregate roundtrip, old v1/v2 readability, nested validation, restore stream refresh, deterministic repeated legacy restore and recovery compensation.
- `flutter test test/launcher_daily_note_widget_test.dart test/focus_clock_home_persisted_data_test.dart`: **13 passed** after correcting intent retry specificity, provider clock lifecycle and note viewport expectations.
- `dart run build_runner build --build-filter='lib/models/focus_intent_document.g.dart'` generated the new singleton; all eight existing generated model files were restored unchanged after the filtered generator removed them. `dart tool/fix_isar_schema_ids.dart` applied to the new schema. Native open/reopen tests passed.
- `flutter build web --no-pub --no-wasm-dry-run --output=/tmp/focus-clock-intent-web-final-20261108 --release`: **passed**. Existing `build/web` and `_bmad/render` artifacts preserved.
- Browser codec and browser harness fixture/format updated; live browser journeys were not run because prior browser access was rejected. Physical Android, TalkBack, and visual device validation remain unverified. Progression/hybrid detail explains the unsupported direct action and never claims completion.

- Final `flutter analyze --no-pub`: **No issues found** (5.2s). `git diff --check`: clean. Final busy-field focus hardening reran the goal save/retry/lock regression: **1 passed**.

### Review triage — 8 November 2026

- medium / patch: foreign-source editor collapsed sourceStoreId into local integer ID. Confirmed against editor and projection; now retains an unavailable-source item and saving unchanged performs no replacement. Focused widget regression passed.
- medium / patch: legacy direct scheduled task had a dead primary action. Confirmed against _openIntentTask; now opens the existing clock at saved date/half, with actual date/half restored on Home return. Focused cue/shell regressions passed.
- medium / patch: original card grouping/colors were dropped and goal-editor controls duplicated. Restored supplied surface/accent colors and one editor affordance; 320dp/200% layout case passed.

Final independent verification after review patches: `flutter test --no-pub --reporter expanded` — 175 tests passed, 24 seconds; `flutter analyze --no-pub` — no issues, 12.3 seconds. This is one full regression run because the new collection, backup and Home providers affect shared core paths. Browser runtime and physical device proof remain open.

### Build artifacts — source revision 2a6761fb365ca8d0f16cb6fedd64a970df479f55

- Final post-review Android arm64 release compile passed (198.9 seconds). Personal preview: `release_dist/2026-11-08-2a6761f/Focus-Clock-2a6761f-Android-arm64-preview.apk`, SHA-256 `ecde1ca743e1b09ae151ca71b1dab18d3683d7f6d857f58d1358809f98676824`. Package remains `com.aizatfir.fitrah_launcher`, version `0.5.3+7`, using the existing Android Debug signing identity. This is a preview, not a public stable signing release. Signature verification passed; arm64 libisar LOAD segments use 0x4000 alignment. No Android device is attached, so installation was not verified.
- Final post-review web compile passed (64.3 seconds) at `/tmp/focus-clock-home-2a6761f`. ZIP preview: `release_dist/2026-11-08-2a6761f/Focus-Clock-2a6761f-Web-preview.zip`, SHA-256 `51ec5258ec857e9d59443de1ad85bcd6a774c0918e62574284095a61f7fddfba`. BUILD-MANIFEST.json and SHA256SUMS accompany both artifacts. Local preview server is bound to 127.0.0.1:4174. No browser runtime/visual verification claim is made.
