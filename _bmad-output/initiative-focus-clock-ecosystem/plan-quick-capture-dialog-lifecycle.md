---
title: 'Keep quick-capture field alive through dialog close'
type: bugfix
ticket: ''
created: '2026-11-23'
status: 'built'
baseline_revision: '7428e895aa1b7ad6b68c368244675d063a5dd9f6'
route: 'oneshot'
route_source: 'pinned'
risk: 'medium'
review: 'none'
review_source: 'pinned'
lenses_ran: []
review_loop_iteration: 0
context:
  - 'docs/ecosystem/2026-11-03/EXPERIENCE.md'
  - 'docs/ecosystem/2026-11-03/BUILD-ROADMAP.md'
---

<frozen-after-approval reason="Owner authorized continued Focus Clock ecosystem development">

## Intent

**Problem:** Saving a task from Home's quick-capture dialog disposes its text controller while the closing route can still rebuild the TextField. Flutter reports a disposed-controller exception, and later Home interactions can fail.

**Approach:** Keep the empty quick-capture field's controller alive until the dialog route has fully completed its exit transition. Preserve current save, retry, and cancel behavior. Align Home timer tests with the approved unobstructed clock cue.

</frozen-after-approval>

## Implementation Notes

The exception reproduced after task save. `showDialog` returns on pop before the overlay finishes its reverse transition, so the controller is now disposed after `ModalRoute.completed`. Home note/task fields have stable keys while their input remains empty. Updated stale tests that searched for removed placeholders, expected the removed floating timer banner, or used the old `Tambah kegiatan` capture title; production behavior stays aligned with the approved goal cue and unobstructed dial.

## Verification

**Commands:**
- `flutter test --no-pub --concurrency=1` -- 456 tests passed.
- `flutter analyze --no-pub` -- no errors/warnings; five info notices in untouched files.
- `flutter build apk --release --no-pub` -- passed; APK package/version and v2 signature verified.
- `npm run build:focus` -- passed; JS bundle and package integrity verified. Existing Wasm incompatibilities were reported in Isar, secure storage and TTS.
- API 36 x86_64 AVD -- v8130 upgraded in place, first-install time unchanged, Fitrah retained HOME role, saved QA goal and clock visible at font scale 2.0, no fatal/ANR/FlutterError in sampled logs.
- Vercel deployment `dpl_FTmnyQ4aRyzeiQWRUS6dpyGfssEJ` -- READY; production root HTTP 200 and version endpoint 0.5.40 / 8131.
- Artifact SHA-256 and web ZIP integrity checks -- passed.
- `git diff --check` -- clean.
