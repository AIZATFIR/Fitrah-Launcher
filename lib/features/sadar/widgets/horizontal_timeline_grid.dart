import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/habit.dart';
import '../../../models/habit_entry.dart';
import '../../../providers/sadar_providers.dart';
import 'quick_action_sheet.dart';

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
  late final ScrollController _scrollController;
  late final List<DateTime> _days;
  static const double _cellWidth = 36.0;
  static const double _cellHeight = 36.0;
  static const double _cellSpacing = 3.0;
  static const double _titleColumnWidth = 148.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Generate 28 days window: 21 days past, today, and 6 days future
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _days = List.generate(28, (i) => today.subtract(Duration(days: 21 - i)));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) return;
    // Today is at index 21
    const todayIndex = 21;
    final targetOffset = (todayIndex * (_cellWidth + _cellSpacing)) - 80;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  void _openQuickAction(Habit habit, DateTime date, HabitEntry? existingEntry) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickActionSheet(
        habit: habit,
        date: date,
        existingEntry: existingEntry,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startStr = _formatDate(_days.first);
    final endStr = _formatDate(_days.last);
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

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 1. DATE HEADER
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: AppPalette.bg,
              border: Border(bottom: BorderSide(color: AppPalette.stroke)),
            ),
            child: Row(
              children: [
                // Fixed left spacer
                Container(
                  width: _titleColumnWidth,
                  padding: const EdgeInsets.only(left: 16),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'KEBIASAAN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: AppPalette.textDim,
                    ),
                  ),
                ),

                // Horizontally scrolling days
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Row(
                      children: _days.map((date) {
                        final isToday = date.year == today.year &&
                            date.month == today.month &&
                            date.day == today.day;
                        final dayLetter = DateFormat('E').format(date).substring(0, 1);
                        final dayNumber = date.day.toString();

                        return Container(
                          width: _cellWidth,
                          margin: const EdgeInsets.only(right: _cellSpacing),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isToday ? AppPalette.accent.withValues(alpha: 0.18) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isToday ? AppPalette.accent : Colors.transparent,
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dayLetter,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isToday ? AppPalette.accent : AppPalette.textDim,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dayNumber,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                                  color: isToday ? AppPalette.accent : AppPalette.text,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. HABIT ROWS
          if (widget.habits.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              alignment: Alignment.center,
              child: const Text(
                'Belum ada kebiasaan. Tambah kebiasaan bermaknamu hari ini.',
                style: TextStyle(fontSize: 13, color: AppPalette.textDim),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.habits.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                color: AppPalette.stroke,
                indent: 16,
              ),
              itemBuilder: (context, index) {
                final habit = widget.habits[index];
                final habitColor = Color(habit.colorValue);

                return InkWell(
                  onLongPress: () => widget.onEditHabit(habit),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        // Left: Habit Info Column
                        InkWell(
                          onTap: () => widget.onEditHabit(habit),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: _titleColumnWidth,
                            padding: const EdgeInsets.only(left: 14, right: 6),
                            child: Row(
                              children: [
                                Text(
                                  habit.iconKey.isNotEmpty ? habit.iconKey : '🎯',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        habit.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppPalette.text,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: habitColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${habit.target} ${_formatUnit(habit.unit)}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppPalette.textDim,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Right: Synchronized Horizontally Scrolling Status Cells
                        Expanded(
                          child: SingleChildScrollView(
                            controller: index == 0 ? null : null, // Uses synced width
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: Row(
                              children: _days.map((date) {
                                final dateStr = _formatDate(date);
                                final entry = entriesMap['${habit.id}-$dateStr'];
                                final status = entry?.status ?? HabitStatus.unmarked;
                                final hasNote = entry?.note?.isNotEmpty == true;

                                return GestureDetector(
                                  onTap: () => _openQuickAction(habit, date, entry),
                                  child: Container(
                                    width: _cellWidth,
                                    height: _cellHeight,
                                    margin: const EdgeInsets.only(right: _cellSpacing),
                                    decoration: BoxDecoration(
                                      color: _getCellColor(status),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: status == HabitStatus.unmarked
                                            ? AppPalette.stroke.withValues(alpha: 0.6)
                                            : Colors.transparent,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: CustomPaint(
                                      painter: hasNote ? const DogEarPainter() : null,
                                      child: Center(
                                        child: _getCellIcon(status),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Color _getCellColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.yes:
        return const Color(0xFF22C55E); // Rich Green
      case HabitStatus.no:
        return const Color(0xFFEF4444); // Clear Red
      case HabitStatus.skip:
        return const Color(0xFF64748B); // Slate
      case HabitStatus.unmarked:
        return AppPalette.bg.withValues(alpha: 0.5);
    }
  }

  Widget? _getCellIcon(HabitStatus status) {
    switch (status) {
      case HabitStatus.yes:
        return const Icon(Icons.check_rounded, size: 16, color: Colors.white);
      case HabitStatus.no:
        return const Icon(Icons.close_rounded, size: 16, color: Colors.white);
      case HabitStatus.skip:
        return const Icon(Icons.redo_rounded, size: 13, color: Colors.white70);
      case HabitStatus.unmarked:
        return null;
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
