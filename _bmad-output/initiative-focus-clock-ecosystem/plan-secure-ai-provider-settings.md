---
title: 'Simpan kredensial AI dengan aman dan gunakan model pilihan'
type: feature
ticket: ''
created: '2026-11-16'
status: 'built'
baseline_revision: '99ba894'
route: 'full'
route_source: 'pinned'
risk: 'high'
review: 'quick'
review_source: 'parent verification'
lenses_ran: [quick]
review_loop_iteration: 0
context:
  - 'docs/ecosystem/2026-11-03/ARCHITECTURE.md'
  - 'docs/ecosystem/2026-11-03/PRD.md'
  - '_bmad-output/initiative-focus-clock-ecosystem/plan-ai-conversation-continuity.md'
  - '_bmad-output/initiative-focus-clock-ecosystem/plan-portable-backup-restore.md'
---

<frozen-after-approval reason="Owner approved continued ecosystem development and user-managed AI providers">

## Intent

**Problem:** AI configuration accepts user-selected providers and models, but the Gemini SDK path hardcodes a model and routes by key prefix; newly saved keys are also copied into durable AppSettings despite secure-storage support.

**Approach:** Keep API credentials in secure storage, migrate existing Settings/legacy provider keys when AI settings open, and route requests using the configured base URL and model. Preserve compatible Google/OpenAI-style chat paths, proposal approval, local-backend fallback, and backup compatibility.

## Boundaries & Constraints

**Always:** Never export API keys; old backups remain readable; restoring data preserves the current installation's secure key; configuration errors keep manual/offline Focus Clock usable; no provider response can write a schedule without existing explicit approval.

**Never:** Add provider SDK dependencies, silently change the user's provider/model, or remove legacy fields before migration compatibility is proven.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Save provider | User saves key, endpoint and model | Key is stored in secure storage; AppSettings stores an empty legacy key; selected endpoint/model reach requests | Show actionable save error; retain the unsaved form |
| Legacy key | Existing AppSettings or Gemini/OpenRouter secure key, no unified key | Settings migrates the existing key into unified secure storage and clears the legacy DB copy without changing endpoint/model | If secure write fails, keep legacy value and report failure; do not clear the only copy |
| Configured Gemini | Google endpoint, Gemini key and chosen model | Direct request targets the configured model; action mode uses the existing approval proposal path | Failed direct call may use configured compatible endpoint/backend; no unapproved writes |
| Other compatible provider | Custom/OpenAI-compatible endpoint, key and model | Request uses that endpoint and exact model, independent of key prefix | Provider errors remain visible and manual scheduling remains available |
| Backup restore | Old backup and current secure credential | Legacy file decodes; secure key stays local; restored AppSettings contains no plaintext credential | Failed migration/restore retains current DB and key |

</frozen-after-approval>

## Code Map

- `lib/services/secure_storage_service.dart` -- add unified key getter/setter with fallback to existing Gemini/OpenRouter entries.
- `lib/features/settings/settings_screen.dart` -- `_AiConfigTile` loads/migrates the key, writes it securely, and clears `AppSettings.aiApiKey` only after secure persistence succeeds.
- `lib/providers/providers.dart` -- `aiServiceProvider` passes stored/legacy configuration without changing the selected base URL or model.
- `lib/services/ai_service.dart` -- `send`, `_sendGeminiDirect`, `_sendServerFallback` and `_callOpenRouterDirect`; route by endpoint, pass selected model and preserve approval gates/history.
- `lib/data/focus_clock_backup_service.dart` -- keep current secure key during restore and clear legacy plaintext after preserving it securely.
- `test/ai_action_proposal_test.dart`, `test/secure_storage_service_test.dart`, `test/focus_clock_backup_service_test.dart` -- provider routing, migration failure, no-secret restore and approval safety.

## Tasks & Acceptance

**Execution:**
- [x] Add unified secure API-key access with compatibility fallback; test old Gemini/OpenRouter keys.
- [x] Migrate Settings save/load to secure storage and clear the Isar legacy value only after successful secure write.
- [x] Route direct Gemini by configured endpoint, pass the selected model, and route other configured compatible providers through their configured endpoint/model.
- [x] Preserve the secure credential across portable restore, remove legacy plaintext from restored AppSettings, and test existing backup decoding and approval behavior.

**Acceptance Criteria:**
- Given a configured provider/model, when AI sends a message, then the request uses that exact endpoint/model regardless of key prefix.
- Given a legacy key, when migration succeeds, then secure storage contains it and AppSettings no longer contains plaintext; on failure the only copy is preserved.
- Given an AI schedule request, when no proposal is explicitly approved, then no repository mutation occurs.

## Implementation Notes


## Plan Change Log


## Review Triage Log


## Verification

**Commands:**
- `flutter test --no-pub test/ai_action_proposal_test.dart test/secure_storage_service_test.dart test/focus_clock_backup_service_test.dart` -- passed, 18/18.
- `flutter analyze lib/services/secure_storage_service.dart lib/services/ai_service.dart lib/features/settings/settings_screen.dart lib/data/focus_clock_backup_service.dart` -- passed with no issues. Full-project analysis reports five existing info-level lints in other files and no errors.
- `flutter build web --release -o /tmp/focus-clock-bookpaper-ui-preview` -- passed after the UI changes; AI implementation also built successfully to `/tmp/focus-clock-secure-ai-web`.
- `git diff --check` -- passed.

**Review:** Parent inspected key migration ordering, backup restore preservation, configured URL/model dispatch, and the existing explicit proposal approval gate. No provider live-call or manual AI Settings flow was exercised.

**Remaining:** PRD FR-04a/FR-04b and AD-17 still require a provider-neutral `GoalUnderstanding`/`PlanProposal` contract and one durable, approval-first batch scheduling use case. This plan covers key storage and configured provider routing only.
