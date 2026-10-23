import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/launcher_settings.dart';
import '../providers/launcher_settings_provider.dart';
import '../utils/hijri_date.dart';
import 'loop_habit_grid_widget.dart';
import 'task_dump_inbox_widget.dart';

/// Focus Clock Home View (Page 1 - Center)
/// Sharp 2px square bento aesthetic, 27% chrome / 73% data area ratio,
/// custom wallpaper with adaptive contrast scrim, and instant theme switcher.
class FocusClockHomeView extends ConsumerStatefulWidget {
  const FocusClockHomeView({
    super.key,
    required this.onOpenFocusClock,
    required this.onOpenAppDrawer,
  });

  final VoidCallback onOpenFocusClock;
  final VoidCallback onOpenAppDrawer;

  @override
  ConsumerState<FocusClockHomeView> createState() => _FocusClockHomeViewState();
}

class _FocusClockHomeViewState extends ConsumerState<FocusClockHomeView> {
  late Timer _clockTimer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Map<String, dynamic> _calculateNextPrayer(LauncherSettings settings) {
    final now = _currentTime;
    final curSec = (now.hour * 60 + now.minute) * 60 + now.second;

    final prayers = [
      {'name': 'Subuh', 'time': settings.prayerSubuh},
      {'name': 'Syuruq', 'time': settings.prayerSyuruq},
      {'name': 'Dzuhur', 'time': settings.prayerDzuhur},
      {'name': 'Ashar', 'time': settings.prayerAshar},
      {'name': 'Maghrib', 'time': settings.prayerMaghrib},
      {'name': 'Isya', 'time': settings.prayerIsya},
    ];

    String nextName = 'Subuh';
    int nextSec = 0;

    for (int i = 0; i < prayers.length; i++) {
      final p = prayers[i];
      final parts = (p['time'] as String).split(':');
      final pSec = (int.parse(parts[0]) * 60 + int.parse(parts[1])) * 60;

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
      nextName = 'Subuh';
    }

    final diffSec = (nextSec - curSec).clamp(0, 24 * 3600);
    final hours = (diffSec ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((diffSec % 3600) ~/ 60).toString().padLeft(2, '0');

    return {
      'nextName': nextName,
      'countdown': '$hours:$minutes',
    };
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(launcherSettingsProvider);
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    final timeStr = settings.is24h
        ? DateFormat('HH:mm').format(_currentTime)
        : DateFormat('hh:mm').format(_currentTime);
    final dateStr = DateFormat('EEEE, d MMM yyyy').format(_currentTime);
    final hijriStr = HijriCalendarHelper.formatHijri(_currentTime);
    final nextPrayer = _calculateNextPrayer(settings);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Optional Device Wallpaper with Adaptive Scrim ──
          if (settings.wallpaperType != 'amoled_black')
            Positioned.fill(
              child: Image.asset(
                'assets/fitrah_campfire_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: theme.scaffoldBackgroundColor),
              ),
            ),

          // Adaptive Dimming Scrim
          if (settings.wallpaperType != 'amoled_black')
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(settings.wallpaperDimming.clamp(0.4, 0.95)),
              ),
            ),

          // ── Main Scrollable Content ──
          SafeArea(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
              children: [
                // ── 1. Minimalist Status Header (27% Chrome Ratio) ──
                _buildMinimalHeader(
                  context,
                  settings,
                  timeStr,
                  dateStr,
                  hijriStr,
                  nextPrayer,
                  accentColor,
                ),
                const SizedBox(height: 8),

                // ── 2. Quick Navigation Bar (Focus Clock 24h & Apps) ──
                _buildQuickNavBar(context, accentColor),
                const SizedBox(height: 8),

                // ── 3. Loop Habit Tracker Grid (7-Day Bento) ──
                const LoopHabitGridWidget(),
                const SizedBox(height: 6),

                // ── 4. Task Dump Inbox (Google Tasks Style & Focus Clock) ──
                TaskDumpInboxWidget(
                  onTaskScheduled: widget.onOpenFocusClock,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalHeader(
    BuildContext context,
    LauncherSettings settings,
    String timeStr,
    String dateStr,
    String hijriStr,
    Map<String, dynamic> nextPrayer,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.92),
        borderRadius: BorderRadius.circular(2), // 2px square bento
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Clock & Prayer Countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: accentColor.withOpacity(0.3), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      '${nextPrayer['nextName']} ${nextPrayer['countdown']}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Date & Hijri
          Row(
            children: [
              Text(
                dateStr,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
              const SizedBox(width: 6),
              Text(
                '•  $hijriStr',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Theme Switcher & Wallpaper Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Theme selector pills (Matcha Green, Sky Blue, Ocean Blue)
              Row(
                children: [
                  _buildThemePill('Matcha', 'fino_green', const Color(0xFF70C050), settings.themePalette),
                  const SizedBox(width: 6),
                  _buildThemePill('Sky', 'sky_blue', const Color(0xFF38BDF8), settings.themePalette),
                  const SizedBox(width: 6),
                  _buildThemePill('Ocean', 'ocean_blue', const Color(0xFF0284C7), settings.themePalette),
                ],
              ),

              // Wallpaper toggle
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  final nextType = settings.wallpaperType == 'amoled_black' ? 'custom_image' : 'amoled_black';
                  ref.read(launcherSettingsProvider.notifier).setWallpaperType(nextType);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        settings.wallpaperType != 'amoled_black' ? Icons.wallpaper_rounded : Icons.nights_stay_rounded,
                        size: 13,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        settings.wallpaperType != 'amoled_black' ? 'Wallpaper ON' : 'AMOLED',
                        style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
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

  Widget _buildThemePill(String label, String paletteKey, Color color, String currentPalette) {
    final isSelected = currentPalette == paletteKey;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(launcherSettingsProvider.notifier).setThemePalette(paletteKey);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 7, height: 7, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? color : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNavBar(BuildContext context, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Left: Go to 24h Analog Focus Clock
          Expanded(
            child: InkWell(
              onTap: widget.onOpenFocusClock,
              borderRadius: BorderRadius.circular(2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.watch_later_outlined, size: 14, color: accentColor),
                    const SizedBox(width: 6),
                    Text(
                      '← CLOCK (24H)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Right: Go to App Drawer
          Expanded(
            child: InkWell(
              onTap: widget.onOpenAppDrawer,
              borderRadius: BorderRadius.circular(2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'APPS DRAWER →',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.apps_rounded, size: 14, color: accentColor),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
