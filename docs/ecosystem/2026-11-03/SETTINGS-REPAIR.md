# Settings repair inventory

Observed 9 November 2026 at source checkpoint4ee413c. The active app uses FitrahLauncherShell and FocusClockHomeView. Existing settings that only affect old FitrahHomeView do not establish behavior in that active shell. These are repair tasks, not decisions to delete requested capabilities.

| Control | Current evidence | Required result |
| --- | --- | --- |
| App icons / automatic keyboard | Icon switch uses local _showAppIcons; active/legacy rows always build icons. Auto-search can read defaults before hydration. | In-progress plan-real-drawer-settings: durable, commit-aware controls; actual rows and delayed focus follow stored choices. |
| Wallpaper | Preset colors, custom HTTP(S) image, dimming, and blur now render behind the active launcher shell. The Settings `Use device wallpaper` switch still writes unsupported `custom`/`campfire` values and does not read Android's actual wallpaper. | Main backdrop choices are connected; device wallpaper integration and save-failure feedback remain open. |
| Home/prayer widget switches | Widget-mode/prayer visibility preferences are consumed by old home, not current FocusClockHomeView. | Reconcile these settings with current Home design and actual prayer/time context, preserving user control. |
| Interrupts | Copy claims notification filtering. No NotificationListenerService or onNotificationPosted implementation was found; action only opens system listener settings. | Honest system-notification controls first; filtering must have an explicit supported implementation before claiming it works. |
| Focus25/50/90 | Fixed in the 14 Nov session preset slice: Settings now starts `TimerSessionSourceKind.preset` through the shared timer owner, preserving one active session and the existing atomic measured Activity completion/retry path. | Verified by the shared focus widget test and existing Isar persistence test for failed write/retry/idempotency. Physical device completion remains unverified. |
| Gestures | Help says swipe up opens apps and describes old prayer/focus tabs. Current shell is a horizontal PageView with clock0/Home1/apps2. | Explain actual gestures and visible equivalents; preserve accessibility and Android Home behavior. |
| Font | Action displays “Font Montserrat aktif”; theme source uses GoogleFonts.inter for the AppBar and does not prove Montserrat selection. | Real font choice or truthful current-font information, with system text scaling and offline availability. |
| Device Settings | Calls openHomeSettings. | Open actual device settings with honest dispatch feedback. |
| Rate us | Only shows a thank-you snackbar. No store destination in action. | Show a real existing destination only; do not present a pretend review action. |
| Credits/licenses | Only closes the More sheet. | Open real Flutter license information and accurate credits. |
| Version | Hardcoded Version5.17; package source0.5.3+7, preview APK build numbers overridden explicitly. | Read installed package metadata; never copy marketing version into runtime status. |
| Theme palette | Home reads its palette, but setThemePalette returns void and sheets close before persistence result; generic ThemeData currently ignores the palette parameter. | Keep approved bookpaper/palettes and show selected state only after commit; check scope of palette claim against actual consumers. |

Evidence paths: lib/features/launcher/widgets/fitrah_settings_screen.dart, launcher_customization_sheet.dart, focus_clock_home_view.dart, fitrah_home_view.dart; lib/features/launcher/fitrah_launcher_shell.dart; lib/services/sadar_timer_engine.dart; android/app/src/main/AndroidManifest.xml and MainActivity.kt. No physical-device or browser-runtime claim from this inventory.
