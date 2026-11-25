# Build checkpoint — usable Focus Clock navigation v8088

**Date:** 18 Nov 2026
**Version:** 0.5.13+8088
**Downloads:** [Android and web preview](../../../release_dist/2026-11-18-focus-clock-usable-navigation-v8088/INSTALL.md)

## What changed

The three main areas now have persistent, labeled navigation: **Jam**, **Hari Ini**, and **Aplikasi**. Each destination uses the existing swipeable page and shows its selected state. The Bookpaper palette, current clock face, and goal-first Home content remain. The clock page header now uses the actual page width when choosing its compact layout, which prevents the wider device MediaQuery from making the capped launcher page overflow.

## Verification

- Added a widget regression that failed before implementation because no visible destinations existed.
- Launcher/Home widget test files: **10 passed**; navigation taps reached all three pages and the selected index updated.
- Scoped analyzer: no issues; `git diff --check`: clean.
- Android universal release APK and web JavaScript release ZIP built. APK package/version metadata and v2 signature verified; web ZIP passed integrity check; hashes are recorded with the download.
- Flutter's Wasm dry-run reports known incompatibilities in current storage and web dependencies. The standard JavaScript build succeeded and is the included web preview.

## Use this checkpoint

Install the APK, select Fitrah as the Home app, then set/review your goal, choose one action for today, and start its focus timer. The visible navigation makes Clock/Home/Apps discoverable without requiring a swipe. Use the app through a normal day and note where the next action or schedule still feels unclear.

## Limits

v8088 is a usable personal preview, not completion of the ecosystem. It was not installed on a physical phone in this checkpoint; TalkBack, large text, OEM behavior, battery/background behavior, and repeated real-day use remain to validate. The previously exercised v8087 timer flow on an API36 x86_64 emulator verified choosing a habit-linked action, starting a 30-minute timer, granting notification permission, pause/resume alarm reconciliation, ending early, and returning to Home with the goal/action retained. That emulator evidence does not establish physical-device delivery or reliability. AI needs a user-configured provider key. Production signing, full web persistence, sync, WhatsApp/MCP and remaining roadmap gates are still open.
