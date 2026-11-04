# E0 implementation baseline

Captured 3 November 2026 from `/home/aizatfir/Project/Fitrah-Launcher`. Status: **partial; release/device gate still closed**.

## Source and working tree

- HEAD: `1de34da466af52a5e50ff7191665304a66a5f54f` (`feat(habits): Loop habit grid with pure solid streak blocks, Organize screen, New Journal with IDEAS, and Focus Clock timer integration`), branch `master`.
- Android default entry point is `lib/main.dart`; `lib/main_fitrah.dart` and `lib/main_sadar.dart` are alternate entry points without configured flavors.
- Before this slice, the only dirty tracked files were `build/web/assets/fonts/MaterialIcons-Regular.otf`, `build/web/flutter_bootstrap.js`, and `build/web/main.dart.js`. Their SHA-256 values at capture: `7ec247452e1cce63cf8f09beebd432cee3171e78388dad7124d3e1190bb7132e`, `e910847446cc7e3e022c3451ad0fd4dd2b99ae3f6df57b5c4bb04597f24d6221`, `b10f80302c1d2006fccdd41d2a646dab59bd46c724afd55c1bb65da27760cc62`.
- These generated web files were retained. No checkout reset or cleanup was run.

## Toolchain and Android identity

- Flutter `3.41.9` stable, revision `00b0c91f06`; Dart `3.11.5`; OpenJDK `21.0.12`; Gradle wrapper `8.14`; Android Gradle Plugin `8.11.1`; Kotlin `2.2.20`.
- Android module: application ID `com.aizatfir.fitrah_launcher`, min SDK `24`, compile SDK `36`, target SDK `35`.
- Resolved core packages: Isar and Isar native libs `3.1.0+1`; Riverpod `2.6.1`; `path_provider` `2.1.5`.
- Release build config currently signs with the debug signing config. The repository APK `Fitrah-Launcher-v0.4-Android.apk` is version `0.4.3`, package `com.aizatfir.fitrah_launcher`, SDK 24/36/35, and Android Debug certificate SHA-256 `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`. It is a repository artifact, not evidence of the APK installed on the owner's phone.
- No device was connected to ADB at capture. No data backup from an installed app was available; no install or upgrade test was run.

## Existing Isar identity

Do not rename schemas or regenerate IDs without a migration comparison. Current collection names and IDs are:

| Collection | Schema name | ID |
|---|---|---:|
| Activity | `Activity81850` | `7577928743684601` |
| AppSettings | `AppSettings209780` | `4711668582438879` |
| DailyReflection | `DailyReflection` | `329460378031511` |
| Habit | `Habit` | `3896650575830519` |
| HabitEntry | `HabitEntry` | `-8920681852023174` |
| Preset | `Preset227440` | `4727396763174827` |
| Task | `Task62620` | `5865284134909238` |
| TimerSession | `TimerSession` | `-4159859870323604` |

## Gate state

- Static Dart analysis passed after the storage and Home cue slices: `flutter analyze` → `No issues found!`.
- `flutter build apk --debug --no-pub` completed from `lib/main.dart`. Output: `build/app/outputs/flutter-apk/app-debug.apk` (195,388,586 bytes; APK SHA-256 `e4e5dbcf1ceac0a3199def0f9300f362d53fa1a8dc6fd9702be53097b8da4a8b`), package `com.aizatfir.fitrah_launcher`, version `0.5.3` (code 7), min/compile/target SDK 24/36/35. APK signer SHA-256: `b8af9d95bd72793e817c2bec78f3e1360d96456ef47db5260ed0d5a19934fe3e`, matching the repository debug certificate. Debug build only; no install/device check.
- Clean-checkout reproducibility, generated schema comparison, real-device backup/restore, font scale, screenshot baseline, and upgrade-signature compatibility remain unverified. E0 is therefore not marked complete.
- The project contains at least two timer implementations and several repositories that accept `isar == null`; these remain separate follow-up slices after storage behavior is safe.
