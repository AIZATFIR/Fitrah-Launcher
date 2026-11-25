---
title: Keep the Home action editor in the selected palette
type: bugfix
ticket: ''
created: '2026-11-14'
status: built
baseline_revision: 'b071a79ba02585ac59f50e09899e916984ae8ad3'
route: 'full'
route_source: 'pinned'
risk: 'low'
review: 'No actionable findings in independent palette, route-scope, behavior, and accessibility review.'
review_source: 'dialog_theme_review subagent'
lenses_ran: ['independent code review']
review_loop_iteration: 0
context:
  - /home/aizatfir/Project/Fitrah-Launcher/docs/ecosystem/2026-11-03/DESIGN.md
  - /home/aizatfir/Project/Fitrah-Launcher/docs/ecosystem/2026-11-03/BUILD-ROADMAP.md
---

<frozen-after-approval reason="human-owned intent — existing authorization to continue Focus Clock ecosystem implementation">

## Intent

**Problem:** On the actual Home screenshot, the “Tindakan hari ini” editor uses the default sage-green dialog and fields while the selected Home palette is sky blue. This breaks visual continuity at the moment the user chooses what to do next.

**Approach:** Apply the palette colors already passed into `HomeIntentCue` to its modal action dialogs, including dialog surface, text, input fields, borders, and primary action. Keep the existing editor layout and behavior.

## Boundaries & Constraints

**Always:** Respect the user's selected Home palette and existing foreground/surface contrast; preserve the saved goal, action selection, optional goal link, busy/error/retry behavior, and responsive layout.

**Never:** Change the app-wide palette, clock face, database/domain behavior, dialog copy, editor layout, or unrelated dialogs/screens. Do not add dependencies or use a hardcoded sky-blue theme for every palette.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Sky palette | Open action editor from blue Home | Dialog, fields, labels, borders, and save action use blue Home semantic colors | No error expected |
| Other palette | Open action editor with sand/sage Home colors | Dialog follows those supplied colors instead of reverting to sage defaults | No error expected |
| Save failure | Editor write fails | Draft and visible failure/retry remain unchanged under the local palette | No false success |

</frozen-after-approval>

## Code Map

- `lib/features/launcher/widgets/focus_clock_home_view.dart::_buildHomeScreen` -- resolves `_HomeThemeColors.fromPalette` and passes foreground, secondary, accent, and surface to `HomeIntentCue`; reuse these values rather than duplicating palette constants.
- `lib/features/launcher/widgets/home_intent_cue.dart::_showIntentDialog` -- creates the modal route for action selection, count, and unsupported-action dialogs. Wrap its builder in a local `Theme` derived from the selected Home colors; leave `_GoalEditor` bottom-sheet behavior out of scope.
- `lib/features/launcher/widgets/habit_action_save_dialog.dart::HabitActionSaveDialog` -- shared Material `AlertDialog`, `DropdownButtonFormField`, and `InputDecoration` consume the inherited theme; do not fork the dialog component.
- `test/home_intent_cue_test.dart::show` and choice-editor test -- widget harness supplies `HomeIntentCue` colors and verifies the route theme while existing save/link/retry checks protect behavior.

## Tasks & Acceptance

**Execution:**
- [x] `test/home_intent_cue_test.dart` -- prove the action-editor route receives the selected palette and its inputs/dialog do not use the global sage defaults.
- [x] `lib/features/launcher/widgets/home_intent_cue.dart` -- provide a local palette-aware theme to intent dialogs, preserving current component and save flow.
- [x] `docs/ecosystem/2026-11-03/BUILD-ROADMAP.md` -- record screenshot/runtime evidence without marking the Home gate complete.

**Acceptance Criteria:**
- Given Home uses the sky-blue palette, when the user opens “Pilih tindakan hari ini”, then dialog and input surfaces use the same blue palette and readable foregrounds.
- Given another selected palette, when any intent editor dialog opens, then semantic colors follow that palette rather than the app's fixed sage theme.
- Given the save fails, when the dialog shows its retained draft and retry, then existing behavior remains intact.

## Implementation Notes

The local `Theme` is scoped to the three intent `DialogRoute`s. It derives surfaces, foreground, accent, input decoration, popup-menu styling, and progress indicator colors from `HomeIntentCue`; the shared dialog widget and its save/retry flow remain unchanged. The test covers sky-blue and sand palettes and confirms failure keeps the route palette.

## Plan Change Log

- Added the local progress-indicator color after review noted it would otherwise retain the global theme during save.

## Review Triage Log

- Independent review: no actionable correctness, route-scope, palette, or accessibility findings. Existing editor layout and durable save/retry behavior stay unchanged.

## Design Notes

The intent cue is a key moment in the product's main loop: see the goal, choose today's action, then start. The modal should feel like a continuation of the selected Home surface, not a separate app theme. Reuse the same colors already rendered by Home; avoid a new palette model or a global-theme migration.

## Verification

**Commands:**
- `flutter test --no-pub test/home_intent_cue_test.dart` -- choice editor theme plus existing save/link/retry behaviors pass.
- `flutter analyze --no-pub` -- no issues.
- `git diff --check` -- clean for source/plan changes.
- `flutter build apk --debug --target-platform android-x64 --build-number 34 --no-pub` -- successful.

**Manual checks:**
- Installed versionCode34 on the disposable API36 x64 AVD; cold-started, opened “Pilih tindakan hari ini” under `sky_blue`, and confirmed dialog/field surfaces and text follow the selected palette while the goal cue and clock retain their colors. Screenshot: `/home/aizatfir/Project/Fitrah-Launcher/.dart_tool/android-qa/2026-11-14-v33/v34-action-picker.png` (SHA-256 `53a13e409491c250b81a67b7ddd4a89c44b045e44ae13a18c83ea756e1574e62`). Synthetic QA goal only; `Medium_Phone` untouched.
