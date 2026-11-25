---
title: 'Calm empty-canvas UI and model-neutral AI setup'
type: 'feature'
ticket: ''
created: '2026-11-21'
status: 'built'
baseline_revision: '51ef42aef32919f510fe7c42440426b78e690cc2'
route: 'oneshot'
route_source: 'auto'
risk: 'low'
review: 'none'
review_source: 'pinned'
lenses_ran: []
review_loop_iteration: 0
context:
  - docs/ecosystem/2026-11-03/EXPERIENCE.md
  - docs/ecosystem/2026-11-03/DESIGN.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Focus Clock and companion screens crowd user-created moments with sample phrases, preset suggestions, and long input hints. The empty AI setup state also gives provider-specific guidance even though the app supports several providers.

**Approach:** Keep new user input fields empty and visually quiet across the app, remove sample text that competes with the user's own thinking, retain saved values when editing, and show concise provider-neutral setup guidance when AI is not configured.

</frozen-after-approval>

## Implementation Notes

Removed sample answers and long hints from goal, intention, AI chat, timer, journal, reflection, habit, and task entry across Focus Clock, Sadar and launcher UI. Removed preloaded quick-intent examples. Existing saved values remain visible when editing. AI setup guidance now names only Pengaturan AI; execution mode distinguishes an unconfigured provider from a working backend. Updated the experience contract for empty user-authored fields.

## Verification

**Commands:**
- `flutter test --no-pub test/now_next_card_large_text_test.dart test/ai_action_proposal_test.dart` -- 23 passed.
- `flutter analyze --no-pub` -- no errors/warnings; 5 existing info notices in unrelated files.
- `flutter build apk --release --no-pub` -- passed; APK metadata 0.5.39 / 8130, v2 signature verifies.
- `npm run build:focus` -- passed; JS web bundle verified. Wasm dry-run reports existing Isar/secure-storage/TTS incompatibilities.
- `unzip -t ...Focus_Clock_Web_0.5.39_v8130.zip` -- passed.
- Production deploy `dpl_RM1DYKPcMaq3dvWsMzmWkJYzotJv` -- READY; alias HTTP 200 and version endpoint 0.5.39 / 8130.
- `git diff --check` -- clean.

**Manual checks:** Installed v8130 over the existing API 36 x86_64 `FocusClock_UI_QA` data. Package metadata reports 0.5.39 / 8130, first install time is unchanged, `com.aizatfir.fitrah_launcher` remains Android HOME, the Home screen opened with the QA goal intact at 200% text, and the sampled log has no app fatal/ANR/FlutterError. No physical phone was connected; live model calls were not tested.
