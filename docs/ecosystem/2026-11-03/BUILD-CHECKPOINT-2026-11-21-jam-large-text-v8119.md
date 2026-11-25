# Focus Clock large-text Jam owner preview v8119

**Date:** 21 November 2026  
**Version:** 0.5.31 (versionCode 8119)  
**Source:** `bee2ce1`

## Download

The local personal preview package is at [INSTALL.md](../../../release_dist/2026-11-21-focus-clock-wrapped-jam-summary-v8119/INSTALL.md). It contains a universal APK, a static web ZIP, QA screenshots, checksums and a build manifest. The APK uses the local Android Debug certificate; it is not a public GitHub or Play Store release.

## Changes

- Jam provides a chronological, labeled schedule list with an action to open each activity's detail sheet, plus clear loading/error/empty states.
- The Jam header wraps on narrow screens, and the empty “Waktu Luang” summary wraps instead of being truncated at large text sizes.
- AI chat remains ephemeral in process memory. The owner chose not to retain chat/curhat history; see [OWNER-INTENT](OWNER-INTENT.md) and [PRD FR-04a](PRD.md).

## Verification

- Schedule-list and large-text widget regressions: **2 passed**. The latter was observed failing before the fix.
- Full serial Flutter suite: **451 passed** (`flutter test --no-pub --concurrency=1 --reporter expanded`).
- Scoped Flutter analyzer: clean for the changed Jam widget and tests.
- Universal Android release APK built and verified: package `com.aizatfir.fitrah_launcher`, versionCode 8119, min API 24, target API 35, APK Signature Scheme v2. Certificate matches v8117/v8118.
- API 36 x86_64 `FocusClock_UI_QA` at 1080×2400 and 200% text upgraded from v8118 to v8119, retained Fitrah as Home role holder, relaunched after force-stop, and returned to Fitrah on the Android Home key. The 200% Jam summary wraps fully, menu text and schedule sheet are readable, and Home's **Buka jam** opens Jam in one tap. [QA screenshots and package notes](../../../release_dist/2026-11-21-focus-clock-wrapped-jam-summary-v8119/BUILD-CHECKPOINT.md).
- Sampled app logs contained no app fatal, FlutterError or target-app ANR.
- Standard JavaScript web build succeeded and was deployed to [Focus Clock web](https://focus-clock-web.vercel.app/) as `dpl_H1W7aGxZmXbCEB8zmSUZBXzFW7LX`; production alias returned HTTP 200. The optional Wasm dry run remains incompatible with current dependencies.

## Limits

Physical handset/OEM behavior, TalkBack, live AI provider calls and seven-day owner use remain unverified. Web data is local to the browser profile, without cross-device sync. Production signing, public release and E0–E11 remain open; this checkpoint is not ecosystem completion.
