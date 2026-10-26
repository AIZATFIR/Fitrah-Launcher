import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/launcher_settings.dart';
import '../providers/launcher_settings_provider.dart';
import 'fitrah_settings_screen.dart';

// ── Identity System ──────────────────────────────────────────────────────────
class IdentityItem {
  final String name;
  final Color color;
  const IdentityItem(this.name, this.color);
}

final List<IdentityItem> kIdentities = [
  const IdentityItem('Programmer', Color(0xFFE8C07D)),
  const IdentityItem('Pembaca', Color(0xFF8FB8E8)),
  const IdentityItem('Binaragawan', Color(0xFFE88F7D)),
  const IdentityItem('Baik hati', Color(0xFF5FD0A5)),
  const IdentityItem('Masa depan', Color(0xFFC3A6F0)),
];

Color colorForIdentity(String? identity) {
  for (final id in kIdentities) {
    if (id.name == identity) return id.color;
  }
  return const Color(0xFF8A93A3);
}

// ── In-Memory Models for Interactive Home Experience ─────────────────────────
class BlockItem {
  final int id;
  double startHour; // 0.0 .. 24.0
  double endHour;   // 0.0 .. 24.0
  String name;
  String? identity;
  bool isSleep;
  bool isDone;

  BlockItem({
    required this.id,
    required this.startHour,
    required this.endHour,
    required this.name,
    this.identity,
    this.isSleep = false,
    this.isDone = false,
  });
}

class PresetItem {
  final int id;
  String name;
  int minutes;
  String identity;

  PresetItem({
    required this.id,
    required this.name,
    required this.minutes,
    required this.identity,
  });
}

class HabitModel {
  final int id;
  String title;
  String identity;
  bool isDone;
  bool isSkipped;
  bool isVision;
  int? minutes;
  String? imageUrl;

  HabitModel({
    required this.id,
    required this.title,
    required this.identity,
    this.isDone = false,
    this.isSkipped = false,
    this.isVision = false,
    this.minutes,
    this.imageUrl,
  });
}

class NoteItem {
  final int id;
  final String dateKey; // YYYY-MM-DD
  String text;
  bool isImportant;

  NoteItem({
    required this.id,
    required this.dateKey,
    required this.text,
    this.isImportant = false,
  });
}

class ActiveTimer {
  String label;
  int totalSeconds;
  int leftSeconds;
  bool isRunning;
  String? source; // 'preset' | 'habit' | 'block' | 'free'
  int? sourceId;
  String? identity;
  double startHour;
  bool hasStarted;

  ActiveTimer({
    required this.label,
    required this.totalSeconds,
    required this.leftSeconds,
    this.isRunning = false,
    this.source,
    this.sourceId,
    this.identity,
    required this.startHour,
    this.hasStarted = false,
  });
}

/// Focus Clock Home View (Page 1 - Center)
/// Direct 1:1 Implementation of Lampiran 1 & Future Self Sadar System
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
  // Navigation State: 'home', 'timer', 'catatan', 'jelas'
  String _currentScreen = 'home';

  // Clock View Settings
  bool _isPieMode = true;
  bool _isListView = false;
  bool _is24hDial = true;

  // Filters & Selected Dates
  String _activePresetIdentity = 'Programmer';
  String _activeHabitFilter = 'Semua';
  late String _selectedNoteDate;
  String _notesFilter = 'date'; // 'date' | 'important'

  // Timer Tick
  late Timer _periodicTimer;
  late DateTime _currentTime;

  // Active Focus Timer
  ActiveTimer? _activeTimer;

  // Next ID Counter
  int _nextId = 200;

  // Future Self / Jelas State
  final List<bool> _topEmotions = [true, true, false];
  final List<String> _gratitudeEntries = ['', '', ''];
  String? _futureSelfVisionImage;

  // Prayer Done Status
  final Map<int, bool> _prayerDone = {};

  // Data Collections
  late List<BlockItem> _blocks;
  late List<PresetItem> _presets;
  late List<HabitModel> _habits;
  late List<NoteItem> _notes;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _selectedNoteDate = _dateKey(0);

    // Seed Blocks (Lampiran 1 & 2)
    _blocks = [
      BlockItem(id: 1, startHour: 21.5, endHour: 24.0, name: 'Tidur', isSleep: true),
      BlockItem(id: 2, startHour: 0.0, endHour: 4.5, name: 'Tidur', isSleep: true),
      BlockItem(id: 3, startHour: 19.5, endHour: 21.0, name: 'SE - Orkestrasi AI', identity: 'Programmer'),
    ];

    // Seed Presets (Lampiran 1)
    _presets = [
      PresetItem(id: 1, name: 'SE - Orkestrasi AI', minutes: 90, identity: 'Programmer'),
      PresetItem(id: 2, name: 'LKS ITSSB', minutes: 45, identity: 'Programmer'),
      PresetItem(id: 3, name: 'Baca', minutes: 15, identity: 'Pembaca'),
      PresetItem(id: 4, name: 'Latihan beban', minutes: 30, identity: 'Binaragawan'),
    ];

    // Seed Habits (Lampiran 1 & 3)
    _habits = [
      HabitModel(id: 1, title: 'Selalu bersikap baik', identity: 'Baik hati', isDone: true),
      HabitModel(
        id: 2,
        title: 'Visualisasikan future selfmu, pejamkan mata, lakukan apa yang future selfmu lakukan',
        identity: 'Masa depan',
        isDone: false,
        isVision: true,
        minutes: 3,
      ),
      HabitModel(id: 3, title: 'Baca 15 menit: Lord of Power', identity: 'Pembaca', isDone: false, minutes: 15),
      HabitModel(id: 4, title: 'Jurnal sampai pikiran lega', identity: 'Pembaca', isDone: true),
    ];

    // Seed Notes (Lampiran 1)
    _notes = [
      NoteItem(id: 1, dateKey: _dateKey(-1), text: 'Tauhid satu-satunya kebenaran. Sedikit itu lebih.', isImportant: true),
      NoteItem(id: 2, dateKey: _dateKey(0), text: 'Lepaskan perfeksionisme, menuju penguasaan.', isImportant: false),
    ];

    // 1-Second Timer for clock & active timer countdown
    _periodicTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentTime = DateTime.now();
        if (_activeTimer != null && _activeTimer!.isRunning) {
          if (_activeTimer!.leftSeconds > 0) {
            _activeTimer!.leftSeconds--;
          } else {
            _finishTimer(autoComplete: true);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _periodicTimer.cancel();
    super.dispose();
  }

  // ── Date Helpers ───────────────────────────────────────────────────────────
  String _dateKey(int offsetDays) {
    final d = DateTime.now().add(Duration(days: offsetDays));
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatDateShort(String key) {
    try {
      final parts = key.split('-');
      return '${parts[2]}/${parts[1]}';
    } catch (_) {
      return key;
    }
  }

  double _hourNow() {
    return _currentTime.hour + _currentTime.minute / 60.0 + _currentTime.second / 3600.0;
  }

  String _formatHour(double h) {
    var clamped = ((h % 24) + 24) % 24;
    var hour = clamped.floor();
    var min = ((clamped - hour) * 60).round();
    if (min == 60) {
      hour++;
      min = 0;
    }
    return '${(hour % 24).toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  String _formatDuration(double hours) {
    final totalMins = (hours * 60).round();
    if (totalMins >= 60) {
      final h = totalMins ~/ 60;
      final m = totalMins % 60;
      return m > 0 ? '${h}j ${m}m' : '${h}j';
    }
    return '${totalMins}m';
  }

  String _formatMmSs(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0E1116))),
        backgroundColor: const Color(0xFFE8C07D),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Conflict Check & Add Block ─────────────────────────────────────────────
  BlockItem? _findConflict(double start, double end) {
    for (final b in _blocks) {
      if (!b.isSleep && start < b.endHour && end > b.startHour) {
        return b;
      }
    }
    return null;
  }

  String? _addBlock(double start, double end, String name, String? identity, {bool isDone = false}) {
    final conflict = _findConflict(start, end);
    if (conflict != null) {
      return 'Bentrok dengan ${conflict.name} (${_formatHour(conflict.startHour)}-${_formatHour(conflict.endHour)})';
    }
    if (end > 24.0) {
      return 'Melewati tengah malam';
    }
    setState(() {
      _blocks.add(BlockItem(
        id: _nextId++,
        startHour: start,
        endHour: end,
        name: name,
        identity: identity,
        isDone: isDone,
      ));
    });
    return null;
  }

  // ── Timer Logic ────────────────────────────────────────────────────────────
  void _startTimer(String label, int minutes, {String? source, int? sourceId, String? identity}) {
    HapticFeedback.mediumImpact();
    setState(() {
      _activeTimer = ActiveTimer(
        label: label,
        totalSeconds: minutes * 60,
        leftSeconds: minutes * 60,
        isRunning: true,
        source: source,
        sourceId: sourceId,
        identity: identity,
        startHour: _hourNow(),
        hasStarted: true,
      );
      _currentScreen = 'timer';
    });
  }

  void _finishTimer({bool autoComplete = false}) {
    if (_activeTimer == null) return;
    HapticFeedback.heavyImpact();
    final timer = _activeTimer!;
    final src = timer.source;
    String message = 'Timer selesai';

    if (src == 'habit' && timer.sourceId != null) {
      for (final h in _habits) {
        if (h.id == timer.sourceId) {
          h.isDone = true;
          h.isSkipped = false;
          message = 'Kebiasaan ditandai selesai';
          break;
        }
      }
    } else if (src == 'preset') {
      final nowH = _hourNow();
      var st = timer.startHour;
      var en = nowH;
      if (en - st < 0.05) en = st + 0.25; // minimum 15 mins logged
      final res = _addBlock(st, math.min(en, 24.0), timer.label, timer.identity, isDone: true);
      message = res != null ? 'Tercatat, tapi $res' : 'Dicatat di jam ${_formatHour(st)}-${_formatHour(en)}';
    } else if (src == 'block' && timer.sourceId != null) {
      for (final b in _blocks) {
        if (b.id == timer.sourceId) {
          b.isDone = true;
          message = 'Blok ditandai selesai';
          break;
        }
      }
    }

    setState(() {
      _activeTimer = null;
      _currentScreen = 'home';
    });
    _showToast(message);
  }

  // ── Prayers Calculation ───────────────────────────────────────────────────
  List<Map<String, dynamic>> _getPrayerList(LauncherSettings settings) {
    return [
      {'name': 'Subuh', 'time': settings.prayerSubuh, 'hour': _timeStringToHour(settings.prayerSubuh)},
      {'name': 'Dzuhur', 'time': settings.prayerDzuhur, 'hour': _timeStringToHour(settings.prayerDzuhur)},
      {'name': 'Asar', 'time': settings.prayerAshar, 'hour': _timeStringToHour(settings.prayerAshar)},
      {'name': 'Maghrib', 'time': settings.prayerMaghrib, 'hour': _timeStringToHour(settings.prayerMaghrib)},
      {'name': 'Isya', 'time': settings.prayerIsya, 'hour': _timeStringToHour(settings.prayerIsya)},
    ];
  }

  double _timeStringToHour(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return int.parse(parts[0]) + int.parse(parts[1]) / 60.0;
    } catch (_) {
      return 12.0;
    }
  }

  Map<String, dynamic> _calculateNextPrayer(List<Map<String, dynamic>> prayers) {
    final nowH = _hourNow();
    for (int i = 0; i < prayers.length; i++) {
      final pHour = prayers[i]['hour'] as double;
      if (pHour > nowH) {
        return {'index': i, 'name': prayers[i]['name'], 'diffHours': pHour - nowH};
      }
    }
    final firstFajr = prayers[0]['hour'] as double;
    return {'index': 0, 'name': prayers[0]['name'], 'diffHours': 24.0 - nowH + firstFajr};
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(launcherSettingsProvider);
    final theme = Theme.of(context);

    // Switch between screens
    if (_currentScreen == 'timer') {
      return _buildTimerScreen(theme);
    } else if (_currentScreen == 'catatan') {
      return _buildCatatanScreen(theme);
    } else if (_currentScreen == 'jelas') {
      return _buildJelasScreen(theme);
    }

    return _buildHomeScreen(settings, theme);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 1: HOME VIEW (Lampiran 1)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHomeScreen(LauncherSettings settings, ThemeData theme) {
    final prayers = _getPrayerList(settings);
    final nextPrayer = _calculateNextPrayer(prayers);
    final hr = _hourNow();

    final todayNotesCount = _notes.where((n) => n.dateKey == _dateKey(0)).length;
    final importantNotesCount = _notes.where((n) => n.isImportant).length;
    final doneHabitsCount = _habits.where((h) => h.isDone).length;

    // Filter presets & habits
    final filteredPresets = _presets.where((p) => p.identity == _activePresetIdentity).toList();
    final filteredHabits = _habits.where((h) => _activeHabitFilter == 'Semua' || h.identity == _activeHabitFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 110),
              children: [
                // ── Top Prayer Header Bar ──
                _buildTopPrayerBar(prayers, nextPrayer),
                const SizedBox(height: 6),

                // Next prayer countdown subtitle
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 8),
                    child: Text(
                      'Berikutnya: ${nextPrayer['name']} ${_formatDuration(nextPrayer['diffHours'] as double)} lagi',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8A93A3), fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

                // ── Middle Section: Left Rail + Center Clock Dial + Right Tools ──
                SizedBox(
                  height: 320,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Rail
                      _buildLeftRail(todayNotesCount, importantNotesCount),
                      const SizedBox(width: 8),

                      // Center Clock Dial / List View
                      Expanded(
                        child: _isListView
                            ? _buildChronologicalListView()
                            : _buildClockDialHero(hr, prayers),
                      ),
                      const SizedBox(width: 8),

                      // Right Tools Rail
                      _buildRightToolsRail(),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Preset Time Block Section (Lampiran 1) ──
                _buildPresetTimeBlockSection(filteredPresets),
                const SizedBox(height: 20),

                // ── Habits Section (Lampiran 1 & 3) ──
                _buildHabitsSection(filteredHabits, doneHabitsCount),
              ],
            ),

            // ── Floating Mini Timer Bar (Active State) ──
            if (_activeTimer != null && _activeTimer!.hasStarted)
              Positioned(
                bottom: 16,
                left: 14,
                right: 14,
                child: GestureDetector(
                  onTap: () => setState(() => _currentScreen = 'timer'),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8C07D),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE8C07D).withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _activeTimer!.isRunning ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              color: const Color(0xFF161A22),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _activeTimer!.label,
                              style: const TextStyle(
                                color: Color(0xFF161A22),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatMmSs(_activeTimer!.leftSeconds),
                          style: const TextStyle(
                            color: Color(0xFF161A22),
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Top Prayer Bar ─────────────────────────────────────────────────────────
  Widget _buildTopPrayerBar(List<Map<String, dynamic>> prayers, Map<String, dynamic> nextPrayer) {
    return Row(
      children: [
        // Menu Button
        InkWell(
          onTap: _openMenuSheet,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF161A22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E2430)),
            ),
            child: const Icon(Icons.menu_rounded, color: Color(0xFFEDEFF2), size: 22),
          ),
        ),
        const SizedBox(width: 8),

        // 5 Prayer Buttons
        Expanded(
          child: Row(
            children: List.generate(prayers.length, (i) {
              final p = prayers[i];
              final isNext = nextPrayer['index'] == i;
              final isDone = _prayerDone[i] == true;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                  child: InkWell(
                    onTap: () => _openPrayerActionSheet(i, p),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161A22),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isNext ? const Color(0xFFE8C07D) : const Color(0xFF1E2430),
                          width: isNext ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p['name'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                              color: isDone
                                  ? const Color(0xFF5FD0A5)
                                  : isNext
                                      ? const Color(0xFFE8C07D)
                                      : const Color(0xFF8A93A3),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p['time'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDone ? const Color(0xFF5FD0A5) : const Color(0xFFEDEFF2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── Left Rail (Notes & Date Navigation) ────────────────────────────────────
  Widget _buildLeftRail(int todayNotesCount, int importantNotesCount) {
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          // Kemarin
          Expanded(
            child: _buildRailButton(
              title: 'Kemarin',
              onTap: () {
                setState(() {
                  _selectedNoteDate = _dateKey(-1);
                  _notesFilter = 'date';
                  _currentScreen = 'catatan';
                });
              },
            ),
          ),
          const SizedBox(height: 6),

          // Catatan
          Expanded(
            child: _buildRailButton(
              title: 'Catatan',
              badge: todayNotesCount.toString(),
              onTap: () {
                setState(() {
                  _selectedNoteDate = _dateKey(0);
                  _notesFilter = 'date';
                  _currentScreen = 'catatan';
                });
              },
            ),
          ),
          const SizedBox(height: 6),

          // Penting
          Expanded(
            child: _buildRailButton(
              title: 'Penting',
              badge: importantNotesCount.toString(),
              onTap: () {
                setState(() {
                  _notesFilter = 'important';
                  _currentScreen = 'catatan';
                });
              },
            ),
          ),
          const SizedBox(height: 6),

          // Date Selector
          Expanded(
            child: _buildRailButton(
              title: _formatDateShort(_dateKey(0)),
              onTap: _openDatePickerSheet,
            ),
          ),
          const SizedBox(height: 8),

          // 3 Green Fulfillment Status Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFulfillmentDot(true),
              const SizedBox(width: 4),
              _buildFulfillmentDot(true),
              const SizedBox(width: 4),
              _buildFulfillmentDot(todayNotesCount > 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFulfillmentDot(bool active) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF5FD0A5) : const Color(0xFF1E2430),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildRailButton({required String title, String? badge, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF161A22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E2430)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xFF8A93A3), fontWeight: FontWeight.w500, height: 1.2),
              ),
              if (badge != null) ...[
                const SizedBox(height: 1),
                Text(
                  badge,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEDEFF2)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Center Clock Dial Hero ────────────────────────────────────────────────
  Widget _buildClockDialHero(double hr, List<Map<String, dynamic>> prayers) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTapUp: (details) => _handleClockTap(details),
            child: CustomPaint(
              size: Size.infinite,
              painter: _SketchClockDialPainter(
                currentHour: hr,
                blocks: _blocks,
                prayers: prayers,
                prayerDone: _prayerDone,
                isPieMode: _isPieMode,
                is24hDial: _is24hDial,
                activeTimer: _activeTimer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatHour(hr),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFFEDEFF2),
          ),
        ),
      ],
    );
  }

  void _handleClockTap(TapUpDetails details) {
    // Open block selector sheet for interactive editing
    if (_blocks.isEmpty) return;
    _openBlockDetailSheet(_blocks.last);
  }

  // ── Chronological List View Fallback ──────────────────────────────────────
  Widget _buildChronologicalListView() {
    final nonSleep = _blocks.where((b) => !b.isSleep).toList()
      ..sort((a, b) => a.startHour.compareTo(b.startHour));

    if (nonSleep.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161A22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E2430)),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Belum ada blok hari ini.\nTambahkan dari preset di bawah.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8A93A3), fontSize: 13),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161A22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2430)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: nonSleep.length,
        separatorBuilder: (_, __) => const Divider(color: Color(0xFF1E2430), height: 1),
        itemBuilder: (context, i) {
          final b = nonSleep[i];
          final col = colorForIdentity(b.identity);

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: InkWell(
              onTap: () {
                final durationMins = math.max(1, ((b.endHour - b.startHour) * 60).round());
                _startTimer(b.name, durationMins, source: 'block', sourceId: b.id, identity: b.identity);
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: col, width: 1.5),
                ),
                child: Icon(Icons.play_arrow_rounded, color: col, size: 20),
              ),
            ),
            title: Text(
              '${b.name}${b.isDone ? ' ✓' : ''}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: b.isDone ? const Color(0xFF8A93A3) : const Color(0xFFEDEFF2),
              ),
            ),
            subtitle: Text(
              '${_formatHour(b.startHour)} sampai ${_formatHour(b.endHour)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A93A3)),
            ),
            onTap: () => _openBlockDetailSheet(b),
          );
        },
      ),
    );
  }

  // ── Right Tools Rail ───────────────────────────────────────────────────────
  Widget _buildRightToolsRail() {
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          // Ganti (Pie vs Ring)
          Expanded(
            child: _buildToolButton(
              icon: Icons.pie_chart_outline_rounded,
              label: 'Ganti',
              isActive: !_isPieMode,
              onTap: () => setState(() => _isPieMode = !_isPieMode),
            ),
          ),
          const SizedBox(height: 6),

          // Daftar (List vs Dial)
          Expanded(
            child: _buildToolButton(
              icon: Icons.format_list_bulleted_rounded,
              label: 'Daftar',
              isActive: _isListView,
              onTap: () => setState(() => _isListView = !_isListView),
            ),
          ),
          const SizedBox(height: 6),

          // 24 / 12 jam
          Expanded(
            child: _buildToolButton(
              icon: Icons.access_time_rounded,
              label: _is24hDial ? '24 jam' : '12 jam',
              isActive: _is24hDial,
              onTap: () => setState(() => _is24hDial = !_is24hDial),
            ),
          ),
          const SizedBox(height: 6),

          // Cari
          Expanded(
            child: _buildToolButton(
              icon: Icons.search_rounded,
              label: 'Cari',
              isActive: false,
              onTap: _openSearchSheet,
            ),
          ),
          const SizedBox(height: 6),

          // Timer
          Expanded(
            child: _buildToolButton(
              icon: Icons.timer_outlined,
              label: 'Timer',
              isActive: _activeTimer != null && _activeTimer!.isRunning,
              onTap: () {
                if (_activeTimer == null) {
                  _startTimer('Fokus bebas', 25, source: 'free');
                } else {
                  setState(() => _currentScreen = 'timer');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final activeCol = const Color(0xFFE8C07D);
    final inactiveCol = const Color(0xFF8A93A3);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF161A22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? activeCol : const Color(0xFF1E2430), width: isActive ? 1.5 : 1),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? activeCol : inactiveCol, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? activeCol : inactiveCol,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Preset Time Block Section (Lampiran 1) ─────────────────────────────────
  Widget _buildPresetTimeBlockSection(List<PresetItem> presets) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161A22),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(color: const Color(0xFF1E2430), width: 1.5),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Preset blok waktu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2)),
                ),
              ),

              // Filter Dropdown Button
              InkWell(
                onTap: _openPresetIdentitySelector,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1116),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E2430)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Identitas: $_activePresetIdentity',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE8C07D)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Color(0xFFE8C07D), size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // (+) New Preset Button
              InkWell(
                onTap: _openNewPresetSheet,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF8A93A3), width: 1.5),
                  ),
                  child: const Icon(Icons.add, color: Color(0xFFEDEFF2), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Preset Items List
          if (presets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Belum ada preset untuk identitas ini. Ketuk + di atas.',
                style: TextStyle(color: Color(0xFF8A93A3), fontSize: 13),
              ),
            )
          else
            ...presets.map((p) {
              final col = colorForIdentity(p.identity);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    // ▶ Lead Play Button (Starts Timer & Records Block on Finish)
                    InkWell(
                      onTap: () => _startTimer(p.name, p.minutes, source: 'preset', sourceId: p.id, identity: p.identity),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: col, width: 1.5),
                        ),
                        child: Icon(Icons.play_arrow_rounded, color: col, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Preset Title & Duration
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFEDEFF2)),
                          ),
                          Text(
                            '${p.minutes} menit',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF8A93A3)),
                          ),
                        ],
                      ),
                    ),

                    // (+) Add to Clock Button
                    InkWell(
                      onTap: () => _openAddToClockSheet(p),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF8A93A3), width: 1.5),
                        ),
                        child: const Icon(Icons.add, color: Color(0xFFEDEFF2), size: 20),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Habits Section (Lampiran 1 & 3) ────────────────────────────────────────
  Widget _buildHabitsSection(List<HabitModel> habits, int doneCount) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161A22),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(color: const Color(0xFF1E2430), width: 1.5),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      'Kebiasaan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$doneCount dari ${_habits.length}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8A93A3), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // Filter Dropdown
              InkWell(
                onTap: _openHabitsFilterSelector,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1116),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E2430)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _activeHabitFilter,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE8C07D)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Color(0xFFE8C07D), size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // (+) New Habit Button
              InkWell(
                onTap: _openNewHabitSheet,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF8A93A3), width: 1.5),
                  ),
                  child: const Icon(Icons.add, color: Color(0xFFEDEFF2), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Habits List
          if (habits.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Belum ada kebiasaan di sini.',
                style: TextStyle(color: Color(0xFF8A93A3), fontSize: 13),
              ),
            )
          else
            ...habits.map((h) {
              final col = colorForIdentity(h.identity);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    // Lead Button [✓ / ▶]
                    InkWell(
                      onTap: () => _handleHabitLeadTap(h),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: h.isDone ? col : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: col, width: 1.5),
                        ),
                        child: h.isDone
                            ? const Icon(Icons.check, color: Color(0xFF0E1116), size: 20)
                            : h.minutes != null && h.minutes! > 0
                                ? Icon(Icons.play_arrow_rounded, color: col, size: 22)
                                : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Habit Title & Subtitle
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (h.isVision) {
                            setState(() => _currentScreen = 'jelas');
                          } else {
                            _openHabitActionsSheet(h);
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: h.isDone ? const Color(0xFF8A93A3) : const Color(0xFFEDEFF2),
                                decoration: h.isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Text(
                              h.isSkipped
                                  ? 'tidak hari ini'
                                  : h.minutes != null
                                      ? '${h.minutes} menit'
                                      : h.identity,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF8A93A3)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Optional Image Thumbnail
                    if (h.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          h.imageUrl!,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),

                    // (+) More Actions Popover
                    InkWell(
                      onTap: () => _openHabitActionsSheet(h),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF8A93A3), width: 1.5),
                        ),
                        child: const Icon(Icons.add, color: Color(0xFFEDEFF2), size: 20),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _handleHabitLeadTap(HabitModel h) {
    if (h.minutes != null && h.minutes! > 0 && !h.isDone) {
      _startTimer(h.isVision ? 'Visualisasi masa depan' : h.title, h.minutes!, source: 'habit', sourceId: h.id, identity: h.identity);
    } else {
      setState(() {
        h.isDone = !h.isDone;
        h.isSkipped = false;
      });
      _showToast(h.isDone ? 'Kebiasaan selesai' : 'Dibatalkan');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 2: ZEN FOCUS TIMER VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTimerScreen(ThemeData theme) {
    final timer = _activeTimer ?? ActiveTimer(label: 'Fokus bebas', totalSeconds: 25 * 60, leftSeconds: 25 * 60, startHour: _hourNow());
    final isIdle = !timer.hasStarted;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => setState(() => _currentScreen = 'home'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161A22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E2430)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Color(0xFFEDEFF2), size: 22),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title & Status
              Text(
                timer.label,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2)),
              ),
              const SizedBox(height: 4),
              Text(
                timer.source != null
                    ? 'Saat selesai, hasilnya dicatat otomatis ke jam.'
                    : 'Timer bebas, tidak mencatat apa pun ke jam.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF8A93A3)),
              ),
              const Spacer(),

              // Big MM:SS Display
              Center(
                child: Text(
                  _formatMmSs(timer.leftSeconds),
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    color: Color(0xFFEDEFF2),
                  ),
                ),
              ),
              const Spacer(),

              // Preset Duration Chips (if idle)
              if (isIdle) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [15, 25, 45, 90].map((m) {
                    final selected = timer.totalSeconds == m * 60;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            timer.totalSeconds = m * 60;
                            timer.leftSeconds = m * 60;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161A22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? const Color(0xFFE8C07D) : const Color(0xFF1E2430),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            '$m mnt',
                            style: TextStyle(
                              color: selected ? const Color(0xFFE8C07D) : const Color(0xFFEDEFF2),
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Play / Pause Button
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (!timer.isRunning) {
                      timer.isRunning = true;
                      if (!timer.hasStarted) {
                        timer.hasStarted = true;
                        timer.startHour = _hourNow();
                      }
                    } else {
                      timer.isRunning = false;
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8C07D),
                  foregroundColor: const Color(0xFF161A22),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  timer.isRunning
                      ? 'Jeda'
                      : timer.hasStarted
                          ? 'Lanjut'
                          : 'Mulai',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),

              // Finish Now Button
              ElevatedButton(
                onPressed: () => _finishTimer(autoComplete: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2430),
                  foregroundColor: const Color(0xFFEDEFF2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Selesai sekarang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),

              // Cancel Button
              TextButton(
                onPressed: () {
                  setState(() {
                    _activeTimer = null;
                    _currentScreen = 'home';
                  });
                },
                child: const Text('Batalkan timer', style: TextStyle(color: Color(0xFF8A93A3))),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 3: CATATAN (NOTES) VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCatatanScreen(ThemeData theme) {
    final filtered = _notesFilter == 'important'
        ? _notes.where((n) => n.isImportant).toList()
        : _notes.where((n) => n.dateKey == _selectedNoteDate).toList();

    final noteInputCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _currentScreen = 'home'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161A22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1E2430)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Color(0xFFEDEFF2), size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Catatan',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildNoteChip('Kemarin', _notesFilter == 'date' && _selectedNoteDate == _dateKey(-1), () {
                      setState(() {
                        _notesFilter = 'date';
                        _selectedNoteDate = _dateKey(-1);
                      });
                    }),
                    const SizedBox(width: 8),
                    _buildNoteChip('Hari ini', _notesFilter == 'date' && _selectedNoteDate == _dateKey(0), () {
                      setState(() {
                        _notesFilter = 'date';
                        _selectedNoteDate = _dateKey(0);
                      });
                    }),
                    const SizedBox(width: 8),
                    _buildNoteChip('Penting', _notesFilter == 'important', () {
                      setState(() => _notesFilter = 'important');
                    }),
                    const SizedBox(width: 8),
                    _buildNoteChip('Tanggal ${_formatDateShort(_selectedNoteDate)}', false, _openDatePickerSheet),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notes List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada catatan.',
                          style: TextStyle(color: Color(0xFF8A93A3), fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final n = filtered[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161A22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF1E2430)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n.text,
                                        style: const TextStyle(fontSize: 14, color: Color(0xFFEDEFF2), height: 1.4),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDateShort(n.dateKey),
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF8A93A3)),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    n.isImportant ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: n.isImportant ? const Color(0xFFE8C07D) : const Color(0xFF8A93A3),
                                  ),
                                  onPressed: () => setState(() => n.isImportant = !n.isImportant),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Color(0xFF8A93A3), size: 18),
                                  onPressed: () {
                                    setState(() => _notes.removeWhere((item) => item.id == n.id));
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Input New Note
              if (_notesFilter != 'important') ...[
                TextField(
                  controller: noteInputCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Color(0xFFEDEFF2)),
                  decoration: InputDecoration(
                    hintText: 'Tulis catatan untuk ${_formatDateShort(_selectedNoteDate)}...',
                    hintStyle: const TextStyle(color: Color(0xFF8A93A3), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF161A22),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2430))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8C07D))),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    final t = noteInputCtrl.text.trim();
                    if (t.isEmpty) return;
                    setState(() {
                      _notes.insert(0, NoteItem(id: _nextId++, dateKey: _selectedNoteDate, text: t));
                    });
                    noteInputCtrl.clear();
                    _showToast('Catatan disimpan');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8C07D),
                    foregroundColor: const Color(0xFF161A22),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan Catatan', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteChip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF161A22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? const Color(0xFFE8C07D) : const Color(0xFF1E2430), width: active ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? const Color(0xFFE8C07D) : const Color(0xFFEDEFF2),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 4: JELAS (FUTURE SELF & GRATITUDE) VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildJelasScreen(ThemeData theme) {
    final visionHabit = _habits.firstWhere((h) => h.isVision, orElse: () => _habits.first);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            // Top Bar
            Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _currentScreen = 'home'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161A22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E2430)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Color(0xFFEDEFF2), size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Jelas',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Vision Quote
            const Text(
              'Jernihkan tujuan, jadilah dirimu di masa depan. Setelah kesulitan datang kemudahan. Sedikit itu lebih. Yang sederhana itu dahsyat. Lihat itu, setiap saat.',
              style: TextStyle(fontSize: 14, color: Color(0xFF8A93A3), height: 1.5),
            ),
            const SizedBox(height: 16),

            // Vision Banner
            InkWell(
              onTap: () {
                _showToast('Visual future self diatur');
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E2430), Color(0xFF2A2418)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF2B3340), style: BorderStyle.solid),
                ),
                alignment: Alignment.center,
                child: _futureSelfVisionImage != null
                    ? Image.network(_futureSelfVisionImage!, fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_outlined, color: Color(0xFF8A93A3), size: 32),
                          SizedBox(height: 6),
                          Text('Ketuk untuk menaruh gambar masa depanmu', style: TextStyle(color: Color(0xFF8A93A3), fontSize: 13)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // 3-Minute Visualization Button
            ElevatedButton(
              onPressed: () {
                _startTimer('Visualisasi masa depan', 3, source: 'habit', sourceId: visionHabit.id, identity: 'Masa depan');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8C07D),
                foregroundColor: const Color(0xFF161A22),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Mulai visualisasi 3 menit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            Text(
              visionHabit.isDone ? 'Sudah dilakukan hari ini' : 'Belum dilakukan hari ini',
              style: TextStyle(
                fontSize: 12,
                color: visionHabit.isDone ? const Color(0xFF5FD0A5) : const Color(0xFF8A93A3),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // 3 Top Emotions Checklist (Lampiran 3)
            const Text('3 emosi utama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
            const SizedBox(height: 10),
            ...[
              'Dekat dengan diriku di masa depan',
              'Lihat dengan matamu, rasakan dirimu di masa depan',
              'Tenang dan bersyukur',
            ].asMap().entries.map((entry) {
              final idx = entry.key;
              final text = entry.value;
              final isChecked = _topEmotions[idx];

              return InkWell(
                onTap: () => setState(() => _topEmotions[idx] = !_topEmotions[idx]),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isChecked ? const Color(0xFF5FD0A5) : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF5FD0A5), width: 1.5),
                        ),
                        child: isChecked ? const Icon(Icons.check, color: Color(0xFF0E1116), size: 18) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(fontSize: 14, color: Color(0xFFEDEFF2), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Gratitude Journal (3 Items)
            const Text('Jurnal syukur, 3 hal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
            const SizedBox(height: 10),
            ...[0, 1, 2].map((i) {
              final placeholders = [
                'Ya Allah, terima kasih atas karunia-Mu',
                'Terima kasih untuk...',
                'Lepaskan perfeksionisme, menuju penguasaan',
              ];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  maxLines: 2,
                  style: const TextStyle(color: Color(0xFFEDEFF2), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: placeholders[i],
                    hintStyle: const TextStyle(color: Color(0xFF8A93A3), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF161A22),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2430))),
                  ),
                  onChanged: (val) => _gratitudeEntries[i] = val,
                ),
              );
            }),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                final nonEmpty = _gratitudeEntries.where((s) => s.trim().isNotEmpty).toList();
                if (nonEmpty.isEmpty) {
                  _showToast('Tulis minimal satu hal');
                  return;
                }
                setState(() {
                  _notes.insert(0, NoteItem(
                    id: _nextId++,
                    dateKey: _dateKey(0),
                    text: 'Syukur: ${nonEmpty.join("; ")}',
                  ));
                  _gratitudeEntries[0] = '';
                  _gratitudeEntries[1] = '';
                  _gratitudeEntries[2] = '';
                });
                _showToast('Disimpan ke catatan hari ini');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2430),
                foregroundColor: const Color(0xFFEDEFF2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Simpan syukur ke catatan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MODAL BOTTOM SHEETS & POPUPS
  // ═══════════════════════════════════════════════════════════════════════════

  // ── 1. Top Menu Sheet ──
  void _openMenuSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161A22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
                const SizedBox(height: 12),
                _buildMenuRow(Icons.home_outlined, 'Beranda', () {
                  Navigator.pop(ctx);
                  setState(() => _currentScreen = 'home');
                }),
                _buildMenuRow(Icons.auto_awesome_outlined, 'Jelas: visual dan syukur', () {
                  Navigator.pop(ctx);
                  setState(() => _currentScreen = 'jelas');
                }),
                _buildMenuRow(Icons.book_outlined, 'Catatan', () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedNoteDate = _dateKey(0);
                    _notesFilter = 'date';
                    _currentScreen = 'catatan';
                  });
                }),
                _buildMenuRow(Icons.person_outline_rounded, 'Identitas preset', () {
                  Navigator.pop(ctx);
                  _openPresetIdentitySelector();
                }),
                _buildMenuRow(Icons.apps_rounded, 'Buka Apps Drawer', () {
                  Navigator.pop(ctx);
                  widget.onOpenAppDrawer();
                }),
                _buildMenuRow(Icons.settings_outlined, 'Pengaturan Launcher', () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FitrahSettingsScreen()));
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuRow(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFE8C07D)),
      title: Text(title, style: const TextStyle(color: Color(0xFFEDEFF2), fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF8A93A3)),
      onTap: onTap,
    );
  }

  // ── 2. Prayer Action Sheet ──
  void _openPrayerActionSheet(int index, Map<String, dynamic> prayer) {
    final name = prayer['name'] as String;
    final time = prayer['time'] as String;
    final pHour = prayer['hour'] as double;
    final isDone = _prayerDone[index] == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161A22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('$name $time', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
              const SizedBox(height: 14),
              ListTile(
                leading: Icon(isDone ? Icons.undo_rounded : Icons.check_circle_outline_rounded, color: const Color(0xFF5FD0A5)),
                title: Text(isDone ? 'Batalkan tanda sudah salat' : 'Tandai sudah salat', style: const TextStyle(color: Color(0xFFEDEFF2))),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _prayerDone[index] = !isDone);
                  _showToast(isDone ? 'Batal tandai $name' : '$name ditandai sudah salat');
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_alarm_rounded, color: Color(0xFFE8C07D)),
                title: const Text('Tambah blok 15 menit ke jam', style: TextStyle(color: Color(0xFFEDEFF2))),
                onTap: () {
                  Navigator.pop(ctx);
                  final res = _addBlock(pHour, pHour + 0.25, name, 'Baik hati');
                  _showToast(res ?? 'Blok $name ditambahkan ke jam');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 3. Add to Clock Modal (Conflict Detection) ──
  void _openAddToClockSheet(PresetItem p) {
    var startH = (_hourNow() * 2).ceil() / 2.0;
    while (_findConflict(startH, startH + p.minutes / 60.0) != null && startH < 24.0) {
      startH += 0.5;
    }

    final startCtrl = TextEditingController(text: _formatHour(startH));
    final durationCtrl = TextEditingController(text: p.minutes.toString());
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161A22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Tambahkan ke jam', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
                  const SizedBox(height: 4),
                  Text(p.name, style: const TextStyle(fontSize: 14, color: Color(0xFF8A93A3))),
                  const SizedBox(height: 14),

                  const Text('Mulai (HH:mm)', style: TextStyle(fontSize: 12, color: Color(0xFF8A93A3))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: startCtrl,
                    style: const TextStyle(color: Color(0xFFEDEFF2)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0E1116),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2430))),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text('Durasi (menit)', style: TextStyle(fontSize: 12, color: Color(0xFF8A93A3))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Color(0xFFEDEFF2)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0E1116),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2430))),
                    ),
                  ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(errorMessage!, style: const TextStyle(color: Color(0xFFE88F7D), fontSize: 12)),
                  ],

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      try {
                        final parts = startCtrl.text.split(':');
                        final s = int.parse(parts[0]) + int.parse(parts[1]) / 60.0;
                        final m = int.parse(durationCtrl.text);

                        final err = _addBlock(s, s + m / 60.0, p.name, p.identity);
                        if (err != null) {
                          setSheetState(() => errorMessage = err);
                        } else {
                          Navigator.pop(ctx);
                          _showToast('Ditambahkan ke jam ${_formatHour(s)}-${_formatHour(s + m / 60.0)}');
                        }
                      } catch (_) {
                        setSheetState(() => errorMessage = 'Format jam salah (gunakan JJ:mm)');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8C07D),
                      foregroundColor: const Color(0xFF161A22),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tambahkan', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── 4. Habit Actions Popover (Ya, Tidak, Mulai, Catatan, Gambar) ──
  void _openHabitActionsSheet(HabitModel h) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161A22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(h.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
              const SizedBox(height: 16),

              // 5 Action Buttons Grid (Lampiran 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHabitActionButton(Icons.check, 'Ya', () {
                    Navigator.pop(ctx);
                    setState(() {
                      h.isDone = true;
                      h.isSkipped = false;
                    });
                    _showToast('Ditandai selesai');
                  }),
                  _buildHabitActionButton(Icons.close, 'Tidak', () {
                    Navigator.pop(ctx);
                    setState(() {
                      h.isDone = false;
                      h.isSkipped = true;
                    });
                    _showToast('Ditandai tidak hari ini');
                  }),
                  _buildHabitActionButton(Icons.play_arrow_rounded, 'Mulai', () {
                    Navigator.pop(ctx);
                    _startTimer(h.isVision ? 'Visualisasi masa depan' : h.title, h.minutes ?? 5, source: 'habit', sourceId: h.id, identity: h.identity);
                  }),
                  _buildHabitActionButton(Icons.edit_note_rounded, 'Catatan', () {
                    Navigator.pop(ctx);
                    _openHabitReflectionSheet(h);
                  }),
                  _buildHabitActionButton(Icons.photo_outlined, 'Gambar', () {
                    Navigator.pop(ctx);
                    setState(() {
                      h.imageUrl = 'https://picsum.photos/200';
                    });
                    _showToast('Gambar ditambahkan');
                  }),
                ],
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE88F7D)),
                title: const Text('Hapus kebiasaan', style: TextStyle(color: Color(0xFFE88F7D))),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _habits.removeWhere((item) => item.id == h.id));
                  _showToast('Kebiasaan dihapus');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHabitActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 60,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF0E1116),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E2430)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFEDEFF2), size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8A93A3))),
          ],
        ),
      ),
    );
  }

  void _openHabitReflectionSheet(HabitModel h) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161A22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Refleksi Kebiasaan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
              const SizedBox(height: 4),
              Text(h.title, style: const TextStyle(color: Color(0xFF8A93A3), fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 4,
                style: const TextStyle(color: Color(0xFFEDEFF2)),
                decoration: InputDecoration(
                  hintText: 'Tulis refleksi atau jurnal...',
                  filled: true,
                  fillColor: const Color(0xFF0E1116),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2430))),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () {
                  final t = ctrl.text.trim();
                  if (t.isNotEmpty) {
                    setState(() {
                      _notes.insert(0, NoteItem(
                        id: _nextId++,
                        dateKey: _dateKey(0),
                        text: '[${h.title}] $t',
                      ));
                    });
                    Navigator.pop(ctx);
                    _showToast('Catatan disimpan');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8C07D),
                  foregroundColor: const Color(0xFF161A22),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Simpan ke Catatan Hari Ini', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 5. Block Detail Sheet (Mulai Timer, Tandai Selesai, Hapus) ──
  void _openBlockDetailSheet(BlockItem b) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161A22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(b.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
              const SizedBox(height: 4),
              Text(
                '${_formatHour(b.startHour)} sampai ${_formatHour(b.endHour)} (${_formatDuration(b.endHour - b.startHour)})',
                style: const TextStyle(fontSize: 13, color: Color(0xFF8A93A3)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded, color: Color(0xFFE8C07D)),
                title: const Text('Mulai timer', style: TextStyle(color: Color(0xFFEDEFF2))),
                onTap: () {
                  Navigator.pop(ctx);
                  final mins = math.max(1, ((b.endHour - b.startHour) * 60).round());
                  _startTimer(b.name, mins, source: 'block', sourceId: b.id, identity: b.identity);
                },
              ),
              ListTile(
                leading: Icon(b.isDone ? Icons.undo_rounded : Icons.check_circle_outline_rounded, color: const Color(0xFF5FD0A5)),
                title: Text(b.isDone ? 'Batalkan selesai' : 'Tandai selesai', style: const TextStyle(color: Color(0xFFEDEFF2))),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => b.isDone = !b.isDone);
                  _showToast(b.isDone ? 'Blok ditandai selesai' : 'Dibatalkan');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE88F7D)),
                title: const Text('Hapus dari jam', style: TextStyle(color: Color(0xFFE88F7D))),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _blocks.removeWhere((item) => item.id == b.id));
                  _showToast('Blok dihapus');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 6. Search Modal (Live Search across Blocks, Habits, Presets, Notes) ──
  void _openSearchSheet() {
    final searchCtrl = TextEditingController();
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161A22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final q = query.toLowerCase().trim();

            final matchedBlocks = _blocks.where((b) => !b.isSleep && b.name.toLowerCase().contains(q)).toList();
            final matchedHabits = _habits.where((h) => h.title.toLowerCase().contains(q)).toList();
            final matchedPresets = _presets.where((p) => p.name.toLowerCase().contains(q)).toList();
            final matchedNotes = _notes.where((n) => n.text.toLowerCase().contains(q)).toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: SizedBox(
                height: 480,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Cari aktivitas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      style: const TextStyle(color: Color(0xFFEDEFF2)),
                      decoration: InputDecoration(
                        hintText: 'Ketik untuk mencari...',
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8A93A3)),
                        filled: true,
                        fillColor: const Color(0xFF0E1116),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2430))),
                      ),
                      onChanged: (val) => setSheetState(() => query = val),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: q.isEmpty
                          ? const Center(child: Text('Cari blok, kebiasaan, preset, atau catatan.', style: TextStyle(color: Color(0xFF8A93A3))))
                          : ListView(
                              children: [
                                ...matchedBlocks.map((b) => ListTile(
                                      title: Text(b.name, style: const TextStyle(color: Color(0xFFEDEFF2))),
                                      subtitle: Text('${_formatHour(b.startHour)} - ${_formatHour(b.endHour)}', style: const TextStyle(color: Color(0xFF8A93A3))),
                                      trailing: const Text('Blok', style: TextStyle(color: Color(0xFFE8C07D), fontSize: 11)),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _openBlockDetailSheet(b);
                                      },
                                    )),
                                ...matchedHabits.map((h) => ListTile(
                                      title: Text(h.title, style: const TextStyle(color: Color(0xFFEDEFF2))),
                                      trailing: const Text('Kebiasaan', style: TextStyle(color: Color(0xFF5FD0A5), fontSize: 11)),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _openHabitActionsSheet(h);
                                      },
                                    )),
                                ...matchedPresets.map((p) => ListTile(
                                      title: Text(p.name, style: const TextStyle(color: Color(0xFFEDEFF2))),
                                      subtitle: Text('${p.minutes} menit', style: const TextStyle(color: Color(0xFF8A93A3))),
                                      trailing: const Text('Preset', style: TextStyle(color: Color(0xFF8FB8E8), fontSize: 11)),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _openAddToClockSheet(p);
                                      },
                                    )),
                                ...matchedNotes.map((n) => ListTile(
                                      title: Text(n.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFEDEFF2))),
                                      subtitle: Text(_formatDateShort(n.dateKey), style: const TextStyle(color: Color(0xFF8A93A3))),
                                      trailing: const Text('Catatan', style: TextStyle(color: Color(0xFFC3A6F0), fontSize: 11)),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        setState(() {
                                          _selectedNoteDate = n.dateKey;
                                          _notesFilter = 'date';
                                          _currentScreen = 'catatan';
                                        });
                                      },
                                    )),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── 7. New Preset Modal ──
  void _openNewPresetSheet() {
    final nameCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '45');
    String selectedId = _activePresetIdentity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161A22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Preset baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
                  const SizedBox(height: 12),
                  const Text('Nama', style: TextStyle(fontSize: 12, color: Color(0xFF8A93A3))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Color(0xFFEDEFF2)),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Deep SE',
                      filled: true,
                      fillColor: const Color(0xFF0E1116),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2430))),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text('Durasi (menit)', style: TextStyle(fontSize: 12, color: Color(0xFF8A93A3))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Color(0xFFEDEFF2)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0E1116),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2430))),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text('Identitas', style: TextStyle(fontSize: 12, color: Color(0xFF8A93A3))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedId,
                    dropdownColor: const Color(0xFF161A22),
                    style: const TextStyle(color: Color(0xFFEDEFF2)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0E1116),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2430))),
                    ),
                    items: kIdentities.map((id) => DropdownMenuItem(value: id.name, child: Text(id.name))).toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedId = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      final n = nameCtrl.text.trim();
                      final m = int.tryParse(durationCtrl.text) ?? 45;
                      if (n.isNotEmpty) {
                        setState(() {
                          _presets.add(PresetItem(id: _nextId++, name: n, minutes: m, identity: selectedId));
                          _activePresetIdentity = selectedId;
                        });
                        Navigator.pop(ctx);
                        _showToast('Preset disimpan');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8C07D),
                      foregroundColor: const Color(0xFF161A22),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Simpan Preset', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── 8. New Habit Modal ──
  void _openNewHabitSheet() {
    final titleCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    String selectedId = _activeHabitFilter == 'Semua' ? 'Programmer' : _activeHabitFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161A22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Kebiasaan baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
                  const SizedBox(height: 12),
                  const Text('Nama', style: TextStyle(fontSize: 12, color: Color(0xFF8A93A3))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Color(0xFFEDEFF2)),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Dzikir pagi',
                      filled: true,
                      fillColor: const Color(0xFF0E1116),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2430))),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text('Durasi menit (kosongkan jika tanpa timer)', style: TextStyle(fontSize: 12, color: Color(0xFF8A93A3))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Color(0xFFEDEFF2)),
                    decoration: InputDecoration(
                      hintText: 'Misal: 15',
                      filled: true,
                      fillColor: const Color(0xFF0E1116),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2430))),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text('Identitas', style: TextStyle(fontSize: 12, color: Color(0xFF8A93A3))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedId,
                    dropdownColor: const Color(0xFF161A22),
                    style: const TextStyle(color: Color(0xFFEDEFF2)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0E1116),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2430))),
                    ),
                    items: kIdentities.map((id) => DropdownMenuItem(value: id.name, child: Text(id.name))).toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedId = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      final n = titleCtrl.text.trim();
                      final m = int.tryParse(durationCtrl.text);
                      if (n.isNotEmpty) {
                        setState(() {
                          _habits.add(HabitModel(
                            id: _nextId++,
                            title: n,
                            identity: selectedId,
                            minutes: m,
                          ));
                        });
                        Navigator.pop(ctx);
                        _showToast('Kebiasaan ditambahkan');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8C07D),
                      foregroundColor: const Color(0xFF161A22),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Simpan Kebiasaan', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── 9. Preset Identity Selector ──
  void _openPresetIdentitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161A22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Identitas preset', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
              const SizedBox(height: 12),
              ...kIdentities.map((id) => ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: id.color, shape: BoxShape.circle),
                    ),
                    title: Text(id.name, style: const TextStyle(color: Color(0xFFEDEFF2), fontWeight: FontWeight.w600)),
                    trailing: _activePresetIdentity == id.name ? const Icon(Icons.check, color: Color(0xFFE8C07D)) : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _activePresetIdentity = id.name);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  // ── 10. Habits Filter Selector ──
  void _openHabitsFilterSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161A22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Filter kebiasaan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Semua', style: TextStyle(color: Color(0xFFEDEFF2), fontWeight: FontWeight.w600)),
                trailing: _activeHabitFilter == 'Semua' ? const Icon(Icons.check, color: Color(0xFFE8C07D)) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _activeHabitFilter = 'Semua');
                },
              ),
              ...kIdentities.map((id) => ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: id.color, shape: BoxShape.circle),
                    ),
                    title: Text(id.name, style: const TextStyle(color: Color(0xFFEDEFF2), fontWeight: FontWeight.w600)),
                    trailing: _activeHabitFilter == id.name ? const Icon(Icons.check, color: Color(0xFFE8C07D)) : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _activeHabitFilter = id.name);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  // ── 11. Date Picker Sheet ──
  void _openDatePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161A22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Pilih tanggal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
              const SizedBox(height: 12),
              ...List.generate(7, (i) {
                final k = _dateKey(-i);
                final label = i == 0 ? 'Hari ini' : '$i hari lalu';
                return ListTile(
                  title: Text(_formatDateShort(k), style: const TextStyle(color: Color(0xFFEDEFF2), fontWeight: FontWeight.w600)),
                  trailing: Text(label, style: const TextStyle(color: Color(0xFF8A93A3))),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedNoteDate = k;
                      _notesFilter = 'date';
                      _currentScreen = 'catatan';
                    });
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTER: Analog Clock Dial (Lampiran 1 & 2)
// ═════════════════════════════════════════════════════════════════════════════
class _SketchClockDialPainter extends CustomPainter {
  final double currentHour;
  final List<BlockItem> blocks;
  final List<Map<String, dynamic>> prayers;
  final Map<int, bool> prayerDone;
  final bool isPieMode;
  final bool is24hDial;
  final ActiveTimer? activeTimer;

  _SketchClockDialPainter({
    required this.currentHour,
    required this.blocks,
    required this.prayers,
    required this.prayerDone,
    required this.isPieMode,
    required this.is24hDial,
    this.activeTimer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 16;
    final isPm = currentHour >= 12.0;

    // Background circle
    final bgPaint = Paint()
      ..color = const Color(0xFF161A22)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF7A4A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius, borderPaint);

    // Hour Markers (0, 6, 12, 18 for 24h, or 12, 3, 6, 9 for 12h)
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final hoursToMark = is24hDial ? [0, 6, 12, 18] : [0, 3, 6, 9];

    for (final h in hoursToMark) {
      final angle = _hourToAngle(h.toDouble());
      final pt = _pointOnCircle(center, radius + 11, angle);
      final label = is24hDial ? h.toString() : (h == 0 ? '12' : h.toString());

      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Color(0xFF8A93A3), fontSize: 11, fontWeight: FontWeight.w600),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pt.dx - textPainter.width / 2, pt.dy - textPainter.height / 2));
    }

    // Upcoming Activity Guide Arc (amber within 3 hours)
    final upcoming = blocks.where((b) {
      if (b.isSleep) return false;
      final visible = is24hDial || (b.startHour >= 12.0) == isPm;
      return visible && b.startHour > currentHour && b.startHour - currentHour <= 3.0;
    }).toList()
      ..sort((a, b) => a.startHour.compareTo(b.startHour));

    if (upcoming.isNotEmpty) {
      final u = upcoming.first;
      final a1 = _hourToAngle(currentHour);
      final a2 = _hourToAngle(u.startHour);
      _drawArc(canvas, center, radius, a1, a2, const Color(0xFFE8C07D).withOpacity(0.35));
    }

    // Active Timer Arc (green while running)
    if (activeTimer != null && activeTimer!.hasStarted) {
      final a1 = _hourToAngle(activeTimer!.startHour);
      final a2 = _hourToAngle(currentHour);
      _drawArc(canvas, center, radius, a1, a2, const Color(0xFF5FD0A5).withOpacity(0.55));
    }

    // Scheduled Activity Wedges (Pie slices or Ring arcs)
    for (final b in blocks) {
      final visible = is24hDial || (b.startHour >= 12.0) == isPm;
      if (!visible) continue;

      final a1 = _hourToAngle(b.startHour);
      final a2 = _hourToAngle(b.endHour);
      final col = b.isSleep ? const Color(0xFF4A5B7D) : colorForIdentity(b.identity);

      if (isPieMode) {
        final wedgePaint = Paint()
          ..color = col.withOpacity(b.isDone ? 0.85 : 0.45)
          ..style = PaintingStyle.fill;
        final strokePaint = Paint()
          ..color = col.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        final path = Path()
          ..moveTo(center.dx, center.dy)
          ..arcTo(Rect.fromCircle(center: center, radius: radius - 2), a1, _sweep(a1, a2), false)
          ..close();

        canvas.drawPath(path, wedgePaint);
        canvas.drawPath(path, strokePaint);
      } else {
        // Ring Outline Mode
        final ringPaint = Paint()
          ..color = col.withOpacity(b.isDone ? 0.85 : 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14.0;

        canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 12), a1, _sweep(a1, a2), false, ringPaint);
      }

      // Wedge Text Label
      final sweepDeg = (_sweep(a1, a2) * 180 / math.pi).abs();
      if (sweepDeg > 20) {
        final midAngle = a1 + _sweep(a1, a2) / 2;
        final labelDist = isPieMode ? radius * 0.62 : radius * 0.45;
        final lp = _pointOnCircle(center, labelDist, midAngle);
        final displayName = b.name.length > 12 ? '${b.name.substring(0, 11)}…' : b.name;

        textPainter.text = TextSpan(
          text: displayName,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2)),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(lp.dx - textPainter.width / 2, lp.dy - textPainter.height / 2));
      }
    }

    // Outer Prayer Indicator Dots
    for (int i = 0; i < prayers.length; i++) {
      final pHour = prayers[i]['hour'] as double;
      final visible = is24hDial || (pHour >= 12.0) == isPm;
      if (!visible) continue;

      final pAngle = _hourToAngle(pHour);
      final pPos = _pointOnCircle(center, radius, pAngle);
      final isDone = prayerDone[i] == true;

      final dotPaint = Paint()
        ..color = isDone ? const Color(0xFF5FD0A5) : const Color(0xFFC97A5A)
        ..style = PaintingStyle.fill;
      final dotStroke = Paint()
        ..color = const Color(0xFF161A22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(pPos, 5.0, dotPaint);
      canvas.drawCircle(pPos, 5.0, dotStroke);
    }

    // Hour Hand Pointing to Current Time + Badge at Tip (Lampiran 1 & 2)
    final handAngle = _hourToAngle(currentHour);
    final handEnd = _pointOnCircle(center, radius - 6, handAngle);

    final handPaint = Paint()
      ..color = const Color(0xFFE8C07D)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, handEnd, handPaint);
    canvas.drawCircle(center, 5.0, Paint()..color = const Color(0xFFE8C07D));

    // Digital Badge at Hand Tip
    final badgePos = _pointOnCircle(center, radius - 26, handAngle);
    final timeStr = DateFormat('HH:mm').format(DateTime.now());

    textPainter.text = TextSpan(
      text: timeStr,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Color(0xFFE8C07D),
      ),
    );
    textPainter.layout();

    // Background pill for tip readout
    final pillRect = Rect.fromCenter(
      center: badgePos,
      width: textPainter.width + 6,
      height: textPainter.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF161A22),
    );
    textPainter.paint(canvas, Offset(badgePos.dx - textPainter.width / 2, badgePos.dy - textPainter.height / 2));
  }

  double _hourToAngle(double hour) {
    // 12 o'clock (top) is -pi / 2
    if (is24hDial) {
      final deg = hour * 15.0; // 360 / 24 = 15 deg per hour
      return (deg - 90.0) * math.pi / 180.0;
    } else {
      final deg = (hour % 12.0) * 30.0; // 360 / 12 = 30 deg per hour
      return (deg - 90.0) * math.pi / 180.0;
    }
  }

  double _sweep(double a1, double a2) {
    var diff = a2 - a1;
    while (diff < 0) {
      diff += 2 * math.pi;
    }
    while (diff > 2 * math.pi) {
      diff -= 2 * math.pi;
    }
    return diff;
  }

  Offset _pointOnCircle(Offset center, double radius, double angle) {
    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }

  void _drawArc(Canvas canvas, Offset center, double radius, double a1, double a2, Color color) {
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius - 2), a1, _sweep(a1, a2), false)
      ..close();

    canvas.drawPath(path, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _SketchClockDialPainter oldDelegate) => true;
}
