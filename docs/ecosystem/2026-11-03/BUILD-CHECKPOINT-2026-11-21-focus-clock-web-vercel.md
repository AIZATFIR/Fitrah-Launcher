# Focus Clock web production update — 21 November 2026

## Published build

- URL: [focus-clock-web.vercel.app](https://focus-clock-web.vercel.app/)
- Vercel deployment: `dpl_JCRKimzMe2sGrrT8pbsPxZLytvvQ` (ready, production)
- Source: `6efbe21d08774d0d6df2f93778ad2096b5884594`
- Build: `npm run build:focus` with Flutter 3.41.9 / Dart 3.11.5; standard JavaScript target. The optional Wasm dry run reported current dependency incompatibilities; it did not prevent the JavaScript build.
- Browser database assets match Drift 2.35.3: `sqlite3.wasm` and `drift_worker.js` passed the pinned SHA-256 checks in `scripts/prepare_browser_storage.sh`.

## Smoke evidence

The production alias opened as **Focus Clock** and rendered the unified app's **Jam / Hari Ini / Aplikasi** navigation. The empty Home showed the goal prompt, add-activity action, current time, analog dial, and habit area. Jam opened to the day view. Aplikasi clearly explained that the installed-app list is available only on Android instead of showing fake apps. Enabling Flutter's accessibility tree exposed labels for the goal, AI entry, date, dial actions, habits, and all three navigation destinations. No personal goal or schedule was entered during this check.

## Limits

This deploy makes the current unified Focus Clock/Fitrah app available on the web; it does not create cross-device sync. Browser data remains in that browser profile. Android-only app drawer capabilities are not available on web. We did not verify offline startup after browser eviction, mobile Safari/Firefox, TalkBack, live AI provider calls, or seven-day daily use. The optional Wasm build remains unsupported by current dependencies; Vercel serves the JavaScript build.

The deployment is separate from the Android owner preview in [v8117](BUILD-CHECKPOINT-2026-11-20-empty-agenda-large-text-v8117.md). It does not complete the remaining ecosystem roadmap.

## Follow-up: schedule access and narrow-screen header (21 November 2026)

- Source revision: committed with this checkpoint.
- The Jam menu now opens a labeled, chronological schedule list. Selecting an activity opens its existing detail sheet; loading, error, and empty states have explicit messages.
- The top date/time controls wrap on narrow screens. Shorter Indonesian menu labels prevent the popup menu from overflowing at a 390 dp viewport.
- `test/focus_clock_schedule_list_test.dart` exercises the real FocusClock tab at 390×844, opens the schedule list, checks its row label and action semantics, and passes. Scoped analyzer and `git diff --check` are clean.
- `npm run build:focus` compiled the standard JavaScript target. The existing optional Wasm dry run still reports unsupported dependencies. Production deployment `dpl_5zrvh6dzis4jVQzb8PUf1ESgLUQF` reached `READY`; `https://focus-clock-web.vercel.app/` returned HTTP 200.

This follow-up did not produce a new Android APK. No ADB device is attached, so the shared Android layout and TalkBack behavior still need phone/emulator validation. It does not close E0–E11, physical/OEM, live AI, or sustained-use gates.

## Follow-up: visible and selectable Home goals (21 November 2026)

Deployment `dpl_4evYQyJiYvgaYjrZzzHQeULdmbkn` rebuilt the Focus Clock web app with the v8121 Home behavior. Creating a new goal checks **Sematkan di Home** when no goal is pinned. Tapping a saved goal selects it as the Home direction in one step; editing remains separate, and adding another goal leaves the current primary goal unchanged. The deployment reached READY and the production alias returned HTTP 200. Web data remains browser-local; Android installation and Home role are unavailable on this target.

## v8122 runtime-assets correction

Flutter 3.41's default web output omitted static assets needed by `index.html`, Flutter's runtime, and Drift. `scripts/vercel_build.sh` now requests the offline-first PWA bundle and runs `scripts/verify_web_bundle.sh` before reporting success. Vercel production deployment `dpl_GqVwfikggysU96zvKA46GJXoWF3y` reached READY with build number 8122. The live version endpoint plus asset manifest, Material font, background, icon, web manifest, Drift worker/WASM, and service worker returned HTTP 200. The local v8122 web Home and AI privacy disclosure rendered in the browser. Browser data remains local to its profile and does not sync with Android.
