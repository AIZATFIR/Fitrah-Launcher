---
title: 'Honest Hari Ini Home data'
type: feature
ticket: ''
created: '2026-11-04'
status: 'built'
baseline_revision: '1de34da466af52a5e50ff7191665304a66a5f54f'
route: 'full'
route_source: 'auto'
risk: 'high'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 0
context:
  - docs/ecosystem/2026-11-03/PRD.md
  - docs/ecosystem/2026-11-03/EXPERIENCE.md
  - docs/ecosystem/2026-11-03/DESIGN.md
  - docs/ecosystem/2026-11-03/BUILD-ROADMAP.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Home currently invents a Programmer identity and sleep blocks, writes them into the schedule store, then derives the Now label from a separate local list. Fresh installs can show false user data; existing schedules can disagree with the dial and status. First boot must help the user see their own day, not an assumed demo persona.

**Approach:** Stop seeding sample presets/habits and remove production-only fake identity/schedule data and automatic schedule writes. Keep explicitly requested demo data isolated behind `useSampleData`; render the dial, chronological agenda and current activity from the same persisted Activity stream, with a clear empty state.

## Boundaries & Constraints

**Always:** Preserve existing user rows and schema IDs. Keep AppSettings initialization. Use ActivityRepository as schedule owner. Preserve the approved Home hierarchy, palette and AnalogClockFace. Keep fake fixtures only when caller explicitly requests sample data. Report empty/paused/unknown states truthfully.

**Never:** Delete existing preset/habit/activity records, silently migrate IDs, persist demo content, replace the dial or change timer ownership in this slice. Do not use the local Home `_blocks` as fallback production truth when the repository is empty.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Fresh install | No user schedules, habits or presets | Empty schedule and user-owned habit section; no Programmer/sleep/preset/habit records are auto-created | Storage-open recovery remains visible |
| Existing day | Persisted Activity rows for today | Dial, chronological list and Now label derive from the same rows | Provider loading/error must not report “Waktu Luang” as confirmed |
| Explicit preview | `useSampleData=true` | Preview fixture remains available only to its explicit caller | No fixture row is written to repositories |

</frozen-after-approval>

## Code Map

- `lib/data/isar_service.dart` -- `_seed` inserts seven generic presets and five habits; retain only technical `AppSettings` initialization, never delete existing rows.
- `lib/features/launcher/widgets/focus_clock_home_view.dart` -- `initState` production branch inserts false identity/sleep blocks; `_syncInitialActivitiesWithSharedRepo` writes them on first open; `_buildHomeScreen`, `_buildCenterFocusClockDial`, `_buildChronologicalListView`, `_getCurrentActivityInfo`, `_toFocusClockActivities` currently read divergent sources.
- `lib/providers/providers.dart` and `lib/data/repositories/activity_repository.dart` -- `activitiesByDateProvider` / `watchByDate` are the persisted date projection to reuse.
- `lib/models/activity.dart` and `lib/core/time_math.dart` -- preserve Isar schema and half-day time convention when deriving dial/current state.
- `docs/ecosystem/2026-11-03/{PRD,EXPERIENCE,DESIGN,BUILD-ROADMAP}.md` -- product invariants and approved hierarchy.

## Tasks & Acceptance

**Execution:**
- [x] `lib/data/isar_service.dart` -- remove generic sample Preset/Habit inserts while retaining settings initialization and all persisted user content.
- [x] `lib/features/launcher/widgets/focus_clock_home_view.dart` -- isolate demo fixtures to explicit preview; remove production fake identities/blocks and automatic DB sync; derive current label, dial and chronological list from one Activity stream and show honest empty/loading/error states.
- [x] `docs/ecosystem/2026-11-03/BUILD-ROADMAP.md` -- record this slice as in progress/complete only with the evidence actually observed; keep E1/E2 gates open.

**Acceptance Criteria:**
- Given a newly opened empty database, when the app initializes, then no sample habits, presets, identity or sleep schedule is created.
- Given persisted activities for today, when Home renders, then dial, list and current status use those same persisted rows.
- Given no persisted activities, when Home renders, then it shows an empty schedule without substituting demo blocks or claiming a real activity.
- Given `useSampleData=true`, when a preview is opened, then sample content is visible only in the preview and never written to Isar.
- Given an existing database with rows, when this change starts, then those rows and all schema IDs remain unchanged.

## Implementation Notes


## Plan Change Log


## Review Triage Log

- medium — fixed — `_findConflict` now checks persisted Activity projections; production cannot create overlapping agenda blocks through this path.
- medium — fixed — agenda completion and deletion use `ActivityRepository`; preview interactions remain local.
- medium — fixed — timer completion now commits the persisted activity and guards against duplicate completion while an async write is pending.
- medium — fixed — `_getCurrentActivityInfo` now skips completed activities; regression coverage proved a completed block previously remained the Home “now” label during its scheduled interval.

## Design Notes

Demo fixtures are presentation-only. Production queries must not fall back to them on an empty repository; otherwise first-run and data-loss states become indistinguishable from real plans. Current Activity time is calculated from `ampmHalf` plus half-day minute values; an end equal to the start must not be presented as an active event.

## Verification

**Commands:**
- `flutter analyze --no-pub` -- passed, no issues.
- `flutter test --no-pub test/focus_clock_home_persisted_data_test.dart test/focus_clock_home_lampiran1_test.dart` -- passed, 15 widget tests, including the completed-activity status regression.
- `flutter build apk --debug --no-pub --split-per-abi` -- passed; arm64 artifact SHA-256 `6cd142a32b484bada7249f87248e45d3348552bff51abaa173ddbe6c621a8133`.
- `git diff --check` -- passed.

**Manual checks:** none; no Android device/emulator is attached. Widget tests cover empty Home, a persisted Activity projection, and the existing explicit sample preview flow. Device persistence/reboot/upgrade and preview non-persistence at the Isar boundary remain E0/E1 gates and are not proven by these commands.
