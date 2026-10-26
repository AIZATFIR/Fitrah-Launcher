import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/time_math.dart';
import '../../../models/activity.dart';
import '../../../providers/providers.dart';
import '../../focusclock/analog_clock_face.dart';
import '../models/launcher_settings.dart';
import '../providers/launcher_settings_provider.dart';
import 'fitrah_settings_screen.dart';

// ── Natural Theme Palettes for Focus Clock Home ──────────────────────────────
class _HomeThemeColors {
  final Color bg;
  final Color card;
  final Color cardElevated;
  final Color stroke;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final int clockThemeIndex;

  const _HomeThemeColors({
    required this.bg,
    required this.card,
    required this.cardElevated,
    required this.stroke,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.clockThemeIndex,
  });

  Color get background => bg;
  Color get cardAlt => cardElevated;

  factory _HomeThemeColors.fromPalette(String palette) {
    switch (palette) {
      case 'fino_green':
        return const _HomeThemeColors(
          bg: Color(0xFF0C120E),
          card: Color(0xFF141C16),
          cardElevated: Color(0xFF1A261D),
          stroke: Color(0xFF223327),
          accent: Color(0xFF70C050),
          textPrimary: Color(0xFFF0F5F2),
          textSecondary: Color(0xFF96A89B),
          textMuted: Color(0xFF67776B),
          clockThemeIndex: 1,
        );
      case 'sky_blue':
        return const _HomeThemeColors(
          bg: Color(0xFF0B1017),
          card: Color(0xFF121924),
          cardElevated: Color(0xFF182230),
          stroke: Color(0xFF1E2B3D),
          accent: Color(0xFF38BDF8),
          textPrimary: Color(0xFFEFF5F8),
          textSecondary: Color(0xFF90A3B5),
          textMuted: Color(0xFF5D7082),
          clockThemeIndex: 3,
        );
      case 'ocean_blue':
        return const _HomeThemeColors(
          bg: Color(0xFF080D15),
          card: Color(0xFF0F1826),
          cardElevated: Color(0xFF152236),
          stroke: Color(0xFF1A2C46),
          accent: Color(0xFF0284C7),
          textPrimary: Color(0xFFEEF4F8),
          textSecondary: Color(0xFF8A9EAF),
          textMuted: Color(0xFF536879),
          clockThemeIndex: 3,
        );
      case 'full_book':
        return const _HomeThemeColors(
          bg: Color(0xFF141210),
          card: Color(0xFF1D1916),
          cardElevated: Color(0xFF26211C),
          stroke: Color(0xFF332B24),
          accent: Color(0xFFE2BE82),
          textPrimary: Color(0xFFF7F2EB),
          textSecondary: Color(0xFFA89F95),
          textMuted: Color(0xFF736A60),
          clockThemeIndex: 5,
        );
      case 'natural_slate':
      default:
        return const _HomeThemeColors(
          bg: Color(0xFF0F1115),
          card: Color(0xFF161920),
          cardElevated: Color(0xFF1C202A),
          stroke: Color(0xFF232834),
          accent: Color(0xFFD4AF37),
          textPrimary: Color(0xFFF0F2F5),
          textSecondary: Color(0xFF9AA3B2),
          textMuted: Color(0xFF687182),
          clockThemeIndex: 1,
        );
    }
  }
}

// ── Identity System ──────────────────────────────────────────────────────────
class IdentityItem {
  final String id;
  String name;
  Color color;
  IdentityItem({required this.id, required this.name, required this.color});
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
  bool isDaily; // true = daily, false = one-time
  int? minutes;
  int elapsedSeconds; // Continuous saved progress!
  bool isRunning;
  String? imageUrl;

  HabitModel({
    required this.id,
    required this.title,
    required this.identity,
    this.isDone = false,
    this.isSkipped = false,
    this.isVision = false,
    this.isDaily = true,
    this.minutes,
    this.elapsedSeconds = 0,
    this.isRunning = false,
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
/// Multiplatform Super-App Homescreen implementing Lampiran 1 & Ecosystem Integration
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
  // Navigation State: 'home', 'timer', 'catatan', 'jelas', 'fullscreen_focus'
  String _currentScreen = 'home';

  // Clock View Settings (AnalogClockFace from Left Focus Clock is default)
  bool _isPieMode = false;
  bool _isListView = false;
  bool _is24hDial = true;

  // Header Toggle: false = Focus Clock Agenda Carousel, true = Prayer Schedule Bar
  bool _showPrayerSchedule = false;

  // Selected Note Filter
  late String _selectedNoteDate;
  String _notesFilter = 'date'; // 'date' | 'important'

  // Timer Tick
  late Timer _periodicTimer;
  late DateTime _currentTime;

  // Active Focus Timer
  ActiveTimer? _activeTimer;

  // Next ID Counter
  int _nextId = 300;

  // Future Self / Jelas State
  final List<bool> _topEmotions = [true, true, false];
  final List<String> _gratitudeEntries = ['', '', ''];
  String? _futureSelfVisionImage;

  // Prayer Done Status
  final Map<int, bool> _prayerDone = {};

  // Dynamic Identities List
  late List<IdentityItem> _identities;

  // Data Collections
  late List<BlockItem> _blocks;
  late List<PresetItem> _presets;
  late List<HabitModel> _habits;
  late List<NoteItem> _notes;
  late List<String> _dumpedTasks;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _selectedNoteDate = _dateKey(0);

    // Initial Identities
    _identities = [
      IdentityItem(id: 'programmer', name: 'Programmer', color: const Color(0xFFE8C07D)),
      IdentityItem(id: 'pembaca', name: 'Pembaca', color: const Color(0xFF8FB8E8)),
      IdentityItem(id: 'binaragawan', name: 'Binaragawan', color: const Color(0xFFE88F7D)),
      IdentityItem(id: 'baik_hati', name: 'Baik hati', color: const Color(0xFF5FD0A5)),
      IdentityItem(id: 'masa_depan', name: 'Masa depan', color: const Color(0xFFC3A6F0)),
    ];

    // Seed Blocks (Focus Clock schedule)
    _blocks = [
      BlockItem(id: 1, startHour: 22.0, endHour: 24.0, name: 'Tidur', isSleep: true),
      BlockItem(id: 2, startHour: 0.0, endHour: 4.5, name: 'Tidur', isSleep: true),
      BlockItem(id: 3, startHour: 19.5, endHour: 21.0, name: 'SE - Orkestrasi AI', identity: 'Programmer'),
    ];

    // Seed Presets by Identity
    _presets = [
      PresetItem(id: 1, name: 'SE - Orkestrasi AI', minutes: 90, identity: 'Programmer'),
      PresetItem(id: 2, name: 'LKS ITSSB', minutes: 45, identity: 'Programmer'),
      PresetItem(id: 3, name: 'Baca Buku', minutes: 15, identity: 'Pembaca'),
      PresetItem(id: 4, name: 'Latihan Beban', minutes: 30, identity: 'Binaragawan'),
      PresetItem(id: 5, name: 'Sedekah & Silaturahmi', minutes: 15, identity: 'Baik hati'),
      PresetItem(id: 6, name: 'Visualisasi Cita-cita', minutes: 10, identity: 'Masa depan'),
    ];

    // Seed Habits by Identity (Continuous Saved Progress)
    _habits = [
      HabitModel(
        id: 1,
        title: 'Deep Coding & Refactoring 30m',
        identity: 'Programmer',
        isDone: false,
        isDaily: true,
        minutes: 30,
        elapsedSeconds: 0,
      ),
      HabitModel(id: 2, title: 'Selalu bersikap baik', identity: 'Baik hati', isDone: true, isDaily: true),
      HabitModel(
        id: 3,
        title: 'Visualisasikan future selfmu, pejamkan mata, lakukan apa yang future selfmu lakukan',
        identity: 'Masa depan',
        isDone: false,
        isVision: true,
        isDaily: true,
        minutes: 3,
        elapsedSeconds: 0,
      ),
      HabitModel(
        id: 4,
        title: 'Baca 15 menit: Lord of Power',
        identity: 'Pembaca',
        isDone: false,
        isDaily: true,
        minutes: 15,
        elapsedSeconds: 300, // 5m saved progress!
      ),
      HabitModel(id: 5, title: 'Jurnal sampai pikiran lega', identity: 'Pembaca', isDone: true, isDaily: true),
      HabitModel(
        id: 6,
        title: 'Push up 20 reps & Dips',
        identity: 'Binaragawan',
        isDone: false,
        isDaily: true,
        minutes: 20,
        elapsedSeconds: 0,
      ),
    ];

    // Seed Notes
    _notes = [
      NoteItem(id: 1, dateKey: _dateKey(-1), text: 'Tauhid satu-satunya kebenaran. Sedikit itu lebih.', isImportant: true),
      NoteItem(id: 2, dateKey: _dateKey(0), text: 'Lepaskan perfeksionisme, menuju penguasaan.', isImportant: false),
    ];

    // Seed Dumped Tasks (Google Tasks / Dump Inbox)
    _dumpedTasks = [
      'Selesaikan modul UI Focus Clock',
      'Submit LKS ITSSB draft',
      'Beli suplemen gym & air galon',
    ];

    // 1-Second Timer Tick
    _periodicTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentTime = DateTime.now();

        // Tick Active Timer
        if (_activeTimer != null && _activeTimer!.isRunning) {
          if (_activeTimer!.leftSeconds > 0) {
            _activeTimer!.leftSeconds--;
          } else {
            _finishTimer(autoComplete: true);
          }
        }

        // Tick any running habit timer
        for (final h in _habits) {
          if (h.isRunning && h.minutes != null) {
            h.elapsedSeconds++;
            if (h.elapsedSeconds >= h.minutes! * 60) {
              h.isRunning = false;
              h.isDone = true;
              _showToast('${h.title} selesai!');
            }
          }
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _syncInitialActivitiesWithSharedRepo();
    });
  }

  Future<void> _syncInitialActivitiesWithSharedRepo() async {
    try {
      final now = DateTime.now();
      final today = dateOnly(now);
      final repo = ref.read(activityRepoProvider);
      final existing = await repo.watchByDate(today).first;
      if (existing.isEmpty) {
        for (final b in _blocks) {
          final stMin = (b.startHour * 60).round();
          final enMin = (b.endHour * 60).round();
          final half = b.startHour < 12.0 ? AmPmHalf.am : AmPmHalf.pm;
          final color = _colorForIdentity(b.identity);
          await repo.upsert(Activity()
            ..title = b.name
            ..startMinute = stMin % 720
            ..endMinute = enMin % 720
            ..ampmHalf = half
            ..colorValue = color.value
            ..date = today
            ..description = b.identity != null ? 'Identitas: ${b.identity}' : '');
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _periodicTimer.cancel();
    super.dispose();
  }

  // ── Color & Identity Helpers ───────────────────────────────────────────────
  Color _colorForIdentity(String? name) {
    for (final id in _identities) {
      if (id.name.toLowerCase() == name?.toLowerCase()) return id.color;
    }
    return const Color(0xFF8A93A3);
  }

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

  // ── Convert In-Memory Blocks to Focus Clock Activity Models ───────────────
  List<Activity> _toFocusClockActivities() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _blocks.map((b) {
      final stMin = (b.startHour * 60).round();
      final enMin = (b.endHour * 60).round();
      final half = b.startHour < 12.0 ? AmPmHalf.am : AmPmHalf.pm;
      return Activity()
        ..title = b.name
        ..startMinute = stMin % 720
        ..endMinute = enMin % 720
        ..ampmHalf = half
        ..colorValue = _colorForIdentity(b.identity).value
        ..date = today
        ..id = b.id;
    }).toList();
  }

  // Current Activity Calculation for instant user clarity
  Map<String, dynamic> _getCurrentActivityInfo() {
    final hr = _hourNow();
    for (final b in _blocks) {
      if (hr >= b.startHour && hr <= b.endHour) {
        final remainingMins = ((b.endHour - hr) * 60).round();
        return {
          'name': b.name,
          'remaining': remainingMins > 0 ? 'sisa ${remainingMins}m' : 'segera berakhir',
          'isFree': false,
          'color': _colorForIdentity(b.identity),
        };
      }
    }
    return {
      'name': 'Waktu Luang',
      'remaining': 'Tidak ada jadwal aktif',
      'isFree': true,
      'color': const Color(0xFF8A93A3),
    };
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
    final now = DateTime.now();
    final today = dateOnly(now);
    final stMin = (start * 60).round();
    final enMin = (end * 60).round();
    final half = start < 12.0 ? AmPmHalf.am : AmPmHalf.pm;
    final color = _colorForIdentity(identity);

    final act = Activity()
      ..title = name
      ..startMinute = toDbMinute(stMin)
      ..endMinute = toDbEndMinute(enMin, half)
      ..ampmHalf = half
      ..colorValue = color.value
      ..date = today
      ..description = identity != null ? 'Identitas: $identity' : '';

    try {
      ref.read(activityRepoProvider).upsert(act);
    } catch (_) {}

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
          h.isRunning = false;
          h.isSkipped = false;
          h.elapsedSeconds = h.minutes != null ? h.minutes! * 60 : timer.totalSeconds;
          message = 'Kebiasaan ditandai selesai';
          break;
        }
      }
    } else if (src == 'preset') {
      final nowH = _hourNow();
      var st = timer.startHour;
      var en = nowH;
      if (en - st < 0.05) en = st + 0.25; // minimum 15 mins
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

    // Switch between full screens
    if (_currentScreen == 'fullscreen_focus') {
      return _buildFullscreenFocusMode();
    } else if (_currentScreen == 'timer') {
      return _buildTimerScreen(theme);
    } else if (_currentScreen == 'catatan') {
      return _buildCatatanScreen(theme);
    } else if (_currentScreen == 'jelas') {
      return _buildJelasScreen(theme);
    }

    return _buildHomeScreen(settings, theme);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 1: HOME VIEW (Lampiran 1 with Stacked Identity Cards)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHomeScreen(LauncherSettings settings, ThemeData theme) {
    final prayers = _getPrayerList(settings);
    final nextPrayer = _calculateNextPrayer(prayers);
    final hr = _hourNow();
    final currentAct = _getCurrentActivityInfo();
    final tc = _HomeThemeColors.fromPalette(settings.themePalette);

    final todayNotesCount = _notes.where((n) => n.dateKey == _dateKey(0)).length;
    final importantNotesCount = _notes.where((n) => n.isImportant).length;

    return Scaffold(
      backgroundColor: tc.bg,
      bottomNavigationBar: _buildBottomFloatingDock(tc),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 120),
              children: [
                // ── Top Header Bar (Now/Next Carousel or Prayer Timeline) ──
                _buildTopHeaderBar(prayers, nextPrayer, tc),
                const SizedBox(height: 10),

                // ── Direct App Launcher Access Bar (Niagara Integration) ──
                _buildQuickLauncherBar(tc),
                const SizedBox(height: 12),

                // ── Middle Section: Left Rail + Center Focus Clock Face + Right Tools ──
                SizedBox(
                  height: 310,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Rail (Notes & Dates)
                      _buildLeftRail(todayNotesCount, importantNotesCount, tc),
                      const SizedBox(width: 8),

                      // Center: Official Focus Clock Analog Dial + Instant Clarity Badge
                      Expanded(
                        child: _isListView
                            ? _buildChronologicalListView(tc)
                            : _buildCenterFocusClockDial(hr, currentAct, tc),
                      ),
                      const SizedBox(width: 8),

                      // Right Tools Rail (Compact, Separated as in Sketch)
                      _buildRightToolsRail(tc),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Task & Habit Dump Section (Dump Inbox -> Direct Clock Schedule) ──
                _buildTaskDumpSection(tc),
                const SizedBox(height: 14),

                // ── Vertical Stack of Identity Cards (Lampiran 1 & 3) ──
                ..._identities.map((identity) => _buildIdentityCard(identity, tc)),
                const SizedBox(height: 12),

                // ── (+) Tambah Identitas Baru Button ──
                _buildAddIdentityButton(tc),
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

  // ── Top Header Bar (Now/Next Carousel or Prayer Timeline) ──────────────────
  Widget _buildTopHeaderBar(List<Map<String, dynamic>> prayers, Map<String, dynamic> nextPrayer, _HomeThemeColors tc) {
    return Row(
      children: [
        // Hamburger Menu Button
        InkWell(
          onTap: _openMenuSheet,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tc.stroke),
            ),
            child: Icon(Icons.menu_rounded, color: tc.textPrimary, size: 22),
          ),
        ),
        const SizedBox(width: 8),

        // Main Content: Prayer Timeline or Agenda Carousel
        Expanded(
          child: _showPrayerSchedule
              ? Row(
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
                              color: tc.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isNext ? tc.accent : tc.stroke,
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
                                            ? tc.accent
                                            : tc.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p['time'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDone ? const Color(0xFF5FD0A5) : tc.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                )
              : _buildAgendaCarousel(tc),
        ),
        const SizedBox(width: 6),

        // Theme Quick Selector Button
        InkWell(
          onTap: _openThemePickerSheet,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tc.stroke),
            ),
            child: Icon(
              Icons.palette_outlined,
              color: tc.accent,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Toggle Switch Button: Agenda vs Prayer Timeline
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _showPrayerSchedule = !_showPrayerSchedule);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _showPrayerSchedule ? tc.accent.withOpacity(0.18) : tc.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showPrayerSchedule ? tc.accent : tc.stroke,
              ),
            ),
            child: Icon(
              _showPrayerSchedule ? Icons.mosque_rounded : Icons.schedule_rounded,
              color: _showPrayerSchedule ? tc.accent : tc.textSecondary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // Horizontal Scrollable Agenda Carousel (Focus Clock Now & Next)
  Widget _buildAgendaCarousel(_HomeThemeColors tc) {
    final nonSleep = _blocks.where((b) => !b.isSleep).toList()
      ..sort((a, b) => a.startHour.compareTo(b.startHour));

    if (nonSleep.isEmpty) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tc.stroke),
        ),
        alignment: Alignment.centerLeft,
        child: Text('Belum ada jadwal. Tambah di bawah.', style: TextStyle(color: tc.textSecondary, fontSize: 12)),
      );
    }

    final hr = _hourNow();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: nonSleep.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final b = nonSleep[i];
          final isCurrent = hr >= b.startHour && hr <= b.endHour;
          final col = _colorForIdentity(b.identity);

          return InkWell(
            onTap: () => _openBlockDetailSheet(b),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tc.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent ? col : tc.stroke,
                  width: isCurrent ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                          color: isCurrent ? Colors.white : tc.textPrimary,
                        ),
                      ),
                      Text(
                        '${_formatHour(b.startHour)}-${_formatHour(b.endHour)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isCurrent ? col : tc.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Center Focus Clock Analog Face Dial ───────────────────────────────────
  // ── Center Focus Clock Analog Face Dial (Compact 215x215, Clean Pie / Dial) ──
  Widget _buildCenterFocusClockDial(double hr, Map<String, dynamic> currentAct, _HomeThemeColors tc) {
    final currentHalf = _currentTime.hour < 12 ? AmPmHalf.am : AmPmHalf.pm;
    final liveActs = ref.watch(activitiesByDateProvider).valueOrNull ?? [];
    final effectiveActivities = liveActs.isNotEmpty ? liveActs : _toFocusClockActivities();

    return Column(
      children: [
        // Center Clock: Clean Pie Arc Chart or Focus Clock Official Dial
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _openScheduleToClockSheet(
                title: '',
                initialDurationMinutes: 60,
                identity: 'Programmer',
              );
            },
            child: Center(
              child: SizedBox(
                width: 215,
                height: 215,
                child: _isPieMode
                    ? CustomPaint(
                        painter: _CleanPieClockPainter(
                          now: _currentTime,
                          activities: effectiveActivities,
                          is24h: _is24hDial,
                        ),
                      )
                    : AnalogClockFace(
                        now: _currentTime,
                        activities: effectiveActivities,
                        tasks: const [],
                        viewHalf: currentHalf,
                        clockHandsMode: 1,
                        is24hDial: _is24hDial,
                        is24hTime: _is24hDial,
                        showCurrentTime: true,
                        clockFaceTheme: tc.clockThemeIndex,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Instant User Clarity Status Badge (Current Time + What Am I Doing Now)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatHour(hr),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: tc.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (currentAct['color'] as Color).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (currentAct['color'] as Color).withOpacity(0.5), width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: currentAct['color'] as Color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        currentAct['remaining'] != null
                            ? '${currentAct['name']} (${currentAct['remaining']})'
                            : currentAct['name'],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: currentAct['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Quick Button: Pasang Jadwal ke Jam
        InkWell(
          onTap: () => _openScheduleToClockSheet(
            title: '',
            initialDurationMinutes: 60,
            identity: 'Programmer',
          ),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tc.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tc.accent.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: tc.accent, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Pasang Jadwal ke Jam',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tc.accent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Left Rail (Enlarged: Kemarin, Catatan, Penting, Tanggal) ───────────────
  Widget _buildLeftRail(int todayNotesCount, int importantNotesCount, _HomeThemeColors tc) {
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          // Kemarin
          Expanded(
            child: _buildRailButton(
              title: 'Kemarin',
              tc: tc,
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

          // Catatan (Journal)
          Expanded(
            child: _buildRailButton(
              title: 'Catatan',
              badge: todayNotesCount.toString(),
              tc: tc,
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
              tc: tc,
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
              tc: tc,
              onTap: _openDatePickerSheet,
            ),
          ),
          const SizedBox(height: 8),

          // 3 Fulfillment Status Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFulfillmentDot(true, tc),
              const SizedBox(width: 4),
              _buildFulfillmentDot(true, tc),
              const SizedBox(width: 4),
              _buildFulfillmentDot(todayNotesCount > 0, tc),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFulfillmentDot(bool active, _HomeThemeColors tc) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF5FD0A5) : tc.stroke,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildRailButton({
    required String title,
    String? badge,
    required VoidCallback onTap,
    required _HomeThemeColors tc,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tc.stroke, width: 1.2),
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
                style: TextStyle(fontSize: 12, color: tc.textPrimary, fontWeight: FontWeight.w700, height: 1.2),
              ),
              if (badge != null) ...[
                const SizedBox(height: 2),
                Text(
                  badge,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: tc.accent),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Right Tools Rail (Enlarged, With Direct App Launcher & Theme Buttons) ──
  Widget _buildRightToolsRail(_HomeThemeColors tc) {
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          // Aplikasi (Direct Niagara App Drawer Launcher!)
          Expanded(
            child: _buildToolButton(
              icon: Icons.apps_rounded,
              label: 'Aplikasi',
              isActive: false,
              accentColor: tc.accent,
              tc: tc,
              onTap: widget.onOpenAppDrawer,
            ),
          ),
          const SizedBox(height: 4),

          // Tema (1-tap Natural Theme Selector)
          Expanded(
            child: _buildToolButton(
              icon: Icons.palette_outlined,
              label: 'Tema',
              isActive: false,
              accentColor: tc.accent,
              tc: tc,
              onTap: _openThemePickerSheet,
            ),
          ),
          const SizedBox(height: 4),

          // Ganti (Pie vs Dial)
          Expanded(
            child: _buildToolButton(
              icon: _isPieMode ? Icons.watch_later_outlined : Icons.pie_chart_outline_rounded,
              label: 'Ganti',
              isActive: !_isPieMode,
              tc: tc,
              onTap: () => setState(() => _isPieMode = !_isPieMode),
            ),
          ),
          const SizedBox(height: 4),

          // Daftar (List vs Dial)
          Expanded(
            child: _buildToolButton(
              icon: Icons.format_list_bulleted_rounded,
              label: 'Daftar',
              isActive: _isListView,
              tc: tc,
              onTap: () => setState(() => _isListView = !_isListView),
            ),
          ),
          const SizedBox(height: 4),

          // 24 / 12 jam
          Expanded(
            child: _buildToolButton(
              icon: Icons.access_time_rounded,
              label: _is24hDial ? '24 jam' : '12 jam',
              isActive: _is24hDial,
              tc: tc,
              onTap: () => setState(() => _is24hDial = !_is24hDial),
            ),
          ),
          const SizedBox(height: 4),

          // Cari
          Expanded(
            child: _buildToolButton(
              icon: Icons.search_rounded,
              label: 'Cari',
              isActive: false,
              tc: tc,
              onTap: _openSearchSheet,
            ),
          ),
          const SizedBox(height: 4),

          // Timer (Opens Focus Timer Hub)
          Expanded(
            child: _buildToolButton(
              icon: Icons.timer_outlined,
              label: 'Timer',
              isActive: _activeTimer != null && _activeTimer!.isRunning,
              tc: tc,
              onTap: _openFocusTimerHub,
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
    Color? accentColor,
    required _HomeThemeColors tc,
  }) {
    final activeCol = accentColor ?? tc.accent;
    final inactiveCol = tc.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeCol.withOpacity(0.6) : tc.stroke,
            width: 1.2,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? activeCol : (accentColor ?? inactiveCol), size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isActive ? activeCol : (accentColor ?? inactiveCol),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chronological List View Fallback ──────────────────────────────────────
  Widget _buildChronologicalListView(_HomeThemeColors tc) {
    final nonSleep = _blocks.where((b) => !b.isSleep).toList()
      ..sort((a, b) => a.startHour.compareTo(b.startHour));

    if (nonSleep.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tc.stroke),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Text(
          'Belum ada blok hari ini.\nTambahkan dari preset di bawah.',
          textAlign: TextAlign.center,
          style: TextStyle(color: tc.textSecondary, fontSize: 13),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.stroke),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: nonSleep.length,
        separatorBuilder: (_, __) => Divider(color: tc.stroke, height: 1),
        itemBuilder: (context, i) {
          final b = nonSleep[i];
          final col = _colorForIdentity(b.identity);

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: InkWell(
              onTap: () {
                final durationMins = math.max(1, ((b.endHour - b.startHour) * 60).round());
                _startTimer(b.name, durationMins, source: 'block', sourceId: b.id, identity: b.identity);
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 34,
                height: 34,
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
                fontSize: 13,
                color: b.isDone ? tc.textMuted : tc.textPrimary,
              ),
            ),
            subtitle: Text(
              '${_formatHour(b.startHour)} - ${_formatHour(b.endHour)}',
              style: TextStyle(fontSize: 11, color: tc.textSecondary),
            ),
            onTap: () => _openBlockDetailSheet(b),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION: VERTICAL STACK OF IDENTITY CARDS (Lampiran 1 & 3)
  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION: VERTICAL STACK OF IDENTITY CARDS (Lampiran 1 & 3)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildIdentityCard(IdentityItem identity, _HomeThemeColors tc) {
    final presets = _presets.where((p) => p.identity.toLowerCase() == identity.name.toLowerCase()).toList();
    final habits = _habits.where((h) => h.identity.toLowerCase() == identity.name.toLowerCase()).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tc.stroke, width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Identity Card Header ──
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: identity.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Identitas: ${identity.name}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: identity.color,
                  ),
                ),
              ),

              // (+) Add Item to This Identity Button
              InkWell(
                onTap: () => _openAddIdentityItemSheet(identity),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tc.cardElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: identity.color.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: identity.color, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Tambah',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: identity.color),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── 1. Preset Time Blocks of This Identity ──
          if (presets.isNotEmpty) ...[
            Text(
              'Preset Blok Waktu',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tc.textSecondary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            ...presets.map((p) => _buildPresetRow(p, identity.color, tc)),
            const SizedBox(height: 10),
          ],

          // ── 2. Habits of This Identity (With Continuous Saved Progress!) ──
          if (habits.isNotEmpty) ...[
            Text(
              'Kebiasaan & Rutinitas',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tc.textSecondary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            ...habits.map((h) => _buildHabitRow(h, identity.color, tc)),
          ],

          if (presets.isEmpty && habits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada preset atau kebiasaan untuk ${identity.name}. Tap + Tambah.',
                style: TextStyle(color: tc.textSecondary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPresetRow(PresetItem p, Color identityColor, _HomeThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // ▶ Play Button (Starts Timer & Records Block on Finish)
          InkWell(
            key: ValueKey('preset_play_${p.id}'),
            onTap: () => _startTimer(p.name, p.minutes, source: 'preset', sourceId: p.id, identity: p.identity),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: identityColor, width: 1.5),
              ),
              child: Icon(Icons.play_arrow_rounded, color: identityColor, size: 20),
            ),
          ),
          const SizedBox(width: 10),

          // Title & Duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: tc.textPrimary),
                ),
                Text(
                  '${p.minutes} menit',
                  style: TextStyle(fontSize: 11, color: tc.textSecondary),
                ),
              ],
            ),
          ),

          // (+) Add to Clock Button
          InkWell(
            onTap: () => _openAddToClockSheet(p),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: tc.stroke, width: 1.5),
              ),
              child: Icon(Icons.add, color: tc.textPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitRow(HabitModel h, Color identityColor, _HomeThemeColors tc) {
    final hasTimer = h.minutes != null && h.minutes! > 0;
    final totalSecs = hasTimer ? h.minutes! * 60 : 0;
    final elapsedSecs = h.elapsedSeconds;
    final progress = hasTimer ? (elapsedSecs / totalSecs).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // ── Far Left: Continuous Progress Button & Timer Play/Pause ──
          InkWell(
            onTap: () => _toggleHabitTimerOrDone(h),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: h.isDone ? identityColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: identityColor, width: 1.5),
              ),
              child: h.isDone
                  ? Icon(Icons.check, color: tc.bg, size: 20)
                  : hasTimer
                      ? Icon(
                          h.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: identityColor,
                          size: 20,
                        )
                      : null,
            ),
          ),
          const SizedBox(width: 10),

          // Habit Title, Recurrence & Continuous Progress Bar
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
                      fontSize: 13,
                      color: h.isDone ? tc.textMuted : tc.textPrimary,
                      decoration: h.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Progress Bar & Duration/Recurrence Text
                  Row(
                    children: [
                      Text(
                        h.isDaily ? 'Harian' : 'Sekali saja',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: h.isDaily ? const Color(0xFF5FD0A5) : const Color(0xFF8FB8E8),
                        ),
                      ),
                      if (hasTimer) ...[
                        const SizedBox(width: 6),
                        Text(
                          '•  ${(elapsedSecs ~/ 60)} / ${h.minutes}m',
                          style: TextStyle(fontSize: 10, color: tc.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: tc.stroke,
                              valueColor: AlwaysStoppedAnimation<Color>(identityColor),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // (+) More Actions Popover (Ya, Tidak, Mulai, Catatan, Gambar)
          InkWell(
            onTap: () => _openHabitActionsSheet(h),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: tc.stroke, width: 1.5),
              ),
              child: Icon(Icons.add, color: tc.textPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleHabitTimerOrDone(HabitModel h) {
    HapticFeedback.selectionClick();
    if (h.minutes != null && h.minutes! > 0 && !h.isDone) {
      setState(() {
        h.isRunning = !h.isRunning;
      });
      _showToast(h.isRunning ? 'Timer ${h.title} berjalan' : 'Timer dijeda');
    } else {
      setState(() {
        h.isDone = !h.isDone;
        h.isRunning = false;
        h.isSkipped = false;
      });
      _showToast(h.isDone ? 'Kebiasaan selesai' : 'Dibatalkan');
    }
  }

  // ── (+) Tambah Identitas Baru Button ──
  Widget _buildAddIdentityButton(_HomeThemeColors tc) {
    return InkWell(
      onTap: _openCreateNewIdentityDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tc.accent.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: tc.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              'Tambah Blok Identitas Baru',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tc.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 2: FOCUS TIMER HUB & FULLSCREEN ZEN MODE
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
              // Back Button & Fullscreen Zen Lockscreen Mode Trigger
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                  // Fullscreen Zen Button
                  IconButton(
                    icon: const Icon(Icons.fullscreen_rounded, color: Color(0xFFE8C07D), size: 28),
                    tooltip: 'Mode Zen Layar Penuh (Lockscreen)',
                    onPressed: () => setState(() => _currentScreen = 'fullscreen_focus'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

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

              // Quick Chips (if idle)
              if (isIdle) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [15, 25, 45, 60, 90].map((m) {
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                const SizedBox(height: 18),
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // Pure Fullscreen Zen / Lockscreen Focus View (No Launcher leakage!)
  Widget _buildFullscreenFocusMode() {
    final timer = _activeTimer ?? ActiveTimer(label: 'Fokus', totalSeconds: 25 * 60, leftSeconds: 25 * 60, startHour: _hourNow());

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white70, size: 30),
                  onPressed: () => setState(() => _currentScreen = 'timer'),
                ),
              ),
              const Spacer(),

              Center(
                child: Text(
                  timer.label,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Text(
                  _formatMmSs(timer.leftSeconds),
                  style: const TextStyle(
                    fontSize: 88,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -3,
                    color: Color(0xFFE8C07D),
                  ),
                ),
              ),
              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 48,
                    icon: Icon(
                      timer.isRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                      color: const Color(0xFFE8C07D),
                    ),
                    onPressed: () {
                      setState(() {
                        timer.isRunning = !timer.isRunning;
                      });
                    },
                  ),
                  IconButton(
                    iconSize: 48,
                    icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF5FD0A5)),
                    onPressed: () {
                      _finishTimer(autoComplete: false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 3: CATATAN (DAILY NOTES & LIGHT JOURNALING WITH TEMPLATES)
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
                    'Catatan Harian',
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
              const SizedBox(height: 14),

              // Journal Templates Chips
              if (_notesFilter != 'important') ...[
                const Text('Template Jurnal:', style: TextStyle(fontSize: 11, color: Color(0xFF8A93A3), fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTemplateChip('🌅 Niat Pagi', 'Niat Pagi:\n1. Goal utama:\n2. Sikap yang kuinginkan:\n3. Rasa syukur:', noteInputCtrl),
                      const SizedBox(width: 8),
                      _buildTemplateChip('🌙 Refleksi Malam', 'Refleksi Malam:\n- Yang sudah terlaksana:\n- Pelajaran hari ini:\n- Hal yang disyukuri:', noteInputCtrl),
                      const SizedBox(width: 8),
                      _buildTemplateChip('⚡ 1 Langkah Berani', '1 Langkah berani hari ini yang mengubah masa depan:', noteInputCtrl),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

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

              // Input New Note / Journal
              if (_notesFilter != 'important') ...[
                TextField(
                  controller: noteInputCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Color(0xFFEDEFF2)),
                  decoration: InputDecoration(
                    hintText: 'Tulis catatan harian untuk ${_formatDateShort(_selectedNoteDate)}...',
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

  Widget _buildTemplateChip(String label, String templateContent, TextEditingController ctrl) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ctrl.text = templateContent;
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF161A22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1E2430)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFEDEFF2), fontWeight: FontWeight.w600)),
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
              onTap: () => _showToast('Visual future self diatur'),
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
                  border: Border.all(color: const Color(0xFF2B3340)),
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
  // MODAL DIALOGS, SHEETS & FOCUS TIMER HUB
  // ═══════════════════════════════════════════════════════════════════════════

  // ── 1. Focus Timer Hub (Quick Start Timed Habits or Free Focus) ──
  void _openFocusTimerHub() {
    final timedHabits = _habits.where((h) => h.minutes != null && h.minutes! > 0).toList();

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
                const Text('Pusat Timer Fokus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
                const SizedBox(height: 4),
                const Text('Pilih kebiasaan atau mulai fokus bebas langsung:', style: TextStyle(fontSize: 12, color: Color(0xFF8A93A3))),
                const SizedBox(height: 16),

                // Lanjutkan Kebiasaan Ber-timer
                if (timedHabits.isNotEmpty) ...[
                  const Text('Lanjutkan Kebiasaan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE8C07D))),
                  const SizedBox(height: 8),
                  ...timedHabits.map((h) {
                    final col = _colorForIdentity(h.identity);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: col, width: 1.5)),
                        child: Icon(Icons.play_arrow_rounded, color: col),
                      ),
                      title: Text(h.title, style: const TextStyle(color: Color(0xFFEDEFF2), fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text('${(h.elapsedSeconds ~/ 60)} / ${h.minutes}m progres', style: const TextStyle(fontSize: 11, color: Color(0xFF8A93A3))),
                      onTap: () {
                        Navigator.pop(ctx);
                        _startTimer(h.title, h.minutes ?? 15, source: 'habit', sourceId: h.id, identity: h.identity);
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // Quick Chips Free Focus
                const Text('Fokus Bebas Cepat:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE8C07D))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [15, 25, 45, 60, 90].map((m) {
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _startTimer('Fokus $m menit', m, source: 'free');
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1116),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF1E2430)),
                        ),
                        child: Text('$m mnt', style: const TextStyle(color: Color(0xFFEDEFF2), fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 2. Create New Custom Identity Dialog ──
  void _openCreateNewIdentityDialog() {
    final nameCtrl = TextEditingController();
    Color selectedColor = const Color(0xFFE8C07D);

    final paletteOptions = [
      const Color(0xFFE8C07D), // Gold
      const Color(0xFF8FB8E8), // Sky
      const Color(0xFFE88F7D), // Coral
      const Color(0xFF5FD0A5), // Emerald
      const Color(0xFFC3A6F0), // Lavender
      const Color(0xFFFFB300), // Amber
      const Color(0xFF4DD0E1), // Cyan
      const Color(0xFFFF8A80), // Rose
    ];

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
                  const Text('Identitas Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
                  const SizedBox(height: 4),
                  const Text('Buat bidang identitas baru untuk mengelompokkan blok & kebiasaanmu:', style: TextStyle(fontSize: 12, color: Color(0xFF8A93A3))),
                  const SizedBox(height: 14),

                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Color(0xFFEDEFF2)),
                    decoration: InputDecoration(
                      hintText: 'Misal: Musisi, Desainer, Penulis',
                      hintStyle: const TextStyle(color: Color(0xFF8A93A3), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF0E1116),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2430))),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Pilih Warna Identitas:', style: TextStyle(fontSize: 12, color: Color(0xFF8A93A3))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: paletteOptions.map((c) {
                      final isSel = selectedColor == c;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedColor = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 2),
                          ),
                          child: isSel ? const Icon(Icons.check, color: Color(0xFF0E1116), size: 18) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isNotEmpty) {
                        setState(() {
                          _identities.add(IdentityItem(
                            id: name.toLowerCase().replaceAll(' ', '_'),
                            name: name,
                            color: selectedColor,
                          ));
                        });
                        Navigator.pop(ctx);
                        _showToast('Identitas $name ditambahkan!');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8C07D),
                      foregroundColor: const Color(0xFF161A22),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Buat Identitas', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── 3. Add Preset or Habit to Specific Identity ──
  void _openAddIdentityItemSheet(IdentityItem identity) {
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
              Text('Tambah ke ${identity.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
              const SizedBox(height: 14),
              ListTile(
                leading: Icon(Icons.alarm_add_rounded, color: identity.color),
                title: const Text('Preset Blok Waktu', style: TextStyle(color: Color(0xFFEDEFF2), fontWeight: FontWeight.w600)),
                subtitle: const Text('Aktivitas yang siap dimasukkan ke jam', style: TextStyle(color: Color(0xFF8A93A3), fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openNewPresetForIdentitySheet(identity);
                },
              ),
              ListTile(
                leading: Icon(Icons.check_circle_outline_rounded, color: identity.color),
                title: const Text('Kebiasaan / Rutinitas', style: TextStyle(color: Color(0xFFEDEFF2), fontWeight: FontWeight.w600)),
                subtitle: const Text('Rutinitas harian atau tugas sekali saja dengan timer', style: TextStyle(color: Color(0xFF8A93A3), fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openNewHabitForIdentitySheet(identity);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 4. New Preset with Sleek Duration Selector (No text field!) ──
  void _openNewPresetForIdentitySheet(IdentityItem identity) {
    final nameCtrl = TextEditingController();
    int selectedMinutes = 45;

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
                  Text('Preset Baru • ${identity.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
                  const SizedBox(height: 12),

                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Color(0xFFEDEFF2)),
                    decoration: InputDecoration(
                      hintText: 'Nama Preset (misal: Deep Work)',
                      hintStyle: const TextStyle(color: Color(0xFF8A93A3), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF0E1116),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2430))),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Sleek Interactive Duration Selector with Chips & Steppers!
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Durasi:', style: TextStyle(fontSize: 13, color: Color(0xFF8A93A3), fontWeight: FontWeight.w600)),
                      Text('$selectedMinutes menit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: identity.color)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF8A93A3)),
                        onPressed: () {
                          if (selectedMinutes > 5) setSheetState(() => selectedMinutes -= 5);
                        },
                      ),
                      ...[15, 25, 30, 45, 60, 90].map((m) {
                        final isSel = selectedMinutes == m;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () => setSheetState(() => selectedMinutes = m),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel ? identity.color : const Color(0xFF0E1116),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSel ? identity.color : const Color(0xFF1E2430)),
                              ),
                              child: Text(
                                '$m',
                                style: TextStyle(
                                  color: isSel ? const Color(0xFF0E1116) : const Color(0xFFEDEFF2),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8A93A3)),
                        onPressed: () => setSheetState(() => selectedMinutes += 5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      final n = nameCtrl.text.trim();
                      if (n.isNotEmpty) {
                        setState(() {
                          _presets.add(PresetItem(id: _nextId++, name: n, minutes: selectedMinutes, identity: identity.name));
                        });
                        Navigator.pop(ctx);
                        _showToast('Preset $n disimpan!');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: identity.color,
                      foregroundColor: const Color(0xFF0E1116),
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

  // ── 5. New Habit with Recurrence (Daily vs One-time) & Duration Stepper ──
  void _openNewHabitForIdentitySheet(IdentityItem identity) {
    final titleCtrl = TextEditingController();
    bool isDaily = true;
    bool hasTimer = true;
    int durationMinutes = 20;

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
                  Text('Kebiasaan Baru • ${identity.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2))),
                  const SizedBox(height: 12),

                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Color(0xFFEDEFF2)),
                    decoration: InputDecoration(
                      hintText: 'Nama kebiasaan / tugas',
                      hintStyle: const TextStyle(color: Color(0xFF8A93A3), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF0E1116),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E2430))),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Recurrence Toggle: Harian vs Sekali Saja
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Harian (Daily)')),
                          selected: isDaily,
                          onSelected: (val) => setSheetState(() => isDaily = true),
                          selectedColor: const Color(0xFF5FD0A5).withOpacity(0.25),
                          backgroundColor: const Color(0xFF0E1116),
                          labelStyle: TextStyle(
                            color: isDaily ? const Color(0xFF5FD0A5) : const Color(0xFF8A93A3),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Sekali Saja (One-Time)')),
                          selected: !isDaily,
                          onSelected: (val) => setSheetState(() => isDaily = false),
                          selectedColor: const Color(0xFF8FB8E8).withOpacity(0.25),
                          backgroundColor: const Color(0xFF0E1116),
                          labelStyle: TextStyle(
                            color: !isDaily ? const Color(0xFF8FB8E8) : const Color(0xFF8A93A3),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Has Timer Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktifkan Timer Fokus', style: TextStyle(color: Color(0xFFEDEFF2), fontSize: 14)),
                    value: hasTimer,
                    activeColor: identity.color,
                    onChanged: (val) => setSheetState(() => hasTimer = val),
                  ),

                  if (hasTimer) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Target Waktu:', style: TextStyle(fontSize: 13, color: Color(0xFF8A93A3), fontWeight: FontWeight.w600)),
                        Text('$durationMinutes menit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: identity.color)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF8A93A3)),
                          onPressed: () {
                            if (durationMinutes > 5) setSheetState(() => durationMinutes -= 5);
                          },
                        ),
                        ...[10, 15, 20, 30, 45].map((m) {
                          final isSel = durationMinutes == m;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () => setSheetState(() => durationMinutes = m),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? identity.color : const Color(0xFF0E1116),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSel ? identity.color : const Color(0xFF1E2430)),
                                ),
                                child: Text(
                                  '$m',
                                  style: TextStyle(
                                    color: isSel ? const Color(0xFF0E1116) : const Color(0xFFEDEFF2),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8A93A3)),
                          onPressed: () => setSheetState(() => durationMinutes += 5),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      if (title.isNotEmpty) {
                        setState(() {
                          _habits.add(HabitModel(
                            id: _nextId++,
                            title: title,
                            identity: identity.name,
                            isDaily: isDaily,
                            minutes: hasTimer ? durationMinutes : null,
                          ));
                        });
                        Navigator.pop(ctx);
                        _showToast('Kebiasaan disimpan');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: identity.color,
                      foregroundColor: const Color(0xFF0E1116),
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

  // ── 6. Interactive Schedule to Focus Clock Modal (Existing Items First!) ──
  void _openScheduleToClockSheet({
    String title = '',
    int initialDurationMinutes = 60,
    String identity = 'Programmer',
    Color? identityColor,
  }) {
    final settings = ref.read(launcherSettingsProvider);
    final tc = _HomeThemeColors.fromPalette(settings.themePalette);

    bool isCustomInput = false;
    String selectedTitle = title.trim();
    if (selectedTitle.isEmpty) {
      if (_dumpedTasks.isNotEmpty) {
        selectedTitle = _dumpedTasks.first;
      } else if (_habits.isNotEmpty) {
        selectedTitle = _habits.first.title;
      } else if (_presets.isNotEmpty) {
        selectedTitle = _presets.first.name;
      } else {
        selectedTitle = 'Fokus Utama';
      }
    }
    final titleCtrl = TextEditingController(text: selectedTitle);

    var startH = (_hourNow() * 2).ceil() / 2.0;
    while (_findConflict(startH, startH + initialDurationMinutes / 60.0) != null && startH < 23.5) {
      startH += 0.5;
    }
    if (startH >= 23.5) startH = _hourNow();

    int duration = initialDurationMinutes;
    String selectedIdentity = identity;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tc.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final activeColor = _colorForIdentity(selectedIdentity);
            final endH = math.min(24.0, startH + duration / 60.0);

            return Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: tc.stroke,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title Header with Toggle Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pasang ke Focus Clock',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: tc.textPrimary),
                            ),
                          ],
                        ),
                        // Button to toggle custom mode
                        InkWell(
                          onTap: () => setSheetState(() => isCustomInput = !isCustomInput),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isCustomInput ? tc.accent.withOpacity(0.2) : tc.cardElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isCustomInput ? tc.accent : tc.stroke),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCustomInput ? Icons.list_alt_rounded : Icons.edit_note_rounded,
                                  size: 14,
                                  color: isCustomInput ? tc.accent : tc.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCustomInput ? 'Pilih yang Ada' : '+ Kustom',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isCustomInput ? tc.accent : tc.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCustomInput
                          ? 'Ketik manual kegiatan baru dan atur jamnya'
                          : 'Pilih cepat dari kegiatan yang ada atau ketuk + Kustom',
                      style: TextStyle(fontSize: 12, color: tc.textSecondary),
                    ),
                    const SizedBox(height: 14),

                    // ── EXISTING ITEMS FIRST (When not in custom mode) ──
                    if (!isCustomInput) ...[
                      // 1. Dari Dump Inbox
                      if (_dumpedTasks.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.inbox_rounded, size: 14, color: tc.accent),
                            const SizedBox(width: 6),
                            Text(
                              'Dari Dump Inbox:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tc.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _dumpedTasks.map((task) {
                            final isSel = selectedTitle == task;
                            return InkWell(
                              onTap: () {
                                setSheetState(() {
                                  selectedTitle = task;
                                  titleCtrl.text = task;
                                  errorMessage = null;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? tc.accent.withOpacity(0.2) : tc.cardElevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel ? tc.accent : tc.stroke,
                                    width: isSel ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSel) ...[
                                      Icon(Icons.check_rounded, size: 13, color: tc.accent),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      task,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                        color: isSel ? tc.accent : tc.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // 2. Dari Kebiasaan & Rutinitas
                      if (_habits.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.repeat_rounded, size: 14, color: tc.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Dari Kebiasaan & Rutinitas:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tc.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _habits.take(6).map((h) {
                              final isSel = selectedTitle == h.title;
                              final hColor = _colorForIdentity(h.identity);
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  onTap: () {
                                    setSheetState(() {
                                      selectedTitle = h.title;
                                      titleCtrl.text = h.title;
                                      selectedIdentity = h.identity;
                                      if (h.minutes != null && h.minutes! > 0) {
                                        duration = h.minutes!;
                                      }
                                      errorMessage = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSel ? hColor.withOpacity(0.2) : tc.cardElevated,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSel ? hColor : tc.stroke,
                                        width: isSel ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(color: hColor, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          h.title,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                            color: isSel ? hColor : tc.textPrimary,
                                          ),
                                        ),
                                        if (h.minutes != null) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            '(${h.minutes}m)',
                                            style: TextStyle(fontSize: 10, color: tc.textMuted),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // 3. Dari Preset Blok Waktu
                      if (_presets.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.layers_outlined, size: 14, color: tc.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Dari Preset Waktu:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tc.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _presets.map((p) {
                              final isSel = selectedTitle == p.name;
                              final pColor = _colorForIdentity(p.identity);
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  onTap: () {
                                    setSheetState(() {
                                      selectedTitle = p.name;
                                      titleCtrl.text = p.name;
                                      selectedIdentity = p.identity;
                                      duration = p.minutes;
                                      errorMessage = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSel ? pColor.withOpacity(0.2) : tc.cardElevated,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSel ? pColor : tc.stroke,
                                        width: isSel ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      '${p.name} (${p.minutes}m)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                        color: isSel ? pColor : tc.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Button to switch to manual input if user prefers
                      InkWell(
                        onTap: () => setSheetState(() => isCustomInput = true),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: tc.cardElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tc.stroke),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded, size: 16, color: tc.accent),
                              const SizedBox(width: 4),
                              Text(
                                '+ Tulis Kegiatan Kustom Manual',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tc.accent),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // ── MANUAL / CUSTOM INPUT ──
                      TextField(
                        controller: titleCtrl,
                        autofocus: true,
                        style: TextStyle(color: tc.textPrimary, fontWeight: FontWeight.w600),
                        onChanged: (v) => setSheetState(() => selectedTitle = v),
                        decoration: InputDecoration(
                          labelText: 'Nama Kegiatan Kustom',
                          labelStyle: TextStyle(color: tc.textSecondary, fontSize: 13),
                          filled: true,
                          fillColor: tc.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: tc.stroke),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: activeColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Identity Selector
                      Text(
                        'Pilih Identitas:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tc.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _identities.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final id = _identities[i];
                            final isSel = id.name.toLowerCase() == selectedIdentity.toLowerCase();
                            return InkWell(
                              onTap: () => setSheetState(() => selectedIdentity = id.name),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? id.color.withOpacity(0.2) : tc.bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel ? id.color : tc.stroke,
                                    width: isSel ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(color: id.color, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      id.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                        color: isSel ? id.color : tc.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // ── TIME BADGE & RANGE SLIDER ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: activeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: activeColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, color: activeColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${_formatHour(startH)} — ${_formatHour(endH)}',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: activeColor),
                              ),
                            ],
                          ),
                          Text(
                            '$duration menit',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tc.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dual-thumb Range Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Geser Jam (00:00 - 24:00):',
                          style: TextStyle(fontSize: 12, color: tc.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${_formatHour(startH)} sd ${_formatHour(endH)}',
                          style: TextStyle(fontSize: 12, color: activeColor, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(startH, endH),
                      min: 0.0,
                      max: 24.0,
                      divisions: 96,
                      activeColor: activeColor,
                      inactiveColor: tc.stroke,
                      labels: RangeLabels(_formatHour(startH), _formatHour(endH)),
                      onChanged: (newVals) {
                        setSheetState(() {
                          startH = newVals.start;
                          var newDur = ((newVals.end - newVals.start) * 60).round();
                          if (newDur < 15) newDur = 15;
                          duration = newDur;
                          errorMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Mulai Cepat Chips
                    Text(
                      'Mulai Cepat:',
                      style: TextStyle(fontSize: 12, color: tc.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTimeChip(
                            label: 'Sekarang (${_formatHour(_hourNow())})',
                            isSelected: (startH - _hourNow()).abs() < 0.25,
                            onTap: () => setSheetState(() => startH = _hourNow()),
                          ),
                          ...[9.0, 13.0, 16.0, 19.5, 21.0].map((h) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _buildTimeChip(
                                label: _formatHour(h),
                                isSelected: (startH - h).abs() < 0.1,
                                onTap: () => setSheetState(() => startH = h),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Pilihan Durasi Chips
                    Text(
                      'Pilihan Durasi:',
                      style: TextStyle(fontSize: 12, color: tc.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [15, 30, 45, 60, 90, 120].map((d) {
                          final isSel = duration == d;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () => setSheetState(() => duration = d),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? activeColor : tc.bg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSel ? activeColor : tc.stroke),
                                ),
                                child: Text(
                                  '$d m',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSel ? tc.bg : tc.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Color(0xFFE88F7D), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Submit Button
                    ElevatedButton(
                      onPressed: () {
                        final actName = selectedTitle.trim().isNotEmpty
                            ? selectedTitle.trim()
                            : (titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : 'Kegiatan Baru');
                        final en = math.min(24.0, startH + duration / 60.0);
                        final res = _addBlock(startH, en, actName, selectedIdentity);
                        if (res != null) {
                          setSheetState(() => errorMessage = res);
                        } else {
                          // Remove from dump if scheduled
                          if (_dumpedTasks.contains(actName)) {
                            setState(() => _dumpedTasks.remove(actName));
                          }
                          Navigator.pop(ctx);
                          _showToast('$actName berhasil dipasang di jam ${_formatHour(startH)}-${_formatHour(en)}');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tc.accent,
                        foregroundColor: tc.bg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pasang ke Focus Clock',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: tc.bg),
                          ),
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

  void _openAddToClockSheet(PresetItem p) {
    _openScheduleToClockSheet(
      title: p.name,
      initialDurationMinutes: p.minutes,
      identity: p.identity,
      identityColor: _colorForIdentity(p.identity),
    );
  }

  Widget _buildTimeChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8C07D) : const Color(0xFF0E1116),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFFE8C07D) : const Color(0xFF1E2430)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? const Color(0xFF161A22) : const Color(0xFFEDEFF2),
          ),
        ),
      ),
    );
  }

  // ── Quick Launcher Bar (Direct Niagara Launcher Drawer Access) ────────────
  Widget _buildQuickLauncherBar(_HomeThemeColors tc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.stroke),
      ),
      child: Row(
        children: [
          Icon(Icons.apps_rounded, color: tc.accent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aplikasi Terpasang (Niagara Launcher)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tc.textPrimary),
            ),
          ),
          InkWell(
            onTap: widget.onOpenAppDrawer,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: tc.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Buka Drawer',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tc.background),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: tc.background, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Task & Habit Dump Section ─────────────────────────────────────────────
  Widget _buildTaskDumpSection(_HomeThemeColors tc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tc.stroke, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inbox_rounded, color: tc.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Task & Habit Dump (Inbox)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tc.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tc.accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_dumpedTasks.length} tugas',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tc.accent),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _openQuickDumpTaskDialog(tc),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tc.cardAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tc.stroke),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: tc.accent, size: 14),
                      const SizedBox(width: 2),
                      Text('Dump', style: TextStyle(fontSize: 11, color: tc.accent, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _openScheduleToClockSheet(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tc.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on_rounded, color: tc.background, size: 13),
                      const SizedBox(width: 2),
                      Text('Pasang', style: TextStyle(fontSize: 11, color: tc.background, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Klik "Sekarang" untuk 1-tap instan, atau "⚡ Pasang" untuk atur durasi ke Focus Clock',
            style: TextStyle(fontSize: 11, color: tc.textSecondary),
          ),
          const SizedBox(height: 10),
          if (_dumpedTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada tugas di dump inbox. Klik + Dump untuk mencatat cepat.',
                style: TextStyle(color: tc.textSecondary, fontSize: 12),
              ),
            )
          else
            ..._dumpedTasks.map((task) => _buildDumpedTaskRow(task, tc)),
        ],
      ),
    );
  }

  Widget _buildDumpedTaskRow(String task, _HomeThemeColors tc) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tc.cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tc.stroke.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle_outlined, color: tc.textSecondary, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task,
              style: TextStyle(fontSize: 13, color: tc.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 6),
          // 1-Tap Quick Schedule Sekarang
          InkWell(
            onTap: () {
              var nowHr = (_hourNow() * 2).floor() / 2.0;
              var endHr = nowHr + 1.0;
              if (endHr > 24.0) endHr = 24.0;
              final err = _addBlock(nowHr, endHr, task, 'Programmer');
              if (err != null) {
                _showToast(err);
                _openScheduleToClockSheet(title: task, initialDurationMinutes: 60, identity: 'Programmer');
              } else {
                setState(() {
                  _dumpedTasks.remove(task);
                });
                _showToast('"$task" dijadwalkan ${_formatHour(nowHr)} - ${_formatHour(endHr)}');
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tc.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tc.stroke),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 13, color: tc.accent),
                  const SizedBox(width: 2),
                  Text(
                    'Sekarang',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tc.accent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Buka Popup Jadwal dengan task terpasang
          InkWell(
            onTap: () => _openScheduleToClockSheet(
              title: task,
              initialDurationMinutes: 60,
              identity: 'Programmer',
            ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tc.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.watch_later_outlined, size: 12, color: tc.background),
                  const SizedBox(width: 3),
                  Text(
                    '⚡ Pasang',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tc.background),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: tc.textSecondary),
            padding: const EdgeInsets.only(left: 4),
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () {
              setState(() => _dumpedTasks.remove(task));
              _showToast('Tugas dihapus dari dump');
            },
          ),
        ],
      ),
    );
  }

  void _openQuickDumpTaskDialog(_HomeThemeColors tc) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tc.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: tc.stroke)),
        title: Text('Catat Cepat ke Dump Inbox', style: TextStyle(color: tc.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: tc.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nama kegiatan / habit / tugas...',
            hintStyle: TextStyle(color: tc.textSecondary),
            filled: true,
            fillColor: tc.cardAlt,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: tc.stroke)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: tc.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.isNotEmpty) {
                setState(() => _dumpedTasks.insert(0, t));
                Navigator.pop(ctx);
                _showToast('Tugas ditambahkan ke dump');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: tc.accent, foregroundColor: tc.background),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ── Bottom Floating Dock (Focus Clock | Beranda | App Launcher) ───────────
  Widget _buildBottomFloatingDock(_HomeThemeColors tc) {
    return Container(
      height: 60,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      decoration: BoxDecoration(
        color: tc.card.withOpacity(0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tc.stroke, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDockButton(
            icon: Icons.access_time_filled_rounded,
            label: 'Focus Clock',
            tc: tc,
            onTap: widget.onOpenFocusClock,
          ),
          _buildDockButton(
            icon: Icons.home_rounded,
            label: 'Beranda',
            isActive: true,
            tc: tc,
            onTap: () {},
          ),
          _buildDockButton(
            icon: Icons.apps_rounded,
            label: 'App Launcher',
            isAccent: true,
            tc: tc,
            onTap: widget.onOpenAppDrawer,
          ),
        ],
      ),
    );
  }

  Widget _buildDockButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required _HomeThemeColors tc,
    bool isActive = false,
    bool isAccent = false,
  }) {
    final col = isAccent
        ? tc.accent
        : (isActive ? tc.textPrimary : tc.textSecondary);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: col, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive || isAccent ? FontWeight.w700 : FontWeight.w500,
                color: col,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 7. Habit Actions Popover (Ya, Tidak, Mulai, Catatan, Gambar) ──
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHabitActionButton(Icons.check, 'Ya', () {
                    Navigator.pop(ctx);
                    setState(() {
                      h.isDone = true;
                      h.isRunning = false;
                      h.isSkipped = false;
                    });
                    _showToast('Ditandai selesai');
                  }),
                  _buildHabitActionButton(Icons.close, 'Tidak', () {
                    Navigator.pop(ctx);
                    setState(() {
                      h.isDone = false;
                      h.isRunning = false;
                      h.isSkipped = true;
                    });
                    _showToast('Ditandai tidak hari ini');
                  }),
                  _buildHabitActionButton(Icons.play_arrow_rounded, 'Mulai', () {
                    Navigator.pop(ctx);
                    _startTimer(h.isVision ? 'Visualisasi masa depan' : h.title, h.minutes ?? 15, source: 'habit', sourceId: h.id, identity: h.identity);
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

  // ── 8. Block Detail Sheet ──
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

  // ── 9. Search Modal (Live Search across Blocks, Habits, Presets, Notes) ──
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

  // ── 10. Menu Sheet ──
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
                _buildMenuRow(Icons.book_outlined, 'Catatan Harian', () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedNoteDate = _dateKey(0);
                    _notesFilter = 'date';
                    _currentScreen = 'catatan';
                  });
                }),
                _buildMenuRow(Icons.person_add_alt_1_outlined, 'Tambah Identitas Baru', () {
                  Navigator.pop(ctx);
                  _openCreateNewIdentityDialog();
                }),
                _buildMenuRow(Icons.palette_outlined, 'Pilih Tema Focus Clock', () {
                  Navigator.pop(ctx);
                  _openThemePickerSheet();
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

  // ── Theme Picker Sheet (5 Natural Palettes) ──
  void _openThemePickerSheet() {
    final settings = ref.read(launcherSettingsProvider);
    final currentPalette = settings.themePalette;

    final palettes = [
      {
        'key': 'natural_slate',
        'name': 'Natural Slate',
        'desc': 'Kenyamanan minimal, slate & pasir keemasan lembut',
        'accent': const Color(0xFFD8B26E),
        'bg': const Color(0xFF12151B),
      },
      {
        'key': 'fino_green',
        'name': 'Fino Green Matcha',
        'desc': 'Menenangkan pikiran, hijau zaitun matcha alami',
        'accent': const Color(0xFF7CA982),
        'bg': const Color(0xFF131916),
      },
      {
        'key': 'sky_blue',
        'name': 'Sky Blue',
        'desc': 'Udara & kejernihan, biru langit lembut natural',
        'accent': const Color(0xFF5FA8D3),
        'bg': const Color(0xFF121820),
      },
      {
        'key': 'ocean_blue',
        'name': 'Ocean Blue',
        'desc': 'Kedalaman & fokus tenang, biru laut dalam',
        'accent': const Color(0xFF4A8FE7),
        'bg': const Color(0xFF0F172A),
      },
      {
        'key': 'full_book',
        'name': 'Full Book Amber',
        'desc': 'Hangat & reflektif, warna kertas buku & kopi espresso',
        'accent': const Color(0xFFE09F3E),
        'bg': const Color(0xFF181512),
      },
    ];

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
              Row(
                children: [
                  const Icon(Icons.palette_outlined, color: Color(0xFFE8C07D), size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Pilih Tema Tampilan',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDEFF2)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF8A93A3)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Warna natural & ramah mata untuk fokus seharian tanpa silau',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A93A3)),
              ),
              const SizedBox(height: 14),
              ...palettes.map((p) {
                final key = p['key'] as String;
                final name = p['name'] as String;
                final desc = p['desc'] as String;
                final accent = p['accent'] as Color;
                final bg = p['bg'] as Color;
                final isSelected = currentPalette == key;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? accent.withOpacity(0.12) : const Color(0xFF0E1116),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? accent : const Color(0xFF1E2430),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                        border: Border.all(color: accent, width: 2.5),
                      ),
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? accent : const Color(0xFFEDEFF2),
                      ),
                    ),
                    subtitle: Text(
                      desc,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8A93A3)),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded, color: accent, size: 20)
                        : null,
                    onTap: () {
                      ref.read(launcherSettingsProvider.notifier).setThemePalette(key);
                      setState(() {});
                      Navigator.pop(ctx);
                      _showToast('Tema diubah ke $name');
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── 11. Prayer Action Sheet ──
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

  // ── 12. Date Picker Sheet ──
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

// ── Clean Pie Clock Painter (Lampiran 1 Custom Aesthetic) ────────────────────
class _CleanPieClockPainter extends CustomPainter {
  final DateTime now;
  final List<Activity> activities;
  final bool is24h;

  _CleanPieClockPainter({
    required this.now,
    required this.activities,
    this.is24h = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // 1. Dark outer dial background
    final bgPaint = Paint()
      ..color = const Color(0xFF141820)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2, bgPaint);

    // 2. Outer rim border with subtle gold accent
    final rimPaint = Paint()
      ..color = const Color(0xFF262D3D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 2, rimPaint);

    // 3. Draw Activity Pie Wedges
    final pieRadius = radius - 18;
    final pieRect = Rect.fromCircle(center: center, radius: pieRadius);
    final totalMinutes = is24h ? 1440.0 : 720.0;

    for (final act in activities) {
      final startMin = toUiMinute(act.startMinute, act.ampmHalf, is24h: is24h);
      final endMin = toUiMinute(act.endMinute, act.ampmHalf, is24h: is24h);
      if (endMin <= startMin) continue;

      // Top (12 o'clock / 00:00) is -pi / 2. Slices sweep clockwise.
      final startAngle = -math.pi / 2 + (startMin / totalMinutes) * 2 * math.pi;
      final sweepAngle = ((endMin - startMin) / totalMinutes) * 2 * math.pi;

      final wedgePaint = Paint()
        ..color = Color(act.colorValue).withOpacity(0.82)
        ..style = PaintingStyle.fill;

      canvas.drawArc(pieRect, startAngle, sweepAngle, true, wedgePaint);

      // Wedge stroke outline
      final wedgeBorder = Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(pieRect, startAngle, sweepAngle, true, wedgeBorder);
    }

    // 4. Subtle hour track ring
    final trackPaint = Paint()
      ..color = const Color(0xFF1E2430)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, pieRadius, trackPaint);

    // 5. Major hour labels (00, 06, 12, 18 in 24h, or 12, 3, 6, 9 in 12h)
    final labelHours = is24h ? [0, 6, 12, 18] : [12, 3, 6, 9];
    const textStyle = TextStyle(
      color: Color(0xFF8A93A3),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );

    for (final h in labelHours) {
      final hourFrac = is24h ? (h / 24.0) : ((h % 12) / 12.0);
      final angle = -math.pi / 2 + hourFrac * 2 * math.pi;
      final labelDist = radius - 30;
      final offset = Offset(
        center.dx + labelDist * math.cos(angle),
        center.dy + labelDist * math.sin(angle),
      );

      final label = h.toString().padLeft(2, '0');
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2));
    }

    // 6. Current Time Golden Pointer Hand
    final currentMinute = is24h
        ? (now.hour * 60 + now.minute)
        : ((now.hour % 12) * 60 + now.minute);
    final handAngle = -math.pi / 2 + (currentMinute / totalMinutes) * 2 * math.pi;

    final handLen = radius - 20;
    final handEnd = Offset(
      center.dx + handLen * math.cos(handAngle),
      center.dy + handLen * math.sin(handAngle),
    );

    // Glowing pointer line
    final handGlow = Paint()
      ..color = const Color(0xFFE8C07D).withOpacity(0.4)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, handEnd, handGlow);

    final handPaint = Paint()
      ..color = const Color(0xFFE8C07D)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, handEnd, handPaint);

    // Hand tip diamond / arrow head
    final tipPaint = Paint()
      ..color = const Color(0xFFE8C07D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(handEnd, 4, tipPaint);

    // 7. Center pivot
    final pivotBg = Paint()
      ..color = const Color(0xFF161A22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 9, pivotBg);

    final pivotBorder = Paint()
      ..color = const Color(0xFFE8C07D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 9, pivotBorder);

    final pivotDot = Paint()
      ..color = const Color(0xFFE8C07D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.5, pivotDot);
  }

  @override
  bool shouldRepaint(covariant _CleanPieClockPainter oldDelegate) {
    return oldDelegate.now.minute != now.minute ||
        oldDelegate.activities != activities ||
        oldDelegate.is24h != is24h;
  }
}
