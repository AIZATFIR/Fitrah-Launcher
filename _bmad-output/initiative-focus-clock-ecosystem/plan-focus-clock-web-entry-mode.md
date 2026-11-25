---
title: 'Open Focus Clock web on the clock surface'
type: 'bugfix'
ticket: ''
created: '2026-11-23'
status: 'built'
baseline_revision: 'c1804baf5e0a4e05ccb9d4a94f84528d34154a4c'
route: 'oneshot'
route_source: 'auto'
risk: 'medium'
review: 'quick'
review_source: 'pinned'
lenses_ran: [quick]
review_loop_iteration: 0
context:
  - 'docs/ecosystem/2026-11-03/EXPERIENCE.md'
  - 'docs/ecosystem/2026-11-03/BUILD-ROADMAP.md'
---

<frozen-after-approval reason="Owner authorized continued Focus Clock ecosystem build">

## Intent

**Problem:** `build:focus` sets `APP_MODE=focus`, but `lib/main.dart` always renders Fitrah's shell at the Home page. The Focus Clock production target therefore ignores its selected mode and fails to open on its clock surface.

**Approach:** Route the existing Focus Clock mode to the Jam page in the shared Fitrah shell, while Fitrah and default builds continue to open Hari Ini. Keep one UI and store implementation so the modules remain connected.

</frozen-after-approval>

## Implementation Notes

One-shot fix in the existing four-page shell: read `selectedAppModeProvider` during initialization, open index 0 for Focus mode, and keep index 1 for Fitrah/default. Do not route through legacy `FocusClockApp`/`HomeShell`, which would split the product UI and storage behavior. The focused regression showed index 1 before the fix and index 0 after. The deployed Focus Clock page visually renders the analog dial with Jam selected.

## Verification

**Commands:**
- `flutter test --no-pub test/fitrah_launcher_test.dart --reporter compact` -- 13 tests pass; the new Focus mode regression failed before the fix because index 1 was selected.
- `flutter analyze --no-pub lib/features/launcher/fitrah_launcher_shell.dart test/fitrah_launcher_test.dart` and `git diff --check` -- clean.
- `flutter build apk --release --no-pub` -- APK 0.5.46 / 8138 built; package ID, versionCode and v2 signature verified.
- `npm run build:focus`, `npm run build:fitrah`, and `npm run build:sadar` -- all dedicated production entry points compile and bundle verification passes.
- Production deployments READY: Focus `dpl_4SDVSnfVmRv4U4zwhyYLqSdq71uT`, Fitrah `dpl_if9Cv2uqekpajyt4CUFVuvBG4Gbs`, Sadar `dpl_AMfU2bRaGoea2uZ33YxAQwrRKQM5`; each alias returns HTTP 200 and reports 8138.

**Acceptance Criteria:**
- Given the Focus Clock production build, when it opens, then Jam is selected first and Home remains reachable in the same shell.
- Given Fitrah or the default entry point, when it opens, then Hari Ini remains selected first.
