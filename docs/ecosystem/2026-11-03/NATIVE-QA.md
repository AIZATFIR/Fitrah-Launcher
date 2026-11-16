# Native Android QA

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
