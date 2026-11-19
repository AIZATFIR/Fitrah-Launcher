---
title: 'Make Home habit actions truthful and recoverable'
type: bugfix
created: '2026-11-09'
status: built
baseline_revision: 76c0c9cc4de66eafdc857748ab5f79cb719f1c2e
route: full
route_source: auto
risk: high
review: quick
review_source: pinned
lenses_ran: [quick]
review_loop_iteration: 0
context: []
---

<frozen-after-approval>

## Intent

Home habits must offer actions that match their units, commit before reporting success, and retain input after failure. A note must never complete a habit. Preserve the approved Home/dial/palettes and visible habit history rather than redesigning the app.

## Boundaries & Constraints

Always preserve measured seconds, existing occurrence target and other evidence during manual actions and notes. Use the existing repository and shared timer. Timer starts only for timed/minute habits with a usable callback; binary gets a completion action, count gets a total-count editor. Progression/hybrid show their existing step/set details and an explicit support limit without pretending to complete or running a generic minute timer. Their full occurrence execution remains a subsequent ecosystem requirement. Preserve legacy persisted data; no schema migration or destructive historical cleanup.

Never infer minutes from repetitions, target, Yes or a note; never launch a timer for count/binary/progression/hybrid; never close a failed editor or mark completion optimistically. Protect existing dirty build/web files and _bmad/render. Do not bypass the prior browser-access rejection.

## I/O & Edge-Case Matrix

| Scenario | Input/state | Expected behavior | Failure handling |
|---|---|---|---|
| Timed | timed/min target45, callback exists | Only this type exposes Play; existing shared callback starts exact habit ID; historical selected cells do not start today's timer | No callback means no dead start action |
| Binary | binary habit, check/uncheck/date chosen | Persist manual status for selected date with zero invented minutes | Disable repeated submission pending write; failed write keeps old state and retry |
| Count | target10, enter3 then10; same-name habits | Store chosen ID/date/value; partial below frozen target, fulfilled at target; zero invented minutes | Reject negative/noninteger/>9999, keep input on failure |
| Existing evidence | measured480 seconds/8min, target45, manual status/count change | Measured seconds/minutes and old target retained | No timer contribution overwritten |
| Notes | unmarked/yes/skip entry or none; write/clear note | Only note and updatedAt change for existing entry; new entry unmarked with zero duration | Editor remains with text/error; pending Back/dismiss cannot lose draft |
| Unsupported modes | progression/hybrid | Details show current step/rest or sets/duration, no generic Play/false completion | Support limit visible and no mutation |
| Accessibility | 320dp, text scale200%, long name | Action controls wrap without overflow, semantic labels and >=48dp hit targets for changed controls | Tests expose layout failure |

</frozen-after-approval>

## Code Map

- `lib/features/launcher/widgets/loop_habit_grid_widget.dart`: direct row Play ~447 and expanded actions ~674 currently unconditional; Yes/No/Skip writes not awaited. `_showNoteDialog` ~876 calls recordEntryStatus yes and immediately pops. Reuse existing habit editor busy/error pattern; replace action area only, preserve weekly grid and palettes. Use Wrap instead of fixed Expanded row if necessary, accessible Material controls and localized labels. Note editor must dispose controller safely after route removal.
- `lib/data/repositories/sadar_repository.dart`: `recordEntryStatus` ~276 defaults actualDurationMinutes from valueCompleted/target, overwrites measured summary on manual status; change omitted-duration behavior to preserve existing duration or zero for new entries, while retaining explicit duration arguments/preserveDuration contract. Never change exact seconds during manual mutation. Add `updateHabitEntryNote` transaction touching note/updatedAt only; create unmarked note entry when absent, validate habit exists for new entry. Memory path is explicit test preview only and must mirror native. Use transaction-local existing entry to avoid stale UI writes.
- `lib/features/launcher/widgets/home_intent_cue.dart`: existing binary/count actions demonstrate zero-duration and count validation. Reuse its behavior (including retained target) rather than introduce another timer. Avoid unnecessary global abstractions. If extracting a small shared manual editor is simpler, update both consumers/tests coherently.
- `lib/features/sadar/widgets/{today_view,quick_action_sheet,horizontal_timeline_grid}.dart`: callers of recordEntryStatus; inspect compatibility with new omission semantics. Explicit user duration input remains explicit; no API removal. `incrementHabitCount` should also stop inventing time through the shared fix.
- `test/loop_habit_save_test.dart`, `test/home_intent_cue_test.dart`, `test/sadar_repository_test.dart`, `test/scheduled_habit_evidence_test.dart`: existing provider injection/native helpers and regressions. Add focused `test/home_habit_actions_test.dart` and native repository cases if useful. No production dependencies.

## Tasks & Acceptance

- [x] Repository: first write failing cases for note-only behavior and manual unit/duration preservation, then implement default semantics plus note-only transaction. Cover native persisted transaction and explicit preview mode; preserve old test intent, never weaken expectations merely to match behavior.
- [x] Grid: implement type-specific primary actions, awaited mutations, pending state and visible recoverable errors. Notes preserve evidence, count editor keeps input, unsupported detail honest. Preserve selected historical date.
- [x] Verify each matrix row with executed focused repository/widget tests; run related cue/session tests and analyzer. Update BUILD-ROADMAP with exact coverage and remaining progression/hybrid/native/browser limits. Parent performs review before local commit; do not commit in builder.

Given Home with timed, binary and count habits, when each action is used, then only timed starts the shared timer and each manual action records its own source/date/unit. Given a failed note/count/status write, when retried, then input remains available and one successful write updates the same entry. Given an existing measured session, when a note or manual status changes, then duration and occurrence target remain unchanged.

## Implementation Notes

Owner repeatedly approved continuing approved UX/build autonomously, including routine design choices and preserved dirty artifacts; no fresh approval required. This plan continues E3/E4 and does not close the ecosystem goal. Prefer correcting existing actions over adding a new navigation destination or redesign.

Investigation guards: legacy source=timer entries may have minutes>0 with seconds=0; preserve/normalize that measured evidence before changing source to manual, otherwise subsequent timer credit loses it. Explicit nonnegative duration arguments remain supported. Add a repository absolute-count mutation resolving current stored targetSnapshot inside its transaction (validate live habit/type/archive); use from grid and cue so stale UI cannot change the target. Existing incrementHabitCount must reuse atomic count logic rather than read-before-write if touched. Note-only update must not normalize/change any other stored evidence. The cue's unsupported dialog currently implies Habits can record progression/hybrid correctly; correct that claim with the same honest detail. Avoid updating unrelated reporting in this slice.

## Review Triage Log

- Medium / patch — Quick reviewer confirmed collapsed-row Play bypassed the globally selected date in the current week (`!isExpanded`). The handler starts today's timer; previous-week-only coverage did not prove the current-week path. Require today's selected date for every row and cover another collapsed row while a different habit is expanded.
- Low / patch — Parent inspection confirmed `habitExecutionLimit` used hybrid details for any non-progression unsupported type. Backup permits arbitrary legacy habitType strings and TodayIntentProjection sends them to this helper, so the message could invent default sets. Add an explicit unknown-type fallback and regression; no source mutation is involved.

## Verification evidence

- Matrix run: 24 tests passed (8 widget and 16 preview/native repository), log `/tmp/home-habit-final.log`. Tests cover every matrix row, including note-only unmarked/yes/skip, clearing, exact duration/target preservation, reopen, atomic increments, count validation/snapshot, pending note/count dismissal and retry, status failure, and 320dp/200% controls. Related session run: 43 passed (`/tmp/home-habit-focused.log`, overlapping coverage). Final repository guard rerun: 16 passed (`/tmp/home-habit-repo-final.log`). Analyzer clean in 9.6 seconds (`/tmp/home-habit-analyze-final.log`); whitespace check clean. These results precede the review patches above.
- Review patches completed before the builder's usage-limit error: every direct Play now checks today's selected date, and unknown types get generic detail. Post-patch tests: 24 grid/cue tests passed (`/tmp/home-habit-review-fixes.log`). Parent independently inspected source/tests and ran the affected grid, repository, cue, save, scheduled evidence and backup suites together: 76 passed in 7 seconds (`/tmp/home-habit-parent-verification.log`). No test expectations were weakened; no full unrelated regression repeated.
- Final source analyzer clean (74.6 seconds) and JavaScript web compile passed (75.7 seconds), output `/tmp/focus-clock-home-actions-final-web`. Parent expanded binary coverage to exercise pending duplicate suppression and undo on the same entry; final grid-only rerun passed all 9 tests (`/tmp/home-habit-status-matrix-final.log`). No source change followed compilation. Whitespace check passed. Browser runtime, Android/device visual and TalkBack remain unverified.

## Verification

Run affected tests once after implementation and after relevant fixes; do not repeat unrelated full suites. Analyzer and diff whitespace check. Browser/runtime/device visual verification unavailable; do not claim it from widget tests or compile alone.

## 17 November progression follow-up

Sadar commits the selected progression step's target snapshot, daily entry, and next cursor in one transaction. Duplicate same-date completion calls are idempotent. The entry now stores a versioned snapshot of the exact step and prior entry state; Home and Sadar show that recorded step and offer undo only when the completion is still latest and the cursor/plan still match. Undo restores the cursor and prior status/value/target/completion/source while retaining note and measured-duration evidence. Legacy completed entries without a snapshot remain readable and do not show a false undo action. Preview and native Isar tests cover concurrent completion, safe undo, and snapshot persistence after close/reopen; live-model and backup codec round trips are covered. The wider ecosystem, daily-use observation, physical accessibility and later sync/AI/WhatsApp/MCP gates remain open.

## 17 November hybrid timer follow-up

Hybrid sessions on Sadar Today use the shared timer's saved plan (`set count`, `work seconds`, `rest seconds`), show current phase and set, and restore after pause/reopen. Completion maps elapsed session time to focused work seconds and fully completed sets; rest intervals do not inflate habit duration. Entry status becomes yes only when the saved set target is met. Native Isar reopen verifies active plan fields and hybrid completion evidence.

Home's selected hybrid habit now projects to an executable `Mulai rangkaian` action and opens the same `SadarTimerView` with its explicitly linked goal snapshot. The Home timer displays the set number, focus/rest phase, and phase countdown; its completion summary reports focused work separately from rests. Finishing during a rest credits only completed work sets and does not mark the target complete.

Home's progression action now shows the current day/step and asks for confirmation before saving. It calls `completeProgressionStep`, which records the selected target snapshot and advances the cursor in one Sadar transaction; repeated completion for that date remains idempotent. Undo/history remains open.

Focused verification: **83 tests passed** across intent projection/repository, Home cue, Sadar timer view/state machine, YPT shared timer, and native Isar persistence. Whole-project analyzer reports five existing info-level diagnostics in unrelated files; `git diff --check` passes. The Home hybrid path is widget-tested against the shared state and timer engine; visual/device accessibility review remains open.
