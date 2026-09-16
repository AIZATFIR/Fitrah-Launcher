import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/launcher_settings.dart';
import '../providers/launcher_settings_provider.dart';
import '../services/app_launcher_service.dart';
import '../utils/hijri_date.dart';
import 'fitrah_settings_screen.dart';

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
      body: Stack(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Date & Hijri Card with Hamburger Menu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.32), width: 1.2),
                      color: Colors.black.withOpacity(0.4),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                          onPressed: _openSettings,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, d MMMM yyyy').format(_currentTime),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                HijriCalendarHelper.formatHijri(_currentTime),
                                style: TextStyle(
                                  fontSize: 12,
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

                  const SizedBox(height: 12),

                  // Prayer Times Grid (Row 1: 4 pills, Row 2: 3 pills)
                  GestureDetector(
                    onTap: () => _showEditPrayersSheet(settings, notifier),
                    child: Column(
                      children: [
                        // Row 1: Fajr, Sunrise, Dhuhr, Asr
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

                        // Row 2: Maghrib, Isha, Next Prayer Countdown
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
                  ),

                  const SizedBox(height: 28),

                  // Search Pill (Tapping opens App Drawer)
                  Center(
                    child: GestureDetector(
                      onTap: widget.onOpenAppDrawer,
                      child: Container(
                        height: 38,
                        width: 130,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.search_rounded, color: Colors.black87, size: 20),
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
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'for everything',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Pinned Favorite Apps (Bottom Left Text List)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 12),
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

                  // Bottom Dock Bar (Phone on Left, Camera on Right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 26),
                        tooltip: 'Telepon',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(appLauncherServiceProvider).launchDialer();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 26),
                        tooltip: 'Kamera',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(appLauncherServiceProvider).launchCamera();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildPinnedAppRow(InstalledApp app) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(appLauncherServiceProvider).launchApp(app.packageName);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          app.appName,
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
