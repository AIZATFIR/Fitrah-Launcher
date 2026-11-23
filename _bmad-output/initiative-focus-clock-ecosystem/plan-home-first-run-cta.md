---
title: Put Android Home setup beside the goal
created: 2026-11-23
type: feature
status: built
baseline_revision: ea3ccdba7f49e152244421347abe23afb60617a4
route: oneshot
route_source: owner-request
risk: low
review: quick
review_source: pinned
lenses_ran: [quick]
context:
  - lib/features/launcher/widgets/home_intent_cue.dart
  - lib/features/launcher/widgets/default_home_status_control.dart
  - lib/features/launcher/services/app_launcher_service.dart
  - test/features/launcher/default_home_quick_action_test.dart
---

## Intent
Make first-run Android setup discoverable from the main goal card: users can make Fitrah their Home app where their goal already lives.

## Boundaries
Reuse the existing native Home-role request and actual status provider. Show a compact, accessible action only on supported Android when the system confirms Fitrah is not default. Hide it on other platforms, while status is unknown, and after Home changes. Keep detailed diagnostics in Settings. No new permission, role assumption, screen, package, or change to clock, palette, or goal content.

## Acceptance
- CTA hidden off Android, during unknown/loading/error, and when Fitrah is already default.
- CTA dispatches the Android system chooser and never claims selection based only on dispatch.
- Request failure remains understandable and retryable.
- Existing Home/default-role behavior and 320dp/200% layout remain intact.

## Verification
- Quick code review found the 200% narrow-screen risk; a 320dp / 200% widget case passes with a 48dp minimum action target.
- Focused suites: 38 passed across the CTA, Home role control, and Home intent cue.
- Analyzer reports 5 existing info diagnostics in unrelated files; no errors or warnings. `git diff --check` is clean.
- APK and three JavaScript release web bundles build as 0.5.49 / 8141; API36 system chooser smoke and deployment checks are being completed for the release package.
