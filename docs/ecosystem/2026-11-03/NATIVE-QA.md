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
