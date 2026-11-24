# Native Android QA

## v8152 fresh AVD HOME and app-index scrub — 24 Nov 2026

Installed the owner-preview release APK `0.5.60 / 8152` on a temporary Android 16/API 36 x86_64 `medium_phone` AVD at 1080×2400. This AVD used the already-installed Google Play system image, ran headless with SwiftShader, and was removed after the run. `cmd role add-role-holder` assigned `com.aizatfir.fitrah_launcher` as `android.app.role.HOME`; pressing Android HOME opened Fitrah `MainActivity`. The Android system Home chooser was not exercised.

The goal-first Home loaded in its blank state. The menu opened **Buka Apps Drawer**; the drawer listed actual installed app names and icons. Holding the alphabet index on **S** displayed only **Safety** and **Settings**. Releasing restored the full list with the S section visible and S still selected. Opening Android Settings from the drawer and pressing HOME returned to Fitrah `MainActivity`. RoleManager still reported Fitrah as HOME. A sampled 2,000-line logcat tail had no `FATAL EXCEPTION`, `FlutterError`, `ANR in`, or `PlatformException` matches.

Screenshots: `release_dist/2026-11-24-focus-clock-v0.5.60-8152/QA_Fitrah_Home_HomeRole_v8152.png`, `QA_Fitrah_AppDrawer_ScrubHeld_S_v8152.png`, and `QA_Fitrah_AppDrawer_ScrubReleased_S_v8152.png`. This verifies one temporary emulator run, not the chooser, physical/OEM home behavior, TalkBack, or long-term daily use. See [v8152 checkpoint](BUILD-CHECKPOINT-2026-11-24-focus-clock-v8152.md).

## API 36 timer-flow evidence — v8087 (18 Nov 2026)

The disposable `FocusClock_UI_QA` API36 x86_64 AVD installed universal v8087 successfully; package metadata reported versionName `0.5.12`, versionCode `8087`. Fitrah was already the Android HOME role holder. Through the real UI, the saved LKS goal was linked to the `Latihan LKS 30 menit` action, then the timer was started. Android's notification prompt was granted. `dumpsys alarm` showed a scheduled RTC_WAKEUP reminder at the saved session duration; pausing removed the active alarm and resuming scheduled the remaining duration. Ending early returned to Home with the selected goal/action still visible. Opening the timer hub worked; returning from Android Home also restored the central goal Home. Hierarchy snapshots are under ignored `.dart_tool/android-qa/v8087-*.xml`.

This is one emulator journey only. It does not prove screen-off/Doze delivery, process-death restoration, physical/OEM reliability, or behavior across repeated days. The AVD is no longer running. The v8088 navigation/header UI has widget-test coverage and was not installed on a physical device.

## API 36 usable-navigation smoke — v8089 (19 Nov 2026)

The same AVD upgraded v8088→v8089; `adb install -r` succeeded, package metadata reported `0.5.14+8089`, and RoleManager still named Fitrah as HOME. On the settled Home screenshot, the pinned `Menang LKS National IT Software Solution` goal and habit row/weekday selector were visible above the Scaffold bottom navigation. Through real UI, TodaySelection for `Latihan LKS 30 menit` was linked to the LKS goal and saved. **Mulai fokus** opened the 30-minute session. Jam→Aplikasi→Hari Ini navigation worked while the session ran; returning Home showed the same linked goal and a `29:10` session countdown. **Selesai sekarang** returned to Home with the selected action retained. The inspected logcat window had no Flutter/FATAL error. Screenshots are in the v8089 preview folder; full hierarchies are in ignored `.dart_tool/android-qa/v8089-ui/`.

This is bounded emulator evidence only. It does not prove Doze/screen-off delivery, force-stop recovery, a physical phone/OEM, accessibility, or repeated-day reliability. The emulator is closed after the smoke. See [checkpoint v8089](BUILD-CHECKPOINT-2026-11-19-navigation-content-v8089.md).

Use a disposable AVD for synthetic test data. Keep the owner's existing device and `Medium_Phone` AVD unchanged.

## Working setup

The verified host setup uses Flutter 3.41.9, Dart 3.11.5, Android SDK compile API36 and the installed `system-images;android-36;google_apis_playstore;x86_64` image. KVM is available. The QA AVD has 1536MB RAM, two cores and SwiftShader graphics. Its data lives under ignored `.dart_tool/android-qa/`, outside the temporary filesystem.

From the repository root, with Android SDK tools on PATH:

```bash
export ANDROID_AVD_HOME="$PWD/.dart_tool/android-qa/avds"
mkdir -p "$ANDROID_AVD_HOME"
avdmanager create avd --name FocusClock_QA_API36 \
  --path "$PWD/.dart_tool/android-qa/FocusClock_QA_API36.avd" \
  --package 'system-images;android-36;google_apis_playstore;x86_64' \
  --device medium_phone
emulator -avd FocusClock_QA_API36 -no-window -no-audio -no-boot-anim \
  -no-snapshot -skip-adb-auth -gpu swiftshader -memory 1536 -cores 2 \
  -camera-back none -camera-front none
```

Create the AVD once; on later runs start the existing one. `-skip-adb-auth` is the emulator's documented test option, used only for this disposable headless AVD. The API37.1 QA image remained unauthorized in this run; no app-runtime result was inferred from it.

Use a second terminal for the build and device checks:

```bash
flutter build apk --release --target-platform android-x64 --build-number 10
adb devices
adb -s emulator-5554 shell getprop sys.boot_completed
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s emulator-5554 shell am start -W \
  -n com.aizatfir.fitrah_launcher/.MainActivity
```

Confirm the actual serial with `adb devices`; `emulator-5554` was the sole QA device during this run. Build number10 is this run's QA override, not a permanent project version. The x64 QA APK is not the arm64 phone download. Verify package version and signing certificate before treating installation as an upgrade.

## Evidence so far

Checkpoint `c8b10871348b54d85e179b6c41b3160af8834b62` installed and rendered Home on API36. Notification permission was denied. Through the real UI, `QA-LKS-Nasional` was created and pinned to Home; it remained visible after force-stop and cold restart. Startup requested notification permission again after the first denial, which remains an onboarding/permission issue to address. These observations do not establish the newer capability changes, daily-device behavior, default Home role, reboot recovery or physical-phone compatibility.

Screenshots, UI hierarchy dumps and the synthetic QA APK are in `.dart_tool/android-qa/`. Build/test logs are in `.dart_tool/verification/launcher-20261109/`; these generated files are ignored by Git. Source verification and remaining gates are tracked in [BUILD-ROADMAP](BUILD-ROADMAP.md).

The subsequent capability changes compiled as x64 versionCode10 in 183.8 seconds and upgraded the versionCode9 installation with the same signing certificate. A fresh post-upgrade hierarchy retained QA-LKS-Nasional. The real drawer opened Android Clock (foreground package verified as `com.google.android.deskclock`), then Back returned to Fitrah and its real app list. Failure paths are covered by mocks, not by induced platform failures on this emulator. Default Home, all app actions, daily/vendor behavior and full migration remain separate gates.

## Download integrity

The first new Android build rejected a 92-byte HTTP504 HTML response as a SQLite library. Retrying the package's official release URL produced an ELF matching the package's expected SHA-256 `949965f0eba976f707ae364cdcb42c342b5f0626081f8d7f0378fb7b52848772`. Only that verified binary was copied into the generated hook cache. Package hashes, source and dependency lock were not changed; build-time integrity validation stays enabled.

## Durable drawer and default Home checkpoint (9 November)

VersionCode12 x64 upgraded the same QA installation. Goal QA-LKS-Nasional survived. Clock added through the actual app sheet remained a favorite after cold restart; after a successful hide commit, Clock remained absent after cold restart. The hidden manager restored Clock with its favorite shortcut intact. Initial HOME holder Pixel matched the app not-default state; canceling the system chooser preserved both. Selecting Fitrah through the system UI changed ROLE_HOME holder to com.aizatfir.fitrah_launcher, and Settings showed the matching held state. Held-state change action opened Android Home settings. Actual emulator reboot retained the role, goal and favorite. This does not prove physical-device behavior.

System Home then exposed a pre-existing navigation bug: Android correctly resumed Fitrah, but Flutter retained its Settings route. VersionCode14 adds a distinct native HOME event and guard-aware shell return. It compiled in141.9 seconds and upgraded successfully. Repeating Fitrah Settings → Android Home settings → system Home now showed central goal Home with the same QA goal. Launching the actual Clock favorite, verified as foreground Android DeskClock, then pressing Home also showed central goal Home. The new checkpoint was not separately reboot-tested. Evidence XML/foreground dumps reside under ignored .dart_tool/android-qa/; tests additionally cover blocked editor routes, session preservation, disposal and ordinary resume.


## Final local preview startup check — 14 November

A disposable `FocusClock_QA_API36` x86_64 AVD installed the versionCode19 QA APK built from current app source `53811bc`. `am start -W` completed with status ok (cold start about 2.6s after boot); package metadata reported versionName0.5.3/versionCode19, and a 1080×2400 screenshot showed the saved synthetic `QA-LKS-Nasional` goal cue, actual analog clock face, empty schedule affordance, and daily note surface. The 300-line logcat tail contained no `FATAL EXCEPTION`, `AndroidRuntime`, or `FlutterError` match. A later `input tap` did not return while the host had 4 GB swap fully committed, so no Settings or Focus preset interaction was inferred. The AVD was terminated; owner `Medium_Phone` was not changed. Screenshot and x64 APK are in ignored `.dart_tool/android-qa/2026-11-14/`; deliverable screenshot is in the local preview folder.

## Notification permission timing follow-up — 14 November

Source inspection confirmed `NotificationService.init()` requested Android notification permission at each app bootstrap. The request now waits until the user creates a scheduled activity, after checking whether notifications are already enabled, and repeats at most once per `NotificationService` process when declined. Flutter channel regression covers no permission call on initialization, request-on-first-schedule, no repeat for later schedules in the same process, and no request when already enabled. Version23 package is compile verified only; runtime permission UI has not been exercised on the emulator/device.

## Preview30 responsive prayer header smoke — 14 November

The isolated API36 `FocusClock_QA_API36` AVD upgraded from the v29 x64 release checkpoint to a same-signature x64 debug buildCode30. Install succeeded; package metadata showed versionName0.5.3/versionCode30. Cold `am start -W` completed with status ok in 6.64s and `topResumedActivity` was Fitrah `MainActivity`. After app data hydrated, screenshot `.dart_tool/android-qa/2026-11-14-v30/v30-home-settled.png` showed the retained QA-LKS-Nasional goal, single-line Subuh/Dzuhur/Asar/Maghrib/Isya cues, analog dial, empty schedule action, and daily note. Tail of 600 logcat lines contained no `FATAL EXCEPTION`, `AndroidRuntime`, or `FlutterError`. The test AVD was shut down and `Medium_Phone` was not used.

This verifies a local API36 x86_64 debug build and the 411dp emulator layout only. The release arm64 APK was compiled and metadata/signature checked, but not installed. Narrow 320dp behavior is widget-tested. No actual Android device, default Home selection, YPT permission trip, lockscreen, reminders through reboot, vendor behavior, or daily use is verified.

## Preview39 upgrade and Home role smoke — 14 November

Dedicated `FocusClock_QA_API36` upgraded from installed versionCode34 to x86_64 versionCode39 from source `107e0fb`, using the same Android Debug certificate. `adb install -r` completed, package metadata reported versionCode39, and the existing synthetic `QA-LKS-Nasional` goal was still visible in Home. `cmd role get-role-holders android.app.role.HOME` returned `com.aizatfir.fitrah_launcher`. Cold `am start -W` returned `Status: ok`, `LaunchState: COLD`, `MainActivity`, and `TotalTime: 3552ms`. Android Home key returned to the same `MainActivity`; the last 600 logcat lines had no `FATAL EXCEPTION`, `AndroidRuntime`, or `FlutterError`. Screenshot: `.dart_tool/android-qa/2026-11-14-v39-home.png`; QA APK: `.dart_tool/android-qa/Focus-Clock-107e0fb-v39-x64-QA.apk`. The disposable AVD was terminated afterward; the owner `Medium_Phone` was not touched.

This is x86_64 emulator upgrade evidence, not an arm64 install or physical-phone claim. It exercises Home launch and retained synthetic data; it does not cover app search/launch/app-info/uninstall, reminder delivery, font scaling, TalkBack, battery restrictions, or daily use.

## Screen-time cue task reuse and compact placement — 15 November

The isolated API36 x86_64 `FocusClock_QA_API36` AVD upgraded in place through versionCodes48–50 with the existing app data retained. Legacy settings opened with both screen-time switches off. With the permissions already present on the QA AVD, enabling only the cue showed a compact amber/charcoal `13 mnt · Tujuan` action below the status bar, without covering the goal text. Opening Launcher Settings and tapping the cue returned to the goal Home within the existing HOME task (`Task #25`, `type=home`); pressing Android Home afterward still showed that same root Home task, not a second standard task. The cue was then disabled; both switches were false and the app-owned overlay window was absent. Build 50 compiled and installed successfully. The daily wait/countdown behavior, unavailable usage statistics, TalkBack, and physical-phone behavior were not exercised in this follow-up.

**Focused widget verification on current source (15 Nov):** drawer and screen-time settings suites pass. Coverage includes both switches off by default, persisted opt-in and threshold, reaching the configured limit, preventing launch during the countdown, launch after waiting, returning to goal without launch, unavailable Usage Access failing open without reporting zero, and revoked/disabled cue removal. This verifies dialog/settings logic with a controlled Usage Stats response; it does not prove the device's real daily total crosses the threshold or an actual wait on a physical phone.


## Bookpaper app-drawer styling preview — 15 November

The drawer now uses the shared charcoal/amber Bookpaper palette, Outfit type, localized Indonesian search/date copy, and removes text shadows. The search field and settings action use the same palette. The Simple Mode headings no longer prefix copy with decorative emoji; legacy activity icon keys still render through the shared Material icon mapper. Web JS compiled and is being served from the v53 preview directory. Android arm64 release versionName0.5.3/versionCode2053 compiled and APK v2 signature/package metadata were checked. This styling change has not been installed or screenshot-verified on the API36 AVD; prior v52 drawer runtime evidence is separate. No physical phone was used.

## Preview53 visual runtime — 15 November

The same isolated `FocusClock_QA_API36` x86_64 AVD upgraded from its prior installation to the v53 x86_64 release build (versionName `0.5.3`, ABI-specific versionCode `4053`) with `adb install -r`. Android still reports `com.aizatfir.fitrah_launcher` as the HOME role holder; cold start returned `Status: ok`. Screenshots under ignored `.dart_tool/android-qa/2026-11-15-v53/` show the Home goal cue and the Bookpaper app drawer. This is current-release x86_64 emulator evidence, not arm64 installation or a physical-phone check. The drawer still presents a large clock, alphabet rail and floating search action; those remain candidates for a usability simplification pass based on the owner's feedback.

## Current launcher HOME loop — 15 November

The isolated API36 x86_64 `FocusClock_QA_API36` AVD upgraded from v53/versionCode4053 to release versionCode4060 (`0.5.3`, targetSDK35, compileSDK36) with `adb install -r`; Android Debug signing matched. `cmd role get-role-holders android.app.role.HOME` returned `com.aizatfir.fitrah_launcher`, and Android's Default home app screen visibly selected Fitrah. The user flow was exercised: add a goal, pin it to Home, open the app drawer, launch Android Clock, press Home, and confirm the same pinned goal remains on Fitrah Home. Returning from Android Home settings also landed on that goal Home. Last 3,000 logcat lines had no `FATAL EXCEPTION`, `E/flutter` or `FlutterError`. The disposable AVD was shut down; `Medium_Phone` was not used.

QA APK: `.dart_tool/android-qa/2026-11-15-v60/FocusClock_Fitrah_v0.5.3-v4060-android-x64-QA.apk` (SHA-256 `054a67d0328c28e7774a6181b8824fee3ee1a0833c76cf91a4995bf76f71cbee`). Screenshots and UI hierarchy are beside it. This proves the launcher HOME/task loop and one successful app launch on an x86_64 emulator. It does not close E5: refresh after install/uninstall, unavailable-app feedback, search/Back/keyboard, favorites/order durability, permission audit, reboot, font scale/TalkBack, physical-device and daily-use checks remain open. E0–E4, E6 and ecosystem milestones also remain open.

## Drawer search and Back smoke — 15 November

On the same v4060 x86_64 AVD, the drawer search button opened a focused field and keyboard. Typing `clock` filtered the real package list to Android Clock; clear restored the list; Back first dismissed the keyboard while retaining the drawer, then returned to Home with the pinned goal visible. Screenshot and UI hierarchy captures are under `.dart_tool/android-qa/2026-11-15-v60/`. This covers a basic search/clear/Back journey only; scrubber accuracy, large-font/TalkBack operation and physical-device behavior remain unverified.

**Alphabet scrubber runtime follow-up:** On the same installed v4060 x86_64 AVD, dragging the alphabet rail to `T` selected T and navigated the installed-app list to the real T group (`TMobile` visible), with the `T` marker highlighted. Screenshot: `.dart_tool/android-qa/2026-11-15-v60/drawer-index-end.png`. This closes the basic actual-section-jump check on emulator; large-font/TalkBack and physical-device interaction remain open.

**Android app-info runtime follow-up:** From the drawer, long-pressing Calendar and selecting `Info aplikasi` opened Android Settings for `com.google.android.calendar`. Android Back returned to the existing Fitrah `MainActivity` drawer task. This confirms the system app-info dispatch/return path on API36; uninstall confirmation, package add/remove refresh, and physical-device behavior remain open. UI hierarchy captures are beside the v60 QA screenshots.

## Personal phone APK — 15 November

Built a split-per-ABI arm64 release APK from current source: `release_dist/2026-11-15-fitrah-phone-6061/Fitrah_Launcher_0.5.3_arm64_v6061.apk`. Metadata: package `com.aizatfir.fitrah_launcher`, versionName `0.5.3`, versionCode `6061`, minSDK24, targetSDK35, and only `arm64-v8a`. APK v2 signature verifies with this workstation's Android Debug certificate; APK zip alignment check passes for 16 KB, and ELF LOAD alignment is 16 KB or higher for each bundled arm64 library. SHA-256 and install steps are in the same directory. No Android device was connected, so physical install, upgrade/data retention and phone HOME behavior are still unverified. This is a personal preview, not a public signing/release build.

## Current source upgrade and Home smoke — 16 November

The current source was built as an x86_64 QA APK with build number 9080 and installed over the disposable API36 `FocusClock_QA_API36` AVD's installed versionCode 9076 using `adb install -r`; package name and Android Debug signing certificate matched. Android retained Fitrah as the `android.app.role.HOME` holder. The Home screenshot and hierarchy at `.dart_tool/android-qa/2026-11-16-v9080/home.png` and `window-after-restart.xml` show the existing pinned “Menang LKS Nasional IT Software Solution” goal and its empty-day cue after force-stop/relaunch. Opening the launcher menu and Apps Drawer displayed the real installed package list; launching Files reached Android DocumentsUI and the Home key returned to Fitrah's existing HOME task. The captured logcat interval had no `FATAL EXCEPTION`, `E/flutter`, or `FlutterError`. Drawer screenshot: `.dart_tool/android-qa/2026-11-16-v9080/drawer.png`; apps screenshot: `apps.png`.

## Current drawer build and HOME return — 16 November

The compact-drawer source was built for x86_64 as QA versionCode9081 and upgraded the same disposable AVD from 9080 with `adb install -r`. Fitrah remained the Android HOME role holder, and the pinned LKS goal remained visible after launch. The drawer screenshot at `.dart_tool/android-qa/2026-11-16-v9081/drawer.png` shows the smaller 32 px clock header and real installed apps. Launching Files opened Android DocumentsUI; pressing Home returned to Fitrah with the same goal still shown. The checked logcat tail had no `FATAL EXCEPTION`, `E/flutter`, or `FlutterError`. Home, drawer, and returned-Home captures are under `.dart_tool/android-qa/2026-11-16-v9081/`; the QA APK SHA-256 is `404d1eed07a453c67c6477e556c3678deac71b728e1ad073ee3c8b34ed8d20d3`.

This is an x86_64 emulator smoke check only. It does not cover the owner's physical phone, accessibility/TalkBack, reboot, long-term use, or all drawer actions. `Medium_Phone` was not used; the disposable AVD was shut down after capture.

## v8081 cold reboot and saved-goal Home — 18 November

The existing `FocusClock_UI_QA` API36 x86_64 AVD already had v8081 installed and Fitrah selected as its Home role. After `adb reboot`, Android reported `sys.boot_completed=1`; `android.app.role.HOME` still returned `com.aizatfir.fitrah_launcher`, and the focused window was Fitrah `MainActivity`. The UI hierarchy showed the saved “Menang LKS National IT Software Solution” goal, its empty TodaySelection state, and the compact analog clock after reboot. The inspected logcat window contained no SystemUI ANR or fatal exception match. Screenshot: `.dart_tool/android-qa/v8081-reboot/home-after-reboot.png`; a copy is included in the v8081 preview folder as `QA_Home_After_Reboot_v8081.png`.

The screen-time cue was active on the QA AVD during this smoke and remained visible after reboot. After capture, both cue and daily-limit settings were switched off through Fitrah Settings, Usage Access and overlay app-ops were restored to `default`, and the HOME role was returned to the installed Nexus Launcher. This remains one emulator reboot check, not physical/OEM reboot evidence or proof of repeated reboot stability.

This is x86_64 emulator evidence only. It does not prove arm64 installation on the owner's physical phone, reboot behavior, accessibility, the full app list lifecycle, or long-term daily use. The distributable universal APK at `release_dist/2026-11-16-fitrah-goal-plan-preview/Fitrah_Launcher_0.5.3_universal_v8066.apk` has versionCode 8066, above the existing v6064 personal preview, and uses the same package and debug signer. It contains the same source as QA build 9081. Physical-phone install remains unverified.

## v8083 Home role and return — 18 November

Universal release v8083 was installed on the disposable `FocusClock_UI_QA` API36 x86_64 AVD. Through Android RoleManager, Fitrah was selected as `android.app.role.HOME`; the Home key focused `MainActivity`. Chrome was launched and the next Home key returned to the same Fitrah Home with the pinned LKS goal visible. After the journey, the HOME role was restored to `com.google.android.apps.nexuslauncher`, and the AVD was shut down. The inspected log tail had no app fatal/Flutter exception match. Screenshot: `release_dist/2026-11-18-focus-clock-ai-setup-preview-v8083/QA_Home_Role_Return_v8083.png`. This proves the current build's x86_64 emulator Home/task loop only; physical phone/OEM activation and repeated reboot remain open.

## v8090 in-place upgrade and HOME return — 19 November

The API36 x86_64 `FocusClock_UI_QA` AVD had v8089 installed with Fitrah as the `android.app.role.HOME` holder and the synthetic LKS goal plus `Latihan LKS 30 menit` choice visible. Installing the universal v8090 APK with `adb install -r` succeeded without uninstalling. Package metadata reported versionName `0.5.15`, versionCode `8090`; RoleManager still reported `com.aizatfir.fitrah_launcher`. The goal/action remained visible after launch. Opening **Aplikasi** displayed the actual installed app list (Calendar, Camera, Chrome, Clock, Contacts, Drive, Files, Gmail, and others). Tapping Chrome from that list opened `com.android.chrome/org.chromium.chrome.browser.firstrun.FirstRunActivity`; pressing Home returned to Fitrah `MainActivity`, with the saved goal/action still in the hierarchy. Long-pressing Chrome exposed favorite, hide, and app-info controls; **Info aplikasi** opened Android Settings activity `com.android.settings/.spa.SpaActivity` with Chrome details, and Home returned to Fitrah again. To check package-list refresh, the API36 AVD installed the legacy Sadar test APK (package `com.aizatfir.sadar`, version `0.3.0`) while Fitrah was active; after switching to Chrome and returning Home, search for Sadar showed the app. The Fitrah **Hapus aplikasi** action opened Android Package Installer; confirming removal and returning to Home made the Sadar search return no match. A second package removal/resume also returned no match. The test APK was uninstalled at the end. Screenshots are packaged as `QA_Home_v8090.png`, `QA_Home_Return_v8090.png`, `QA_Apps_Drawer_v8090.png`, `QA_Apps_Launch_Return_v8090.png`, `QA_Chrome_App_Info_v8090.png`, `QA_Sadar_After_Install_v8090.png`, and `QA_Sadar_After_Uninstall_v8090.png`; XML dumps are in ignored `.dart_tool/android-qa/v8090-ui.xml`, `v8090-home-return.xml`, `v8090-drawer-return.xml`, `v8090-app-info.xml`, and `v8090-sadar-reinstalled-search.xml`/`v8090-sadar-uninstalled-again.xml`.

This verifies one emulator in-place upgrade, installed-app launch, app-info handoff, return journey, and app-list refresh for one package-add/remove cycle. It does not prove Android Play Store/OEM variations, every package-change timing, the owner's phone/OEM, repeated reboot, TalkBack/large text, long-term use or the real AI provider path.

## v8092 goal → action → timer with notifications denied — 19 November

The API36 x86_64 QA AVD was running v8085 with Fitrah as HOME. Installing v8092 with `adb install -r` retained package data and HOME role. The saved goal `Menang LKS National IT Software Solution` remained visible. In **Hari Ini**, the user selected `Latihan LKS 30 menit`, linked it to that goal and tapped **Mulai fokus**. Before the fix, v8091 showed Android's notification permission dialog during start. After installing v8092, `adb shell appops get com.aizatfir.fitrah_launcher POST_NOTIFICATION` still reported `ignore`; the same action opened the timer at 29:57 with no permission dialog. UI hierarchy exposed the activity name, **Jeda**, **Selesai sekarang**, and **Batalkan timer**. The QA timer was canceled; Fitrah's HOME role was restored to Nexus Launcher; emulator was shut down. Packaged evidence: `QA_Home_v8092.png`, `QA_Goal_Action_v8092.png`, `QA_Timer_No_Prompt_v8092.png`, and `QA_Timer_End_Return_v8092.png`. This confirms this path on one API36 emulator only; physical/OEM, reminder permission settings, accessibility, and long-term use remain open.

## v8092 screen-time cue interaction — 19 November

On the same API36 x86_64 QA AVD, **Tampilkan cue waktu layar** explained Usage Access and overlay access before opening the matching Android settings. After granting both, the small `mnt · Tujuan` cue appeared over Chrome and did not block the screen underneath. Dragging it to the display edge produced a small `›` handle; tapping restored the cue; tapping it while Chrome was foreground returned to Fitrah's goal Home. Captures are packaged in `release_dist/2026-11-19-focus-timer-no-prompt-v8092/`.

The AVD reported about 1,318 minutes because it had synthetic test use; this is interaction evidence only, not screen-time accuracy evidence. The cue and daily-limit defaults are both off. Physical/OEM behavior, permission revocation recovery, TalkBack, and real daily measurements remain unverified.

## v8090 packaged permission audit — 19 November

`aapt dump permissions` on the delivered universal APK reports INTERNET, RECORD_AUDIO, RECEIVE_BOOT_COMPLETED, VIBRATE, POST_NOTIFICATIONS, PACKAGE_USAGE_STATS, REQUEST_DELETE_PACKAGES, SYSTEM_ALERT_WINDOW, ACCESS_NETWORK_STATE and Google services read access, plus the app's private dynamic-receiver permission. Source references map these permissions to network/provider use, explicit voice input, reminder restore, timer/reminder feedback, optional screen-time cue/guard, and Android's uninstall handoff. The screen-time cue defaults off; its Usage Access and overlay settings journey starts only after opt-in and explanation. Notification permission is deferred until scheduling. App visibility is scoped to launcher activities; there is no QUERY_ALL_PACKAGES. INTERNET appears in debug/profile manifests for Flutter tooling and remains needed in release for network features. This is a manifest/source mapping, not a Play policy determination or device-vendor behavior proof.

## v8141 clean install, chooser and Home persistence — 23 November

On the disposable API36 x86_64 `Fitrah_Clean_Install_QA` AVD, universal v8141 installed as `0.5.49+8141`. The goal card showed **Jadikan layar utama**. Tapping it opened Android's Home role chooser; selecting Fitrah set `android.app.role.HOME` to `com.aizatfir.fitrah_launcher`, removed the setup action, and pressing Android HOME resumed `MainActivity`. After reboot, the role holder and `resolve-activity` still pointed to Fitrah; once boot settled, Android foreground was `MainActivity`. Force-stopping Fitrah and pressing HOME relaunched `MainActivity`. Sampled logcat had no app fatal, FlutterError, or ANR. Screenshots are in `release_dist/2026-11-23-home-default-cta-v8141/`.

This verifies one clean API36 x86_64 AVD, including reboot after explicit role selection. It does not prove installation or OEM behavior on the owner's physical handset, TalkBack, or long-term daily use.

## API 36 activity editor and save — v8100 (20 Nov 2026)

Installed universal APK `0.5.21+8100` over the QA build. On Focus Clock, opened **Tambah kegiatan**, entered `QA_v8100`, saved, then observed the saved 09:15–09:30 activity on the clock. Opened the block details and entered edit mode. `logcat` had no Flutter `LateInitializationError`, Unhandled Exception, or Android fatal exception after save. Notification permission was denied by the emulator prompt. Screenshots: `release_dist/2026-11-20-focus-clock-activity-save-v8100/QA_Editor_v8100.png`, `QA_Clock_Saved_Activity_v8100.png`, `QA_Activity_Detail_v8100.png`. After QA, restored Nexus Launcher as Android HOME role holder and shut down the AVD.

## v8097 goal → action → timer → Home — 20 November

The API36 x86_64 `FocusClock_UI_QA` AVD had the prior Fitrah preview installed with Nexus as HOME. Universal v8097 installed with `adb install -r`; package metadata reports `0.5.18`, versionCode `8097`, minSdk 24 and targetSdk 35. The saved LKS goal remained visible. In the **Tindakan hari ini** sheet, selected `Latihan LKS 30 menit` and linked it to `Menang LKS National IT Software Solution`. Home showed the selected action and **Mulai fokus**. With `POST_NOTIFICATION` app-op set to `ignore`, tapping **Mulai fokus** opened the 30-minute timer at 29:57 without a notification permission prompt. Canceled the QA timer, navigated **Jam → Aplikasi → Hari Ini**, and used the Home key; Fitrah `MainActivity` resumed with the saved goal/action visible. Captures: `release_dist/2026-11-20-focus-clock-daily-use-v8097/QA_Home_Goal_Action_v8097.png`, `QA_Timer_v8097.png`, `QA_Apps_v8097.png`, and `QA_Clock_v8097.png`. Nexus Launcher was restored as the AVD's HOME role holder and the emulator was shut down.

This verifies one Android API36 x86_64 emulator run only. It does not verify owner phone/OEM behavior, an explicit chooser flow, repeated reboot, TalkBack, a live AI provider call, screen-time accuracy, or sustained daily use.

## v8090 packaged permission audit — 19 November

`aapt dump permissions` on the delivered universal APK reports INTERNET, RECORD_AUDIO, RECEIVE_BOOT_COMPLETED, VIBRATE, POST_NOTIFICATIONS, PACKAGE_USAGE_STATS, REQUEST_DELETE_PACKAGES, SYSTEM_ALERT_WINDOW, ACCESS_NETWORK_STATE and Google services read access, plus the app's private dynamic-receiver permission. Source references map these permissions to network/provider use, explicit voice input, reminder restore, timer/reminder feedback, optional screen-time cue/guard, and Android's uninstall handoff. The screen-time cue defaults off; its Usage Access and overlay settings journey starts only after opt-in and explanation. Notification permission is deferred until scheduling. App visibility is scoped to launcher activities; there is no QUERY_ALL_PACKAGES. INTERNET appears in debug/profile manifests for Flutter tooling and remains needed in release for network features. This is a manifest/source mapping, not a Play policy determination or device-vendor behavior proof.
## Fresh v8153 HOME chooser and app loop — 24 Nov 2026

- Device: disposable clean Android 16/API 36 x86_64 medium_phone AVD, 1080 × 2400, Google Play system image. The emulator raised requested 2048 MB RAM to 2560 MB.
- Installed the GitHub v8153 APK, opened Android Default Home settings, selected **Fitrah Launcher** through the visible system setting, then confirmed `android.app.role.HOME` reports `com.aizatfir.fitrah_launcher`.
- Home showed the blank goal prompt “Apa arah yang ingin kamu jaga?” with no sample goal. Tapping **Buka jam** opened the analog clock page. Swiping from Home opened Habits and the app drawer; drawer listed installed apps including Chrome. Tapping Chrome opened its first-run activity; Android HOME returned to Fitrah's MainActivity and the role remained assigned.
- Sampled 2,000 logcat lines after the Home/clock/drawer/Chrome loop; no `FATAL EXCEPTION`, `FlutterError`, `ANR in`, or `PlatformException` match.
- Screenshots in release evidence: `QA_Fitrah_Home_v8153.png`, `QA_FocusClock_NoQuickPrompt_v8153.png`, `QA_Fitrah_AppDrawer_v8153.png`, and `QA_Fitrah_HomeReturn_v8153.png`.
- This was emulator-only and used a clean install. It does not verify a physical/OEM device, TalkBack, or sustained daily use. No new build was installed on a physical phone.
