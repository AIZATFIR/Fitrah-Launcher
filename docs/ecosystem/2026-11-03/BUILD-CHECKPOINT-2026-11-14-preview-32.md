# Focus Clock preview 32 — 14 November 2026

Source revision: `2acf375`.

## Shipped in this source checkpoint

- Schedule capture starts with a blank text-first activity field when no existing task or habit is selected.
- Exact start time uses the 24-hour time picker; duration uses touch-friendly chips instead of a dual-thumb range control.
- Inbox actions expose compact tooltips and larger touch targets. The schedule form and Home overflow cases have widget coverage at 320 dp.
- Active focus timers use monotonic `Stopwatch` time while running. Android saves boot count and elapsed realtime, so a process restart during the same boot does not depend on a changed wall clock.
- Legacy timer records and environments without the Android clock bridge keep the guarded wall-clock recovery path. A reboot with a calendar/timezone change remains an explicitly uncertain case.

## Verification

- Full Flutter suite: **310 passed** (serial run).
- `flutter analyze --no-pub`: clean.
- Android arm64 APK compiled and package/version/signature metadata inspected.
- Web JavaScript bundle compiled; ZIP integrity passed.
- SHA-256 manifest checked successfully for both deliverables.

## Local preview files

Folder: `release_dist/2026-11-14-focus-clock-preview-32/` (local ignored artifacts).

- Android arm64 APK, versionName `0.5.3`, versionCode `32`, minSDK 24 / targetSDK 35 / compileSDK 36.
- Web JavaScript ZIP.
- Manifest, checkpoint notes and checksums.

APK SHA-256: `021d9dc24f54040f8fa89700da8e9928fbe27eb58a343f8d0e5c9bfe322d4082`.

Web ZIP SHA-256: `e943dccc232e5f2f765bcf390eb5eb8eb4f488a630e308f81342e637259ad0c1`.

## Limits

These are locally built preview artifacts, not a public release. The APK uses the existing Android Debug signing identity. No physical phone was attached; version 32 was not installed on an Android device. Browser interaction and persistence were not exercised; a successful JavaScript compile and ZIP check do not prove browser runtime behavior. Same-boot timer recovery is covered in code/tests, while post-reboot recovery and OS process-kill behavior still need device verification. The larger E0–E6 adoption, storage, accessibility and device gates remain open; AI, cross-device sync, WhatsApp, MCP and public distribution are later roadmap work.
