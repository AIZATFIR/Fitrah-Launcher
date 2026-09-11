import 'dart:async';
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
import '../services/app_launcher_service.dart';

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
    final activeTimer = ref.watch(timerEngineProvider);
    final activitiesAsync = ref.watch(activitiesByDateProvider);
    final habitsAsync = ref.watch(habitsStreamProvider);
    final rangeQuery = DateRangeQuery(start: _todayStr, end: _todayStr);
    final entriesAsync = ref.watch(habitEntriesStreamProvider(rangeQuery));
    final fulfillmentAsync = ref.watch(dailyFulfillmentProvider(_todayStr));

    final timeStr = DateFormat('HH:mm').format(_currentTime);
    final dateStr = _formatDateIndonesian(_currentTime);

    final entriesMap = <int, HabitEntry>{};
    entriesAsync.whenData((entries) {
      for (final e in entries) {
        entriesMap[e.habitId] = e;
      }
    });

    return Scaffold(
      backgroundColor: AppPalette.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              children: [
                Expanded(
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
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w200,
                                letterSpacing: -1.5,
                                color: AppPalette.text,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.pie_chart_outline_rounded, size: 22, color: AppPalette.accent),
                              tooltip: 'Focus Clock (Geser Kiri)',
                              onPressed: widget.onOpenFocusClock,
                            ),
                            IconButton(
                              icon: const Icon(Icons.grid_view_rounded, size: 22, color: AppPalette.textDim),
                              tooltip: 'Aplikasi (Geser Kanan)',
                              onPressed: widget.onOpenAppDrawer,
                            ),
                          ],
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: AppPalette.textDim,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 2. HERO: Ongoing Main Event Card (Event Sedang Berlangsung)
                        _buildMainEventHero(activeTimer),

                        const SizedBox(height: 28),

                        // 3. Section: Kotak-Kotak Event Hari Ini (Schedule Timeline)
                        Row(
                          children: [
                            const Text(
                              'AGENDA HARI INI',
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
                              icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppPalette.textDim),
                              label: const Text(
                                'Lihat Jam',
                                style: TextStyle(fontSize: 11, color: AppPalette.textDim, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        activitiesAsync.when(
                          data: (activities) {
                            if (activities.isEmpty) {
                              return Container(
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
                              );
                            }

                            return Column(
                              children: activities.map((act) => _buildActivityBox(act)).toList(),
                            );
                          },
                          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                          error: (e, _) => Text('Error: $e', style: const TextStyle(color: Color(0xFFEF4444))),
                        ),

                        const SizedBox(height: 28),

                        // 4. Section: Sadar Habits & Intentions (Alat Fitrah)
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

                // 6. Minimalist Bottom Dock (Phone, Message, Browser, Camera)
                _buildMinimalistDock(),
              ],
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

  Widget _buildActivityBox(Activity act) {
    final startFormatted = formatMinuteOfHalf(act.startMinute, act.ampmHalf, is24h: true);
    final endFormatted = formatMinuteOfHalf(act.endMinute, act.ampmHalf, is24h: true);
    final durationMin = act.endMinute >= act.startMinute
        ? act.endMinute - act.startMinute
        : (act.endMinute - act.startMinute + 720);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: Color(act.colorValue),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppPalette.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$startFormatted – $endFormatted ($durationMin m)',
                  style: const TextStyle(fontSize: 11, color: AppPalette.textDim),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow_outlined, size: 18, color: AppPalette.accent),
            tooltip: 'Mulai Timer',
            onPressed: () {
              final habit = Habit()
                ..name = act.title
                ..target = durationMin > 0 ? durationMin : 25
                ..unit = HabitUnit.min;
              _startQuickTimer(habit);
            },
          ),
        ],
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

  Widget _buildMinimalistDock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppPalette.card,
        border: Border(top: BorderSide(color: AppPalette.stroke)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDockIcon(Icons.phone_outlined, 'Telepon', 'com.android.dialer'),
          _buildDockIcon(Icons.chat_bubble_outline_rounded, 'Pesan', 'com.android.mms'),
          _buildDockIcon(Icons.language_rounded, 'Browser', 'com.android.browser'),
          _buildDockIcon(Icons.camera_alt_outlined, 'Kamera', 'com.android.camera'),
        ],
      ),
    );
  }

  Widget _buildDockIcon(IconData icon, String label, String packageName) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(appLauncherServiceProvider).launchApp(packageName);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppPalette.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.stroke),
        ),
        child: Icon(icon, size: 20, color: AppPalette.accent),
      ),
    );
  }
}
