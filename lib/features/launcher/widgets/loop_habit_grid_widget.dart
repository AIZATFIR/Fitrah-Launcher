import 'habit_action_save_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../widgets/activity_icon.dart';
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
class LoopHabitGridWidget extends ConsumerStatefulWidget {
  const LoopHabitGridWidget({super.key, this.onStartTimer});

  final void Function(Habit habit)? onStartTimer;

  @override
  ConsumerState<LoopHabitGridWidget> createState() =>
      _LoopHabitGridWidgetState();
}

class _LoopHabitGridWidgetState extends ConsumerState<LoopHabitGridWidget> {
  int? _expandedHabitId;
  bool _actionBusy = false;
  String? _actionError;
  int _selectedDayIndex = 0; // 0..6 (Mon..Sun)
  late DateTime _referenceDate;

  // Preset habit ideas matching user's actual habits
  static const List<String> _habitIdeas = [
    'Baca satu ayat Al-Qur’an',
    'Buka laptop dan jauhkan ponsel selama 10 menit',
    'Selesaikan satu modul Dicoding',
    'Latihan kekuatan tubuh',
    'Baca satu kalam harian',
    'Baca 5 halaman',
    'Tonton 2 video edukasi tersimpan',
    'Main gitar selama 10 menit',
    'Tulis satu kalimat di jurnal',
    'Fokus mendalam selama 45 menit',
    'Kardio atau joging selama 20 menit',
    'Refleksi selama 10 menit',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _referenceDate = DateTime(now.year, now.month, now.day);
    _selectedDayIndex = (_referenceDate.weekday - 1).clamp(0, 6);
  }

  List<DateTime> _getCurrentWeekDays() {
    final monday = _referenceDate.subtract(
      Duration(days: _referenceDate.weekday - 1),
    );
    return List.generate(
      7,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );
  }

  String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  bool get _isCurrentWeek {
    final now = DateTime.now();
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));
    final dispMonday = _referenceDate.subtract(
      Duration(days: _referenceDate.weekday - 1),
    );
    return currentMonday.year == dispMonday.year &&
        currentMonday.month == dispMonday.month &&
        currentMonday.day == dispMonday.day;
  }

  void _previousWeek() {
    if (_actionBusy) return;
    HapticFeedback.selectionClick();
    setState(() {
      _referenceDate = _referenceDate.subtract(const Duration(days: 7));
      _expandedHabitId = null;
    });
  }

  void _nextWeek() {
    if (_actionBusy) return;
    HapticFeedback.selectionClick();
    setState(() {
      _referenceDate = _referenceDate.add(const Duration(days: 7));
      _expandedHabitId = null;
    });
  }

  void _goToToday() {
    if (_actionBusy) return;
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
    final showWeekControls = habitsAsync.valueOrNull?.isNotEmpty ?? true;
    final weekDays = _getCurrentWeekDays();
    final startDateStr = _formatDate(weekDays.first);
    final endDateStr = _formatDate(weekDays.last);

    final entriesAsync = ref.watch(
      habitEntriesStreamProvider(
        DateRangeQuery(start: startDateStr, end: endDateStr),
      ),
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
              if (showWeekControls) ...[
                // Week controls are useful once there are habits to track.
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                  child: Row(
                    children: [
                      // Organize / Menu Hamburger button
                      IconButton(
                        icon: const Icon(
                          Icons.menu_rounded,
                          size: 22,
                          color: AppPalette.text,
                        ),
                        tooltip: 'Atur kebiasaan',
                        splashRadius: 18,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () => _openOrganizeSheet(context),
                      ),
                      const SizedBox(width: 4),

                      // "This Week" (or Date range)
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _isCurrentWeek
                                ? 'Minggu ini'
                                : DateFormat(
                                    'MMM d - MMM d',
                                  ).format(weekDays.first),
                            maxLines: 1,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.text,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Navigation arrows < >
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          size: 20,
                          color: AppPalette.textDim,
                        ),
                        splashRadius: 16,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Minggu Sebelumnya',
                        onPressed: _previousWeek,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppPalette.textDim,
                        ),
                        splashRadius: 16,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Minggu Selanjutnya',
                        onPressed: _nextWeek,
                      ),

                      const Spacer(),

                      // Today Calendar button
                      IconButton(
                        icon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppPalette.text,
                        ),
                        splashRadius: 18,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Hari Ini',
                        onPressed: _goToToday,
                      ),
                    ],
                  ),
                ),

                // ── Weekday Headers ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                            if (_actionBusy) return;
                            HapticFeedback.selectionClick();
                            setState(() => _selectedDayIndex = idx);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                const [
                                  'Sen',
                                  'Sel',
                                  'Rab',
                                  'Kam',
                                  'Jum',
                                  'Sab',
                                  'Min',
                                ][day.weekday - 1],
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : (isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500),
                                  color: isToday
                                      ? const Color(
                                          0xFFF59E0B,
                                        ) // Vibrant Amber/Orange for active day like Screenshot 1
                                      : (isSelected
                                            ? AppPalette.text
                                            : AppPalette.textDim),
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

                const Divider(height: 1, color: AppPalette.stroke),
              ],

              // ── Habits List with Pure Flat Solid Day Cells ──
              habitsAsync.when(
                data: (habits) {
                  if (habits.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Belum ada kebiasaan',
                              style: TextStyle(color: AppPalette.textDim),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openNewJournalSheet(context),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Tambah'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppPalette.accent,
                              side: const BorderSide(color: AppPalette.stroke),
                              minimumSize: const Size(48, 44),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return entriesAsync.when(
                    data: (entries) {
                      final entryMap = <int, Map<String, HabitEntry>>{};
                      for (final e in entries) {
                        entryMap.putIfAbsent(
                          e.habitId,
                          () => {},
                        )[e.dateString] = e;
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
                              // ── Habit icon, title, and timer action ──
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  12,
                                  12,
                                  6,
                                ),
                                child: Row(
                                  children: [
                                    if (habit.iconKey.isNotEmpty) ...[
                                      ActivityIcon(
                                        iconKey: habit.iconKey,
                                        size: 15,
                                        color: AppPalette.accent,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => _openNewJournalSheet(
                                          context,
                                          habit,
                                        ),
                                        child: Text(
                                          habit.name,
                                          style: GoogleFonts.outfit(
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
                                    if (_canTime(habit) &&
                                        _isCurrentWeek &&
                                        selectedDateStr ==
                                            _formatDate(DateTime.now()))
                                      IconButton(
                                        icon: const Icon(
                                          Icons.play_circle_outline_rounded,
                                          size: 20,
                                          color: AppPalette.accent,
                                        ),
                                        tooltip: 'Mulai di Focus Clock',
                                        splashRadius: 16,
                                        constraints: const BoxConstraints(
                                          minWidth: 48,
                                          minHeight: 48,
                                        ),
                                        padding: EdgeInsets.zero,
                                        onPressed: _actionBusy
                                            ? null
                                            : () {
                                                HapticFeedback.lightImpact();
                                                widget.onStartTimer?.call(
                                                  habit,
                                                );
                                              },
                                      ),
                                    // More options
                                    IconButton(
                                      icon: const Icon(
                                        Icons.more_horiz_rounded,
                                        size: 18,
                                        color: AppPalette.textDim,
                                      ),
                                      tooltip: 'Edit Journal',
                                      splashRadius: 16,
                                      constraints: const BoxConstraints(
                                        minWidth: 26,
                                        minHeight: 26,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () =>
                                          _openNewJournalSheet(context, habit),
                                    ),
                                  ],
                                ),
                              ),

                              // ── Line 2: 7 Wide Flat Solid Day Pills (Pure Solid Blocks matching Screenshot 1) ──
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Row(
                                  children: weekDays.asMap().entries.map((
                                    dayEntry,
                                  ) {
                                    final dayIdx = dayEntry.key;
                                    final day = dayEntry.value;
                                    final dStr = _formatDate(day);
                                    final entry = habitEntries[dStr];
                                    final status =
                                        entry?.status ?? HabitStatus.unmarked;
                                    final isTargetCell =
                                        isExpanded &&
                                        _selectedDayIndex == dayIdx;
                                    final hasNote =
                                        entry?.note?.isNotEmpty ?? false;

                                    return Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          if (_actionBusy) return;
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
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 2.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getBlockColor(
                                              status,
                                              habit,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ), // clean pill like Screenshot 1
                                            border: isTargetCell
                                                ? Border.all(
                                                    color: AppPalette.accent,
                                                    width: 1.8,
                                                  )
                                                : Border.all(
                                                    color: AppPalette.text
                                                        .withOpacity(0.06),
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
                                                    painter:
                                                        DiagonalStripesPainter(
                                                          color: AppPalette.text
                                                              .withOpacity(
                                                                0.35,
                                                              ),
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
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors
                                                              .amberAccent,
                                                          shape:
                                                              BoxShape.circle,
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Row(
                                    children: List.generate(7, (i) {
                                      return Expanded(
                                        child: Center(
                                          child: i == _selectedDayIndex
                                              ? const CustomPaint(
                                                  size: Size(12, 7),
                                                  painter:
                                                      _TriangleCaretPainter(
                                                        color:
                                                            AppPalette.accent,
                                                      ),
                                                )
                                              : const SizedBox(height: 7),
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppPalette.cardHigh,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppPalette.accent.withOpacity(0.6),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                DateFormat(
                                                  'EEEE, d MMMM',
                                                ).format(selectedDate),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppPalette.accent,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Tutup tindakan',
                                              constraints: const BoxConstraints(
                                                minWidth: 48,
                                                minHeight: 48,
                                              ),
                                              onPressed: _actionBusy
                                                  ? null
                                                  : () => setState(
                                                      () => _expandedHabitId =
                                                          null,
                                                    ),
                                              icon: const Icon(
                                                Icons.close,
                                                size: 14,
                                                color: AppPalette.textDim,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      _habitActions(
                                        habit,
                                        selectedDateStr,
                                        currentEntry,
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 6),
                              Divider(
                                height: 1,
                                color: AppPalette.text.withOpacity(0.06),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const SizedBox(height: 60),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Error: $e',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppPalette.danger,
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(height: 80),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppPalette.danger,
                    ),
                  ),
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
        return AppPalette.accent; // Pure solid green like Screenshot 1
      case HabitStatus.no:
        return AppPalette.danger; // Pure solid red like Screenshot 1
      case HabitStatus.skip:
        return AppPalette.cardHigh;
      case HabitStatus.unmarked:
        return AppPalette.text.withOpacity(0.06);
    }
  }

  bool _canTime(Habit habit) =>
      habit.habitType == 'timed' &&
      habit.unit == HabitUnit.min &&
      habit.target > 0 &&
      widget.onStartTimer != null;

  Widget _habitActions(Habit habit, String date, HabitEntry? entry) {
    final unsupported =
        habit.habitType == 'progression' || habit.habitType == 'hybrid';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unsupported) Text(habitExecutionLimit(habit)),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: _actionBusy
                  ? null
                  : () => _showNoteDialog(context, habit, date, entry?.note),
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Catatan'),
            ),
            if (!unsupported &&
                (habit.unit == HabitUnit.binary || habit.habitType == 'binary'))
              TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: _actionBusy
                    ? null
                    : () => _saveStatus(
                        habit,
                        date,
                        entry?.status == HabitStatus.yes
                            ? HabitStatus.unmarked
                            : HabitStatus.yes,
                      ),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  entry?.status == HabitStatus.yes
                      ? 'Batalkan selesai'
                      : 'Tandai dilakukan',
                ),
              ),
            if (!unsupported &&
                habit.unit != HabitUnit.binary &&
                habit.habitType != 'binary' &&
                (habit.habitType == 'count' || habit.unit == HabitUnit.count))
              TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: _actionBusy
                    ? null
                    : () => _showCountDialog(habit, date, entry),
                icon: const Icon(Icons.add),
                label: const Text('Catat jumlah'),
              ),
            if (_canTime(habit) && date == _formatDate(DateTime.now()))
              TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: _actionBusy
                    ? null
                    : () => widget.onStartTimer!(habit),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Mulai fokus'),
              ),
            if (!unsupported) ...[
              for (final status in [HabitStatus.no, HabitStatus.skip])
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: _actionBusy
                      ? null
                      : () => _saveStatus(
                          habit,
                          date,
                          entry?.status == status
                              ? HabitStatus.unmarked
                              : status,
                        ),
                  child: Text(
                    status == HabitStatus.no ? 'Tidak dilakukan' : 'Lewati',
                  ),
                ),
            ],
          ],
        ),
        if (_actionBusy) const LinearProgressIndicator(),
        if (_actionError != null)
          Text(_actionError!, style: const TextStyle(color: AppPalette.danger)),
      ],
    );
  }

  Future<void> _saveStatus(Habit habit, String date, HabitStatus status) async {
    if (_actionBusy) return;
    setState(() {
      _actionBusy = true;
      _actionError = null;
    });
    try {
      await ref
          .read(sadarRepoProvider)
          .recordEntryStatus(
            habitId: habit.id,
            dateString: date,
            status: status,
          );
    } catch (e) {
      if (mounted) {
        setState(
          () => _actionError =
              '${habit.name} ($date): Belum tersimpan. Coba lagi. $e',
        );
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _showCountDialog(
    Habit habit,
    String date,
    HabitEntry? entry,
  ) async {
    final controller = TextEditingController(
      text: '${entry?.valueCompleted ?? 0}',
    );
    await showHabitActionDialog(
      context: context,
      builder: (_) => HabitActionSaveDialog(
        title: 'Jumlah ${habit.name}',
        body: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Jumlah total $date'),
        ),
        onSave: () async {
          final value = int.tryParse(controller.text);
          if (value == null || value < 0 || value > 9999) {
            throw StateError('Masukkan jumlah 0–9999.');
          }
          await ref
              .read(sadarRepoProvider)
              .setHabitCount(habitId: habit.id, dateString: date, value: value);
        },
      ),
    );
    controller.dispose();
  }

  Future<void> _showNoteDialog(
    BuildContext context,
    Habit habit,
    String dateString,
    String? existingNote,
  ) async {
    final controller = TextEditingController(text: existingNote ?? '');
    await showHabitActionDialog(
      context: context,
      builder: (_) => HabitActionSaveDialog(
        title: 'Catatan: ${habit.name}',
        body: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(labelText: 'Catatan $dateString'),
        ),
        onSave: () async {
          await ref
              .read(sadarRepoProvider)
              .updateHabitEntryNote(
                habitId: habit.id,
                dateString: dateString,
                note: controller.text.trim(),
              );
        },
      ),
    );
    controller.dispose();
  }

  // ── Organize Screen (Pixel-faithful to Screenshot 2) ──
  void _openOrganizeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.card,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppPalette.text,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Atur kebiasaan',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.text,
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
                                color: AppPalette.textDim,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: AppPalette.stroke),

                    // + New Journal button
                    InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _openNewJournalSheet(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_circle,
                              color: AppPalette.accent,
                              size: 24,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Catatan baru',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.text,
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
                          'CATATAN',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppPalette.textDim,
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
                              child: Text(
                                'Tidak ada habit.',
                                style: TextStyle(color: AppPalette.textDim),
                              ),
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
                              await ref
                                  .read(sadarRepoProvider)
                                  .reorderHabits(ids);
                            },
                            itemBuilder: (context, idx) {
                              final habit = habits[idx];
                              return ListTile(
                                key: ValueKey('organize_habit_${habit.id}'),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 2,
                                ),
                                leading: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: AppPalette.danger,
                                    size: 22,
                                  ),
                                  tooltip: 'Hapus / Arsipkan',
                                  onPressed: () =>
                                      _confirmArchiveOrDelete(context, habit),
                                ),
                                title: Text(
                                  habit.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppPalette.text,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(
                                  Icons.drag_handle,
                                  color: AppPalette.textDim,
                                  size: 22,
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(
                          child: Text(
                            'Error: $e',
                            style: const TextStyle(color: AppPalette.danger),
                          ),
                        ),
                      ),
                    ),

                    // Bottom caption
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      child: Text(
                        'Tekan dan geser untuk mengatur urutan.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppPalette.textDim,
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
    int target = habitToEdit?.target ?? 20;
    bool saving = false;
    String? saveError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return PopScope(
              canPop: !saving,
              child: Padding(
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
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppPalette.text,
                              ),
                              onPressed: saving
                                  ? null
                                  : () => Navigator.pop(ctx),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              habitToEdit == null
                                  ? 'Kebiasaan baru'
                                  : 'Ubah kebiasaan',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.text,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final name = nameCtrl.text.trim();
                                  if (name.isEmpty) return;
                                  setModalState(() {
                                    saving = true;
                                    saveError = null;
                                  });
                                  final previousName = habitToEdit?.name;
                                  final previousTarget = habitToEdit?.target;
                                  final previousUpdatedAt =
                                      habitToEdit?.updatedAt;
                                  try {
                                    final habit =
                                        habitToEdit ??
                                        (Habit()
                                          ..name = name
                                          ..iconKey = ''
                                          ..target = target
                                          ..unit = HabitUnit.min
                                          ..colorValue = 0xFF48C774
                                          ..timerEnabled = true
                                          ..createdAt = DateTime.now());
                                    habit
                                      ..name = name
                                      ..target = target;
                                    await ref
                                        .read(sadarRepoProvider)
                                        .upsertHabit(habit);
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  } catch (_) {
                                    if (habitToEdit != null) {
                                      habitToEdit
                                        ..name = previousName!
                                        ..target = previousTarget!
                                        ..updatedAt = previousUpdatedAt;
                                    }
                                    if (ctx.mounted) {
                                      setModalState(() {
                                        saving = false;
                                        saveError =
                                            'Belum tersimpan. Coba lagi.';
                                      });
                                    }
                                  }
                                },
                          child: Text(
                            saving ? 'Menyimpan…' : 'Simpan',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppPalette.accent,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (saveError != null)
                      Text(
                        saveError!,
                        style: const TextStyle(color: AppPalette.danger),
                      ),

                    const SizedBox(height: 14),

                    // Name Row with IDEAS Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            enabled: !saving,
                            autofocus: habitToEdit == null,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: AppPalette.text,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Name',
                              labelStyle: const TextStyle(
                                color: AppPalette.textDim,
                                fontSize: 14,
                              ),
                              hintText: 'e.g. 1 ayat Al quran',
                              hintStyle: TextStyle(
                                color: AppPalette.textDim.withOpacity(0.5),
                                fontSize: 13,
                              ),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppPalette.text.withOpacity(0.2),
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppPalette.accent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppPalette.accent,
                              width: 1.4,
                            ),
                            foregroundColor: AppPalette.accent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: saving
                              ? null
                              : () {
                                  _showIdeasPicker(context, (chosenIdea) {
                                    setModalState(() {
                                      nameCtrl.text = chosenIdea;
                                    });
                                  });
                                },
                          child: Text(
                            'IDE KEGIATAN',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
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
      backgroundColor: AppPalette.card,
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
                'IDE KEGIATAN',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.accent,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const Divider(height: 1, color: AppPalette.stroke),
            Expanded(
              child: ListView.separated(
                itemCount: _habitIdeas.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppPalette.text.withOpacity(0.04),
                ),
                itemBuilder: (context, idx) {
                  final idea = _habitIdeas[idx];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 4,
                    ),
                    title: Text(
                      idea,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppPalette.text,
                      ),
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
        backgroundColor: AppPalette.cardHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Hapus kebiasaan?',
          style: GoogleFonts.outfit(
            color: AppPalette.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Pilih apakah ingin mengarsipkan atau menghapus permanen "${habit.name}".',
          style: const TextStyle(color: AppPalette.textDim, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppPalette.textDim),
            ),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(sadarRepoProvider)
                  .deleteHabit(habit.id, hardDelete: false);
              Navigator.pop(ctx);
            },
            child: const Text(
              'Arsipkan',
              style: TextStyle(color: AppPalette.accent),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.danger),
            onPressed: () {
              ref
                  .read(sadarRepoProvider)
                  .deleteHabit(habit.id, hardDelete: true);
              Navigator.pop(ctx);
            },
            child: const Text(
              'Hapus Permanen',
              style: TextStyle(color: AppPalette.text),
            ),
          ),
        ],
      ),
    );
  }

  // ── Show Archived Habits Sheet ──
  void _showArchivedHabitsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppPalette.card,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Catatan arsip',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.text,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppPalette.textDim,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppPalette.stroke),
                Expanded(
                  child: list.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada jurnal yang diarsipkan.',
                            style: TextStyle(color: AppPalette.textDim),
                          ),
                        )
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, idx) {
                            final h = list[idx];
                            return ListTile(
                              title: Text(
                                h.name,
                                style: const TextStyle(color: AppPalette.text),
                              ),
                              trailing: TextButton(
                                onPressed: () {
                                  h.isArchived = false;
                                  ref.read(sadarRepoProvider).upsertHabit(h);
                                  Navigator.pop(ctx);
                                },
                                child: const Text(
                                  'Pulihkan',
                                  style: TextStyle(color: AppPalette.accent),
                                ),
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
