---
title: Durable, usable launcher preferences
status: built
baseline_revision: 257d50a278af01d35f0dab57e60b800f34996231
review: 'quick'
review_source: 'pinned'
lenses_ran: [quick]
context:
  - lib/features/launcher/models/launcher_settings.dart
  - lib/features/launcher/providers/launcher_settings_provider.dart
  - lib/features/launcher/services/app_launcher_service.dart
  - lib/features/launcher/widgets/minimalist_app_drawer.dart
  - lib/features/launcher/widgets/niagara_unified_stream_view.dart
  - lib/features/launcher/widgets/fitrah_home_view.dart
  - lib/features/launcher/widgets/fitrah_settings_screen.dart
  - test/launcher_daily_note_test.dart
  - test/launcher_daily_note_widget_test.dart
---

<frozen-after-approval>
## Intent
Make launcher favorites and hidden applications durable and usable in the existing approved interface. Favorites must offer quick access; hiding must be reversible. Preserve clock, palettes, goals, daily notes, native capability truthfulness and existing storage. Owner already authorized implementation and affected verification; no approval pause needed.

## Scope and boundaries
Use existing LauncherSettings JSON and its serialized, commit-before-publish mutation queue. Do not add storage systems/dependencies or redesign the shell. Actual default Home role/status is the following slice, not this one. No Git push or release in this implementation. Do not touch pre-existing dirty build/web files or untracked _bmad/render. Do not access browser runtime: prior browser URL-policy rejection remains in force. Native emulator testing is permitted. Do not claim physical-device proof.

## Acceptance
1. Favorite and hidden package identifiers survive fresh settings hydration; prior JSON without fields remains compatible. Explicit empty favorites stays empty. New collections immutable, package validation deliberate, duplicates normalized. Malformed saved new fields surface load failure and cannot trigger destructive fallback writes. Keep valid IDs for temporarily unavailable/uninstalled applications.
2. Queue-backed idempotent per-package mutations return commit success; callers await them. No stale whole-set writes, optimistic false success, lost parallel settings changes, or updates after failed persistence.
3. Active drawer exposes a clear favorites shortcut section from actual installed visible apps, filters hidden apps in normal/search views, and provides hide/unhide management reachable even with every app hidden. Search contains each installed app once. Hiding a favorite preserves its favorite preference for restoration. Empty/no-results/unsupported/load-error states remain distinct and recoverable.
4. App options and hidden manager have pending/error/retry behavior. Failed save keeps the relevant surface usable; successful feedback follows commit. Prevent duplicate conflicting operations. Preferences loading/failure cannot briefly reveal saved hidden apps. Existing clock/core remains usable.
5. Every old favorite/hidden write site, including legacy stream undo, uses durable APIs. Other read consumers use read-only projections. No production fake app/storage fallback.
6. Changed controls fit 320dp and 200% text with accessible labels and at least 48dp targets. Preserve current visual language.
7. Drawer letter navigation remains accurate with favorites, hidden apps, long names and variable row heights; remove fixed-height offset assumptions if the prefix changes. Use a bounded simple solution without a new dependency.

## I/O & edge-case matrix
| Input / condition | Expected proof |
| --- | --- |
| Legacy settings JSON | Existing fields preserved; default favorite policy explicit; no hidden apps |
| Empty favorites, duplicates, unavailable valid package ID | Empty retained, duplicates normalized, unavailable preference retained |
| Invalid new JSON field type/entry | Visible settings load failure; no destructive write |
| Fresh notifier after successful favorite/hide change | Same saved preferences |
| Concurrent favorite/hide plus theme/note mutation | All committed values survive |
| Read/write fails then succeeds | No false success/publication; recovery retries successfully |
| Hide favorite then unhide | Absent normal/search/favorites while hidden; restored favorite afterwards |
| All apps hidden | Restore entry accessible and works |
| Initial hydration pending/fails | No hidden-app flash; recovery available |
| Search, unavailable native list, empty native list | Unique matches; truthful separate states |
| Offscreen letter after favorites/hidden and variable-height rows | Correct section reached, bounded/cancellable work |
| 320dp / 200% text app sheet and hidden manager | No overflow, usable labels/actions |
| Legacy favorite/hide/undo sites | Durable mutations with honest failure handling |

## Verification and stop
Add/run focused model/provider/widget tests for this matrix and existing impacted launcher tests. Run analyzer. Build only if needed for a meaningful compile checkpoint; don't rebuild both platforms repeatedly. Record exact evidence and remaining limitations. Stop this slice once matrix and analyzer pass and review fixes are addressed; broader ecosystem goal remains open.
</frozen-after-approval>

## Code map
Settings notifier already serializes _mutate and publishes only after write. Favorite/hidden providers currently use volatile StateProvider sets. Active drawer has favorite option but no quick favorite surface or hide management; letter scroll assumes fixed heights. Legacy Niagara contains additional direct set writes and hide undo. Reuse daily-note storage fakes for failure/delay cases.

## Implementation log
- Implemented durable immutable favorite/hidden collections in existing settings JSON, with strict malformed-data failure, explicit legacy defaults, and preserved empty/unavailable preferences.
- Added per-package queued commit APIs and read-only projections. Migrated active and legacy app options and undo to the shared durable sheet; home/legacy read consumers respect hidden preferences and hydration.
- Added visible installed favorites, unique filtered search, always-reachable hidden management, failure/retry/pending controls, and variable-height letter seeking with cancellation.
- Restored clock/calendar/settings access in scrollable pending/error recovery after review feedback; app rows remain gated.
- Corrected stale frontmatter context paths from views/ to widgets/. Added 29 focused tests and updated existing drawer tests to explicitly inject test storage.
- Verification evidence: [durable-drawer-verification.md](durable-drawer-verification.md). No build/web, render, browser runtime, push or release work performed.

## Review / verification
- Pre-review affected suite: 102 tests passed; analyzer: no issues; diff whitespace check: clean.
- Hydration-header review fix: affected drawer widget/capability suite passes all 15 tests. Final full verification and review acceptance remain with the parent agent.
- Detailed commands, coverage, sequence and limitations recorded in [durable-drawer-verification.md](durable-drawer-verification.md).

## Review Triage Log
- medium / patch — reviewer found hydration failure removes clock/calendar/settings header. Verified the !preferences.isLoaded branch renders only a message while _buildClockHeader is inside data content. Keep header accessible in the gated recovery branch, without exposing hidden app rows; add a focused assertion for pending/failure.

## Parent acceptance
Reviewed the complete source/test diff, all matrix rows mapped to the 29 new and existing capability tests. Final parent run: 35 preference/drawer/capability tests passed in 3 seconds; flutter analyze --no-pub clean in 6.5 seconds. Review hydration-header finding fixed and tested; reviewer inspected final shared sheet with no additional findings. No deferred findings from this slice. Native/runtime proof remains separate.
