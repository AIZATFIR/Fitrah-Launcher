---
title: 'Keep Home habits connected to saved data'
type: bugfix
created: '2026-11-07'
status: built
baseline_revision: f997757a9d477b958b99c6390f8d9ce9408c9d2e
route: oneshot
route_source: auto
risk: medium
review: quick
review_source: pinned
lenses_ran: [quick]
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="owner authorized continuing the approved ecosystem build">

## Intent

Home currently presents a second habit section backed only by widget state, so a habit created there disappears on reopening and duplicates the real habit grid. Show one durable habit surface in production: the existing Sadar-backed grid, retaining the sample-only section for preview fixtures. Make creating and editing a habit in that grid wait for repository persistence, prevent duplicate saves, and show a recoverable error without dismissing the editor if saving fails. Preserve the approved clock face, theme, and existing stored habits.

Given a normal Home, when the user opens habits, they see the repository-backed grid and no local-only duplicate. Given a habit editor, when the user saves a valid name, the editor closes only after saving; a failed save leaves the editor open with an error and the input intact. Existing previews remain available.

</frozen-after-approval>

## Implementation Notes

Home now shows the repository-backed grid in production, while sample previews keep the old demo section. The editor waits for persistence, preserves input on errors, and removes the description input that had no storage field. While a write is pending, dismissal and editing are blocked to keep the outcome visible.

## Plan Change Log

## Review Triage Log

- Medium, patched: the sheet could be dismissed during an outstanding write, losing a failure message and allowing duplicate creation. Disabled barrier/drag, back navigation and editing during the write; the pending-save widget test covers barrier/back and verifies one write.

## Verification

Home/habit suite: 20 passed. After the review fix, the two habit save/retry tests passed; `flutter analyze --no-pub` reported no issues.
