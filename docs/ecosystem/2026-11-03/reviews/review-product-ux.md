# Product and UX review

Reviewed 3 November 2026. Scope: OWNER-INTENT, PRD, EXPERIENCE, DESIGN, BUILD-ROADMAP and their architecture interfaces. This review helps Fahim and subsequent builders turn the owner's intent into a usable product without another uncontrolled rewrite. No app code, builds or tests were changed or run.

## Verdict

The package preserves the owner's thesis: personally meaningful cues, the selected analog dial, habits near Home, one trustworthy session, and evidence without punishment. It distinguishes owner's instructions from proposed decisions unusually well. It is usable as a long-build planning baseline; the next planning revision should make the first usable slice explicit and close two product contracts before implementation spreads.

## PRD rubric

| Dimension | Judgment | Evidence and action |
|---|---|---|
| Decision-readiness | Adequate | PRD §1/§7 and README explicitly identify Android-first, storage, layout and sync decisions as proposals. Preserve those labels; do not turn a draft into permission to migrate. |
| Substance over theater | Strong | A concrete first user, actual journeys, observed code gaps and domain-specific failure gates replace decorative personas or novelty claims. |
| Strategic coherence | Strong | Goal → action → evidence explains the feature choices. Anti-streak, optional reflection, rest and honest data support the owner's manifesto. Seven-day use plus complaints/workarounds are useful counterweights to activity metrics. |
| Done-ness clarity | Adequate | Most FRs have observable consequences and roadmap gates. FR-04 needs a persisted selection contract; FR-05 needs an explicit eligibility/order rule. See findings below. |
| Scope honesty | Adequate | FR-21/22 and optional integrations are clearly deferred. FR-01–20 is a complete personal release, not a small first usable increment; name the smaller checkpoint explicitly. |
| Downstream usability | Adequate | FR-01–22, UJ-1–7 and NFR-01–08 are contiguous and glossary terms mostly consistent. Pinning a Goal and choosing an action currently share imprecise language. |
| Shape fit | Strong | Light enough for a solo owner while still supplying architecture, UX and builder gates. Separate source evidence and owner intent are appropriate for this brownfield recovery. |

### Concrete product findings

1. **Persist the user's chosen action separately from the pinned Goal.** PRD FR-01 describes a Goal cue; FR-04 describes a pinned action, and EXPERIENCE gives that action precedence after an active session. ARCHITECTURE's aggregate table contains `Goal.cuePinned` but no record for the chosen action. Define whether the choice expires at a new day, where its Habit/Task/block reference is saved, what happens when its source is archived/completed, and how it survives reopen. Acceptance example: choose LKS, reopen with no active session, and see the same chosen action; pinning a different Goal must not silently replace it.

2. **Specify which habits appear on Home and keep that rule deterministic.** FR-05 says “habit yang relevan hari ini”; EXPERIENCE says user ordering must not change after completion. Neither defines whether relevance means today's occurrences, pinned habits, overdue entries or the Goal selection. DESIGN shows a few rows without a long-list rule. Define a proposed default, completed/skip visibility, user control and scrolling behavior. Verify 0, 3 and 30 habits, including completed and archived occurrences, with a 200% text scale. Preserve access and daily actions on Home; do not solve density by hiding habits behind a destination.

3. **Name a first usable vertical slice before the complete personal release.** PRD §6 assigns all FR-01–20 to the first personal release. E3 includes five habit types, recurrence, historical targets, inbox, notes and reflection before E4's integrated Home. That is defensible as the long-build destination but too broad to be the sole initial usability checkpoint. Mark a thin early checkpoint: a user Goal, an existing timed habit, a shared session with reopen/partial completion, and a modest Home using real data. Keep unsupported existing habit data readable and preserved; finish the larger E3/E6 gates before declaring full personal release. This changes milestone visibility, not the requirement to retain all habit types.

## Owner-intent coverage

The authentic-prompt excerpts are explicitly treated as input supplied now, rather than falsely authenticated historical logs. The product carries the omitted quotations' meaning through the calm typography, real launcher integration and companion stages. Habit prominence, the selected legacy dial, rest, Tauhid-sensitive wording, absence of moral scores and optional reflection are represented. The treatment of “low cortisol” and “one second” as preferences/aspirations avoids turning the manifesto into unsupported medical or performance claims. No additional product finding is needed here.

## Editorial structure, then prose

Reader: humans, primarily Fahim and builders. Structure models: strategic/context for the PRD and owner intent; reference for DESIGN/EXPERIENCE; linear guide for BUILD-ROADMAP. Counts from the installed `word_metrics.py`: PRD 2,043; OWNER-INTENT 662; EXPERIENCE 1,743; DESIGN 1,260; BUILD-ROADMAP 2,352; total 8,060 words. Counts include frontmatter where the script treats it as preamble.

| Pass | Original text/location | Revised text/disposition | Changes |
|---|---|---|---|
| structure | PRD §6, “Scope build pertama dan arah lanjutan” (119 words), follows the full FR/NFR detail | MOVE the release boundary immediately after §1, retaining a cross-reference from requirements | A decision-maker sees what is proposed before reading 22 FRs. No cut; approximately zero word reduction. |
| structure | OWNER-INTENT, authentic quotes and interpretation boundary | PRESERVE both | The boundary prevents later agents from confusing owner language, historical claims and new decisions. Its repetition of selected product ideas serves traceability. No cut. |
| prose | Roadmap E2 gate: “sesi survive reopen” | “sesi dipulihkan setelah aplikasi ditutup dan dibuka ulang” | Expresses the acceptance action directly. Keep technical terms such as transaction, revision and operation ID where they identify contracts. |
| prose | PRD glossary “Tujuan / Goal”; FR-01 “cue Goal”; FR-04 “memilih/pin tindakan” | Use “Goal utama” for the displayed Goal and “tindakan pilihan” for the action, with separate glossary entries | Removes ambiguity without changing the owner's product concept. The substantive storage consequence is finding 1. |

Four editorial recommendations; expected reduction approximately zero words (0% of 8,060). No length target was supplied. Do not compress the failure states, provenance or habit-unit distinctions merely to shorten the package.

## Mechanical notes

The assumption table contains A1–A6, while only A1/A2 are explicitly introduced inline in PRD body; A3 is inline in DESIGN. Add inline references for A4–A6 where used, or state that §7 is the authoritative register so the assumption round-trip is explicit. No duplicate or missing FR/UJ/NFR IDs were found. No metric ID family is needed merely to imitate a template.

The mockup file was still being authored during this review. This review evaluates its documented composition rather than claiming screenshot or runtime verification.

## Resolution recheck

Rechecked the revised planning contracts and prototype source on 3 November 2026, without running app tests or modifying the main documents.

| Original finding | Resolution | Evidence |
|---|---|---|
| Persist action separately from Goal | Resolved for planning | PRD FR-04 now requires per-date durable selection surviving restart; EXPERIENCE Now/next and ARCHITECTURE AD-9 plus the TodaySelection aggregate distinguish it from pinned Goal. Source archive/delete fallback remains a normal slice-level edge case to specify, rather than an unresolved architecture choice. |
| Define Home habit eligibility/order/density | Resolved | PRD FR-05 and EXPERIENCE Information Architecture now include today's occurrences or today's evidence, retain completed/skipped rows in user order, permit scrolling and wrap rather than hide rows at large text sizes. |
| Expose first usable slice before full release | Resolved | PRD §6 names U0 after E3a. Roadmap separates E3a timed/binary integrated pilot from E3b remaining type/legacy parity and keeps E6 dependent on parity. Pilot limitations preserve existing records and expose honest capability states. |

The prototype is now present at `mockups/today.html`, with idle, running, paused and empty scenario controls and explicit local-demo boundaries; three screenshot artifacts are also present. Source review confirms the small dial/status group, habits and visible navigation correspond to the documented hierarchy. This is not a Flutter runtime, storage or screenshot accessibility pass.

No residual high-impact product/UX issue was found in the requested changes. The earlier editorial suggestions remain optional and do not block owner review or the E0 baseline work. The rubric judgments for done-ness clarity and scope honesty are now strong for this planning stage; downstream usability remains adequate until slice-level failure details are written.
