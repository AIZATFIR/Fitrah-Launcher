# Technical evidence review

Date: 2026-11-03. Lens: BMAD architecture named-technology/current-fit reviewer. Reviewed ARCHITECTURE.md and EVIDENCE.md against repository source, exact installed package source and primary Flutter/Android documentation. BUILD-ROADMAP.md was consulted to avoid reporting already-gated work as missing. No app tests, builds or device checks were run. Main documents were not changed.

**Verdict: sound proposed architecture; two medium clarifications before the relevant implementation gates. No critical/high unsupported technology decision found.** This is a planning-evidence verdict, not proof that the current app satisfies the architecture.

## Findings

### P2 TE-01 — E0 toolchain inventory should include resolved Android build/API settings

Location: ARCHITECTURE.md AD-15 (line 144); EVIDENCE.md technical-source table; BUILD-ROADMAP.md E0.

E0 explicitly requires exact Flutter/Dart/JDK and resolved dependencies, but does not explicitly name Gradle, Android Gradle Plugin, Kotlin plugin, compileSdk, targetSdk and minSdk. These affect whether Android permission, background and edge-to-edge rules apply and whether another builder reproduces the artifact. Current source has compileSdk 36, targetSdk 35, minSdk 24, Java/JVM target 17, AGP 8.11.1, Kotlin 2.2.20, and Gradle wrapper 8.14. These are observed configuration values; they do not establish the installed Flutter SDK, actual JDK executable or a successful build. The proposed architecture correctly avoids calling existing dependency versions the latest and correctly defers an exact SDK release pin to E0.

Fix: expand AD-15/E0's explicit inventory and gate to include the Android settings above, actual resolved environment and supported OS/API matrix. Pin the selected exact Flutter SDK after the E0 reproducibility check. Do not silently upgrade the stack during this documentation fix. If dependency names are presented as resolved baseline, distinguish pubspec constraint `flutter_riverpod: ^2.5.1` from lockfile resolution `2.6.1`.

Evidence: `android/app/build.gradle.kts:10,14,20,32,33`; `android/settings.gradle.kts:22,23`; `android/gradle/wrapper/gradle-wrapper.properties`; `pubspec.lock:393`. [Android edge-to-edge](https://developer.android.com/develop/ui/views/layout/edge-to-edge) explicitly makes behavior conditional on target SDK and OS. Disposition: clear documentation fix before E0 is called complete.

### P2 TE-02 — Reminder reconciliation needs a durable delivery-intent rule

Location: ARCHITECTURE.md AD-6 (line 90), AD-11 (line 120); BUILD-ROADMAP.md E2.

The plan correctly commits session data before notification effects and already calls for pause/cancel/resume, process death, reboot and crash-between-commit-and-side-effect checks. The spine does not yet bind how an OS alarm is reconciled after a crash in that gap. Independent builders could schedule only after the Dart command returns, while another assumes native registration is already reliable. That can leave a durable running session without a registered completion reminder or leave a stale alarm after pause.

Fix: require reminder intent to be durably derivable from session ID/revision/state/deadline and reconciled on startup/resume, permission changes and boot when supported. OS registration/cancellation must be repeatable; delivered callbacks check current session/revision before acting. E2 selects the concrete receiver/plugin/bridge implementation and records the result. Separate OS alert delivery from domain terminal accounting when Dart is absent; a posted alert must not fabricate habit credit. A separate event-sourcing system is unnecessary if existing session state provides the durable desired state.

Evidence: [Android alarms](https://developer.android.com/develop/background-work/services/alarms) operate outside app lifetime, but are external effects; [exact-alarm access](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms) requires permission-state handling; [Android 15 stopped state](https://developer.android.com/about/versions/15/behavior-changes-all) cancels pending intents after force stop. Disposition: clear contract fix before E2 implementation is considered ready; no new library decision required now.

## Verified constraints and appropriate deferrals

| Topic | Review result |
|---|---|
| Modular app and repositories | Consistent with [Flutter architecture](https://docs.flutter.dev/app-architecture/guide) and [offline-first](https://docs.flutter.dev/app-architecture/design-patterns/offline-first). Class names, module names and domain shapes are labeled project recommendations, not claims that Flutter mandates them. |
| Separate APKs/private databases | Correct. Android private storage is per app; [ContentProvider](https://developer.android.com/guide/topics/providers/content-providers) offers intentional cross-process access. [App Links](https://developer.android.com/training/app-links/about) route content and are not a replication protocol. [Storage/security](https://developer.android.com/privacy-and-security/security-best-practices) supports this boundary. |
| Isar existing version/web | Correct and unusually well evidenced. Lockfile pins `3.1.0+1`; exact [tag web source](https://raw.githubusercontent.com/isar/isar/3.1.0%2B1/packages/isar/lib/src/web/open.dart) and local pub-cache source throw on open; web core initialization also throws. Repo catches errors and returns null, and repository fallbacks use memory. No browser persistence success is claimed. Generic Isar website web wording must not supersede exact-version code. |
| Database replacement | Properly gated to E1 with two bounded alternatives and migration fixtures. No unresearched new database/backend is selected. Native data/schema identities are protected. A current-version check and platform POC are required at the later binding decision. |
| Monotonic timer and reboot | AD-4 matches [SystemClock](https://developer.android.com/reference/android/os/SystemClock): elapsedRealtime includes sleep and is since boot; wall clock may jump. Review-required recovery after uncertain reboot is conservative and credible. Boot identity implementation is not yet selected; prove its actual availability/correctness in E2 rather than presenting it as a ready API. |
| Force stop | Correctly distinguished from ordinary process death. Android 15 cancels pending intents; documents avoid promising delivery after force stop. |
| Notification/exact alarm/FGS | Correctly conditional. [Notification permission](https://developer.android.com/develop/ui/compose/notifications/notification-permission) affects visibility. [FGS types](https://developer.android.com/develop/background-work/services/fgs/service-types) make shortService unsuitable for long sessions and dataSync an inappropriate generic timer label. No accidental foreground-service dependency is committed. At E0/E2 audit existing manifest's USE_EXACT_ALARM and SCHEDULE_EXACT_ALARM together against the actual intended distribution/use case; existing declarations alone prove neither access nor eligibility. |
| Home role | [RoleManager](https://developer.android.com/reference/android/app/role/RoleManager) supports requesting and checking actual role state. Opening Settings is correctly not treated as success. |
| Accessibility/insets | Referenced [Android accessibility](https://developer.android.com/guide/topics/ui/accessibility/apps), [Flutter accessibility](https://docs.flutter.dev/ui/accessibility) and edge-to-edge sources support the stated touch/contrast/semantics/inset checks. They do not imply Compose implementation is required in this Flutter app. |
| Sync and cloud | Existing Firebase dependencies are correctly not treated as provider selection. E8 owns auth/provider/CAS/retry evidence; local-only core stays functional. Proposed merge and ownership semantics are project policies, not claimed guarantees from an unselected backend. |

## Evidence scope

Primary web sources were checked during this research run; exact installed Isar source and repository configuration were read directly. OS behavior statements remain conditional on OS/target SDK/permissions and require device evidence at E2/E5/E6. No assertion here certifies the latest Flutter/Riverpod/Isar release, Play distribution eligibility, runtime alarm reliability, restore behavior or migration safety.
