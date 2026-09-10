import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/habit.dart';
import '../../../models/habit_entry.dart';
import '../../../providers/sadar_providers.dart';
import 'sadar_timer_view.dart';

class HorizontalTimelineGrid extends ConsumerStatefulWidget {
  const HorizontalTimelineGrid({
    super.key,
    required this.habits,
    required this.onEditHabit,
  });

  final List<Habit> habits;
  final ValueChanged<Habit> onEditHabit;

  @override
  ConsumerState<HorizontalTimelineGrid> createState() => _HorizontalTimelineGridState();
}

class _HorizontalTimelineGridState extends ConsumerState<HorizontalTimelineGrid> {
  late DateTime _currentMonday;
  late DateTime _selectedDate;
  int? _activeHabitId;
  bool _isNoteExpanded = false;
  late TextEditingController _noteCtrl;

  static const List<String> _dayNames = ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Monday is 1, Sunday is 7 in Dart
    _currentMonday = today.subtract(Duration(days: today.weekday - 1));
    _selectedDate = today;
    if (widget.habits.isNotEmpty) {
      _activeHabitId = widget.habits.first.id;
    }
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  List<DateTime> get _weekDays => List.generate(
        7,
        (i) => _currentMonday.add(Duration(days: i)),
      );

  bool get _isCurrentWeek {
    final now = DateTime.now();
    final thisMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return _currentMonday.year == thisMonday.year &&
        _currentMonday.month == thisMonday.month &&
        _currentMonday.day == thisMonday.day;
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  static const List<String> _fullDayNames = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  String _formatWeekRange() {
    final start = _currentMonday;
    final end = _currentMonday.add(const Duration(days: 6));
    final startM = _monthNames[start.month - 1];
    final endM = _monthNames[end.month - 1];
    if (start.month == end.month) {
      return '${start.day} - ${end.day} $endM ${end.year}';
    }
    return '${start.day} $startM - ${end.day} $endM ${end.year}';
  }

  String _formatSelectedDateLabel() {
    final dayName = _fullDayNames[_selectedDate.weekday - 1];
    final monthName = _monthNames[_selectedDate.month - 1];
    return '$dayName, ${_selectedDate.day} $monthName';
  }

  void _previousWeek() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonday = _currentMonday.subtract(const Duration(days: 7));
      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      _isNoteExpanded = false;
    });
  }

  void _nextWeek() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonday = _currentMonday.add(const Duration(days: 7));
      _selectedDate = _selectedDate.add(const Duration(days: 7));
      _isNoteExpanded = false;
    });
  }

  void _jumpToToday() {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _currentMonday = today.subtract(Duration(days: today.weekday - 1));
      _selectedDate = today;
      _isNoteExpanded = false;
    });
  }

  Future<void> _updateEntryStatus({
    required Habit habit,
    required HabitStatus status,
    required Map<String, HabitEntry> entriesMap,
  }) async {
    HapticFeedback.mediumImpact();
    final dateStr = _formatDate(_selectedDate);
    final key = '${habit.id}-$dateStr';
    final currentEntry = entriesMap[key];

    // Toggle back to unmarked if tapping same status
    final targetStatus = (currentEntry?.status == status) ? HabitStatus.unmarked : status;

    await ref.read(sadarRepoProvider).recordEntryStatus(
      habitId: habit.id,
      dateString: dateStr,
      status: targetStatus,
      valueCompleted: targetStatus == HabitStatus.yes ? habit.target : 0,
      note: currentEntry?.note,
    );

    ref.invalidate(dailyFulfillmentProvider);
    ref.invalidate(whatIRepeatProvider);
    ref.invalidate(awarenessStatsProvider);
  }

  Future<void> _saveNote({
    required Habit habit,
    required Map<String, HabitEntry> entriesMap,
  }) async {
    HapticFeedback.lightImpact();
    final dateStr = _formatDate(_selectedDate);
    final key = '${habit.id}-$dateStr';
    final currentEntry = entriesMap[key];
    final text = _noteCtrl.text.trim();

    await ref.read(sadarRepoProvider).recordEntryStatus(
      habitId: habit.id,
      dateString: dateStr,
      status: currentEntry?.status ?? HabitStatus.unmarked,
      note: text.isEmpty ? null : text,
    );

    setState(() => _isNoteExpanded = false);
    ref.invalidate(dailyFulfillmentProvider);
  }

  void _startTimerForHabit(Habit habit) {
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

  @override
  Widget build(BuildContext context) {
    final startStr = _formatDate(_currentMonday);
    final endStr = _formatDate(_currentMonday.add(const Duration(days: 6)));
    final rangeQuery = DateRangeQuery(start: startStr, end: endStr);

    final entriesAsync = ref.watch(habitEntriesStreamProvider(rangeQuery));
    final entriesMap = <String, HabitEntry>{};

    entriesAsync.whenData((entries) {
      for (final e in entries) {
        entriesMap['${e.habitId}-${e.dateString}'] = e;
      }
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekDays = _weekDays;

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Week Navigation Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: AppPalette.text, size: 26),
                  tooltip: 'Minggu Kemarin',
                  onPressed: _previousWeek,
                ),
                InkWell(
                  onTap: _isCurrentWeek ? null : _jumpToToday,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isCurrentWeek ? 'Minggu Ini' : _formatWeekRange(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.text,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (_isCurrentWeek) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${_formatWeekRange()})',
                            style: const TextStyle(fontSize: 12, color: AppPalette.textDim),
                          ),
                        ] else ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppPalette.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppPalette.accent.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'Kembali ke Hari Ini',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppPalette.accent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: AppPalette.text, size: 26),
                  tooltip: 'Minggu Depan',
                  onPressed: _nextWeek,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppPalette.stroke),

          // ── 7-Day Column Header Row (Senin - Minggu) ───────────────────
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 8),
            child: Row(
              children: List.generate(7, (i) {
                final d = weekDays[i];
                final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
                final isSelected = d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;
                final dayName = _dayNames[i];

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedDate = d;
                        _isNoteExpanded = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppPalette.stroke.withValues(alpha: 0.45) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected ? Border.all(color: AppPalette.accent.withValues(alpha: 0.6), width: 1.2) : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                              color: isToday ? AppPalette.accent : (isSelected ? AppPalette.text : AppPalette.textDim),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: isToday
                                ? BoxDecoration(
                                    color: AppPalette.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  )
                                : null,
                            child: Text(
                              '${d.day}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                                color: isToday ? Colors.black : (isSelected ? Colors.white : AppPalette.textDim),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const Divider(height: 1, color: AppPalette.stroke),

          // ── Habits List ─────────────────────────────────────────────────
          if (widget.habits.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Belum ada kebiasaan. Tambah kebiasaan pertama Anda.', style: TextStyle(color: AppPalette.textDim)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.habits.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppPalette.stroke),
              itemBuilder: (context, idx) {
                final habit = widget.habits[idx];
                final isHabitActive = _activeHabitId == habit.id;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Habit Title & Details Row
                    Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10, top: 12, bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            habit.iconKey.isNotEmpty ? habit.iconKey : '🎯',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              habit.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.text,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (habit.target > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppPalette.bg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppPalette.stroke),
                              ),
                              child: Text(
                                '${habit.target}${_formatUnit(habit.unit)}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppPalette.textDim),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          IconButton(
                            icon: const Icon(Icons.more_horiz_rounded, size: 18, color: AppPalette.textDim),
                            tooltip: 'Opsi Kebiasaan',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: () => widget.onEditHabit(habit),
                          ),
                        ],
                      ),
                    ),

                    // The 7-Day Bar (Matching the 7 Columns)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
                      child: Row(
                        children: List.generate(7, (i) {
                          final d = weekDays[i];
                          final dateStr = _formatDate(d);
                          final key = '${habit.id}-$dateStr';
                          final entry = entriesMap[key];
                          final status = entry?.status ?? HabitStatus.unmarked;
                          final hasNote = entry?.note != null && entry!.note!.trim().isNotEmpty;
                          final isSelectedCell = isHabitActive &&
                              d.year == _selectedDate.year &&
                              d.month == _selectedDate.month &&
                              d.day == _selectedDate.day;
                          final isTodayCell = d.year == today.year && d.month == today.month && d.day == today.day;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _activeHabitId = habit.id;
                                  _selectedDate = d;
                                  _isNoteExpanded = false;
                                  _noteCtrl.text = entry?.note ?? '';
                                });
                              },
                              child: Container(
                                height: 38,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: _getCellColor(status, isTodayCell),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelectedCell
                                        ? Colors.white
                                        : (isTodayCell && status == HabitStatus.unmarked
                                            ? AppPalette.accent.withValues(alpha: 0.5)
                                            : AppPalette.stroke.withValues(alpha: 0.4)),
                                    width: isSelectedCell ? 2.0 : 1.0,
                                  ),
                                  boxShadow: isSelectedCell
                                      ? [
                                          BoxShadow(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _buildCellIcon(status),
                                    if (hasNote)
                                      const Positioned(
                                        top: 0,
                                        right: 0,
                                        child: CustomPaint(
                                          size: Size(10, 10),
                                          painter: DogEarPainter(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // ── Inline Action Panel (DIRECTLY UNDERNEATH HABIT ROW) ──
                    if (isHabitActive)
                      _buildInlineActionPanel(
                        habit: habit,
                        entriesMap: entriesMap,
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ── Inline Action Panel (Way of Life Buttons) ─────────────────────────────
  Widget _buildInlineActionPanel({
    required Habit habit,
    required Map<String, HabitEntry> entriesMap,
  }) {
    final dateStr = _formatDate(_selectedDate);
    final key = '${habit.id}-$dateStr';
    final entry = entriesMap[key];
    final currentStatus = entry?.status ?? HabitStatus.unmarked;

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Target Day Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.arrow_drop_up_rounded, color: AppPalette.accent, size: 20),
                  Text(
                    _formatSelectedDateLabel(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.accent,
                    ),
                  ),
                ],
              ),
              if (habit.timerEnabled)
                InkWell(
                  onTap: () => _startTimerForHabit(habit),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppPalette.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppPalette.accent.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: AppPalette.accent),
                        SizedBox(width: 4),
                        Text(
                          'Mulai Timer',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppPalette.accent),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Way of Life 4 Buttons Directly Below
          Row(
            children: [
              // 1. Note Button (Yellow)
              Expanded(
                child: _buildActionCard(
                  icon: Icons.description_rounded,
                  label: 'Catatan',
                  color: const Color(0xFFEAB308), // Yellow
                  isActive: entry?.note != null && entry!.note!.trim().isNotEmpty,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isNoteExpanded = !_isNoteExpanded;
                      _noteCtrl.text = entry?.note ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 2. Yes Button (Green)
              Expanded(
                child: _buildActionCard(
                  icon: Icons.check_rounded,
                  label: 'Ya',
                  color: const Color(0xFF22C55E), // Green
                  isActive: currentStatus == HabitStatus.yes,
                  onTap: () => _updateEntryStatus(
                    habit: habit,
                    status: HabitStatus.yes,
                    entriesMap: entriesMap,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 3. No Button (Red)
              Expanded(
                child: _buildActionCard(
                  icon: Icons.close_rounded,
                  label: 'Tidak',
                  color: const Color(0xFFEF4444), // Red
                  isActive: currentStatus == HabitStatus.no,
                  onTap: () => _updateEntryStatus(
                    habit: habit,
                    status: HabitStatus.no,
                    entriesMap: entriesMap,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 4. Skip Button (Blue)
              Expanded(
                child: _buildActionCard(
                  icon: Icons.redo_rounded,
                  label: 'Lewati',
                  color: const Color(0xFF0EA5E9), // Blue
                  isActive: currentStatus == HabitStatus.skip,
                  onTap: () => _updateEntryStatus(
                    habit: habit,
                    status: HabitStatus.skip,
                    entriesMap: entriesMap,
                  ),
                ),
              ),
            ],
          ),

          // Inline Note Input
          if (_isNoteExpanded) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppPalette.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPalette.stroke),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteCtrl,
                      autofocus: true,
                      style: const TextStyle(fontSize: 13, color: AppPalette.text),
                      decoration: const InputDecoration(
                        hintText: 'Tulis catatan harian singkat...',
                        hintStyle: TextStyle(fontSize: 13, color: AppPalette.textDim),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => _saveNote(habit: habit, entriesMap: entriesMap),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_rounded, size: 18, color: AppPalette.accent),
                    tooltip: 'Simpan Catatan',
                    onPressed: () => _saveNote(habit: habit, entriesMap: entriesMap),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.22) : AppPalette.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : AppPalette.stroke,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? color : color.withValues(alpha: 0.8), size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? color : AppPalette.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCellColor(HabitStatus status, bool isToday) {
    switch (status) {
      case HabitStatus.yes:
        return const Color(0xFF22C55E); // Green
      case HabitStatus.no:
        return const Color(0xFFEF4444); // Red
      case HabitStatus.skip:
        return const Color(0xFF0EA5E9); // Blue
      case HabitStatus.unmarked:
        return isToday ? const Color(0xFF1E293B) : const Color(0xFF0F172A);
    }
  }

  Widget _buildCellIcon(HabitStatus status) {
    switch (status) {
      case HabitStatus.yes:
        return const Icon(Icons.check_rounded, color: Colors.white, size: 20);
      case HabitStatus.no:
        return const Icon(Icons.close_rounded, color: Colors.white, size: 18);
      case HabitStatus.skip:
        return const Icon(Icons.redo_rounded, color: Colors.white, size: 16);
      case HabitStatus.unmarked:
        return const SizedBox.shrink();
    }
  }

  String _formatUnit(HabitUnit unit) {
    switch (unit) {
      case HabitUnit.min:
        return 'm';
      case HabitUnit.count:
        return 'x';
      case HabitUnit.binary:
        return '';
    }
  }
}

/// Custom painter to draw the folded corner "dog-ear" in the top right
class DogEarPainter extends CustomPainter {
  const DogEarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const foldSize = 9.0;
    final path = Path()
      ..moveTo(size.width - foldSize, 0)
      ..lineTo(size.width, foldSize)
      ..lineTo(size.width, 0)
      ..close();

    final paint = Paint()
      ..color = const Color(0xFFFDE047) // Soft Golden fold
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    final borderPath = Path()
      ..moveTo(size.width - foldSize, 0)
      ..lineTo(size.width - foldSize, foldSize)
      ..lineTo(size.width, foldSize);

    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawPath(borderPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
