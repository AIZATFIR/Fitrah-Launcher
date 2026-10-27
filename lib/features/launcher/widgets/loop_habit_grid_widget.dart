import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
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

/// Upward Pointing Triangle Caret Painter
class _TriangleCaretPainter extends CustomPainter {
  final Color color;
  const _TriangleCaretPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TriangleCaretPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Loop Habit Tracker Inspired 7-Day Grid Widget
/// Pixel-faithful to user screenshots with pure flat solid pills, Organize reorderable list,
/// New Journal with IDEAS presets, and direct Focus Clock timer integration.
class LoopHabitGridWidget extends ConsumerStatefulWidget {
  const LoopHabitGridWidget({
    super.key,
    this.onStartTimer,
  });

  final void Function(Habit habit)? onStartTimer;

  @override
  ConsumerState<LoopHabitGridWidget> createState() => _LoopHabitGridWidgetState();
}

class _LoopHabitGridWidgetState extends ConsumerState<LoopHabitGridWidget> {
  int? _expandedHabitId;
  int _selectedDayIndex = 0; // 0..6 (Mon..Sun)
  late DateTime _referenceDate;

  // Preset habit ideas matching user's actual habits
  static const List<String> _habitIdeas = [
    '😇 🕌 1 ayat Al quran (smkdutalib, jalan yg benar, pencerahan)',
    '10 min Open Laptop and throw my phone',
    '🎓 1 module AI 50% - Dicoding - Portofolio, skill, knowledge, advantage',
    '💪 Grind Physique (abs, shoulder, Hand group, back)',
    '🪶 😇 1 Kalaam harian (Paham Rahmat tuhan)',
    '🧠 📖 Baca 5 halaman (growth, lebih pintar)',
    '🧠 🎬 Tonton 2 Watch later edukasi (growth, lebih pintar)',
    '🎸 10 menit pegang guitar (attractive, relaxing)',
    '📝 Write story notebook 1 Sentence',
    '💻 45 min Focus / Deep Work',
    '🏃 20 min Cardio / Jogging',
    '🧘 10 min Mindfulness / Refleksi',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _referenceDate = DateTime(now.year, now.month, now.day);
    _selectedDayIndex = (_referenceDate.weekday - 1).clamp(0, 6);
  }

  List<DateTime> _getCurrentWeekDays() {
    final monday = _referenceDate.subtract(Duration(days: _referenceDate.weekday - 1));
    return List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  bool get _isCurrentWeek {
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    final dispMonday = _referenceDate.subtract(Duration(days: _referenceDate.weekday - 1));
    return currentMonday.year == dispMonday.year &&
        currentMonday.month == dispMonday.month &&
        currentMonday.day == dispMonday.day;
  }

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

    final now = DateTime.now();
    final todayStr = _formatDate(now);

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header (Screenshot 1: Menu ≡, This Week, Calendar 📅) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                child: Row(
                  children: [
                    // Organize / Menu Hamburger button
                    IconButton(
                      icon: const Icon(Icons.menu_rounded, size: 22, color: AppPalette.text),
                      tooltip: 'Organize',
                      splashRadius: 18,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      onPressed: () => _openOrganizeSheet(context),
                    ),
                    const SizedBox(width: 4),

                    // "This Week" (or Date range)
                    Text(
                      _isCurrentWeek ? 'This Week' : DateFormat('MMM d - MMM d').format(weekDays.first),
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Navigation arrows < >
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20, color: AppPalette.textDim),
                      splashRadius: 16,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                      tooltip: 'Minggu Sebelumnya',
                      onPressed: _previousWeek,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20, color: AppPalette.textDim),
                      splashRadius: 16,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                      tooltip: 'Minggu Selanjutnya',
                      onPressed: _nextWeek,
                    ),

                    const Spacer(),

                    // Today Calendar button
                    IconButton(
                      icon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppPalette.text),
                      splashRadius: 18,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      tooltip: 'Hari Ini',
                      onPressed: _goToToday,
                    ),
                  ],
                ),
              ),

              // ── Weekday Headers (Mon Tue Wed Thu Fri Sat Sun) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  children: weekDays.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final day = entry.value;
                    final isToday = _formatDate(day) == todayStr;
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
                              DateFormat('E').format(day), // Mon, Tue...
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isToday ? FontWeight.w700 : (isSelected ? FontWeight.w600 : FontWeight.w500),
                                color: isToday
                                    ? const Color(0xFFF59E0B) // Vibrant Amber/Orange for active day like Screenshot 1
                                    : (isSelected ? AppPalette.text : AppPalette.textDim),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(height: 1, color: Color(0xFF222622)),

              // ── Habits List with Pure Flat Solid Day Cells ──
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
                              'Belum ada kebiasaan.',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF48C774),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('New Journal',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              onPressed: () => _openNewJournalSheet(context),
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
                              // ── Line 1: Emoji + Habit Title + Play Timer Button ──
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                                child: Row(
                                  children: [
                                    if (habit.iconKey.isNotEmpty) ...[
                                      Text(
                                        habit.iconKey,
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => _openNewJournalSheet(context, habit),
                                        child: Text(
                                          habit.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppPalette.text,
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    // Direct Play in Clock button
                                    IconButton(
                                      icon: const Icon(Icons.play_circle_outline_rounded,
                                          size: 20, color: Color(0xFF48C774)),
                                      tooltip: 'Mulai di Focus Clock',
                                      splashRadius: 16,
                                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        widget.onStartTimer?.call(habit);
                                      },
                                    ),
                                    // More options
                                    IconButton(
                                      icon: const Icon(Icons.more_horiz_rounded,
                                          size: 18, color: AppPalette.textDim),
                                      tooltip: 'Edit Journal',
                                      splashRadius: 16,
                                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _openNewJournalSheet(context, habit),
                                    ),
                                  ],
                                ),
                              ),

                              // ── Line 2: 7 Wide Flat Solid Day Pills (Pure Solid Blocks matching Screenshot 1) ──
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  children: weekDays.asMap().entries.map((dayEntry) {
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
                                          height: 32,
                                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                          decoration: BoxDecoration(
                                            color: _getBlockColor(status, habit),
                                            borderRadius: BorderRadius.circular(4), // clean pill like Screenshot 1
                                            border: isTargetCell
                                                ? Border.all(color: const Color(0xFF38BDF8), width: 1.8)
                                                : Border.all(
                                                    color: Colors.white.withOpacity(0.06),
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
                                                      color: Colors.white.withOpacity(0.35),
                                                    ),
                                                  ),
                                                ),

                                              // Note indicator badge (small subtle dot)
                                              if (hasNote)
                                                Positioned(
                                                  top: 3,
                                                  right: 3,
                                                  child: Container(
                                                    width: 4,
                                                    height: 4,
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
                                  }).toList(),
                                ),
                              ),

                              // ── Caret Indicator & Tactile Popover ──
                              if (isExpanded) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Row(
                                    children: List.generate(7, (i) {
                                      return Expanded(
                                        child: Center(
                                          child: i == _selectedDayIndex
                                              ? const CustomPaint(
                                                  size: Size(12, 7),
                                                  painter: _TriangleCaretPainter(
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                )
                                              : const SizedBox(height: 7),
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141A16),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF2563EB).withOpacity(0.6),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DateFormat('EEEE, d MMMM').format(selectedDate),
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF38BDF8),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => setState(() => _expandedHabitId = null),
                                              child: const Icon(Icons.close, size: 14, color: AppPalette.textDim),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Squircle Action Buttons: [Note] [Yes] [No] [Skip] [Timer]
                                      Row(
                                        children: [
                                          _buildActionButton(
                                            icon: Icons.edit_note_rounded,
                                            label: 'Note',
                                            color: Colors.white,
                                            isActive: (currentEntry?.note?.isNotEmpty ?? false),
                                            onTap: () => _showNoteDialog(
                                              context,
                                              habit,
                                              selectedDateStr,
                                              currentEntry?.note,
                                            ),
                                          ),
                                          _buildActionButton(
                                            icon: Icons.check_circle_rounded,
                                            label: 'Yes',
                                            color: const Color(0xFF48C774),
                                            isActive: currentEntry?.status == HabitStatus.yes,
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              final target = currentEntry?.status == HabitStatus.yes
                                                  ? HabitStatus.unmarked
                                                  : HabitStatus.yes;
                                              ref.read(sadarRepoProvider).recordEntryStatus(
                                                    habitId: habit.id,
                                                    dateString: selectedDateStr,
                                                    status: target,
                                                    note: currentEntry?.note,
                                                  );
                                            },
                                          ),
                                          _buildActionButton(
                                            icon: Icons.cancel_rounded,
                                            label: 'No',
                                            color: const Color(0xFFEF5350),
                                            isActive: currentEntry?.status == HabitStatus.no,
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              final target = currentEntry?.status == HabitStatus.no
                                                  ? HabitStatus.unmarked
                                                  : HabitStatus.no;
                                              ref.read(sadarRepoProvider).recordEntryStatus(
                                                    habitId: habit.id,
                                                    dateString: selectedDateStr,
                                                    status: target,
                                                    note: currentEntry?.note,
                                                  );
                                            },
                                          ),
                                          _buildActionButton(
                                            icon: Icons.redo_rounded,
                                            label: 'Skip',
                                            color: const Color(0xFF94A3B8),
                                            isActive: currentEntry?.status == HabitStatus.skip,
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              final target = currentEntry?.status == HabitStatus.skip
                                                  ? HabitStatus.unmarked
                                                  : HabitStatus.skip;
                                              ref.read(sadarRepoProvider).recordEntryStatus(
                                                    habitId: habit.id,
                                                    dateString: selectedDateStr,
                                                    status: target,
                                                    note: currentEntry?.note,
                                                  );
                                            },
                                          ),
                                          _buildActionButton(
                                            icon: Icons.timer_outlined,
                                            label: 'Clock',
                                            color: AppPalette.accent,
                                            isActive: false,
                                            onTap: () {
                                              HapticFeedback.mediumImpact();
                                              setState(() => _expandedHabitId = null);
                                              widget.onStartTimer?.call(habit);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 6),
                              Divider(height: 1, color: Colors.white.withOpacity(0.06)),
                            ],
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const SizedBox(height: 60),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Error: $e', style: const TextStyle(fontSize: 10, color: Colors.red)),
                    ),
                  );
                },
                loading: () => const SizedBox(height: 80),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Error: $e', style: const TextStyle(fontSize: 10, color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Pure flat solid colors without inner icons matching user's screenshots
  Color _getBlockColor(HabitStatus status, Habit habit) {
    switch (status) {
      case HabitStatus.yes:
        return const Color(0xFF48C774); // Pure solid green like Screenshot 1
      case HabitStatus.no:
        return const Color(0xFFEF5350); // Pure solid red like Screenshot 1
      case HabitStatus.skip:
        return const Color(0xFF2C322E);
      case HabitStatus.unmarked:
        return Colors.white.withOpacity(0.06);
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.25) : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? color : Colors.white.withOpacity(0.12),
              width: isActive ? 1.5 : 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isActive ? color : Colors.white),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? color : Colors.white70,
                ),
              ),
            ],
          ),
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
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF28362B)),
        ),
        title: Text(
          'Catatan: ${habit.name}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
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
                hintText: 'Tulis catatan harian...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF0F1511),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
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
              backgroundColor: const Color(0xFF48C774),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  // ── Organize Screen (Pixel-faithful to Screenshot 2) ──
  void _openOrganizeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121713),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final habitsAsync = ref.watch(habitsStreamProvider);

            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollCtrl) {
                return Column(
                  children: [
                    // Top Bar: ← Organize, SHOW ARCHIVED
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Organize',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              _showArchivedHabitsSheet(context);
                            },
                            child: const Text(
                              'SHOW ARCHIVED',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFF222823)),

                    // + New Journal button
                    InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _openNewJournalSheet(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.add_circle, color: Color(0xFF48C774), size: 24),
                            const SizedBox(width: 14),
                            Text(
                              'New Journal',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Section Title: JOURNALS
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'JOURNALS',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),

                    // Reorderable Habits List
                    Expanded(
                      child: habitsAsync.when(
                        data: (habits) {
                          if (habits.isEmpty) {
                            return const Center(
                              child: Text('Tidak ada habit.', style: TextStyle(color: Colors.white38)),
                            );
                          }

                          return ReorderableListView.builder(
                            scrollController: scrollCtrl,
                            itemCount: habits.length,
                            onReorder: (oldIdx, newIdx) async {
                              if (newIdx > oldIdx) newIdx--;
                              final items = List<Habit>.from(habits);
                              final moved = items.removeAt(oldIdx);
                              items.insert(newIdx, moved);
                              final ids = items.map((h) => h.id).toList();
                              await ref.read(sadarRepoProvider).reorderHabits(ids);
                            },
                            itemBuilder: (context, idx) {
                              final habit = habits[idx];
                              return ListTile(
                                key: ValueKey('organize_habit_${habit.id}'),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                leading: IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Color(0xFFEF5350), size: 22),
                                  tooltip: 'Hapus / Arsipkan',
                                  onPressed: () => _confirmArchiveOrDelete(context, habit),
                                ),
                                title: Text(
                                  '${habit.iconKey.isNotEmpty ? '${habit.iconKey} ' : ''}${habit.name}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.drag_handle, color: Colors.white38, size: 22),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                      ),
                    ),

                    // Bottom caption
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: Text(
                        'Tap, hold, and drag the handles to move an item.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ── New Journal / Edit Journal Screen (Pixel-faithful to Screenshot 3) ──
  void _openNewJournalSheet(BuildContext context, [Habit? habitToEdit]) {
    final nameCtrl = TextEditingController(text: habitToEdit?.name ?? '');
    final descCtrl = TextEditingController();
    int target = habitToEdit?.target ?? 20;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121713),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 10,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: ← New Journal, SAVE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            habitToEdit == null ? 'New Journal' : 'Edit Journal',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;

                          if (habitToEdit != null) {
                            habitToEdit.name = name;
                            habitToEdit.target = target;
                            ref.read(sadarRepoProvider).upsertHabit(habitToEdit);
                          } else {
                            final newHabit = Habit()
                              ..name = name
                              ..iconKey = ''
                              ..target = target
                              ..unit = HabitUnit.min
                              ..colorValue = 0xFF48C774
                              ..timerEnabled = true
                              ..createdAt = DateTime.now();
                            ref.read(sadarRepoProvider).upsertHabit(newHabit);
                          }
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'SAVE',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: const Color(0xFF48C774),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Name Row with IDEAS Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          autofocus: habitToEdit == null,
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Name',
                            labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                            hintText: 'e.g. 1 ayat Al quran',
                            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF48C774), width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.4),
                          foregroundColor: const Color(0xFF38BDF8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          _showIdeasPicker(context, (chosenIdea) {
                            setModalState(() {
                              nameCtrl.text = chosenIdea;
                            });
                          });
                        },
                        child: Text(
                          'IDEAS',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Description TextField
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                      hintText: 'Optional purpose or notes',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF48C774), width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── IDEAS Preset Bottom Sheet ──
  void _showIdeasPicker(BuildContext context, ValueChanged<String> onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151C17),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Text(
                'IDEAS & PRESETS',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF38BDF8),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFF263328)),
            Expanded(
              child: ListView.separated(
                itemCount: _habitIdeas.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.04)),
                itemBuilder: (context, idx) {
                  final idea = _habitIdeas[idx];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    title: Text(
                      idea,
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onSelect(idea);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Delete / Archive Confirmation ──
  void _confirmArchiveOrDelete(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171F19),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Hapus Habit?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Pilih apakah ingin mengarsipkan atau menghapus permanen "${habit.name}".',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              ref.read(sadarRepoProvider).deleteHabit(habit.id, hardDelete: false);
              Navigator.pop(ctx);
            },
            child: const Text('Arsipkan', style: TextStyle(color: Colors.amberAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF5350)),
            onPressed: () {
              ref.read(sadarRepoProvider).deleteHabit(habit.id, hardDelete: true);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus Permanen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Show Archived Habits Sheet ──
  void _showArchivedHabitsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121713),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return FutureBuilder<List<Habit>>(
          future: ref.read(sadarRepoProvider).getArchivedHabits(),
          builder: (context, snapshot) {
            final list = snapshot.data ?? [];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        'Archived Journals',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFF222823)),
                Expanded(
                  child: list.isEmpty
                      ? const Center(
                          child: Text('Tidak ada jurnal yang diarsipkan.', style: TextStyle(color: Colors.white38)),
                        )
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, idx) {
                            final h = list[idx];
                            return ListTile(
                              title: Text(h.name, style: const TextStyle(color: Colors.white)),
                              trailing: TextButton(
                                onPressed: () {
                                  h.isArchived = false;
                                  ref.read(sadarRepoProvider).upsertHabit(h);
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Pulihkan', style: TextStyle(color: Color(0xFF48C774))),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
