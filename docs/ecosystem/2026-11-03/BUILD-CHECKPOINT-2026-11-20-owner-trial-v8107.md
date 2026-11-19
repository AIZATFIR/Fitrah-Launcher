# Owner trial checkpoint v8107

**Date:** 20 November 2026
**Version:** 0.5.28 (versionCode 8107)
**Purpose:** Prepare a clean, downloadable Focus Clock / Fitrah Launcher build for an owner trial centered on goal, today's activity, the analog clock, and a real focus session.

## Product path exercised

On a clean API36 x86_64 AVD profile, the user could:

1. Open **Hari Ini** and see an empty goal prompt, **Tambah kegiatan**, the clock, habits, and the three primary tabs.
2. Add and pin `Menang LKS Nasional IT Software Solution` as the Home goal.
3. Capture `Latihan LKS 30 menit` into the inbox, select it as today's action, and link it to the goal.
4. Add a 15-minute block at 04:00. Android notification permission was denied; schedule saving still succeeded.
5. Start the linked action from Home, finish after 25 measured seconds, and see `Fokus hari ini · 25 detik` on Home.
6. Switch between **Jam**, **Hari Ini**, and **Aplikasi**, force-stop and reopen, and retain the goal/action/focus total.
7. Install v8107 over v8106 without clearing application data; the same goal/action/focus total remained visible after the upgrade.
8. Export a non-empty v5 JSON backup through Android Save As, inspect its preview, change the QA goal title, and restore the file through DocumentsUI. The original pinned goal, today's linked action, scheduled activity and 23-second focus total returned. The app reported that a private local recovery copy was created before replacement.

The smoke used disposable AVD data. No QA goal or screenshot is inside the downloadable package.

## Default Home follow-up

On 20 November, the v8107 API36 AVD was reset and Fitrah's **Pilih Fitrah sebagai launcher default** control opened Android's real Home-app chooser. Selecting Fitrah made `com.aizatfir.fitrah_launcher` the Android Home role holder. With a pinned `QA_HOME_LKS` goal, pressing system Home from Android Settings and relaunching after force-stop both returned to Hari Ini with that goal visible. The QA goal was cleared and Nexus Launcher restored before ending the run. Screenshots remain outside the package in ignored `.dart_tool/android-qa/v8107/`. This is AVD evidence; it does not prove physical/OEM or reboot behavior.

## Verification

- The four focused suites recorded for the unchanged v8106 source passed **52 tests**, including Home history/persistence, goal/action cue, launcher shell, app drawer, 320 dp, and 200% text.
- v8107 Android universal release APK and Flutter Web JavaScript release output built successfully.
- v8107 installed over v8106 on the disposable API36 x86_64 AVD. App metadata reported versionCode 8107; the key user journey and persistence after force-stop/reopen passed.
- No Flutter fatal or unhandled exception appeared in the sampled log during these journeys.
- Android notification permission was denied during schedule creation; activity and timer remained usable.
- Non-empty backup counts: one schedule, one task, one preference record, one goal/today-selection document, and one terminal focus session; that session and its completed activity both preserved **23 measured seconds**. The backup's app-settings allowlist contained no API-key field. Other record types were empty in this fixture.
- Restore preview identified format v5, showed its record counts and warned that restore replaces local data. The restored Home showed the original goal and action; its measured focus total remained **23 detik**.
- The saved backup was exported to Android Downloads, pulled to the local disposable-QA evidence folder for inspection, then selected again through DocumentsUI. It is not included in this package.
- Web archive integrity, APK package/signature metadata, and SHA-256 checksums are recorded in the downloadable package.

## Download and install

See the package's `INSTALL.md`. For an Android phone, use the universal APK and install it over the prior preview to preserve data, provided Android accepts the same signing certificate. If Android reports a signature conflict, do not uninstall first; export a backup before changing installations. The APK uses the local Android Debug certificate and is a personal preview, not a Play Store release.

## Limits

This is an owner-trial checkpoint, not ecosystem completion. The test was on an emulator, not the owner's physical phone. OEM launcher behavior, TalkBack navigation, live AI provider calls, long-term daily use, and remaining E0–E11 gates stay open. Web is a static JavaScript preview; browser runtime/persistence and deployment are not claimed here. AI, sync, WhatsApp, MCP, and open-source publication remain future work.
