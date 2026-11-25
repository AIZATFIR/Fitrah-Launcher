# Checkpoint v8110: favorites remain visible in app drawer

**Date:** 20 November 2026  
**Build:** 0.5.28 (versionCode 8110)

## User-facing fix

The installed-app drawer separates pinned favorites from the alphabetical list to avoid duplicates. When every installed app was either a favorite or hidden, an early empty-state return prevented the Favorites section from rendering. The empty-state now appears only when there are no regular apps and no favorites to show.

## Evidence

- Full-suite regression first failed at the missing “Favorit” heading with one favorite and the other installed app hidden.
- Drawer preference widget suite: 23 passed after the fix, covering hidden management, once-only favorites, search and restore.
- Full serial Flutter suite: 442 passed.
- Full analyzer: no warning/error diagnostics; five pre-existing info-level lints in untouched files.
- Production repository browser journeys passed in Chrome 150 / `sharedIndexedDb`: reload durability across all live models and goal, recurrence/exclusions, rollback, unsafe ID guard, two-tab timer exclusivity, exact 67-second contribution, Activity completion idempotency and backup recovery export.
- Android universal APK and Flutter Web JavaScript build completed. APK metadata confirms package `com.aizatfir.fitrah_launcher`, version `0.5.28`, code `8110`, min API 24, target API 35. v2 signature and both package checksums verify.

## Limits

No physical phone was attached. No fresh emulator screenshot was captured because the API36 QA emulator had shown an Android System UI not-responding dialog during its previous cold launch. Production/debug signing, TalkBack, OEM behavior, live provider, daily owner use, deployment and later ecosystem features remain open.

Download: [v8110 install notes and artifacts](../../../release_dist/2026-11-20-focus-clock-drawer-favorites-v8110/INSTALL.md).
