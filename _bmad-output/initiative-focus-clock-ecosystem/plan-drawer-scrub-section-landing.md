---
title: 'Keep the selected app section after alphabet scrubbing'
type: 'bugfix'
ticket: ''
created: '2026-11-24'
status: 'built'
baseline_revision: '9cf222cfbb745c97462d504b78e1a6336d824931'
route: 'oneshot'
route_source: 'auto'
risk: 'low'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="Owner has repeatedly authorized continuing implementation through the usable launcher checkpoint">

## Intent

**Problem:** While dragging the app drawer's alphabet index, the list filters to one letter. Releasing clears the filter at the filtered list's near-zero scroll position, so the full list returns at its beginning instead of the selected section.

**Approach:** Keep the temporary single-letter preview while the finger moves, avoid restarting the full-list seek for every letter, then restore the full list and seek to the last selected section once after layout.

</frozen-after-approval>

## Implementation Notes

Root cause: the held filter made the selected section's header sit at the list origin; release cleared that filter without seeking in the restored full list. The drawer now avoids full-list seeking during ordinary letter changes, keeps the special end-of-list marker scrolling, and performs one revision-guarded section seek after release/cancel. `pubspec.yaml` advances the distributable to 0.5.59+8151. No installed-app or preference writes change. Risk is low: this affects navigation state only.

## Verification

**Commands:**
- `flutter analyze --no-pub lib/features/launcher/widgets/minimalist_app_drawer.dart` -- expected: no issues.
- `git diff --check` -- expected: clean diff.
- `flutter build apk --release --no-pub` -- expected: release APK builds.
- `apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk` -- passed with APK v2 signing; metadata reports 0.5.59 / 8151 and matches the stable owner-preview certificate.

**Manual checks:**
- On a temporary Android 16/API 36 x86_64 AVD at 1080x2400, holding the index on S showed only Safety and Settings.
- Releasing restored the full list with S selected and the matching section visible. Launching Android Settings from the list and pressing HOME returned to Fitrah `MainActivity`.
- Android RoleManager reported Fitrah as HOME; role was assigned via shell, so the system chooser flow was not exercised.

Implementation checks: focused analyzer and `git diff --check` passed; the quick review found no issues. Commit `ebaaaeb` was published in owner-preview release v0.5.59-v8151; multi-platform workflow 45423577710 passed. Release v8152 contains this fix plus the clock prompt cleanup. The temporary AVD run showed no FATAL EXCEPTION, FlutterError, ANR, or PlatformException in the sampled logcat tail. Physical/OEM behavior and the Android system chooser remain unverified.
