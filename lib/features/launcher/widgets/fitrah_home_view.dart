import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../core/time_math.dart';
import '../../../models/activity.dart';
import '../../../models/habit.dart';
import '../../../models/habit_entry.dart';
import '../../../providers/providers.dart';
import '../../../providers/sadar_providers.dart';
import '../../../services/sadar_timer_engine.dart';
import '../../sadar/widgets/reflection_sheet.dart';
import '../../sadar/widgets/sadar_timer_view.dart';
import '../models/prayer_schedule.dart';
import '../providers/launcher_settings_provider.dart';
import '../services/app_launcher_service.dart';
import 'launcher_customization_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

enum UnifiedEventType {
  focusClock,
  prayer,
  habit,
}

class UnifiedTimelineEvent {
  final String title;
  final String timeLabel;
  final int startMinuteOfDay;
  final int endMinuteOfDay;
  final Color color;
  final UnifiedEventType type;
  final String subtitle;
  final Activity? activity;
  final Habit? habit;
  final bool isDone;

  const UnifiedTimelineEvent({
    required this.title,
    required this.timeLabel,
    required this.startMinuteOfDay,
    required this.endMinuteOfDay,
    required this.color,
    required this.type,
    required this.subtitle,
    this.activity,
    this.habit,
    this.isDone = false,
  });
}

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
  late Timer _clockTimer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String get _todayStr {
    final y = _currentTime.year.toString().padLeft(4, '0');
    final m = _currentTime.month.toString().padLeft(2, '0');
    final d = _currentTime.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _startQuickTimer(Habit habit) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => SadarTimerView(
          habit: habit,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  void _openDailyReflection() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReflectionSheet(
        dateString: _todayStr,
        onSaved: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _openLauncherSettings() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LauncherCustomizationSheet(),
    );
  }

  String _formatDateIndonesian(DateTime dt) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(launcherSettingsProvider);
    final activeTimer = ref.watch(timerEngineProvider);
    final activitiesAsync = ref.watch(activitiesByDateProvider);
    final habitsAsync = ref.watch(habitsStreamProvider);
    final rangeQuery = DateRangeQuery(start: _todayStr, end: _todayStr);
    final entriesAsync = ref.watch(habitEntriesStreamProvider(rangeQuery));
    final fulfillmentAsync = ref.watch(dailyFulfillmentProvider(_todayStr));

    final timePattern = settings.is24h
        ? (settings.showSeconds ? 'HH:mm:ss' : 'HH:mm')
        : (settings.showSeconds ? 'hh:mm:ss a' : 'hh:mm a');
    final timeStr = DateFormat(timePattern).format(_currentTime);
    final dateStr = _formatDateIndonesian(_currentTime);

    final entriesMap = <int, HabitEntry>{};
    entriesAsync.whenData((entries) {
      for (final e in entries) {
        entriesMap[e.habitId] = e;
      }
    });

    final currentMinute = _currentTime.hour * 60 + _currentTime.minute;
    final List<UnifiedTimelineEvent> timelineEvents = [];

    // 1. Focus Clock activities for today
    activitiesAsync.whenData((activities) {
      for (final act in activities) {
        final startMinOfHalf = act.startMinute;
        final startOfDay = act.ampmHalf == AmPmHalf.pm ? (startMinOfHalf + 720) : startMinOfHalf;
        final endMinOfHalf = act.endMinute;
        final endOfDay = act.ampmHalf == AmPmHalf.pm ? (endMinOfHalf + 720) : endMinOfHalf;
        final startFormatted = formatMinuteOfHalf(act.startMinute, act.ampmHalf, is24h: settings.is24h);
        final endFormatted = formatMinuteOfHalf(act.endMinute, act.ampmHalf, is24h: settings.is24h);
        final durationMin = act.endMinute >= act.startMinute
            ? act.endMinute - act.startMinute
            : (act.endMinute - act.startMinute + 720);

        timelineEvents.add(
          UnifiedTimelineEvent(
            title: act.title,
            timeLabel: '$startFormatted – $endFormatted',
            startMinuteOfDay: startOfDay,
            endMinuteOfDay: endOfDay >= startOfDay ? endOfDay : (endOfDay + 1440),
            color: Color(act.colorValue),
            type: UnifiedEventType.focusClock,
            subtitle: 'Focus Clock (${durationMin}m)',
            activity: act,
          ),
        );
      }
    });

    // 2. Prayer times (if settings.showPrayerTimes)
    if (settings.showPrayerTimes) {
      final prayers = [
        {'name': 'Subuh', 'time': settings.prayerSubuh},
        {'name': 'Syuruq', 'time': settings.prayerSyuruq},
        {'name': 'Dzuhur', 'time': settings.prayerDzuhur},
        {'name': 'Ashar', 'time': settings.prayerAshar},
        {'name': 'Maghrib', 'time': settings.prayerMaghrib},
        {'name': 'Isya', 'time': settings.prayerIsya},
      ];

      for (final p in prayers) {
        final name = p['name'] as String;
        final timeStr = p['time'] as String;
        final minOfDay = PrayerItem.parseMinute(timeStr);

        timelineEvents.add(
          UnifiedTimelineEvent(
            title: name,
            timeLabel: timeStr,
            startMinuteOfDay: minOfDay,
            endMinuteOfDay: minOfDay + 20,
            color: const Color(0xFF10B981),
            type: UnifiedEventType.prayer,
            subtitle: 'Waktu Sholat',
          ),
        );
      }
    }

    timelineEvents.sort((a, b) => a.startMinuteOfDay.compareTo(b.startMinuteOfDay));

    Color bgColor = const Color(0xFF000000); // Default AMOLED pure black
    if (settings.wallpaperType == 'midnight_slate') bgColor = const Color(0xFF0B111E);
    if (settings.wallpaperType == 'forest_night') bgColor = const Color(0xFF0A150E);
    if (settings.wallpaperType == 'deep_obsidian') bgColor = const Color(0xFF101014);
    if (settings.wallpaperType == 'warm_charcoal') bgColor = const Color(0xFF161412);

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: _openLauncherSettings,
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Minimalist Top Header (Clock & Date)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: settings.showSeconds ? 36 : 44,
                            fontWeight: FontWeight.w200,
                            letterSpacing: -1.5,
                            color: AppPalette.text,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.tune_rounded, size: 20, color: AppPalette.accent),
                          tooltip: 'Pengaturan Launcher & Wallpaper',
                          onPressed: _openLauncherSettings,
                        ),
                        IconButton(
                          icon: const Icon(Icons.pie_chart_outline_rounded, size: 20, color: AppPalette.accent),
                          tooltip: 'Focus Clock (Geser Kiri)',
                          onPressed: widget.onOpenFocusClock,
                        ),
                        IconButton(
                          icon: const Icon(Icons.grid_view_rounded, size: 20, color: AppPalette.textDim),
                          tooltip: 'Aplikasi (Geser Kanan)',
                          onPressed: widget.onOpenAppDrawer,
                        ),
                      ],
                    ),
                    if (settings.showDate)
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.textDim,
                        ),
                      ),

                        const SizedBox(height: 24),

                    // 2. HERO: Ongoing Main Event Card (Event Sedang Berlangsung)
                    if (settings.showHeroEvent) ...[
                      _buildMainEventHero(activeTimer),
                      const SizedBox(height: 28),
                    ],

                    // 3. Section: Kotak-Kotak Garis Waktu Hari Ini (Focus Clock + Waktu Sholat)
                    if (settings.showAgendaWidget) ...[
                      Row(
                        children: [
                          const Text(
                            'JADWAL & GARIS WAKTU HARI INI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: AppPalette.accent,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: widget.onOpenFocusClock,
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 14, color: AppPalette.accent),
                            label: const Text(
                              'Tambah Blok',
                              style: TextStyle(fontSize: 11, color: AppPalette.accent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (timelineEvents.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            color: AppPalette.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppPalette.stroke),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 18, color: AppPalette.textDim),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Belum ada blok waktu di Focus Clock hari ini.',
                                  style: TextStyle(fontSize: 12, color: AppPalette.textDim),
                                ),
                              ),
                              TextButton(
                                onPressed: widget.onOpenFocusClock,
                                child: const Text('Buat Blok', style: TextStyle(fontSize: 12, color: AppPalette.accent)),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: timelineEvents
                              .map((evt) => _buildTimelineCard(evt, currentMinute))
                              .toList(),
                        ),
                      const SizedBox(height: 28),
                    ],

                    // 4. Section: Sadar Habits & Intentions (Alat Fitrah)
                    if (settings.showHabitsWidget) ...[
                      Row(
                        children: [
                          const Text(
                            'KEBIASAAN & FITRAH',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: AppPalette.textDim,
                            ),
                          ),
                          const Spacer(),
                          fulfillmentAsync.when(
                            data: (summary) => Text(
                              '${summary.completedCount}/${summary.totalCount} Selesai',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppPalette.accent),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      habitsAsync.when(
                        data: (habits) {
                          if (habits.isEmpty) return const SizedBox.shrink();
                          return Column(
                            children: habits.map((habit) {
                              final entry = entriesMap[habit.id];
                              final isDone = entry?.status == HabitStatus.yes;
                              return _buildHabitRow(habit, isDone);
                            }).toList(),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 20),
                    ],

                        // 5. Daily Reflection Quick Card
                        InkWell(
                          onTap: _openDailyReflection,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppPalette.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppPalette.stroke),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.favorite_outline_rounded, size: 18, color: AppPalette.accent),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Refleksi Hari Ini',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppPalette.text),
                                      ),
                                      Text(
                                        'Apakah hari ini kau jalani dengan cara yang kau hargai?',
                                        style: TextStyle(fontSize: 11, color: AppPalette.textDim),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, size: 18, color: AppPalette.textDim),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
          ),
        ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.94),
            border: const Border(top: BorderSide(color: AppPalette.stroke, width: 1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _buildMinimalistDock(settings.dockPackages),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainEventHero(TimerState activeTimer) {
    if (activeTimer.isActive) {
      final remSec = activeTimer.remainingSeconds;
      final m = remSec ~/ 60;
      final s = remSec % 60;
      final remStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppPalette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppPalette.accent.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppPalette.accent.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppPalette.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SEDANG BERLANGSUNG',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: AppPalette.accent,
                  ),
                ),
                const Spacer(),
                Text(
                  activeTimer.isPaused ? 'JEDA' : 'FOKUS AKTIF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: activeTimer.isPaused ? AppPalette.textDim : AppPalette.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              activeTimer.habitName.isNotEmpty ? activeTimer.habitName : 'Sesi Fokus',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppPalette.text,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$remStr tersisa',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppPalette.textDim,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: activeTimer.progress,
                minHeight: 4,
                backgroundColor: AppPalette.stroke,
                valueColor: const AlwaysStoppedAnimation(AppPalette.accent),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    side: const BorderSide(color: AppPalette.stroke),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(activeTimer.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 16),
                  label: Text(activeTimer.isPaused ? 'Lanjut' : 'Jeda', style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    if (activeTimer.isPaused) {
                      ref.read(timerEngineProvider.notifier).resume();
                    } else {
                      ref.read(timerEngineProvider.notifier).pause();
                    }
                  },
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(timerEngineProvider.notifier).finishEarly();
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    // When no timer is running: calm Idle State Card
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.spa_outlined, size: 16, color: AppPalette.accent),
              SizedBox(width: 8),
              Text(
                'WAKTU LUANG & TENANG',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: AppPalette.textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Pikiran tenang, siap bertindak.',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppPalette.text,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mulai sesi fokus 25 menit untuk tugas terpentingmu.',
            style: TextStyle(fontSize: 12, color: AppPalette.textDim),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQuickPresetButton('15m', 15),
              const SizedBox(width: 8),
              _buildQuickPresetButton('25m', 25),
              const SizedBox(width: 8),
              _buildQuickPresetButton('45m', 45),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPresetButton(String label, int minutes) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          side: const BorderSide(color: AppPalette.stroke),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {
          HapticFeedback.selectionClick();
          final tempHabit = Habit()
            ..name = 'Fokus $label'
            ..target = minutes
            ..unit = HabitUnit.min;
          ref.read(timerEngineProvider.notifier).start(tempHabit);
        },
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppPalette.text),
        ),
      ),
    );
  }

  Widget _buildTimelineCard(UnifiedTimelineEvent event, int currentMinute) {
    final isCurrent = currentMinute >= event.startMinuteOfDay &&
        currentMinute < event.endMinuteOfDay;
    final isPast = currentMinute >= event.endMinuteOfDay;
    final isPrayer = event.type == UnifiedEventType.prayer;

    return Opacity(
      opacity: isPast ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppPalette.card
              : (isPrayer
                  ? const Color(0xFF10B981).withValues(alpha: 0.08)
                  : AppPalette.card),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent
                ? AppPalette.accent
                : (isPrayer
                    ? const Color(0xFF10B981).withValues(alpha: 0.35)
                    : AppPalette.stroke),
            width: isCurrent ? 1.5 : 1.0,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppPalette.accent.withValues(alpha: 0.18),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Left: Time badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isPrayer
                    ? const Color(0xFF10B981).withValues(alpha: 0.18)
                    : AppPalette.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPrayer
                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                      : AppPalette.stroke,
                ),
              ),
              child: Text(
                event.timeLabel,
                style: TextStyle(
                  fontSize: isPrayer ? 12 : 11,
                  fontWeight: FontWeight.bold,
                  color: isPrayer ? const Color(0xFF34D399) : AppPalette.accent,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Middle: Color bar & Event details
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isPast ? AppPalette.textDim : AppPalette.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppPalette.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AKTIF',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppPalette.accent),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isPrayer ? const Color(0xFF10B981) : AppPalette.textDim,
                      fontWeight: isPrayer ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // Right: Action button
            if (isPrayer)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.brightness_3_outlined,
                  size: 16,
                  color: Color(0xFF34D399),
                ),
              )
            else if (event.type == UnifiedEventType.focusClock && event.activity != null)
              IconButton(
                icon: const Icon(Icons.play_arrow_outlined, size: 20, color: AppPalette.accent),
                tooltip: 'Mulai Timer',
                onPressed: () {
                  final act = event.activity!;
                  final durationMin = act.endMinute >= act.startMinute
                      ? act.endMinute - act.startMinute
                      : (act.endMinute - act.startMinute + 720);
                  final habit = Habit()
                    ..name = act.title
                    ..target = durationMin > 0 ? durationMin : 25
                    ..unit = HabitUnit.min;
                  _startQuickTimer(habit);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitRow(Habit habit, bool isDone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFF22C55E).withValues(alpha: 0.08) : AppPalette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? const Color(0xFF22C55E).withValues(alpha: 0.3) : AppPalette.stroke,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () async {
              HapticFeedback.mediumImpact();
              final newStatus = isDone ? HabitStatus.unmarked : HabitStatus.yes;
              await ref.read(sadarRepoProvider).recordEntryStatus(
                habitId: habit.id,
                dateString: _todayStr,
                status: newStatus,
                valueCompleted: newStatus == HabitStatus.yes ? habit.target : 0,
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFF22C55E) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDone ? const Color(0xFF22C55E) : AppPalette.stroke,
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${habit.name}${habit.unit == HabitUnit.min ? ' (${habit.target}m)' : ''}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isDone ? FontWeight.w500 : FontWeight.w600,
                color: isDone ? AppPalette.textDim : AppPalette.text,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (habit.timerEnabled && !isDone)
            IconButton(
              icon: const Icon(Icons.timer_outlined, size: 16, color: AppPalette.textDim),
              tooltip: 'Fokus',
              onPressed: () => _startQuickTimer(habit),
            ),
        ],
      ),
    );
  }

  Widget _buildMinimalistDock(List<String> dockPackages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        final pkg = index < dockPackages.length
            ? dockPackages[index]
            : 'com.android.browser';
        return _buildDockIcon(pkg, index);
      }),
    );
  }

  Widget _buildDockIcon(String packageName, int slotIndex) {
    final iconData = _resolveDockIcon(packageName, slotIndex);
    final label = _resolveDockLabel(packageName, slotIndex);

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => _launchDockApp(packageName),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppPalette.card.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppPalette.stroke),
          ),
          child: Icon(iconData, size: 20, color: AppPalette.accent),
        ),
      ),
    );
  }

  IconData _resolveDockIcon(String pkg, int index) {
    if (pkg.contains('dialer') || pkg.contains('phone')) return Icons.phone_outlined;
    if (pkg.contains('mms') || pkg.contains('message')) return Icons.chat_bubble_outline_rounded;
    if (pkg.contains('browser') || pkg.contains('chrome')) return Icons.language_rounded;
    if (pkg.contains('camera')) return Icons.camera_alt_outlined;
    return Icons.apps_rounded;
  }

  String _resolveDockLabel(String pkg, int index) {
    if (pkg.contains('dialer') || pkg.contains('phone')) return 'Telepon';
    if (pkg.contains('mms') || pkg.contains('message')) return 'Pesan';
    if (pkg.contains('browser') || pkg.contains('chrome')) return 'Browser';
    if (pkg.contains('camera')) return 'Kamera';
    final parts = pkg.split('.');
    return parts.isNotEmpty ? parts.last : 'Slot ${index + 1}';
  }

  Future<void> _launchDockApp(String packageName) async {
    HapticFeedback.lightImpact();
    if (!kIsWeb && Theme.of(context).platform == TargetPlatform.android) {
      await ref.read(appLauncherServiceProvider).launchApp(packageName);
      return;
    }

    // Cross-platform fallbacks for Web/Desktop:
    try {
      if (packageName.contains('dialer') || packageName.contains('phone')) {
        await launchUrl(Uri.parse('tel:'));
      } else if (packageName.contains('mms') || packageName.contains('message')) {
        await launchUrl(Uri.parse('mailto:'));
      } else if (packageName.contains('browser') || packageName.contains('chrome')) {
        await launchUrl(Uri.parse('https://www.google.com'), mode: LaunchMode.externalApplication);
      } else {
        await ref.read(appLauncherServiceProvider).launchApp(packageName);
      }
    } catch (_) {}
  }
}
