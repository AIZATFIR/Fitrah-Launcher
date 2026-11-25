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
- Full Flutter suite: 468 tests passed serially. Four pre-existing stale test assumptions were corrected without changing production behavior: viewport size, primary CTA type/label, and pending animation timing.
- Analyzer reports 5 existing info diagnostics in unrelated files; no errors or warnings. `git diff --check` is clean.
- APK and three JavaScript release web bundles build and deploy as 0.5.49 / 8141. API36 clean-install system chooser smoke verified the HOME role, reboot persistence, foreground Home activity, and force-stop relaunch; no app fatal/FlutterError/ANR in sampled logs.
