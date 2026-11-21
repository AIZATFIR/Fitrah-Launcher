---
title: 'Remove inactive Fitrah Android Home manifest'
type: 'chore'
ticket: ''
created: '2026-11-21'
status: 'built'
baseline_revision: '731412b336b3902ffb195179761c250f8be8414d'
route: 'oneshot'
route_source: 'pinned'
risk: 'low'
review: 'quick'
review_source: 'pinned'
lenses_ran: ['quick']
review_loop_iteration: 0
context:
  - 'docs/ecosystem/2026-11-03/BUILD-ROADMAP.md'
  - '_bmad-output/initiative-focus-clock-ecosystem/plan-honest-launcher-capabilities.md'
---

## Code Map

- `android/app/build.gradle.kts` — application config has one `com.aizatfir.fitrah_launcher` ID and no product flavors.
- `android/app/src/main/AndroidManifest.xml` — sole active manifest; declares the real launcher `MainActivity` as MAIN/HOME/DEFAULT/LAUNCHER.
- `android/app/src/fitrah/AndroidManifest.xml` — orphan manifest names a missing `com.aizatfir.focus_clock.MainActivity`; no `fitrah` variant exists.
- `docs/ecosystem/2026-11-03/BUILD-ROADMAP.md` — E5 manifest audit and device-level gates.

## Tasks & Acceptance

- [x] Remove the unused `src/fitrah` manifest; it cannot build a distinct app in the current Gradle configuration and points at a nonexistent activity.
- [x] Split the roadmap audit checkbox into configured-variant audit (complete after checking packaged debug/release) and physical/OEM Home/reboot verification (still open).

**Acceptance Criteria**

- Given current debug and release variants, when their packaged manifests are inspected, then both expose only `com.aizatfir.fitrah_launcher` as the Home-capable app and include its launcher entry.
- Given the installed v8125 app is Android's Home role holder, when Android Home is invoked after the cleanup, then the same Fitrah task returns with the existing goal intact.
- The roadmap does not claim that emulator evidence proves physical/OEM behavior.

## Implementation Notes

Removed the orphan manifest: `android/app/build.gradle.kts` defines only `debug`, `profile`, and `release`, all using `src/main`; no `fitrah` product flavor exists. Debug and release APKs rebuilt successfully. Both packaged manifests contain only `com.aizatfir.fitrah_launcher.MainActivity` with MAIN/HOME/DEFAULT/LAUNCHER. The rebuilt release APK is byte-identical to the current v8125 download.

Installed the rebuilt release over the API36 x86_64 QA AVD. Android continued to report Fitrah as the HOME role holder; pressing HOME resumed `MainActivity`, and accessibility XML retained `Menang LKS Nasional QA`, `Latihan LKS`, and the daily focus summary. The sampled log had no fatal, FlutterError, or ANR. This is emulator evidence only. Automated tests were not run because no runtime code changed.

## Verification

- `flutter build apk --debug` — passed: `build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter build apk --release` — passed: `build/app/outputs/flutter-apk/app-release.apk`.
- `aapt dump badging` and `aapt dump xmltree` on both APKs — passed: package/version correct; only the main Fitrah activity is HOME/DEFAULT/LAUNCHER.
- AVD manual check — passed: HOME role remains Fitrah and Android Home returns to saved-goal Home; physical/OEM verification remains open.
- `git diff --check` — passed.

## Review Triage Log

- patched — The first quick review found completed implementation tasks still unchecked while `status` remained in progress; marked both tasks and the plan built to match the recorded APK/AVD evidence.
