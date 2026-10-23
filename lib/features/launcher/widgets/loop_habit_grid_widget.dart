import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/habit.dart';
import '../../../models/habit_entry.dart';
import '../../../providers/sadar_providers.dart';

/// Diagonal Stripes Painter for Loop-style Skipped Habit Days
class DiagonalStripesPainter extends CustomPainter {
  final Color color;
  const DiagonalStripesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const step = 6.0;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DiagonalStripesPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Loop Habit Tracker Inspired 7-Day Grid Widget
/// Pixel-faithful to Reference 1 with interactive day cells, full CRUD (Add/Edit/Delete),
/// and inline caret-pointed tactile [Note][Yes][No][Skip] action row.
class LoopHabitGridWidget extends ConsumerStatefulWidget {
  const LoopHabitGridWidget({super.key});

  @override
  ConsumerState<LoopHabitGridWidget> createState() => _LoopHabitGridWidgetState();
}

class _LoopHabitGridWidgetState extends ConsumerState<LoopHabitGridWidget> {
  int? _expandedHabitId;
  int _selectedDayIndex = 0; // 0..6 (Mon..Sun)
  late DateTime _referenceDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _referenceDate = DateTime(now.year, now.month, now.day);
    // Find weekday index (Mon=0 .. Sun=6)
    _selectedDayIndex = (_referenceDate.weekday - 1).clamp(0, 6);
  }

  // Get 7 days for the current displayed week (Monday - Sunday)
  List<DateTime> _getCurrentWeekDays() {
    final monday = _referenceDate.subtract(Duration(days: _referenceDate.weekday - 1));
    return List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  void _previousWeek() {
    HapticFeedback.selectionClick();
    setState(() {
      _referenceDate = _referenceDate.subtract(const Duration(days: 7));
      _expandedHabitId = null;
    });
  }

  void _nextWeek() {
    HapticFeedback.selectionClick();
    setState(() {
      _referenceDate = _referenceDate.add(const Duration(days: 7));
      _expandedHabitId = null;
    });
  }

  void _goToToday() {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    setState(() {
      _referenceDate = DateTime(now.year, now.month, now.day);
      _selectedDayIndex = (_referenceDate.weekday - 1).clamp(0, 6);
      _expandedHabitId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsStreamProvider);
    final weekDays = _getCurrentWeekDays();
    final startDateStr = _formatDate(weekDays.first);
    final endDateStr = _formatDate(weekDays.last);

    final entriesAsync = ref.watch(
      habitEntriesStreamProvider(DateRangeQuery(start: startDateStr, end: endDateStr)),
    );

    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Loop Style Date Navigator & Controls ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                // Section Title with Matcha accent indicator
                Container(
                  width: 3.5,
                  height: 14,
                  color: accentColor,
                  margin: const EdgeInsets.only(right: 8),
                ),
                Text(
                  'DAILY HABITS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const Spacer(),

                // Week Range / Date Display
                Text(
                  '${DateFormat('d MMM').format(weekDays.first)} - ${DateFormat('d MMM yyyy').format(weekDays.last)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 4),

                // Arrow Previous
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  color: Colors.white70,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  splashRadius: 16,
                  tooltip: 'Minggu Sebelumnya',
                  onPressed: _previousWeek,
                ),

                // Arrow Next
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  color: Colors.white70,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  splashRadius: 16,
                  tooltip: 'Minggu Selanjutnya',
                  onPressed: _nextWeek,
                ),

                // Today Calendar jump
                IconButton(
                  icon: const Icon(Icons.today_rounded, size: 18),
                  color: accentColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  splashRadius: 16,
                  tooltip: 'Kembali ke Hari Ini',
                  onPressed: _goToToday,
                ),

                // Add Habit (+) Button
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  color: Colors.white,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  splashRadius: 16,
                  tooltip: 'Tambah Habit Baru',
                  onPressed: () => _showAddHabitDialog(context),
                ),
              ],
            ),
          ),

          // ── Weekday Headers (Mon Tue Wed Thu Fri Sat Sun) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Kegiatan / Habit',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white38,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...weekDays.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final day = entry.value;
                  final isToday = DateFormat('yyyy-MM-dd').format(day) ==
                      DateFormat('yyyy-MM-dd').format(DateTime.now());
                  final isSelected = idx == _selectedDayIndex;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedDayIndex = idx);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('E').format(day).substring(0, 1),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                              color: isSelected
                                  ? accentColor
                                  : (isToday ? Colors.white : Colors.white38),
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (isSelected)
                            Container(width: 4, height: 4, color: accentColor)
                          else if (isToday)
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: Colors.white38,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF222622)),

          // ── Habits List with Interactive Day Cells ──
          habitsAsync.when(
            data: (habits) {
              if (habits.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 28, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada habit harian.',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Buat Habit Pertama',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          onPressed: () => _showAddHabitDialog(context),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return entriesAsync.when(
                data: (entries) {
                  final entryMap = <int, Map<String, HabitEntry>>{};
                  for (final e in entries) {
                    entryMap.putIfAbsent(e.habitId, () => {})[e.dateString] = e;
                  }

                  return Column(
                    children: habits.map((habit) {
                      final isExpanded = _expandedHabitId == habit.id;
                      final habitEntries = entryMap[habit.id] ?? {};
                      final selectedDate = weekDays[_selectedDayIndex];
                      final selectedDateStr = _formatDate(selectedDate);
                      final currentEntry = habitEntries[selectedDateStr];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Main Habit Row ──
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                // Title & Emoji + Edit Tap
                                Expanded(
                                  flex: 3,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _showEditHabitDialog(context, habit),
                                    onLongPress: () => _showEditHabitDialog(context, habit),
                                    child: Row(
                                      children: [
                                        if (habit.iconKey.isNotEmpty) ...[
                                          Text(
                                            habit.iconKey,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Expanded(
                                          child: Text(
                                            habit.name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.edit_rounded,
                                            size: 11, color: Colors.white.withOpacity(0.2)),
                                        const SizedBox(width: 6),
                                      ],
                                    ),
                                  ),
                                ),

                                // 7 Square Bento Day Cells (Independently Clickable!)
                                ...weekDays.asMap().entries.map((dayEntry) {
                                  final dayIdx = dayEntry.key;
                                  final day = dayEntry.value;
                                  final dStr = _formatDate(day);
                                  final entry = habitEntries[dStr];
                                  final status = entry?.status ?? HabitStatus.unmarked;
                                  final isTargetCell = isExpanded && _selectedDayIndex == dayIdx;
                                  final hasNote = entry?.note?.isNotEmpty ?? false;

                                  return Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          if (_expandedHabitId == habit.id &&
                                              _selectedDayIndex == dayIdx) {
                                            _expandedHabitId = null;
                                          } else {
                                            _expandedHabitId = habit.id;
                                            _selectedDayIndex = dayIdx;
                                          }
                                        });
                                      },
                                      child: Container(
                                        height: 24,
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        decoration: BoxDecoration(
                                          color: _getBlockColor(status, accentColor, habit),
                                          borderRadius: BorderRadius.circular(2), // 2px bento rule
                                          border: isTargetCell
                                              ? Border.all(color: Colors.white, width: 1.5)
                                              : Border.all(
                                                  color: Colors.white.withOpacity(0.12),
                                                  width: 0.8,
                                                ),
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Skip diagonal stripes painter
                                            if (status == HabitStatus.skip)
                                              Positioned.fill(
                                                child: CustomPaint(
                                                  painter: DiagonalStripesPainter(
                                                    color: Colors.white.withOpacity(0.4),
                                                  ),
                                                ),
                                              ),

                                            // Status Icon
                                            if (_buildBlockIcon(status) != null)
                                              _buildBlockIcon(status)!,

                                            // Note indicator badge (small dot in top-right)
                                            if (hasNote)
                                              Positioned(
                                                top: 2,
                                                right: 2,
                                                child: Container(
                                                  width: 3.5,
                                                  height: 3.5,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.amberAccent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),

                          // ── Caret Indicator & Tactile Action Popover [Note][Yes][No][Skip] ──
                          if (isExpanded) ...[
                            // Upward pointing triangle caret aligned to the selected day
                            Container(
                              padding: const EdgeInsets.only(left: 12, right: 12),
                              child: Row(
                                children: [
                                  const Expanded(flex: 3, child: SizedBox.shrink()),
                                  ...List.generate(7, (i) {
                                    return Expanded(
                                      child: Center(
                                        child: i == _selectedDayIndex
                                            ? CustomPaint(
                                                size: const Size(10, 6),
                                                painter: _TriangleCaretPainter(
                                                  color: const Color(0xFF1E2820),
                                                ),
                                              )
                                            : const SizedBox(height: 6),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),

                            // Floating Tactile Popover Row
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2820),
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Selected Date & Habit title label
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('EEEE, d MMMM').format(selectedDate),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: accentColor,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => setState(() => _expandedHabitId = null),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white38),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // 4 Square Action Buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // 1. Note Button
                                      _buildActionButton(
                                        icon: Icons.edit_note_rounded,
                                        label: 'Note',
                                        color: Colors.white70,
                                        isActive: (currentEntry?.note?.isNotEmpty ?? false),
                                        onTap: () => _showNoteDialog(
                                          context,
                                          habit,
                                          selectedDateStr,
                                          currentEntry?.note,
                                        ),
                                      ),

                                      // 2. Yes Button
                                      _buildActionButton(
                                        icon: Icons.check_circle_rounded,
                                        label: 'Yes',
                                        color: accentColor,
                                        isActive: currentEntry?.status == HabitStatus.yes,
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          ref.read(sadarRepoProvider).recordEntryStatus(
                                                habitId: habit.id,
                                                dateString: selectedDateStr,
                                                status: currentEntry?.status == HabitStatus.yes
                                                    ? HabitStatus.unmarked
                                                    : HabitStatus.yes,
                                              );
                                        },
                                      ),

                                      // 3. No Button
                                      _buildActionButton(
                                        icon: Icons.cancel_rounded,
                                        label: 'No',
                                        color: const Color(0xFFEF4444),
                                        isActive: currentEntry?.status == HabitStatus.no,
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          ref.read(sadarRepoProvider).recordEntryStatus(
                                                habitId: habit.id,
                                                dateString: selectedDateStr,
                                                status: currentEntry?.status == HabitStatus.no
                                                    ? HabitStatus.unmarked
                                                    : HabitStatus.no,
                                              );
                                        },
                                      ),

                                      // 4. Skip Button
                                      _buildActionButton(
                                        icon: Icons.label_off_rounded,
                                        label: 'Skip',
                                        color: const Color(0xFF94A3B8),
                                        isActive: currentEntry?.status == HabitStatus.skip,
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          ref.read(sadarRepoProvider).recordEntryStatus(
                                                habitId: habit.id,
                                                dateString: selectedDateStr,
                                                status: currentEntry?.status == HabitStatus.skip
                                                    ? HabitStatus.unmarked
                                                    : HabitStatus.skip,
                                              );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const Divider(height: 1, color: Color(0xFF1E221E)),
                        ],
                      );
                    }).toList(),
                  );
                },
                loading: () => const SizedBox(height: 60),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Error entries: $e', style: const TextStyle(fontSize: 10, color: Colors.red)),
                ),
              );
            },
            loading: () => const SizedBox(height: 80),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Error habits: $e', style: const TextStyle(fontSize: 10, color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBlockColor(HabitStatus status, Color accentColor, Habit habit) {
    switch (status) {
      case HabitStatus.yes:
        return habit.colorValue != 0 ? Color(habit.colorValue) : accentColor;
      case HabitStatus.no:
        return const Color(0xFF451A1A);
      case HabitStatus.skip:
        return const Color(0xFF2C322E);
      case HabitStatus.unmarked:
        return Colors.white.withOpacity(0.04);
    }
  }

  Widget? _buildBlockIcon(HabitStatus status) {
    switch (status) {
      case HabitStatus.yes:
        return const Icon(Icons.check, size: 14, color: Colors.black);
      case HabitStatus.no:
        return const Icon(Icons.close, size: 13, color: Color(0xFFEF4444));
      case HabitStatus.skip:
      case HabitStatus.unmarked:
        return null;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.25) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(2), // 2px square rule
          border: Border.all(
            color: isActive ? color : Colors.white.withOpacity(0.12),
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isActive ? color : Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? color : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Note Dialog ──
  void _showNoteDialog(BuildContext context, Habit habit, String dateString, String? existingNote) {
    final noteCtrl = TextEditingController(text: existingNote ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171F19),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: Color(0xFF28362B)),
        ),
        title: Text(
          'Catatan: ${habit.name}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tanggal: $dateString',
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              maxLines: 4,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Catatan',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF0F1511),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2),
                  borderSide: const BorderSide(color: Color(0xFF28362B)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF70C050),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            onPressed: () {
              ref.read(sadarRepoProvider).recordEntryStatus(
                    habitId: habit.id,
                    dateString: dateString,
                    status: habit.isArchived ? HabitStatus.unmarked : HabitStatus.yes,
                    note: noteCtrl.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ── Full Habit CRUD: Add Habit Dialog ──
  void _showAddHabitDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    int target = 30;
    HabitUnit unit = HabitUnit.min;
    int selectedColor = 0xFF70C050;

    final colorOptions = [
      0xFF70C050, // Matcha
      0xFF38BDF8, // Sky Blue
      0xFF0284C7, // Ocean Blue
      0xFFF97316, // Orange
      0xFF8B5CF6, // Purple
      0xFFEC4899, // Pink
      0xFFEAB308, // Gold
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151E17),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: const BorderSide(color: Color(0xFF28362B)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TAMBAH HABIT BARU',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),



                // Name Input
                const Text('Nama Habit:',
                    style: TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nama kebiasaan',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0F1511),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: const BorderSide(color: Color(0xFF28362B)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Color Swatches
                const Text('Warna Card:',
                    style: TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: colorOptions.map((c) {
                    final isSel = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = c),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Color(c),
                          borderRadius: BorderRadius.circular(2),
                          border: isSel ? Border.all(color: Colors.white, width: 2) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF70C050),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    ),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;

                      final newHabit = Habit()
                        ..name = name
                        ..iconKey = ''
                        ..target = target
                        ..unit = unit
                        ..colorValue = selectedColor
                        ..timerEnabled = true
                        ..createdAt = DateTime.now();

                      ref.read(sadarRepoProvider).upsertHabit(newHabit);
                      Navigator.pop(ctx);
                    },
                    child: const Text('SIMPAN HABIT',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Full Habit CRUD: Edit & Delete Habit Dialog ──
  void _showEditHabitDialog(BuildContext context, Habit habit) {
    final nameCtrl = TextEditingController(text: habit.name);
    int selectedColor = habit.colorValue != 0 ? habit.colorValue : 0xFF70C050;
    int target = habit.target > 0 ? habit.target : 30;

    final colorOptions = [
      0xFF70C050, // Matcha
      0xFF38BDF8, // Sky Blue
      0xFF0284C7, // Ocean Blue
      0xFFF97316, // Orange
      0xFF8B5CF6, // Purple
      0xFFEC4899, // Pink
      0xFFEAB308, // Gold
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151E17),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: const BorderSide(color: Color(0xFF28362B)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'EDIT HABIT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),



                // Name Input
                const Text('Nama Habit:',
                    style: TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F1511),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: const BorderSide(color: Color(0xFF28362B)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Color Swatches
                const Text('Warna Card:',
                    style: TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: colorOptions.map((c) {
                    final isSel = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = c),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Color(c),
                          borderRadius: BorderRadius.circular(2),
                          border: isSel ? Border.all(color: Colors.white, width: 2) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Save Changes & Delete Row
                Row(
                  children: [
                    // Delete Habit Button
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Hapus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        onPressed: () => _confirmDeleteHabit(context, habit),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Save Button
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF70C050),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;

                          habit.name = name;
                          habit.iconKey = habit.iconKey;
                          habit.colorValue = selectedColor;
                          habit.target = target;
                          habit.updatedAt = DateTime.now();

                          ref.read(sadarRepoProvider).upsertHabit(habit);
                          Navigator.pop(ctx);
                        },
                        child: const Text('SIMPAN PERUBAHAN',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteHabit(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171F19),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: Color(0xFF28362B)),
        ),
        title: const Text('Hapus Habit?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
        content: Text(
          'Habit "${habit.name}" akan dihapus permanen.',
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            onPressed: () {
              ref.read(sadarRepoProvider).deleteHabit(habit.id, hardDelete: true);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close edit sheet
            },
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Simple Triangle Caret Painter
class _TriangleCaretPainter extends CustomPainter {
  final Color color;
  const _TriangleCaretPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TriangleCaretPainter oldDelegate) =>
      oldDelegate.color != color;
}
