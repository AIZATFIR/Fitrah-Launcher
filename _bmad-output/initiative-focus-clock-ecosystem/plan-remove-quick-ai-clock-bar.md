---
title: 'Remove the duplicate quick AI prompt from the clock surface'
type: 'ui-simplification'
ticket: ''
created: '2026-11-24'
status: 'built'
baseline_revision: 'ebaaaeb'
route: 'oneshot'
route_source: 'auto'
risk: 'low'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="Owner asked to inspect the ambiguous text feature and remove it if redundant">

## Intent

**Problem:** The Focus Clock surface shows a floating “Gemini AI Focus” prompt while a separate AI chat surface and a direct natural-language activity input already exist. The floating prompt sends free text through voice-command handling and displays a temporary status, which makes its purpose unclear.

**Approach:** Remove the floating prompt only from the full clock surface. Preserve the activity input and full AI conversation surface. Keep the prompt in Simple Mode, where it is a distinct quick-command surface.

</frozen-after-approval>

## Implementation Notes

Removed the floating quick-AI overlay and its import from `HomeShell`. This is applied in the standalone Focus Clock checkout and the Fitrah Launcher ecosystem source. No user data or settings change. Version advances to 0.5.60+8152 for the next distributable.

## Verification

- `flutter analyze --no-pub lib/features/shell/home_shell.dart` — passed.
- `git diff --check` — passed.
- Full multi-platform release build and web deployment are pending for v8152.
- No Android device is connected for a visual runtime check.
