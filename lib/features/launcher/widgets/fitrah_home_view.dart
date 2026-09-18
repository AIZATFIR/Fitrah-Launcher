import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/time_math.dart';
import '../../../models/activity.dart';
import '../../../providers/providers.dart';
import '../models/launcher_settings.dart';
import '../providers/launcher_settings_provider.dart';
import '../services/app_launcher_service.dart';
import '../utils/hijri_date.dart';
import 'app_icon_widget.dart';
import 'fitrah_settings_screen.dart';
import 'launcher_customization_sheet.dart';

class FitrahHomeView extends ConsumerStatefulWidget {
  const FitrahHomeView({
    super.key,
    required this.onOpenFocusClock,
    required this.onOpenAppDrawer,
  });

  final VoidCallback onOpenFocusClock;
  final VoidCallback onOpenAppDrawer;

  @override
  ConsumerState<FitrahHomeView> createState() => _FitrahHomeViewState();
}

class _FitrahHomeViewState extends ConsumerState<FitrahHomeView> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Map<String, dynamic> _calculateNextPrayer(LauncherSettings settings) {
    final now = _currentTime;
    final curSec = (now.hour * 60 + now.minute) * 60 + now.second;

    final prayers = [
      {'name': 'Fajr', 'time': settings.prayerSubuh},
      {'name': 'Sunrise', 'time': settings.prayerSyuruq},
      {'name': 'Dhuhr', 'time': settings.prayerDzuhur},
      {'name': 'Asr', 'time': settings.prayerAshar},
      {'name': 'Maghrib', 'time': settings.prayerMaghrib},
      {'name': 'Isha', 'time': settings.prayerIsya},
    ];

    String nextName = 'Fajr';
    int nextSec = 0;
    String currentActiveName = '';

    for (int i = 0; i < prayers.length; i++) {
      final p = prayers[i];
      final parts = (p['time'] as String).split(':');
      final pSec = (int.parse(parts[0]) * 60 + int.parse(parts[1])) * 60;

      if (curSec >= pSec) {
        currentActiveName = p['name'] as String;
      }

      if (pSec > curSec) {
        nextName = p['name'] as String;
        nextSec = pSec;
        break;
      }
    }

    if (nextSec == 0) {
      final parts = settings.prayerSubuh.split(':');
      final fajrSec = (int.parse(parts[0]) * 60 + int.parse(parts[1])) * 60;
      nextSec = 24 * 3600 + fajrSec;
      nextName = 'Fajr';
    }

    final diffSec = (nextSec - curSec).clamp(0, 24 * 3600);
    final hours = (diffSec ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((diffSec % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (diffSec % 60).toString().padLeft(2, '0');
    final countdownStr = '$hours:$minutes:$seconds';

    return {
      'nextName': nextName,
      'countdown': countdownStr,
      'currentActive': currentActiveName,
    };
  }

  void _openSettings() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FitrahSettingsScreen()),
    );
  }

  void _openCustomization() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LauncherCustomizationSheet(),
    );
  }

  void _launchDockPackage(String pkg) {
    HapticFeedback.lightImpact();
    if (pkg.contains('dialer') || pkg.contains('phone')) {
      ref.read(appLauncherServiceProvider).launchDialer();
    } else if (pkg.contains('camera')) {
      ref.read(appLauncherServiceProvider).launchCamera();
    } else {
      ref.read(appLauncherServiceProvider).launchApp(pkg);
    }
  }

  String _getShortSlotLabel(String pkg, int index) {
    if (pkg.contains('dialer') || pkg.contains('phone')) return 'Phone';
    if (pkg.contains('mms') || pkg.contains('message')) return 'Messages';
    if (pkg.contains('browser') || pkg.contains('chrome')) return 'Browser';
    if (pkg.contains('camera')) return 'Camera';
    final parts = pkg.split('.');
    return parts.isNotEmpty ? parts.last : 'App ${index + 1}';
  }

  IconData _getSlotIcon(String pkg, int index) {
    if (pkg.contains('dialer') || pkg.contains('phone')) return Icons.phone_rounded;
    if (pkg.contains('mms') || pkg.contains('message')) return Icons.chat_bubble_rounded;
    if (pkg.contains('browser') || pkg.contains('chrome')) return Icons.language_rounded;
    if (pkg.contains('camera')) return Icons.camera_alt_rounded;
    return Icons.apps_rounded;
  }

  void _showEditPrayersSheet(LauncherSettings settings, LauncherSettingsNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Waktu Sholat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ketuk untuk mengubah jam sholat sesuai lokasi Anda',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _prayerEditTile('Fajr', settings.prayerSubuh, (val) => notifier.setPrayerTime('subuh', val)),
                  _prayerEditTile('Sunrise', settings.prayerSyuruq, (val) => notifier.setPrayerTime('syuruq', val)),
                  _prayerEditTile('Dhuhr', settings.prayerDzuhur, (val) => notifier.setPrayerTime('dzuhur', val)),
                  _prayerEditTile('Asr', settings.prayerAshar, (val) => notifier.setPrayerTime('ashar', val)),
                  _prayerEditTile('Maghrib', settings.prayerMaghrib, (val) => notifier.setPrayerTime('maghrib', val)),
                  _prayerEditTile('Isha', settings.prayerIsya, (val) => notifier.setPrayerTime('isya', val)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _prayerEditTile(String name, String currentTime, ValueChanged<String> onSaved) {
    return InkWell(
      onTap: () async {
        final parts = currentTime.split(':');
        final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );
        if (picked != null) {
          final h = picked.hour.toString().padLeft(2, '0');
          final m = picked.minute.toString().padLeft(2, '0');
          onSaved('$h:$m');
          if (mounted) Navigator.pop(context);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF222226),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            Text(name, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 4),
            Text(currentTime, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(launcherSettingsProvider);
    final notifier = ref.read(launcherSettingsProvider.notifier);
    final nextPrayerInfo = _calculateNextPrayer(settings);
    final activePrayer = nextPrayerInfo['currentActive'] as String;

    final appsAsync = ref.watch(installedAppsFutureProvider);
    final favoritePackages = ref.watch(favoritePackagesProvider);
    final activitiesAsync = ref.watch(activitiesByDateProvider);
    final activities = activitiesAsync.valueOrNull ?? <Activity>[];

    // Identify 2-4 pinned favorite apps to show at bottom-left
    List<InstalledApp> pinnedApps = [];
    appsAsync.whenData((allApps) {
      pinnedApps = allApps.where((app) => favoritePackages.contains(app.packageName)).take(4).toList();
      if (pinnedApps.isEmpty && allApps.isNotEmpty) {
        pinnedApps = allApps.take(2).toList();
      }
    });

    final isAmoled = settings.wallpaperType == 'amoled_black';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: _openCustomization,
        onVerticalDragEnd: (details) {
          final vel = details.primaryVelocity ?? 0;
          if (vel > 280) {
            // Swipe down: expand notification panel
            HapticFeedback.selectionClick();
            ref.read(appLauncherServiceProvider).expandNotificationsPanel();
          } else if (vel < -280) {
            // Swipe up: open app drawer
            HapticFeedback.selectionClick();
            widget.onOpenAppDrawer();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
          // 1. Wallpaper (Campfire default)
          if (!isAmoled)
            Positioned.fill(
              child: Image.asset(
                'assets/fitrah_campfire_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              ),
            ),

          // Dark overlay for readability
          if (!isAmoled)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.35),
              ),
            ),

          // 2. Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Date & Hijri Card with Hamburger Menu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.32), width: 1.2),
                      color: Colors.black.withOpacity(0.4),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                          onPressed: _openSettings,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, d MMMM yyyy').format(_currentTime),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                HijriCalendarHelper.formatHijri(_currentTime),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.7),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.pie_chart_outline_rounded, color: Colors.white70, size: 20),
                          tooltip: 'Focus Clock',
                          onPressed: widget.onOpenFocusClock,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Mode Switcher Header (Waktu Sholat vs Focus Clock Events)
                  _buildModeSwitcher(settings, notifier),

                  const SizedBox(height: 6),

                  // Content Widget based on mode
                  if (settings.widgetDisplayMode == 'focus_clock')
                    _buildFocusClockEventsGrid(activities)
                  else
                    _buildPrayerTimesGrid(settings, notifier, activePrayer, nextPrayerInfo),

                  const SizedBox(height: 12),

                  // Search Pill (Tapping opens App Drawer)
                  Center(
                    child: GestureDetector(
                      onTap: widget.onOpenAppDrawer,
                      child: Container(
                        height: 34,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.search_rounded, color: Colors.black87, size: 18),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Center Calligraphy / Dhikr
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Alhamdulillah',
                          style: GoogleFonts.satisfy(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'for everything',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Pinned Favorite Apps (Bottom Left Text List)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pinnedApps.isNotEmpty
                          ? pinnedApps.map((app) => _buildPinnedAppRow(app)).toList()
                          : [
                              _buildDefaultPinnedItem('Substack'),
                              _buildDefaultPinnedItem('Bayyinah'),
                            ],
                    ),
                  ),

                  // Bottom Dock Bar (4 Quick-Access slots with real icons)
                  _buildDockBar(settings, appsAsync.valueOrNull ?? []),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildModeSwitcher(LauncherSettings settings, LauncherSettingsNotifier notifier) {
    final isFocusClock = settings.widgetDisplayMode == 'focus_clock';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSegmentTab(
                title: '🕌 Sholat',
                isSelected: !isFocusClock,
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.setWidgetDisplayMode('prayer');
                },
              ),
              const SizedBox(width: 4),
              _buildSegmentTab(
                title: '⏱️ Focus Clock',
                isSelected: isFocusClock,
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.setWidgetDisplayMode('focus_clock');
                },
              ),
            ],
          ),
        ),
        const Spacer(),
        if (isFocusClock)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onOpenFocusClock();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new_rounded, size: 13, color: Colors.white70),
                  SizedBox(width: 4),
                  Text(
                    'Buka Clock',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white70, size: 18),
            tooltip: 'Ubah Waktu Sholat',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _showEditPrayersSheet(settings, notifier),
          ),
      ],
    );
  }

  Widget _buildSegmentTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.white.withOpacity(0.4), width: 1) : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.65),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerTimesGrid(
    LauncherSettings settings,
    LauncherSettingsNotifier notifier,
    String activePrayer,
    Map<String, dynamic> nextPrayerInfo,
  ) {
    return GestureDetector(
      onTap: () => _showEditPrayersSheet(settings, notifier),
      child: Column(
        children: [
          Row(
            children: [
              _buildPrayerPill('Fajr', settings.prayerSubuh, isCurrent: activePrayer == 'Fajr'),
              const SizedBox(width: 8),
              _buildPrayerPill('Sunrise', settings.prayerSyuruq, isCurrent: activePrayer == 'Sunrise'),
              const SizedBox(width: 8),
              _buildPrayerPill('Dhuhr', settings.prayerDzuhur, isCurrent: activePrayer == 'Dhuhr'),
              const SizedBox(width: 8),
              _buildPrayerPill('Asr', settings.prayerAshar, isCurrent: activePrayer == 'Asr'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPrayerPill('Maghrib', settings.prayerMaghrib, isCurrent: activePrayer == 'Maghrib'),
              const SizedBox(width: 8),
              _buildPrayerPill('Isha', settings.prayerIsya, isCurrent: activePrayer == 'Isha'),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
                    color: Colors.black.withOpacity(0.4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${nextPrayerInfo['nextName']} in',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextPrayerInfo['countdown'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusClockEventsGrid(List<Activity> activities) {
    if (activities.isEmpty) {
      return GestureDetector(
        onTap: widget.onOpenFocusClock,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.1),
            color: Colors.black.withOpacity(0.4),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Belum Ada Event Focus Clock',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ketuk untuk membuat jadwal blok fokus hari ini',
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
            ],
          ),
        ),
      );
    }

    final currentMinute = _currentTime.hour * 60 + _currentTime.minute;
    final sorted = List<Activity>.from(activities)
      ..sort((a, b) => toUiMinute(a.startMinute, a.ampmHalf).compareTo(toUiMinute(b.startMinute, b.ampmHalf)));

    Activity? activeActivity;
    for (final a in sorted) {
      final s = toUiMinute(a.startMinute, a.ampmHalf);
      final e = toUiMinute(a.endMinute, a.ampmHalf);
      if (s <= currentMinute && currentMinute < e && !a.isCompleted) {
        activeActivity = a;
        break;
      }
    }

    final upcoming = sorted.where((a) {
      final s = toUiMinute(a.startMinute, a.ampmHalf);
      return s > currentMinute && !a.isCompleted;
    }).toList();

    return Column(
      children: [
        // Hero Active or Next Activity status bar
        GestureDetector(
          onTap: widget.onOpenFocusClock,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: activeActivity != null
                    ? const Color(0xFF10B981).withOpacity(0.6)
                    : Colors.white.withOpacity(0.3),
                width: activeActivity != null ? 1.4 : 1.1,
              ),
              color: activeActivity != null
                  ? const Color(0xFF10B981).withOpacity(0.18)
                  : Colors.black.withOpacity(0.45),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: activeActivity != null ? const Color(0xFF10B981) : Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeActivity != null
                        ? 'Aktif: ${activeActivity.title}'
                        : (upcoming.isNotEmpty
                            ? 'Berikutnya: ${upcoming.first.title}'
                            : 'Semua event hari ini telah selesai ✨'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (activeActivity != null) ...[
                  Builder(builder: (ctx) {
                    final remaining = toUiMinute(activeActivity!.endMinute, activeActivity.ampmHalf) - currentMinute;
                    return Text(
                      '${remaining}m tersisa',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF34D399),
                      ),
                    );
                  }),
                ] else if (upcoming.isNotEmpty) ...[
                  Builder(builder: (ctx) {
                    final diff = toUiMinute(upcoming.first.startMinute, upcoming.first.ampmHalf) - currentMinute;
                    return Text(
                      'dlm ${diff}m',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Grid of 3-4 upcoming or current event pills
        Row(
          children: [
            for (int i = 0; i < (sorted.length > 3 ? 3 : sorted.length); i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _buildEventPill(sorted[i], currentMinute),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEventPill(Activity a, int currentMinute) {
    final start = toUiMinute(a.startMinute, a.ampmHalf);
    final end = toUiMinute(a.endMinute, a.ampmHalf);
    final isCurrent = start <= currentMinute && currentMinute < end && !a.isCompleted;
    final timeStr = formatMinuteOfHalf(a.startMinute, a.ampmHalf, is24h: true);

    return GestureDetector(
      onTap: widget.onOpenFocusClock,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent
                ? Colors.white
                : (a.isCompleted ? Colors.white24 : Colors.white.withOpacity(0.28)),
            width: isCurrent ? 1.4 : 1.0,
          ),
          color: isCurrent
              ? Colors.white.withOpacity(0.22)
              : (a.isCompleted ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (a.iconKey != null && a.iconKey!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Text(a.iconKey!, style: const TextStyle(fontSize: 11)),
                  ),
                Flexible(
                  child: Text(
                    a.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: a.isCompleted ? Colors.white38 : Colors.white.withOpacity(0.9),
                      decoration: a.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: isCurrent ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerPill(String name, String time, {bool isCurrent = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent ? Colors.white : Colors.white.withOpacity(0.28),
            width: isCurrent ? 1.5 : 1.1,
          ),
          color: isCurrent ? Colors.white.withOpacity(0.22) : Colors.black.withOpacity(0.4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: Colors.white.withOpacity(isCurrent ? 1.0 : 0.75),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockBar(LauncherSettings settings, List<InstalledApp> allApps) {
    final packages = settings.dockPackages.isNotEmpty
        ? settings.dockPackages
        : const ['com.android.dialer', 'com.android.mms', 'com.android.browser', 'com.android.camera'];

    return Container(
      margin: const EdgeInsets.only(bottom: 4, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.42),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.14), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: packages.asMap().entries.map((entry) {
          final index = entry.key;
          final pkg = entry.value;
          final app = allApps.where((a) => a.packageName == pkg).firstOrNull;
          final label = app?.appName ?? _getShortSlotLabel(pkg, index);

          return Tooltip(
            message: label,
            child: InkWell(
              onTap: () => _launchDockPackage(pkg),
              onLongPress: () {
                HapticFeedback.mediumImpact();
                _openCustomization();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Center(
                  child: AppIconWidget(
                    packageName: pkg,
                    appName: label,
                    size: 28,
                    fallbackIcon: _getSlotIcon(pkg, index),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPinnedAppRow(InstalledApp app) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(appLauncherServiceProvider).launchApp(app.packageName);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _openCustomization();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconWidget(
              packageName: app.packageName,
              appName: app.appName,
              size: 26,
            ),
            const SizedBox(width: 10),
            Text(
              app.appName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultPinnedItem(String title) {
    return GestureDetector(
      onTap: widget.onOpenAppDrawer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
