import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:fitrah_launcher/features/focusclock/analog_clock_face.dart';
import '../models/launcher_settings.dart';
import '../providers/launcher_settings_provider.dart';
import '../utils/hijri_date.dart';
import 'fitrah_settings_screen.dart';
import 'loop_habit_grid_widget.dart';
import 'task_dump_inbox_widget.dart';

/// Focus Clock Home View (Page 1 - Center)
/// Living circular 24h Analog Clock Face front and center as the soul & branding,
/// borderless editorial aesthetic without rigid boxing, and direct access to settings & apps.
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

    final currentHalf = halfOfNow();
    final activities = ref.watch(activitiesByHalfProvider).valueOrNull ?? const [];
    final tasks = ref.watch(tasksByHalfProvider);

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

          // ── Main Scrollable Content (Borderless & Clean) ──
          SafeArea(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
              children: [
                // ── Top Navigation Bar: Minimal Branding + Settings & Apps ──
                _buildTopBar(context, accentColor),
                const SizedBox(height: 12),

                // ── Hero Section: Focus Clock Living Analog Dial ──
                _buildClockHero(
                  context: context,
                  accentColor: accentColor,
                  settings: settings,
                  timeStr: timeStr,
                  dateStr: dateStr,
                  hijriStr: hijriStr,
                  nextPrayer: nextPrayer,
                  currentHalf: currentHalf,
                  activities: activities,
                  tasks: tasks,
                ),
                const SizedBox(height: 18),

                // Hairline Divider
                Divider(
                  height: 1,
                  thickness: 0.8,
                  color: Colors.white.withOpacity(0.08),
                ),
                const SizedBox(height: 14),

                // ── Section 1: Loop Habit Tracker Grid (Frameless) ──
                const LoopHabitGridWidget(),
                const SizedBox(height: 14),

                // Hairline Divider
                Divider(
                  height: 1,
                  thickness: 0.8,
                  color: Colors.white.withOpacity(0.08),
                ),
                const SizedBox(height: 14),

                // ── Section 2: Task Dump Inbox (Google Tasks Style & Focus Clock) ──
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

  Widget _buildTopBar(BuildContext context, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Branding with live accent indicator
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'FOCUS CLOCK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          // Actions: Apps Drawer & Settings
          Row(
            children: [
              // Apps link
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onOpenAppDrawer();
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        'APPS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.north_east_rounded, size: 12, color: accentColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Settings Cog
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 18),
                color: Colors.white.withOpacity(0.75),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashRadius: 18,
                tooltip: 'Pengaturan Launcher',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FitrahSettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClockHero({
    required BuildContext context,
    required Color accentColor,
    required LauncherSettings settings,
    required String timeStr,
    required String dateStr,
    required String hijriStr,
    required Map<String, dynamic> nextPrayer,
    required AmPmHalf currentHalf,
    required List<dynamic> activities,
    required List<dynamic> tasks,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onOpenFocusClock();
      },
      child: Column(
        children: [
          // ── Analog Clock Face (Soul of the App) ──
          Center(
            child: SizedBox(
              width: 215,
              height: 215,
              child: AnalogClockFace(
                now: _currentTime,
                activities: activities.cast(),
                tasks: tasks.cast(),
                viewHalf: currentHalf,
                clockHandsMode: 1,
                is24hDial: settings.is24h,
                is24hTime: settings.is24h,
                showCurrentTime: false,
                clockFaceTheme: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Digital Time & Next Prayer Pill ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: accentColor.withOpacity(0.3), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      '${nextPrayer['nextName']} in ${nextPrayer['countdown']}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── Date & Hijri Calendar ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dateStr,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.75)),
              ),
              const SizedBox(width: 6),
              Text(
                '•  $hijriStr',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Subtle Timeline Cue ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '24H TIMELINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: accentColor.withOpacity(0.85),
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.arrow_forward_rounded, size: 10, color: accentColor.withOpacity(0.85)),
            ],
          ),
        ],
      ),
    );
  }
}
