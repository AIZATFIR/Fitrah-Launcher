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

**Approach:** Remove the floating prompt from the full clock and Simple Mode. Preserve the activity input, the full AI conversation surface, and the clock screen's dedicated AI chat shortcut.

</frozen-after-approval>

## Implementation Notes

Removed the floating quick-AI overlay from `HomeShell` and Simple Mode, then deleted its unused component. The settings copy now describes the remaining AI chat shortcut. The activity input, full AI conversation surface, and clock screen's AI chat shortcut remain. No user data or settings change. Version advances to 0.5.61+8153 for the next distributable.

## Verification

- `flutter analyze --no-pub lib/features/shell/home_shell.dart` — passed.
- `git diff --check` — passed.
- Fresh scoped analyzer for Simple Mode and Settings passed. `git diff --check` passed.
- GitHub release run [45434240365](https://github.com/AIZATFIR/Fitrah-Launcher/actions/runs/45434240365) passed all six platform builds and APK signature verification; six artifact checksums passed.
- Production deployments for all three web apps reached READY; authenticated requests for each main bundle returned HTTP 200.
- v8153 release includes six platform downloads, checksums, and the verified all-platform ZIP. No v8153 emulator interaction test was run; HOME behavior evidence remains from v8152, and no physical/OEM phone was available.
