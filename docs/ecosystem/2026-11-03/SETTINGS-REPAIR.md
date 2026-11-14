# Settings repair inventory

Observed 9 November 2026 at source checkpoint4ee413c. The active app uses FitrahLauncherShell and FocusClockHomeView. Existing settings that only affect old FitrahHomeView do not establish behavior in that active shell. These are repair tasks, not decisions to delete requested capabilities.

| Control | Current evidence | Required result |
| --- | --- | --- |
| App icons / automatic keyboard | Icon switch uses local _showAppIcons; active/legacy rows always build icons. Auto-search can read defaults before hydration. | In-progress plan-real-drawer-settings: durable, commit-aware controls; actual rows and delayed focus follow stored choices. |
| Wallpaper | Preset colors, custom HTTP(S) image, dimming, and blur now render behind the active launcher shell. The Settings `Use device wallpaper` switch still writes unsupported `custom`/`campfire` values and does not read Android's actual wallpaper. | Main backdrop choices are connected; device wallpaper integration and save-failure feedback remain open. |
| Home/prayer widget switches | `FocusClockHomeView` now derives the top row from saved `widgetDisplayMode` and `showPrayerTimes`; its toggle persists the choice and is labeled/toggled for accessibility. Disabled prayer times explain how to restore the row. Other `showHeroEvent`, `showAgendaWidget`, and `showHabitsWidget` controls still need active-Home wiring. | Prayer/Focus Events row now follows durable preferences; other Home widget controls remain open. |
| Interrupts | Settings now says notification filtering is not implemented and labels the action as opening Android notification access settings. | Honest copy shipped; filtering implementation remains open. |
| Focus25/50/90 | Fixed in the 14 Nov session preset slice: Settings now starts `TimerSessionSourceKind.preset` through the shared timer owner, preserving one active session and the existing atomic measured Activity completion/retry path. | Verified by the shared focus widget test and existing Isar persistence test for failed write/retry/idempotency. Physical device completion remains unverified. |
| Gestures | Help now documents left from Home to Apps, right from Home to Focus Clock, the agenda/prayer toggle, and hold-to-exit focus mode. | Updated to match active PageView; device gesture variations remain. |
| Font | Font action now reports Inter as current and says selection is not available. | Truthful status shipped; font picker remains open. |
| Device Settings | Calls openHomeSettings. | Open actual device settings with honest dispatch feedback. |
| Rate us | No Play Store destination is configured; action now explains that and points to existing email support. | Honest fallback shipped; rating deep link remains open. |
| Credits/licenses | More now opens Flutter's real license page. | License viewer shipped; curated first-party credits remain open. |
| Version | Display previously said Version5.17; source version is 0.5.3 and preview APK build number is separately overridden. Display now says 0.5.3. | Marketing mismatch corrected; installed build number display remains open. |
| Theme palette | Home reads its palette. Palette choice now waits for commit and keeps the sheet open with an error on failure. | Save feedback shipped; some generic ThemeData consumers may not follow palette yet. |

Evidence paths: lib/features/launcher/widgets/fitrah_settings_screen.dart, launcher_customization_sheet.dart, focus_clock_home_view.dart, fitrah_home_view.dart; lib/features/launcher/fitrah_launcher_shell.dart; lib/services/sadar_timer_engine.dart; android/app/src/main/AndroidManifest.xml and MainActivity.kt. No physical-device or browser-runtime claim from this inventory.
