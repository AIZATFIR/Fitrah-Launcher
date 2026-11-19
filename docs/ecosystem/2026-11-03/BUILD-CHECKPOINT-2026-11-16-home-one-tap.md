# Focus Clock Home follow-up — 16 November 2026

Source base: `d3c5ca5c4c700b877efca82c7e6c8e5036800071`; current working tree has uncommitted changes.

## Product changes

- Home keeps the selected goal, today's action, analog clock, and habits in the primary view. Journal, inbox, history, and timer tools remain inside the collapsed **Catatan & alat** section.
- Home refreshes its displayed clock without rebuilding the full screen every second. Short arc labels are hidden when they cannot fit cleanly on the compact clock face.
- A selected task with a scheduled activity now presents **Mulai fokus**. One tap starts a timer for that activity's scheduled duration instead of opening its detail sheet first.
- The task's selected goal ID and title are carried into the active timer, saved session, and later session history.
- Recurring proposal conflict checks honor excluded dates and include overlapping future one-off commitments.
- The chat widget test now supplies its provider key through the secure-storage test double; it no longer hangs on the platform secure-storage channel.
- Android launch surfaces now use the Bookpaper charcoal background while Flutter initializes.

## Verification

- Focused AI, goal-plan, Home intent, and timer-state suites: **69 passed** serially. Home presentation and persisted-data suites: **24 passed** after updating old UI assumptions to use the current menu and collapsed tools section.
- Targeted analyzer: **No issues found**. `git diff --check`: clean.
- `flutter build apk --debug`: succeeded. A universal release APK was subsequently built as version `0.5.3+8067`; SHA-256: `e8e33dcdc8b0ab99bb98a74e6f4a39c6047320ed1d56d23a0bedc075815e50c7`. It was installed over preview `8066` on the API36 x86_64 AVD. After selecting Fitrah as the default Home app in Android's chooser, the Home key returned to Fitrah and the saved goal/action remained present. Package details and install notes are in [the preview bundle](../../../release_dist/2026-11-16-fitrah-home-screen-time-preview/INSTALL.md).
- Installed on the disposable API36 x86_64 QA AVD. Cold launch reached `MainActivity`; screenshot showed goal, selected action, dial, and upcoming schedule. Tapping **Mulai fokus** opened `Latihan LKS 30 menit` at 29:59. Follow-up screenshot confirmed the compact Home dial now exposes its Timer action. No fatal Flutter or Android error appeared in the checked log tail.
- Screenshots: `.dart_tool/android-qa/2026-11-16-focus-clock-ui/home-after-one-tap.png` and `timer-after-one-tap.png`.

## Still open

- The AI goal-plan flow is covered by provider, approval, atomic-write, and Home/timer integration suites, but it has not been run end-to-end on a phone with a configured real provider.
- The legacy Home widget tests were updated to exercise current interactions: prayer mode and list view from Menu, tools after expanding **Catatan & alat**, and quick capture through the current text-first inbox action. A 320 dp expanded-tools test exposed and verified fixes for horizontal overflow in preset/habit headers and task actions. The compact Home dial had lost its Timer hub entry point; a direct Timer action now opens the existing shared timer hub.
- No physical phone, TalkBack session, browser interaction/reload, web release package, or public deployment was verified. The Android APK is a personal preview signed with the existing local debug-compatible certificate; a public production signing key is not configured.
- E5 follow-up on the API36 x86_64 AVD verified HOME role, physical Home key return, actual installed-app listing, Chrome launch/return, and the opt-in screen-time overlay including tuck/restore and goal return. Overlay placement was corrected after seeing it overlap the prayer header. Emulator permissions were reset to default and the cue turned off afterward; screenshots and exact limits are recorded in [BUILD-ROADMAP.md](BUILD-ROADMAP.md).
- Existing E0–E6 adoption/device/storage/accessibility gates and the later sync, WhatsApp, MCP, and open-source milestones remain open.

## Default Home cold-boot follow-up — 16 November 2026

- Rebooted the disposable API36 AVD after clearing host memory pressure. System UI again showed a “not responding” dialog. Android's Default Home settings displayed Fitrah selected, but Home opened `ResolverActivity` until **Fitrah Launcher → Always** was chosen. That selection launched MainActivity and later Home presses returned there.
- No product-code fix was retained: the repeated System UI ANR and chooser behavior were not isolated to app code. The existing RoleManager-backed status remains unchanged.
- The v8067 preview remains available; the current source was rebuilt as universal release v8068 and installed on the AVD. Goal survived the upgrade and Home opened Fitrah after choosing **Always**. Package, checksum, and install notes: [`v8068 preview bundle`](../../../release_dist/2026-11-17-fitrah-launcher-home-preview-v8068/INSTALL.md). Clean physical-device/OEM reboot behavior still needs verification. Full TalkBack, seven-day personal-use, real-provider, and multi-device gates remain open.
