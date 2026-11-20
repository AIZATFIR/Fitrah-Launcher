# Checkpoint: Goal-first Home v8114

**Date:** 20 November 2026  
**App version:** 0.5.28 (versionCode 8114)  
**Purpose:** Make the user's goal the first meaningful content on Home, including at large text sizes.

## What changed

- Home order is navigation, personal goal cue, Gregorian/Hijri date, today's focus summary, then the clock dial.
- At 200% text scale the goal heading receives the full row and the assistant action moves below it. The decorative flag is hidden in this constrained large-text layout.
- Existing colors, typography scale, date content and clock face are retained.
- Goal-first ordering and width are covered by widget regression tests.

## Verification

- Red/green regression was recorded for both goal/date order and the large-text heading width.
- Focused Home suites: **53 tests passed** across `focus_clock_home_lampiran1_test.dart`, `focus_clock_home_persisted_data_test.dart`, and `home_intent_cue_test.dart`.
- Scoped `flutter analyze` on the changed cue and its tests: no issues.
- `flutter build apk --release --no-pub`: succeeded.
- `flutter build web --release --no-pub --no-wasm-dry-run`: succeeded (JavaScript build).
- API 36 x86_64 emulator at Android font scale 2.0 installed and launched the APK. UI hierarchy showed “TUJUAN UTAMA” before the date and the complete Hijri date; the HOME role remained `com.aizatfir.fitrah_launcher`. `dumpsys activity lastanr` reported no ANR since boot, and inspected logcat had no app fatal/Flutter exception.

## Artifacts

See [`release_dist/2026-11-20-focus-clock-goal-first-home-v8114/INSTALL.md`](../../../release_dist/2026-11-20-focus-clock-goal-first-home-v8114/INSTALL.md) for the owner-use APK and static web preview, install notes, manifest, and SHA-256 file.

## Limits / next work

This validates a 200% text-scale emulator viewport at the default logical width. It does not close physical-device fit, TalkBack/accessibility, live AI provider, browser interaction/reload, production signing/deployment, or sustained-use review. The wider Focus Clock ecosystem remains active work; this checkpoint is a usable preview milestone, not ecosystem completion.
