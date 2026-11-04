# Architecture seam review

Date: 2026-11-03. Lens: independent feature builders obeying the same ADs but choosing incompatible semantics. Reviewed ARCHITECTURE.md, PRD.md and BUILD-ROADMAP.md. Read-only review; no application implementation or runtime tests.

**Verdict: strong brownfield spine; amend four high-priority contracts before E1–E3 builders work independently.** No critical finding. E8 ownership refinement can wait for E8, but must remain an explicit blocking contract there.

## High findings

### H1 — Daily occurrence identity and snapshot effective date are not convergent

**Locations:** ARCHITECTURE.md:96,102,108,114,160; PRD.md:74; BUILD-ROADMAP.md:44,78.

Builder A creates a UUID occurrence when Today first reads a habit and snapshots its then-current target; builder B lazily creates it when a check-in/session is saved. Both obey UUID IDs, separated definitions and immutable snapshots, yet a target edit between those actions yields two targets for the same habit/day. Two offline devices can also create different UUIDs for the same day and separately advance progression, because only schedule occurrence identity is fixed to series/date. Neither an archive boolean nor today's target can reconstruct applicable habits/targets for an unvisited past date, despite FR-08 requiring that denominator.

**Fix:** bind habit occurrence uniqueness to workspace/habit/local-date (or an equally explicit logical key independent of generated record UUID). Define effective-dated definition/schedule/target revisions and how today's edits apply: by default future occurrences, with an explicit current-occurrence amendment if desired. Resolve the target/step from the revision effective for that occurrence, not first-view/first-write time. Preserve schedule applicability and archive effective dates so no-entry history is reproducible; deleting a recurring occurrence is a retained exception. E1 owns identity and temporal contracts; E3 implements them rather than choosing anew. Progression advancement must be a unique effect of the logical occurrence key, including after sync.

### H2 — Evidence is preserved, but habit fulfilment projection can still disagree

**Locations:** ARCHITECTURE.md:72,102,161,168,209; PRD.md:72,88; BUILD-ROADMAP.md:63,85.

Builder A credits timed EndedEarly actual seconds into daily progress; builder B retains partial session history but credits only TargetReached, justified by line 209's specific permission for that status. The 8-minute gate can pass in both because it checks measured history, not displayed habit progress. Separately, a user can mark skip/no after measured target fulfilment. One builder lets manual status override the visual state; another recomputes done from ledger. Both preserve manual origin and session evidence, but Home and Sadar can present opposite status. Manual quantity edits can also be interpreted as an absolute replacement or additive event, changing totals after replay.

**Fix:** add one shared fulfilment/progress projection contract and a small eligibility/precedence table: eligible measured contribution for EndedEarly and TargetReached; cancelled evidence retained but excluded; unresolved recovery not credited until accepted; manual yes/no/skip/unmarked shown as the user's declaration distinct from measured progress; explicit rule for which combinations satisfy the habit and cue ordering. Specify manual quantity as either absolute revision-checked state or uniquely keyed additive logs, never both. Clearing manual status does not clear ledger. Require Home/history to consume this projection. Add an acceptance example: 8/45 minutes then 37/45 minutes reaches 45 measured exactly once; manual skip or clear after 45 keeps evidence and yields the same labelled presentation on every screen.

### H3 — A server ownership CAS does not fence an offline former timer owner

**Locations:** ARCHITECTURE.md:126,132,164,188; BUILD-ROADMAP.md:148–150.

Builder A handles handoff by server CAS plus requester ACK; builder B permits the locally cached owner to continue mutation offline as AD-13 allows. If the old owner misses the handoff result or its OS notification is stale, both can mutate segments of the same session ID. Dedup by ID or revision then either drops actual evidence or double-credits overlapping segments. This is distinct from the already-addressed case of two independently created offline sessions.

**Fix:** E8 must define an ownership epoch/fencing token and a handoff protocol carrying an immutable accumulated checkpoint. Require acknowledged durable pause/release by the source before normal ownership transfer, or make a force-takeover explicitly uncertain and reconcilable. Stale-epoch commands cannot mutate the canonical session, but their local measured evidence must survive as a conflict record. ACK loss returns the same transfer operation outcome on retry. Specify how device reboot and reinstall identify owners; device ID is not proof of authorization. Add the lost-ACK + stale-notification + former-owner-offline scenario to the E8 gate.

### H4 — Legacy integer mapping lacks a persistent source-store namespace

**Locations:** ARCHITECTURE.md:96,138; BUILD-ROADMAP.md:31,44,47–48,77.

Builder A maps legacy Habit 1 to one UUID during Fitrah migration; builder B maps Sadar Habit 1 using only entity type and integer key. They can collide, or a second import can produce a new UUID for the same source record. `sourceApp` distinguishes products but not two installations or copied stores of the same app. Duplicate-ID validation cannot detect an identity regenerated on each import. Matching by title would violate AD-7 and cannot repair this safely.

**Fix:** persist a sourceStoreId (and workspace identity) in the migration/export envelope and keep an idempotent mapping keyed by sourceStoreId/entityType/legacyPrimaryKey. Re-import preserves that mapping; two unrelated stores are never merged by integer key/title. State how restoring a clone preserves identity and how intentional workspace duplication creates a new namespace with remapped internal refs. Establish mapping before data adapters/import builders split; migration fixtures must include two distinct stores with the same legacy integer IDs and replay of one import.

## Medium findings

- **M1 — Web/desktop elapsed-time contract is unfinished.** AD-4 is precise for Android boot/elapsedRealtime but not browser tab/process lifetime. E7 must bind same-document monotonic accounting, reopened-tab wall-time trust/review policy, permissible anomaly detection and unsupported alert behavior. Do not assume `DateTime` deltas become measured evidence on other targets just because Android is specified. This can remain an explicit E7 prerequisite.
- **M2 — Revision conflict and idempotency ordering needs one rule.** AD-7/command contract names operationId and expectedRevision, but does not state that an existing receipt is resolved before rejecting a stale expected revision, nor what happens if the same operationId is replayed with different payload. Fix: return original receipt for identical request fingerprint; reject ID reuse with different payload; otherwise validate current revision then mutate+receipt in one transaction. This prevents a successful command with lost response returning Conflict on retry.
- **M3 — Recurring schedule edits need bounded temporal scope.** AD-10 permits occurrence/series edits and freezes past events conceptually, but does not bind whether editing a series affects past, current and future occurrences, or how active-session refs survive a moved/deleted block. Before E3, fix default future-only series edits, retained exceptions and immutable session snapshots; removing a plan must not terminate/delete its actual session. Provider-specific recurrence syntax can remain deferred.

## Good-spine rubric

| Check | Assessment |
|---|---|
| Named paradigm and meaningful divergence points | Pass. Modular monolith and repository owners match current code and avoid a rewrite. |
| Every AD enforceable and prevents its divergence | Partial. AD-1–AD-6/AD-9/AD-11/AD-14–AD-16 are enforceable at this altitude. AD-7/AD-8/AD-10 need H1/H2/H4; AD-13 needs H3 at E8. |
| Deferred cannot cause independent builders to diverge now | Partial. DB/provider choice is correctly gated; H1/H2/H4 are shared contracts rather than implementation details and must land before parallel E1–E3 work. M1/H3 may be explicitly blocked until E7/E8. |
| Named technology verified and bounded | Baseline Isar/Riverpod treated as observed code, not current-version recommendations; no unverified future provider bound. External documentation freshness was not independently rechecked in this lens. |
| Ratifies brownfield reality | Pass. Preserves dial, repositories, grid, native launcher and IDs while replacing duplicate owners by slices. |
| Requirement breadth | Pass with H1/H2 corrections. FR-01–22 have relevant invariants/gates; private reflection/notes use generic durable ownership rather than an unnecessary separate architecture. |
| Operational/environmental dimension | Pass. Build identity/signing/output, profiles, backup, capability/errors, diagnostic privacy, platform limits and local offline operation are explicit. |
| Parent invariant conflicts | Not applicable: initiative spine has no inherited parent ADs. Product decisions are appropriately marked proposals pending owner review. |
| Overconstraint / build burden | Acceptable. Logical repository names and schema seed allow adapting existing code. Retain E0–E8 gates and avoid adding deployment/microservice machinery for this review. |

## Triage

H1, H2, H4 and M2: amend the spine and matching E1/E2/E3 gates before handoff. M3: amend temporal scope before E3; can stay compact. H3 and M1: capture precise prerequisite contracts for E8/E7 respectively; implementation/provider mechanics stay deferred. No new owner questionnaire is necessary to make these reliability contracts deterministic; product-sensitive display of manual-vs-measured fulfilment should be called out as a proposed policy at UX review.

## Resolution addendum — amended spine recheck

Re-read the amended AD-4/AD-7–AD-15, shared projection and command contract, plus related roadmap changes on 2026-11-03. **Revised verdict: pass at initiative altitude for owner review and E0 baseline work; no residual critical/high blocker from this lens.** This is a document-contract verdict, not an implementation or runtime pass.

| Original finding | Resolution in amended ARCHITECTURE.md | Status |
|---|---|---|
| H1 | AD-8 now fixes unique `(habitId, localDate)`, effective-dated target/schedule revisions, explicit occurrence correction and effective archive behavior. AD-9 defines applicable/evidenced daily rows. | High resolved. E3 fixture must prove a target edit on an unvisited historical date does not change denominator/target. |
| H2 | Shared projection at line 171 now credits eligible EndedEarly/TargetReached once, excludes cancelled, preserves manual override with measured evidence and returns to evidence on clear. | High resolved. This manual override display is a reviewable product proposal, not an owner-approved policy yet. |
| H3 | AD-13 now binds ownerEpoch, source checkpoint/release, server CAS, ACK and stale-control fencing while retaining disputed offline evidence. E8 explicitly requires source release acknowledgement. | High resolved. Lost-ACK protocol details and authorization remain E8 slice prerequisites. |
| H4 | AD-7 now keys persistent mapping by sourceStoreId/entityType/legacyKey; sourceStoreId accompanies backup and same-source re-import uses the same mapping. Roadmap adds replay and same-integer/different-installation fixture. | High resolved. Intentional workspace cloning can remain an explicit import choice in E1. |
| M2 | Command receipt includes payload fingerprint; lookup precedes revision validation; different-payload ID reuse rejected. | Resolved. |
| M3 | AD-10 now fixes single-occurrence exceptions and effective series revision for today onward without historical rewrites. Ledger/snapshot survive delete. | Resolved at initiative altitude. |
| M1 | Shared Clock text states browser/desktop live-context monotonic and reopened wall checkpoint with uncertainty review; Android equivalence is not assumed. | Sufficiently bounded for E7; exact detection/trust windows belong to its adapter contract. |

Two implementation-slice clarifications remain **medium**, not reasons to block delivery of the planning pack:

1. Before E3 check-in handlers split, specify that `manualQuantity` is revision-checked absolute state (recommended for the current command shape), while explicitly logged duration and session adjustments are separately identified records. If additive count logs are chosen instead, give each a stable ID. The present projection removes the high-level status disagreement but does not yet fix absolute versus additive manual quantity semantics.
2. Before E1/E3 occurrence materialization, turn “next unfrozen occurrence” into a concrete effective-date example and define when an occurrence is frozen. A safe proposed default is next applicable local date; amendment to today's existing occurrence is an explicit operation. This is now bounded by effective-dated revisions and unique logical key, so it is a slice contract detail rather than the former high divergence.

Do not describe these two recommendations as existing implementation or demand another owner approval round solely for technical consistency. Add them to E1/E3 task acceptance when those tasks are cut. A1 distribution/repository choice, A3 Home hierarchy and the shared manual-status presentation remain legitimate owner-review proposals. Provider/auth choice is an explicit E8 blocker; production storage/migration detail remains an E1 gate; neither blocks E0 evidence collection.
