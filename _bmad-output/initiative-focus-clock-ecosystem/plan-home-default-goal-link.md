---
title: 'Link a new daily action to the active goal by default'
type: 'feature'
ticket: ''
created: '2026-11-21'
status: 'built'
baseline_revision: '29e53947d366a6db7a6c6c05c46ddde7bc2baf94'
route: 'oneshot'
route_source: 'auto'
risk: 'low'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 1
context:
  - docs/ecosystem/2026-11-03/EXPERIENCE.md
  - docs/ecosystem/2026-11-03/BUILD-ROADMAP.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Choosing today's next action asks for a task/habit and then an optional goal even though Home already shows the user's active goal. This adds a decision to the most important daily action.

**Approach:** When creating a new daily choice, preselect the active pinned goal in the existing goal field. Keep “Tanpa tujuan” available, and preserve the current link (including no link) when editing an existing choice.

</frozen-after-approval>

## Implementation Notes

- The existing `HomeIntentCue._choose` dialog already reads `IntentState.pinnedGoal` and displays the selected goal, so no storage/schema change is needed.
- Change the initial goal only when no task/habit is currently selected. Existing choices without a link remain unlinked unless the user explicitly changes the field.
- Updated `lib/features/launcher/widgets/home_intent_cue.dart`; no schema, timer, or clock-face changes.
- Review caught that a stored cleared choice (`sourceId: null`) is distinct from no choice. The default now applies only when no `TodaySelection` exists for that date.
- Package as owner preview 0.5.35 / versionCode 8126 so an existing v8125 install can upgrade.
- Keep the current clock face, palette, dialog layout, and selection/save flow.

## Verification

**Commands:**
- `flutter build apk --release --no-pub` -- passed; produced v0.5.35 / versionCode 8126 universal APK.
- `npm run build:focus` -- passed; web output/version.json is v0.5.35 / build 8126 and `verify_web_bundle.sh` confirms required offline assets.
- Vercel production deploy `dpl_F73MhppKnx7svtfjewJu2zHRputB` -- READY; alias and required assets returned HTTP 200.

**Manual checks:**
- API 36 x86_64 AVD upgraded v8125 to v8126 with its saved goal, daily action, timer total, and HOME role intact.
- Cleared the QA daily choice, reopened the picker, and confirmed it remained “Kosongkan pilihan” / “Tanpa tujuan”; restored the prior QA task and goal link.
- Fresh isolated web origin: added a synthetic pinned goal and inbox task; new daily-action picker showed the pinned goal selected and retained the “Tanpa tujuan” option.
- UI screenshot retained the Bookpaper palette and analog dial; no change to clock-face layout.

## Review Triage Log

- medium — patch — first review found `sourceId: null` represents a durable cleared choice, not an absent selection. The default now checks `selectionFor(date) == null`; quick re-review found no remaining issue.
