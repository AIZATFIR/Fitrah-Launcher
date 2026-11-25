# Build checkpoint — usable goal-first preview v8090

**Date:** 19 Nov 2026
**Version:** 0.5.15+8090
**Download/install notes:** [personal preview package](../../../release_dist/2026-11-19-focus-clock-usable-checkpoint-v8090/INSTALL.md)

## What is ready to use

- Fitrah Home keeps the chosen goal visible; Hari Ini helps choose an action, and Mulai fokus starts the shared focus timer.
- Jam, Hari Ini, and Aplikasi have labeled navigation that stays below scrollable content. Bookpaper colors and the analog clock remain.
- Goal/action/timer and navigation were exercised on API36 x86_64 in v8089. v8090 carries that UI and adds the provider fix below.
- AI settings distinguish a saved key from a working connection and offer an explicit **Uji koneksi** action. No request happens just by opening Settings.
- Custom OpenAI-compatible HTTPS providers can be used without a key when they permit it. Their selected URL/model is used directly, Authorization is omitted for blank keys, and a failed custom endpoint does not silently reroute conversation text to the backend.

## Verification evidence

- AI provider probe, Settings widget and action proposal suites: **24 passed**.
- Complete Flutter test suite: **424 passed, 0 failed**, serially. Full-project analyzer reports five info-level lints in existing unrelated files and no warnings/errors; `git diff --check` is clean.
- Scoped analyzer for provider routing, AI service and action tests: clean. `git diff --check`: clean at time of checkpoint.
- Universal APK and standard JavaScript web release builds succeeded. APK metadata: `com.aizatfir.fitrah_launcher`, 0.5.15 / versionCode 8090. APK v2 signature and web ZIP integrity verified. Hashes: `release_dist/2026-11-19-focus-clock-usable-checkpoint-v8090/SHA256SUMS`.
- Installed v8090 over v8089 on API36 x86_64 using `adb install -r`. Package version 0.5.15 / code 8090 was confirmed; Fitrah remained HOME role holder and the saved LKS goal/action remained after install. **Aplikasi** listed real installed apps; Chrome launched from that drawer; long-press offered favorite/hide/app-info; app info opened Android Settings for Chrome; Home returned to Fitrah with the same goal/action. A Sadar test APK appeared in search after installing it and returning from Chrome; Fitrah's delete action opened Android Package Installer, and search showed no match after uninstall/return. The test package was removed from the emulator. The AVD HOME role was restored to Nexus Launcher after capture. Screenshots and package verification are in the preview folder.
- No real provider request or API key was used. The actual goal→action→timer journey was exercised in v8089; v8090 runtime specifically verifies upgrade and Home return, while its AI provider behavior is covered by targeted tests.

## Limits

This is a downloadable personal preview, not an ecosystem finish. It uses the local Android Debug signing certificate. One add/remove refresh cycle passed on API36; Play Store install flow, physical/OEM phone behavior, TalkBack/large text, sustained daily use and actual user provider/model quality remain unverified. WebAssembly dry-run reports current dependency incompatibilities; use the standard JS bundle. Browser persistence is profile-local. Production signing, cross-app sync, WhatsApp/MCP and remaining ecosystem roadmap work are still open.
