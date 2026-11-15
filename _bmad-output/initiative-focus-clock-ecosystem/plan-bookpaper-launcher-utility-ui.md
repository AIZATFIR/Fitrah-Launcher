---
title: 'Bring launcher utility surfaces into Bookpaper'
type: 'feature'
ticket: ''
created: '2026-11-15'
status: 'built'
baseline_revision: 'e5d3230824bd16bca712a715f0a6e7cb1a61ccc6'
route: 'full'
route_source: 'pinned'
risk: 'low'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 0
context:
  - 'docs/ecosystem/2026-11-03/DESIGN.md'
  - 'docs/ecosystem/2026-11-03/BUILD-ROADMAP.md'
---

<frozen-after-approval reason="Owner approved ongoing Bookpaper Focus Clock ecosystem implementation and asked that launcher UI match the existing Focus Clock branding">

## Intent

**Problem:** The launcher’s default-Home status and app action sheet use generic black/white styling, English labels, and loose spacing. These surfaces appear during the core task of choosing Fitrah as Home and launching or managing installed apps, so they weaken clarity and the approved Bookpaper identity.

**Approach:** Reuse the shared Focus Clock palette, Outfit theme, and Material components to bring both utility surfaces into the same charcoal-and-amber visual language. Keep the OS role flow, native app actions, and durable preference behavior intact while making their Indonesian labels and feedback clear.

## Boundaries & Constraints

**Always:** Preserve the real Android default-Home status/request/settings behavior, the current launch/app-info/uninstall dispatch, and favorite/hidden preference persistence. Keep controls operable with screen readers, large text, and 48dp minimum targets. Use existing theme tokens and no decorative emoji.

**Never:** Add dependencies, infer success from launching the Android chooser, change package access/permissions, or change which actions system apps expose.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Default Home unknown | Android status request is loading or fails | Clearly label checking/unknown state and keep retry available | Never claim Fitrah is selected without Android confirmation |
| Default Home action | Fitrah is not selected, then user opens Android chooser | Show the current status after returning; user remains in control of selection | Cancel or another launcher leaves the state unselected |
| App action sheet | User opens options for an installed app | Show app identity and favorite, hide, system info, and eligible uninstall actions in Bookpaper styling | Failed save or dispatch stays visible and retryable |

</frozen-after-approval>

## Code Map

- `lib/core/theme.dart` -- canonical `AppPalette`, Outfit text theme, surfaces, and component shapes. Reuse these tokens; do not add a parallel palette.
- `lib/features/launcher/widgets/default_home_status_control.dart` -- Android role state, chooser/settings actions, pending state, and retry. Restyle the existing widget without changing its provider or dispatch flow.
- `lib/features/launcher/widgets/app_preferences_sheet.dart` -- app identity and durable/native actions. Keep the existing notifier commits, undo, and feedback context; change presentation and labels only.
- `lib/features/launcher/widgets/fitrah_settings_screen.dart` -- contains the default-Home control and current Bookpaper settings container.
- `test/features/launcher/default_home_status_control_test.dart` -- covers unknown, pending, selected, cancelled, failed, and unsupported states; preserve those assertions with updated copy.
- `test/launcher_drawer_preferences_widget_test.dart` -- covers durable drawer preferences and app-info dispatch; extend or update the app sheet assertions here.

## Tasks & Acceptance

**Execution:**
- [x] `default_home_status_control.dart` -- apply shared Bookpaper colors, typography, and grouped status/action hierarchy while preserving role checks and retry.
- [x] `app_preferences_sheet.dart` -- match the Bookpaper sheet and localize user-facing app actions without changing their handlers.
- [x] `default_home_status_control_test.dart`, `launcher_drawer_preferences_widget_test.dart` -- assert localized states, minimum action targets, and unchanged native/persisted outcomes.

**Acceptance Criteria:**
- Given launcher settings are open, when Android reports Fitrah selected, not selected, or unknown, then each state has clear Indonesian text and a usable next action in the shared theme.
- Given an app’s options are open, when the user favorites, hides, opens system info, or uninstalls an eligible app, then the existing action executes and save/dispatch failure remains recoverable.
- Given a 320dp screen or 200% text scale, when either surface is open, then controls remain visible by scrolling, readable, and at least 48dp high.
- Given any surface, when the UI renders, then it uses the Focus Clock charcoal/amber palette and has no decorative emoji.

## Implementation Notes

## Plan Change Log

## Review Triage Log

## Verification

**Commands:**
- `flutter test test/features/launcher/default_home_status_control_test.dart test/launcher_drawer_preferences_widget_test.dart --reporter compact` -- focused behavior/layout tests pass.
- `flutter analyze --no-pub lib/features/launcher/widgets/default_home_status_control.dart lib/features/launcher/widgets/app_preferences_sheet.dart test/features/launcher/default_home_status_control_test.dart test/launcher_drawer_preferences_widget_test.dart` -- no issues.
- `flutter build web --release --no-pub` -- succeeded; Flutter reported dependency-only WebAssembly dry-run incompatibilities, while the standard web build completed.
- `git diff --check` -- clean.

**Manual checks:**
- Inspected the existing launcher Home and Focus Clock Bookpaper web reference. The changed app-action and hidden-app sheets were not visually inspected on a device; the disposable QA AVD was not run, no physical device was attached, and the owner `Medium_Phone` AVD remains untouched. Widget coverage checks the Bookpaper surface color and action targets.
