# Focus Clock web production update — 21 November 2026

## Published build

- URL: [focus-clock-web.vercel.app](https://focus-clock-web.vercel.app/)
- Vercel deployment: `dpl_JCRKimzMe2sGrrT8pbsPxZLytvvQ` (ready, production)
- Source: `6efbe21d08774d0d6df2f93778ad2096b5884594`
- Build: `npm run build:focus` with Flutter 3.41.9 / Dart 3.11.5; standard JavaScript target. The optional Wasm dry run reported current dependency incompatibilities; it did not prevent the JavaScript build.
- Browser database assets match Drift 2.35.3: `sqlite3.wasm` and `drift_worker.js` passed the pinned SHA-256 checks in `scripts/prepare_browser_storage.sh`.

## Smoke evidence

The production alias opened as **Focus Clock** and rendered the unified app's **Jam / Hari Ini / Aplikasi** navigation. The empty Home showed the goal prompt, add-activity action, current time, analog dial, and habit area. Enabling Flutter's accessibility tree exposed labels for the goal, AI entry, date, dial actions, habits, and all three navigation destinations. No personal goal or schedule was entered during this check.

## Limits

This deploy makes the current unified Focus Clock/Fitrah app available on the web; it does not create cross-device sync. Browser data remains in that browser profile. Android-only app drawer capabilities are not available on web. We did not verify offline startup after browser eviction, mobile Safari/Firefox, TalkBack, live AI provider calls, or seven-day daily use. The optional Wasm build remains unsupported by current dependencies; Vercel serves the JavaScript build.

The deployment is separate from the Android owner preview in [v8117](BUILD-CHECKPOINT-2026-11-20-empty-agenda-large-text-v8117.md). It does not complete the remaining ecosystem roadmap.
