import 'home_intent_cue.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/time_math.dart';
import '../../../models/activity.dart';
import '../../../models/task.dart';
import '../../../models/habit.dart';
import '../../../providers/providers.dart';
import '../../focusclock/analog_clock_face.dart';
import '../../ai_chat/ai_chat_sheet.dart';
import '../../sadar/widgets/sadar_timer_view.dart';
import '../../settings/settings_screen.dart';
import '../models/launcher_settings.dart';
import '../providers/launcher_settings_provider.dart';
import 'fitrah_settings_screen.dart';
import 'launcher_customization_sheet.dart';
import '../utils/hijri_date.dart';
import 'loop_habit_grid_widget.dart';
import '../../../models/habit_entry.dart';
import '../../../models/timer_session.dart';
import '../../../models/terminal_focus_session.dart';
import '../../../domain/focus_intent.dart';
import '../../../providers/sadar_providers.dart';
import '../../../services/sadar_timer_engine.dart';
import '../../../services/home_schedule_service.dart';

// ── Natural Theme Palettes for Focus Clock Home (Sadar Way of Life M3) ─────────
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
      case 'full_book':
        return const _HomeThemeColors(
          bg: AppPalette.bg,
          card: AppPalette.card,
          cardElevated: AppPalette.bookpaperFieldBg,
          stroke: AppPalette.stroke,
          accent: AppPalette.accent,
          textPrimary: Color(0xFFF5EBE6),
          textSecondary: Color(0xFFA69F95),
          textMuted: Color(0xFFA69F95),
          clockThemeIndex: 7,
        );
      case 'sand':
      case 'warm_sand':
        return const _HomeThemeColors(
          bg: Color(0xFF141210),
          card: Color(0xFF1D1916),
          cardElevated: Color(0xFF26211C),
          stroke: Color(0xFF332B24),
          accent: Color(0xFFE8C89A),
          textPrimary: Color(0xFFF7F2EB),
          textSecondary: Color(0xFFA89F95),
          textMuted: Color(0xFF736A60),
          clockThemeIndex: 7,
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
      case 'sage':
      case 'fino_green':
        return const _HomeThemeColors(
          bg: Color(0xFF0F1410),
          card: Color(0xFF1A2018),
          cardElevated: Color(0xFF222B20),
          stroke: Color(0xFF2E3E30),
          accent: Color(0xFF7FCFAA),
          textPrimary: Color(0xFFE8F0EB),
          textSecondary: Color(0xFF8FAF9A),
          textMuted: Color(0xFF5A7A60),
          clockThemeIndex: 1,
        );
      case 'natural_slate':
        return const _HomeThemeColors(
          bg: Color(0xFF12151B),
          card: Color(0xFF1D222B),
          cardElevated: Color(0xFF262C36),
          stroke: Color(0xFF363D49),
          accent: Color(0xFFD8B26E),
          textPrimary: Color(0xFFF3EEE6),
          textSecondary: Color(0xFFA79F94),
          textMuted: Color(0xFF716B63),
          clockThemeIndex: 7,
        );
      default:
        return _HomeThemeColors.fromPalette('full_book');
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
  double endHour; // 0.0 .. 24.0
  String name;
  String? identity;
  final Activity? activity;
  bool isSleep;
  bool isDone;

  BlockItem({
    required this.id,
    required this.startHour,
    required this.endHour,
    required this.name,
    this.identity,
    this.activity,
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
  DateTime? endsAt;

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
    this.endsAt,
  });
}

/// Focus Clock Home View (Page 1 - Center)
/// Multiplatform Super-App Homescreen implementing Lampiran 1 & Ecosystem Integration
class FocusClockHomeView extends ConsumerStatefulWidget {
  const FocusClockHomeView({
    super.key,
    required this.onOpenFocusClock,
    required this.onOpenAppDrawer,
    this.onOpenHabits,
    this.useSampleData = false,
    this.now,
  });

  final VoidCallback onOpenFocusClock;
  final VoidCallback onOpenAppDrawer;
  final VoidCallback? onOpenHabits;
  final bool useSampleData;
  final DateTime Function()? now;

  @override
  ConsumerState<FocusClockHomeView> createState() => _FocusClockHomeViewState();
}

class _FocusClockHomeViewState extends ConsumerState<FocusClockHomeView> {
  // Navigation State: 'home', 'timer', 'catatan', 'jelas', 'fullscreen_focus'
  String _currentScreen = 'home';

  // Clock View Settings (AnalogClockFace from Left Focus Clock is default)
  bool _isListView = false;
  AmPmHalf _clockViewHalf = DateTime.now().hour < 12
      ? AmPmHalf.am
      : AmPmHalf.pm;

  // Single Daily Scratchpad (Obsidian Mobile Philosophy)
  late final TextEditingController _dailyNoteController;
  String _dailyNote = '';
  late String _dailyNoteDate;
  String _dailyNoteStatus = '';
  int _dailyNoteRevision = 0;

  // Selected Filter for Unified Sections (Lampiran 1 & Sadar Prototype)
  String _selectedPresetIdentity = '';
  String _selectedHabitIdentity = 'Semua';

  // Selected Note Filter
  late String _selectedNoteDate;
  String _notesFilter = 'date'; // 'date' | 'important'

  // Timer Tick
  late Timer _periodicTimer;
  late DateTime _currentTime;

  // Active Focus Timer
  ActiveTimer? _activeTimer;
  bool _isFinishingTimer = false;

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
  late List<Task> _dumpedTasks;
  final Set<int> _inboxBusy = {};
  List<Task> get _inboxTasks => widget.useSampleData
      ? _dumpedTasks
      : (ref.read(eisenhowerTasksProvider).valueOrNull ?? [])
            .where(
              (t) =>
                  !t.isCompleted &&
                  t.activityId == null &&
                  t.startMinute == null &&
                  t.endMinute == null,
            )
            .toList();

  @override
  void initState() {
    super.initState();
    _currentTime = widget.now?.call() ?? DateTime.now();
    _selectedNoteDate = _dateKey(0);
    final notifier = ref.read(launcherSettingsProvider.notifier);
    final pendingDates = notifier.noteDrafts.keys.toList()..sort();
    _dailyNoteDate = pendingDates.isEmpty ? _dateKey(0) : pendingDates.first;
    final initialDraft = notifier.noteDrafts[_dailyNoteDate];
    _dailyNote = initialDraft ?? '';
    if (initialDraft != null) {
      _dailyNoteStatus = notifier.noteSaving[_dailyNoteDate] == true
          ? 'Menyimpan…'
          : 'Gagal menyimpan';
    }
    _dailyNoteController = TextEditingController(text: _dailyNote);
    ref.listenManual(launcherSettingsProvider, (_, settings) {
      final notifier = ref.read(launcherSettingsProvider.notifier);
      final hasDraft = notifier.noteDrafts.containsKey(_dailyNoteDate);
      if (hasDraft) {
        _dailyNoteStatus = notifier.noteSaving[_dailyNoteDate] == true
            ? 'Menyimpan…'
            : 'Gagal menyimpan';
      } else if (notifier.loadFailed) {
        _dailyNoteStatus = 'Gagal memuat';
      } else if (_dailyNoteStatus == 'Gagal memuat') {
        _dailyNoteStatus = '';
      } else if (_dailyNoteStatus == 'Menyimpan…' ||
          _dailyNoteStatus == 'Gagal menyimpan') {
        _dailyNoteStatus = 'Tersimpan';
      }
      final text =
          notifier.noteDrafts[_dailyNoteDate] ??
          settings.dailyNotes[_dailyNoteDate] ??
          '';
      if (_dailyNoteController.text != text && !hasDraft) {
        _dailyNoteController.text = text;
        _dailyNote = text;
      }
    }, fireImmediately: true);

    if (widget.useSampleData) {
      // Seed data for tests
      _identities = [
        IdentityItem(
          id: 'programmer',
          name: 'Programmer',
          color: AppPalette.accent,
        ),
        IdentityItem(
          id: 'pembaca',
          name: 'Pembaca',
          color: const Color(0xFF8FB8E8),
        ),
        IdentityItem(
          id: 'binaragawan',
          name: 'Binaragawan',
          color: const Color(0xFFE88F7D),
        ),
        IdentityItem(
          id: 'baik_hati',
          name: 'Baik hati',
          color: const Color(0xFF5FD0A5),
        ),
        IdentityItem(
          id: 'masa_depan',
          name: 'Masa depan',
          color: const Color(0xFFC3A6F0),
        ),
      ];

      _blocks = [
        BlockItem(
          id: 1,
          startHour: 22.0,
          endHour: 24.0,
          name: 'Tidur',
          isSleep: true,
        ),
        BlockItem(
          id: 2,
          startHour: 0.0,
          endHour: 4.5,
          name: 'Tidur',
          isSleep: true,
        ),
        BlockItem(
          id: 3,
          startHour: 19.5,
          endHour: 21.0,
          name: 'SE - Orkestrasi AI',
          identity: 'Programmer',
        ),
      ];

      _presets = [
        PresetItem(
          id: 1,
          name: 'SE - Orkestrasi AI',
          minutes: 90,
          identity: 'Programmer',
        ),
        PresetItem(
          id: 2,
          name: 'LKS ITSSB',
          minutes: 45,
          identity: 'Programmer',
        ),
        PresetItem(id: 3, name: 'Baca Buku', minutes: 15, identity: 'Pembaca'),
        PresetItem(
          id: 4,
          name: 'Latihan Beban',
          minutes: 30,
          identity: 'Binaragawan',
        ),
        PresetItem(
          id: 5,
          name: 'Sedekah & Silaturahmi',
          minutes: 15,
          identity: 'Baik hati',
        ),
        PresetItem(
          id: 6,
          name: 'Visualisasi Cita-cita',
          minutes: 10,
          identity: 'Masa depan',
        ),
      ];

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
        HabitModel(
          id: 2,
          title: 'Selalu bersikap baik',
          identity: 'Baik hati',
          isDone: true,
          isDaily: true,
        ),
        HabitModel(
          id: 3,
          title:
              'Visualisasikan future selfmu, pejamkan mata, lakukan apa yang future selfmu lakukan',
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
        HabitModel(
          id: 5,
          title: 'Jurnal sampai pikiran lega',
          identity: 'Pembaca',
          isDone: true,
          isDaily: true,
        ),
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

      _notes = [
        NoteItem(
          id: 1,
          dateKey: _dateKey(-1),
          text: 'Tauhid satu-satunya kebenaran. Sedikit itu lebih.',
          isImportant: true,
        ),
        NoteItem(
          id: 2,
          dateKey: _dateKey(0),
          text: 'Lepaskan perfeksionisme, menuju penguasaan.',
          isImportant: false,
        ),
      ];

      _dumpedTasks =
          [
                'Selesaikan modul UI Focus Clock',
                'Submit LKS ITSSB draft',
                'Beli suplemen gym & air galon',
              ]
              .asMap()
              .entries
              .map(
                (e) => Task()
                  ..id = e.key + 1
                  ..title = e.value
                  ..createdAt = DateTime.now(),
              )
              .toList();
    } else {
      // Production starts with no assumed identity, schedule, preset or habit.
      _identities = [];
      _blocks = [];
      _presets = [];
      _habits = [];
      _notes = [];
      _dumpedTasks = [];
    }

    ref.listenManual<TimerState>(timerEngineProvider, (previous, next) {
      if (!mounted) return;
      final wasPending = previous?.isSavePending ?? false;
      setState(() {
        if (next.isActive ||
            next.isSavePending ||
            (next.isCompleted && wasPending)) {
          _activeTimer = ActiveTimer(
            label: next.habitName,
            totalSeconds: next.targetSeconds,
            leftSeconds: next.remainingSeconds,
            isRunning: next.isRunning,
            source: switch (next.sourceKind) {
              TimerSessionSourceKind.preset => 'preset',
              TimerSessionSourceKind.activity => 'block',
              TimerSessionSourceKind.free => 'free',
              _ => null,
            },
            sourceId: next.activityId,
            startHour: _hourNow() - next.actualDurationSeconds / 3600,
            hasStarted: true,
            endsAt: next.isRunning
                ? DateTime.now().add(Duration(seconds: next.remainingSeconds))
                : null,
          );
        } else if (_activeTimer?.source != 'habit') {
          _activeTimer = null;
        }
      });
      if (wasPending && next.isCompleted && !next.isSavePending) {
        unawaited(_finishTimer(autoComplete: true));
      }
      if (next.restoreError != null) {
        _showToast(next.restoreError!);
      }
    }, fireImmediately: true);

    // Keep the displayed time fresh without rebuilding this entire home every
    // second. Only a running timer needs per-second rendering.
    _periodicTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = widget.now?.call() ?? DateTime.now();
      final today = _dateKey(0);
      final notifier = ref.read(launcherSettingsProvider.notifier);
      var noteChanged = false;
      if (today != _dailyNoteDate &&
          !notifier.noteDrafts.containsKey(_dailyNoteDate)) {
        final pendingDates = notifier.noteDrafts.keys.toList()..sort();
        _dailyNoteDate = pendingDates.isEmpty ? today : pendingDates.first;
        _dailyNote =
            notifier.noteDrafts[_dailyNoteDate] ??
            ref.read(launcherSettingsProvider).dailyNotes[_dailyNoteDate] ??
            '';
        _dailyNoteController.text = _dailyNote;
        _dailyNoteStatus = notifier.noteDrafts.containsKey(_dailyNoteDate)
            ? (notifier.noteSaving[_dailyNoteDate] == true
                  ? 'Menyimpan…'
                  : 'Gagal menyimpan')
            : '';
        _dailyNoteRevision++;
        noteChanged = true;
      }
      final timerIsRunning = _activeTimer?.isRunning == true;
      final displayedMinuteChanged =
          now.year != _currentTime.year ||
          now.month != _currentTime.month ||
          now.day != _currentTime.day ||
          now.hour != _currentTime.hour ||
          now.minute != _currentTime.minute;
      _currentTime = now;
      if (!timerIsRunning && !displayedMinuteChanged && !noteChanged) return;

      setState(() {
        // Tick any running habit timer
        if (timerIsRunning) {
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
        }
      });
    });
  }

  @override
  void dispose() {
    _dailyNoteController.dispose();
    const MethodChannel('fitrah_launcher/apps')
        .invokeMethod('setLockscreenFocus', {'enabled': false})
        .catchError((_) => null);
    _periodicTimer.cancel();
    super.dispose();
  }

  // ── Color & Identity Helpers ───────────────────────────────────────────────
  Color _colorForIdentity(String? name) {
    for (final id in _identities) {
      if (id.name.toLowerCase() == name?.toLowerCase()) return id.color;
    }
    return AppPalette.textDim;
  }

  String _dateKey(int offsetDays) {
    final d = (widget.now?.call() ?? DateTime.now()).add(
      Duration(days: offsetDays),
    );
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
    return _currentTime.hour +
        _currentTime.minute / 60.0 +
        _currentTime.second / 3600.0;
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
        content: Text(
          msg,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppPalette.bg,
          ),
        ),
        backgroundColor: AppPalette.accent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Convert In-Memory Blocks to Focus Clock Activity Models ───────────────
  List<BlockItem> _blocksFromActivities(List<Activity> activities) {
    return activities.map((activity) {
      final startMinute = toUiMinute(activity.startMinute, activity.ampmHalf);
      final endMinute = toUiMinute(activity.endMinute, activity.ampmHalf);
      return BlockItem(
        id: activity.id,
        startHour: startMinute / 60.0,
        endHour: endMinute / 60.0,
        name: activity.title,
        activity: activity,
        identity: activity.description.startsWith('Identitas: ')
            ? activity.description.substring('Identitas: '.length)
            : null,
        isDone: activity.isCompleted,
      );
    }).toList();
  }

  // Schedule status and title derive from the persisted Activity projection.
  Map<String, dynamic> _getCurrentActivityInfo(
    AsyncValue<List<Activity>> state,
  ) {
    if (state.hasError) {
      return {
        'name': 'Jadwal tidak dapat dimuat',
        'isFree': false,
        'color': const Color(0xFFCC8E7B),
      };
    }
    if (state.isLoading) {
      return {
        'name': 'Memuat jadwal…',
        'isFree': false,
        'color': AppPalette.textDim,
      };
    }
    final activities = state.valueOrNull ?? const <Activity>[];
    if (activities.isEmpty) {
      return {
        'name': 'Belum ada jadwal',
        'isFree': false,
        'color': AppPalette.textDim,
      };
    }
    final nowMinute = _currentTime.hour * 60 + _currentTime.minute;
    for (final activity in activities) {
      if (activity.isCompleted) continue;
      final start = toUiMinute(activity.startMinute, activity.ampmHalf);
      final end = toUiMinute(activity.endMinute, activity.ampmHalf);
      // Zero-length/equal endpoints are not an active event.
      if (end <= start) continue;
      if (nowMinute >= start && nowMinute < end) {
        final remainingMins = end - nowMinute;
        return {
          'activityId': activity.id,
          'name': 'Terjadwal sekarang · ${activity.title}',
          'remaining': 'sisa ${remainingMins}m',
          'isFree': false,
          'color': Color(activity.colorValue),
        };
      }
    }
    final upcoming =
        activities
            .where((activity) => !activity.isCompleted)
            .map((activity) {
              final start = toUiMinute(activity.startMinute, activity.ampmHalf);
              final end = toUiMinute(activity.endMinute, activity.ampmHalf);
              return (activity: activity, start: start, end: end);
            })
            .where((item) => item.end > item.start && item.start > nowMinute)
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    if (upcoming.isNotEmpty) {
      final next = upcoming.first;
      return {
        'name':
            'Berikutnya · ${_formatHour(next.start / 60)} · ${next.activity.title}',
        'remaining': null,
        'isFree': false,
        'color': Color(next.activity.colorValue),
      };
    }
    return {
      'name': 'Tidak ada kegiatan terjadwal sekarang',
      'remaining': null,
      'isFree': false,
      'color': AppPalette.textDim,
    };
  }

  // ── Conflict Check & Add Block ─────────────────────────────────────────────
  List<BlockItem>? _scheduleBlocksForConflictCheck() {
    if (widget.useSampleData) return _blocks;
    final state = ref.read(activitiesByDateProvider);
    if (state.isLoading || state.hasError || !state.hasValue) return null;
    return _blocksFromActivities(state.valueOrNull ?? const []);
  }

  BlockItem? _findConflict(double start, double end) {
    for (final b in _scheduleBlocksForConflictCheck() ?? const <BlockItem>[]) {
      if (!b.isSleep && start < b.endHour && end > b.startHour) {
        return b;
      }
    }
    return null;
  }

  Future<String?> _addBlock(
    double start,
    double end,
    String name,
    String? identity, {
    bool isDone = false,
  }) async {
    if (_scheduleBlocksForConflictCheck() == null) {
      return 'Jadwal belum siap. Coba lagi setelah selesai dimuat.';
    }
    if (start < 0 || end > 24.0 || end <= start) {
      return 'Waktu kegiatan tidak valid.';
    }
    final conflict = _findConflict(start, end);
    if (conflict != null) {
      return 'Bentrok dengan ${conflict.name} (${_formatHour(conflict.startHour)}-${_formatHour(conflict.endHour)})';
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
      ..description = identity != null && identity.isNotEmpty
          ? 'Identitas: $identity'
          : ''
      ..isCompleted = isDone
      ..createdAt = now
      ..updatedAt = now;

    if (widget.useSampleData) {
      final id = _nextId++;
      act.id = id;
      setState(() {
        _blocks.add(
          BlockItem(
            id: id,
            startHour: start,
            endHour: end,
            name: name,
            identity: identity,
            activity: act,
            isDone: isDone,
          ),
        );
      });
    } else {
      try {
        await ref.read(activityRepoProvider).upsert(act);
      } catch (_) {
        return 'Jadwal belum tersimpan. Coba lagi.';
      }
    }
    return null;
  }

  Future<String?> _scheduleInboxTask(
    Task? task,
    double startHour,
    int duration,
    String identity, {
    String? title,
    int? habitId,
  }) async {
    final now = widget.now?.call() ?? DateTime.now();
    final start = dateOnly(
      now,
    ).add(Duration(minutes: (startHour * 60).round()));
    if (start.isBefore(now)) return 'Waktu mulai sudah lewat.';
    if (duration <= 0) return 'Durasi tidak valid.';
    if (widget.useSampleData) {
      if (startHour >= 24 || startHour + duration / 60 > 24) {
        return 'Pratinjau belum mendukung jadwal melewati tengah malam.';
      }
      final error = await _addBlock(
        startHour,
        startHour + duration / 60,
        task?.title ?? title ?? '',
        identity,
      );
      if (error == null && task != null) {
        setState(() => _dumpedTasks.removeWhere((t) => t.id == task.id));
      }
      return error;
    }
    final store = ref.read(taskRepoProvider).isar;
    if (store == null || !store.isDurable) return 'Penyimpanan tidak tersedia.';
    late final List<Activity> created;
    try {
      created = await HomeScheduleService(store).schedule(
        taskId: task?.id,
        habitId: habitId,
        title: task?.title ?? title ?? '',
        start: start,
        durationMinutes: duration,
        now: now,
        colorValue: _colorForIdentity(identity).value,
        identity: identity,
      );
    } on StateError catch (e) {
      return e.message.toString();
    } catch (_) {
      return 'Jadwal belum tersimpan. Coba lagi.';
    }
    try {
      await ref
          .read(notificationServiceProvider)
          .scheduleForActivity(created.first, leadMinutes: 1);
    } catch (_) {
      // The transaction is committed; notification errors must not trigger a retry.
    }
    return null;
  }

  // ── Timer Logic ────────────────────────────────────────────────────────────
  Future<void> _startTimer(
    String label,
    int minutes, {
    String? source,
    int? sourceId,
    String? identity,
    String? goalId,
    String? goalTitle,
  }) async {
    final engine = ref.read(timerEngineProvider.notifier);
    await engine.waitUntilRestored();
    if (source == 'habit') {
      if (ref.read(timerEngineProvider).isActive) return;
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
      return;
    }
    if (ref.read(timerEngineProvider).isActive ||
        ref.read(timerEngineProvider).isSavePending) {
      _showToast('Selesaikan sesi aktif sebelum memulai timer lain.');
      return;
    }
    final kind = switch (source) {
      'preset' => TimerSessionSourceKind.preset,
      'block' when !widget.useSampleData => TimerSessionSourceKind.activity,
      _ => TimerSessionSourceKind.free,
    };
    bool started;
    try {
      started = await engine.startNonHabit(
        title: label,
        targetSeconds: minutes * 60,
        sourceKind: kind,
        activityId: kind == TimerSessionSourceKind.activity ? sourceId : null,
        sourceIdentity: kind == TimerSessionSourceKind.preset ? identity : null,
        goalId: goalId,
        goalTitle: goalTitle,
        sourceColorValue: kind == TimerSessionSourceKind.preset
            ? _colorForIdentity(identity).value
            : null,
      );
    } catch (_) {
      if (mounted) _showToast('Timer belum tersimpan. Coba lagi.');
      return;
    }
    if (!started || !mounted) return;
    HapticFeedback.mediumImpact();
    const MethodChannel('fitrah_launcher/apps')
        .invokeMethod('setLockscreenFocus', {'enabled': true})
        .catchError((_) => null);
    setState(() => _currentScreen = 'timer');
  }

  Future<void> _toggleTimer(ActiveTimer timer) async {
    HapticFeedback.selectionClick();
    if (timer.source != 'habit') {
      final engine = ref.read(timerEngineProvider.notifier);
      if (timer.isRunning) {
        try {
          await engine.pause();
        } catch (_) {
          if (mounted) _showToast('Jeda belum tersimpan. Coba lagi.');
        }
      } else {
        try {
          await engine.resume();
        } catch (_) {
          if (mounted) _showToast('Timer belum dilanjutkan. Coba lagi.');
        }
      }
      return;
    }
    setState(() {
      if (timer.isRunning) {
        if (timer.endsAt != null) {
          timer.leftSeconds = math.max(
            0,
            timer.endsAt!.difference(DateTime.now()).inSeconds,
          );
        }
        timer.endsAt = null;
        timer.isRunning = false;
      } else {
        timer.isRunning = true;
        timer.endsAt = DateTime.now().add(Duration(seconds: timer.leftSeconds));
        if (!timer.hasStarted) {
          timer.hasStarted = true;
          timer.startHour = _hourNow();
        }
      }
    });
  }

  Future<void> _finishTimer({bool autoComplete = false}) async {
    if (_activeTimer == null || _isFinishingTimer) return;
    _isFinishingTimer = true;
    HapticFeedback.heavyImpact();
    final timer = _activeTimer!;
    final src = timer.source;
    String message = 'Timer selesai';

    final engine = ref.read(timerEngineProvider.notifier);
    if (src != 'habit' && ref.read(timerEngineProvider).isSavePending) {
      try {
        await engine.retryCompletion();
      } catch (_) {
        if (mounted) _showToast('Timer belum tersimpan. Coba lagi.');
        _isFinishingTimer = false;
        return;
      }
    } else if (src != 'habit' && ref.read(timerEngineProvider).isActive) {
      try {
        await engine.finishEarly();
      } catch (_) {
        if (mounted) _showToast('Timer belum tersimpan. Coba lagi.');
        _isFinishingTimer = false;
        return;
      }
    }

    if (src == 'habit' && timer.sourceId != null) {
      for (final h in _habits) {
        if (h.id == timer.sourceId) {
          h.isDone = true;
          h.isRunning = false;
          h.isSkipped = false;
          h.elapsedSeconds = h.minutes != null
              ? h.minutes! * 60
              : timer.totalSeconds;
          message = 'Kebiasaan ditandai selesai';
          break;
        }
      }
      try {
        final now = DateTime.now();
        final todayStr = DateFormat('yyyy-MM-dd').format(now);
        ref
            .read(sadarRepoProvider)
            .recordEntryStatus(
              habitId: timer.sourceId!,
              dateString: todayStr,
              status: HabitStatus.yes,
            );
      } catch (_) {}
    } else if (src == 'preset') {
      message = 'Preset selesai dan tersimpan';
    } else if (src == 'block' && timer.sourceId != null) {
      if (widget.useSampleData) {
        for (final b in _blocks) {
          if (b.id == timer.sourceId) {
            b.isDone = true;
            message = 'Blok ditandai selesai';
            break;
          }
        }
      } else {
        message = 'Blok ditandai selesai';
      }
    }

    const MethodChannel('fitrah_launcher/apps')
        .invokeMethod('setLockscreenFocus', {'enabled': false})
        .catchError((_) => null);

    if (mounted) {
      setState(() {
        _activeTimer = null;
        _currentScreen = 'home';
      });
      _showToast(message);
    }
    _isFinishingTimer = false;
  }

  Future<void> _openIntentTask(
    Task task, {
    String? goalId,
    String? goalTitle,
  }) async {
    if (task.activityId != null) {
      final activity = await ref
          .read(activityRepoProvider)
          .get(task.activityId!);
      if (activity == null) {
        throw StateError(
          'Jadwal tugas tidak tersedia. Buka Jadwal untuk memperbaikinya.',
        );
      }
      if (!mounted) return;
      final block = _blocksFromActivities([activity]).single;
      await _startTimer(
        block.name,
        math.max(1, ((block.endHour - block.startHour) * 60).round()),
        source: 'block',
        sourceId: activity.id,
        identity: block.identity,
        goalId: goalId,
        goalTitle: goalTitle,
      );
      return;
    }
    if (task.startMinute != null && task.endMinute != null) {
      final date = task.date;
      if (date == null) {
        throw StateError('Tanggal jadwal tugas tidak tersedia.');
      }
      ref.read(currentDateProvider.notifier).state = dateOnly(date);
      ref.read(ampmHalfProvider.notifier).state = task.ampmHalf;
      widget.onOpenFocusClock();
      return;
    }
    await _startTimer(
      task.title,
      homeQuickTaskFocusMinutes,
      source: 'free',
      goalId: goalId,
      goalTitle: goalTitle,
    );
  }

  void _openHabitFocusTimer(Habit habit) {
    _pushHabitFocusTimer(habit);
  }

  void _openAttributedHabitFocusTimer(
    Habit habit,
    String? goalId,
    String? goalTitle,
  ) {
    _pushHabitFocusTimer(habit, goalId: goalId, goalTitle: goalTitle);
  }

  void _pushHabitFocusTimer(Habit habit, {String? goalId, String? goalTitle}) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (routeContext) => SadarTimerView(
            habit: habit,
            goalId: goalId,
            goalTitle: goalTitle,
            onClose: () => Navigator.of(routeContext).pop(),
          ),
        ),
      ),
    );
  }

  // ── Prayers Calculation ───────────────────────────────────────────────────
  List<Map<String, dynamic>> _getPrayerList(LauncherSettings settings) {
    return [
      {
        'name': 'Subuh',
        'time': settings.prayerSubuh,
        'hour': _timeStringToHour(settings.prayerSubuh),
      },
      {
        'name': 'Dzuhur',
        'time': settings.prayerDzuhur,
        'hour': _timeStringToHour(settings.prayerDzuhur),
      },
      {
        'name': 'Asar',
        'time': settings.prayerAshar,
        'hour': _timeStringToHour(settings.prayerAshar),
      },
      {
        'name': 'Maghrib',
        'time': settings.prayerMaghrib,
        'hour': _timeStringToHour(settings.prayerMaghrib),
      },
      {
        'name': 'Isya',
        'time': settings.prayerIsya,
        'hour': _timeStringToHour(settings.prayerIsya),
      },
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

  Map<String, dynamic> _calculateNextPrayer(
    List<Map<String, dynamic>> prayers,
  ) {
    final nowH = _hourNow();
    for (int i = 0; i < prayers.length; i++) {
      final pHour = prayers[i]['hour'] as double;
      if (pHour > nowH) {
        return {
          'index': i,
          'name': prayers[i]['name'],
          'diffHours': pHour - nowH,
        };
      }
    }
    final firstFajr = prayers[0]['hour'] as double;
    return {
      'index': 0,
      'name': prayers[0]['name'],
      'diffHours': 24.0 - nowH + firstFajr,
    };
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
    final activitiesState = widget.useSampleData
        ? AsyncData<List<Activity>>(_sampleActivities())
        : ref.watch(activitiesByDateProvider);
    final focusSessionsState = widget.useSampleData
        ? const AsyncData<List<TerminalFocusSession>>([])
        : ref.watch(terminalFocusSessionsForDateProvider(_dateKey(0)));
    final prayers = _getPrayerList(settings);
    final nextPrayer = _calculateNextPrayer(prayers);
    final hr = _hourNow();
    final currentAct = _getCurrentActivityInfo(activitiesState);
    final tc = _HomeThemeColors.fromPalette(settings.themePalette);
    final showPrayerSchedule =
        settings.showPrayerTimes &&
        settings.widgetDisplayMode == 'prayer' &&
        settings.prayerTimesVerified;
    final showPrayerSetupCue =
        settings.showPrayerTimes &&
        settings.widgetDisplayMode == 'prayer' &&
        !settings.prayerTimesVerified;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              key: const ValueKey('focus-clock-home-list'),
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                // Keep navigation at the top; it must not split the goal cue
                // from the clock that makes the day visible.
                _buildTopHeaderBar(
                  prayers,
                  nextPrayer,
                  tc,
                  activitiesState,
                  showPrayerSchedule: showPrayerSchedule,
                  showPrayerSetupCue: showPrayerSetupCue,
                  currentActivityId: currentAct['activityId'] as int?,
                  showAgendaWidget: settings.showAgendaWidget,
                ),
                const SizedBox(height: 12),
                widget.useSampleData
                    ? _buildFocusGoalCue(settings.focusGoal, tc)
                    : HomeIntentCue(
                        foreground: tc.textPrimary,
                        secondary: tc.textSecondary,
                        accent: tc.accent,
                        surface: tc.card,
                        onHabitTimer: _openHabitFocusTimer,
                        onAttributedHabitTimer: _openAttributedHabitFocusTimer,
                        onHabitSchedule: (habit) =>
                            _openScheduleToClockSheet(initialHabit: habit),
                        onTaskSchedule: (task) => _openScheduleToClockSheet(
                          inboxTask: task,
                          title: task.title,
                        ),
                        onAssistant: _openGoalAssistant,
                        onTaskAction: _openIntentTask,
                        onAddTask: () =>
                            _openQuickDumpTaskDialog(tc, startToday: true),
                        onSession: () =>
                            setState(() => _currentScreen = 'timer'),
                      ),
                if (settings.showDate) ...[
                  const SizedBox(height: 12),
                  _buildHomeDateCue(tc),
                ],
                if (!widget.useSampleData)
                  _buildTodayFocusSummary(tc, focusSessionsState),
                const SizedBox(height: 14),
                // ── Center Focus Clock Analog Face Dial with AM/PM pill switch ──
                _isListView
                    ? _buildChronologicalListView(activitiesState, tc)
                    : _buildCenterFocusClockDial(
                        hr,
                        currentAct,
                        activitiesState,
                        tc,
                        showHeroEvent: settings.showHeroEvent,
                        compact: true,
                      ),
                const SizedBox(height: 14),

                // Habits stay close to the goal and clock cue.
                if (settings.showHabitsWidget)
                  Column(
                    key: const ValueKey('home-habit-grid'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Kebiasaan hari ini',
                                style: TextStyle(
                                  color: tc.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: widget.onOpenHabits,
                              child: const Text('Semua'),
                            ),
                          ],
                        ),
                      ),
                      LoopHabitGridWidget(
                        onStartTimer: _openHabitFocusTimer,
                        maxHabits: 3,
                      ),
                    ],
                  ),
                const SizedBox(height: 14),

                // Keep the home screen centered on today's intention, clock,
                // and habits. Supporting tools stay one tap away below.
                Theme(
                  data: theme.copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: tc.accent.withOpacity(0.08),
                    highlightColor: tc.accent.withOpacity(0.04),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                    childrenPadding: EdgeInsets.zero,
                    collapsedShape: const RoundedRectangleBorder(),
                    shape: const RoundedRectangleBorder(),
                    iconColor: tc.textSecondary,
                    collapsedIconColor: tc.textSecondary,
                    title: Text(
                      'Catatan & alat',
                      style: TextStyle(
                        color: tc.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Jurnal, kotak masuk, dan timer',
                      style: TextStyle(color: tc.textSecondary, fontSize: 12),
                    ),
                    children: [
                      if (!widget.useSampleData) ...[
                        _buildTodayFocusHistory(tc, focusSessionsState),
                        const SizedBox(height: 14),
                      ],
                      _buildObsidianDailyNoteCard(tc),
                      const SizedBox(height: 14),
                      _buildTaskDumpSection(tc),
                      const SizedBox(height: 14),
                      _buildUnifiedPresetSection(tc),
                      if (widget.useSampleData &&
                          settings.showHabitsWidget) ...[
                        const SizedBox(height: 14),
                        _buildUnifiedHabitSection(tc),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayFocusSummary(
    _HomeThemeColors tc,
    AsyncValue<List<TerminalFocusSession>> history,
  ) {
    final sessions = history.valueOrNull;
    if (sessions == null) return const SizedBox.shrink();
    final completedSeconds = sessions
        .where((s) => s.status == TerminalSessionStatus.completed)
        .fold<int>(0, (sum, s) => sum + s.actualDurationSeconds);
    if (completedSeconds <= 0) return const SizedBox.shrink();
    final label =
        'Fokus hari ini · ${_formatSessionDuration(completedSeconds)}';
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2),
      child: Semantics(
        label: label,
        child: ExcludeSemantics(
          child: Row(
            children: [
              Icon(Icons.timelapse_rounded, size: 16, color: tc.textMuted),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tc.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayFocusHistory(
    _HomeThemeColors tc,
    AsyncValue<List<TerminalFocusSession>> history,
  ) {
    return history.when(
      loading: () => _focusHistoryCard(
        tc,
        Text(
          'Memuat sesi hari ini…',
          style: TextStyle(color: tc.textSecondary),
        ),
      ),
      error: (_, __) => _focusHistoryCard(
        tc,
        Text(
          'Histori sesi belum dapat dimuat.',
          style: TextStyle(color: tc.textSecondary),
        ),
      ),
      data: (sessions) {
        if (sessions.isEmpty) return const SizedBox.shrink();
        return _focusHistoryCard(
          tc,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history_rounded, size: 18, color: tc.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Riwayat sesi',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tc.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              for (final session in sessions)
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Row(
                    children: [
                      Icon(
                        session.status == TerminalSessionStatus.cancelled
                            ? Icons.close_rounded
                            : Icons.check_rounded,
                        size: 16,
                        color: session.status == TerminalSessionStatus.cancelled
                            ? tc.textMuted
                            : tc.accent,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.titleSnapshot,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: tc.textPrimary),
                            ),
                            if (session.goalTitleSnapshot != null)
                              Text(
                                'Tujuan: ${session.goalTitleSnapshot}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: tc.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        session.status == TerminalSessionStatus.cancelled
                            ? 'Dibatalkan'
                            : _formatSessionDuration(
                                session.actualDurationSeconds,
                              ),
                        style: TextStyle(color: tc.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _focusHistoryCard(_HomeThemeColors tc, Widget child) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: tc.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: tc.stroke),
    ),
    child: child,
  );

  String _formatSessionDuration(int seconds) {
    final safeSeconds = math.max(0, seconds);
    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final remainderSeconds = safeSeconds % 60;
    return [
      if (hours > 0) '$hours jam',
      if (minutes > 0) '$minutes menit',
      if (remainderSeconds > 0 || (hours == 0 && minutes == 0))
        '$remainderSeconds detik',
    ].join(' ');
  }

  List<Activity> _sampleActivities() {
    final now = DateTime.now();
    return _blocks.where((block) => !block.isSleep).map((block) {
      final start = (block.startHour * 60).round();
      final end = (block.endHour * 60).round();
      final half = block.startHour < 12 ? AmPmHalf.am : AmPmHalf.pm;
      return Activity()
        ..id = block.id
        ..title = block.name
        ..startMinute = start % 720
        ..endMinute = toDbEndMinute(end, half)
        ..ampmHalf = half
        ..date = dateOnly(now)
        ..colorValue = _colorForIdentity(block.identity).value
        ..description = block.identity == null
            ? ''
            : 'Identitas: ${block.identity}'
        ..isCompleted = block.isDone
        ..createdAt = now
        ..updatedAt = now;
    }).toList();
  }

  // ── Top Header Bar (Now/Next Carousel or Prayer Timeline) ──────────────────
  Widget _buildTopHeaderBar(
    List<Map<String, dynamic>> prayers,
    Map<String, dynamic> nextPrayer,
    _HomeThemeColors tc,
    AsyncValue<List<Activity>> activitiesState, {
    required bool showPrayerSchedule,
    required bool showPrayerSetupCue,
    required int? currentActivityId,
    required bool showAgendaWidget,
  }) {
    return Row(
      children: [
        // Hamburger Menu Button
        InkWell(
          key: const ValueKey('home-menu-button'),
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
          child: showPrayerSchedule
              ? Builder(
                  builder: (context) {
                    final index = nextPrayer['index'] as int;
                    final prayer = prayers[index];
                    final isDone = _prayerDone[index] == true;
                    return InkWell(
                      key: const ValueKey('home-prayer-schedule-cue'),
                      onTap: () => _openPrayerScheduleSheet(prayers, index, tc),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: tc.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: tc.stroke),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.mosque_outlined,
                              size: 18,
                              color: isDone ? tc.textSecondary : tc.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                prayer['name'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDone
                                      ? tc.textSecondary
                                      : tc.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              prayer['time'] as String,
                              style: TextStyle(
                                color: isDone ? tc.textSecondary : tc.accent,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : showPrayerSetupCue
              ? InkWell(
                  key: const ValueKey('home-prayer-setup-cue'),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const LauncherCustomizationSheet(),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: math.max(
                        44,
                        MediaQuery.textScalerOf(context).scale(14) * 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: tc.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tc.stroke),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.mosque_outlined, size: 18, color: tc.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Atur jadwal salat',
                            style: TextStyle(
                              color: tc.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: tc.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                )
              : showAgendaWidget
              ? KeyedSubtree(
                  key: const ValueKey('home-agenda-carousel'),
                  child: _buildAgendaCarousel(
                    activitiesState,
                    tc,
                    currentActivityId: currentActivityId,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // Horizontal Scrollable Agenda Carousel (Focus Clock Now & Next)
  Widget _buildAgendaCarousel(
    AsyncValue<List<Activity>> activitiesState,
    _HomeThemeColors tc, {
    int? currentActivityId,
  }) {
    final nonSleep =
        _blocksFromActivities(
            activitiesState.valueOrNull ?? const [],
          ).where((block) => block.id != currentActivityId).toList()
          ..sort((a, b) => a.startHour.compareTo(b.startHour));

    if (activitiesState.hasError || activitiesState.isLoading) {
      return _scheduleStatusPill(
        activitiesState.hasError
            ? 'Jadwal tidak dapat dimuat'
            : 'Memuat jadwal…',
        tc,
      );
    }
    if (nonSleep.isEmpty) {
      return Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: tc.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tc.stroke),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          currentActivityId == null
              ? 'Belum ada jadwal hari ini.'
              : 'Jadwal sedang berjalan.',
          style: TextStyle(color: tc.textSecondary, fontSize: 12),
        ),
      );
    }

    final hr = _hourNow();

    final textScaler = MediaQuery.textScalerOf(context);
    final agendaItemHeight = math.max(
      44.0,
      textScaler.scale(12) * 1.5 + textScaler.scale(10) * 1.5 + 10,
    );

    return SizedBox(
      height: agendaItemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: nonSleep.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final b = nonSleep[i];
          final isCurrent =
              hr >= b.startHour && hr < b.endHour && b.endHour > b.startHour;
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
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                    ),
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
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w600,
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

  Widget _scheduleStatusPill(String message, _HomeThemeColors tc) => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: tc.card,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: tc.stroke),
    ),
    alignment: Alignment.centerLeft,
    child: Text(
      message,
      style: TextStyle(color: tc.textSecondary, fontSize: 12),
    ),
  );

  // ── Center Focus Clock Analog Face Dial ───────────────────────────────────
  // ── Center Focus Clock Analog Face Dial (Compact 215x215, Clean Pie / Dial) ──
  Widget _buildAmPmPill(
    String text,
    bool active,
    VoidCallback onTap,
    _HomeThemeColors tc,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? tc.accent.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: active ? Border.all(color: tc.accent, width: 1.0) : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? tc.accent : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderToolPill({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required _HomeThemeColors tc,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? tc.accent.withOpacity(0.2)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? tc.accent : Colors.white.withOpacity(0.08),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? tc.accent : Colors.white70),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? tc.accent : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Center Focus Clock Analog Face Dial (Spacious 240x240, Clean 12h + AM/PM) ──
  Widget _buildCenterFocusClockDial(
    double hr,
    Map<String, dynamic> currentAct,
    AsyncValue<List<Activity>> activitiesState,
    _HomeThemeColors tc, {
    required bool showHeroEvent,
    bool compact = false,
  }) {
    final effectiveActivities =
        activitiesState.valueOrNull ?? const <Activity>[];
    final compactDialSize = (MediaQuery.sizeOf(context).width * 0.45)
        .clamp(148.0, 208.0)
        .toDouble();

    return Container(
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tc.stroke, width: 1.0),
      ),
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        children: [
          if (compact) ...[
            Row(
              children: [
                Semantics(
                  key: const ValueKey('home-analog-clock'),
                  button: true,
                  label:
                      'Buka jam jadwal. Sekarang pukul ${_formatHour(_hourNow())}.',
                  onTap: widget.onOpenFocusClock,
                  child: GestureDetector(
                    excludeFromSemantics: true,
                    onTap: widget.onOpenFocusClock,
                    child: SizedBox(
                      width: compactDialSize,
                      height: compactDialSize,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: 240,
                          height: 240,
                          child: AnalogClockFace(
                            now: _currentTime,
                            activities: effectiveActivities,
                            tasks: const [],
                            viewHalf: _clockViewHalf,
                            clockHandsMode: 1,
                            is24hDial: false,
                            is24hTime: false,
                            showCurrentTime: false,
                            clockFaceTheme: tc.clockThemeIndex,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SEKARANG',
                        style: TextStyle(
                          color: tc.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatHour(hr),
                        style: TextStyle(
                          color: tc.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentAct['name'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tc.textSecondary, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: widget.onOpenFocusClock,
                        style: TextButton.styleFrom(
                          foregroundColor: tc.accent,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 44),
                        ),
                        icon: const Icon(Icons.schedule_rounded, size: 18),
                        label: const Text('Buka jam'),
                      ),
                      TextButton.icon(
                        key: const ValueKey('home-open-focus-timer'),
                        onPressed: _openFocusTimerHub,
                        style: TextButton.styleFrom(
                          foregroundColor: tc.accent,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 44),
                          alignment: Alignment.centerLeft,
                        ),
                        icon: const Icon(Icons.timer_outlined, size: 18),
                        label: const Text('Timer'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Keep every labeled action visible on narrow phone screens.
            Builder(
              builder: (context) {
                final amPmSelector = Container(
                  decoration: BoxDecoration(
                    color: tc.cardElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: tc.stroke, width: 1.0),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAmPmPill('AM', _clockViewHalf == AmPmHalf.am, () {
                        HapticFeedback.selectionClick();
                        setState(() => _clockViewHalf = AmPmHalf.am);
                      }, tc),
                      _buildAmPmPill('PM', _clockViewHalf == AmPmHalf.pm, () {
                        HapticFeedback.selectionClick();
                        setState(() => _clockViewHalf = AmPmHalf.pm);
                      }, tc),
                    ],
                  ),
                );
                final timerTool = _buildHeaderToolPill(
                  icon: Icons.timer_outlined,
                  label: 'Timer',
                  isActive: _activeTimer != null && _activeTimer!.isRunning,
                  onTap: _openFocusTimerHub,
                  tc: tc,
                );

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [amPmSelector, timerTool],
                );
              },
            ),
            const SizedBox(height: 18),

            // Center 12h Analog Clock Face
            Semantics(
              key: const ValueKey('home-analog-clock'),
              button: true,
              label:
                  'Jam jadwal hari ini. Sekarang pukul ${_formatHour(_hourNow())}. Ketuk untuk menambah jadwal.',
              onTap: _openScheduleFromClock,
              child: GestureDetector(
                excludeFromSemantics: true,
                onTap: _openScheduleFromClock,
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: AnalogClockFace(
                    now: _currentTime,
                    activities: effectiveActivities,
                    tasks: const [],
                    viewHalf: _clockViewHalf,
                    clockHandsMode: 1,
                    is24hDial: false,
                    is24hTime: false,
                    showCurrentTime: true,
                    clockFaceTheme: tc.clockThemeIndex,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Instant User Clarity Status Badge (Current Time + What Am I Doing Now)
            if (showHeroEvent) ...[
              Row(
                key: const ValueKey('home-current-event'),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (currentAct['color'] as Color).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (currentAct['color'] as Color).withOpacity(
                            0.5,
                          ),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: currentAct['color'] as Color,
                              shape: BoxShape.circle,
                            ),
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
              const SizedBox(height: 10),
            ],

            // Clean Inline Tap Button to Schedule Activity
            InkWell(
              onTap: () => _openScheduleToClockSheet(
                title: '',
                initialDurationMinutes: 60,
                identity: '',
              ),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tc.accent.withOpacity(0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: tc.accent, size: 15),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Pasang Jadwal ke Jam',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tc.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Obsidian Daily Note Card (Direct friction-free scratchpad) ─────────────
  Widget _buildObsidianDailyNoteCard(_HomeThemeColors tc) {
    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final date = DateTime.parse(_dailyNoteDate);
    return Container(
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.stroke, width: 0.6),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note_rounded, size: 18, color: tc.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Catatan hari ini',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      color: tc.textPrimary,
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Text(
                  '${weekdays[date.weekday - 1]}, ${date.day} '
                  '${months[date.month - 1]}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: tc.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            key: const ValueKey('home-daily-note-input'),
            enabled: ref.read(launcherSettingsProvider.notifier).isLoaded,
            controller: _dailyNoteController,
            maxLines: 4,
            minLines: 1,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              height: 1.45,
              color: tc.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
            onChanged: (val) {
              _dailyNote = val;
              _saveDailyNote();
            },
          ),
          if (_dailyNoteStatus.isNotEmpty)
            Row(
              children: [
                Text(
                  _dailyNoteStatus,
                  style: TextStyle(fontSize: 11, color: tc.textSecondary),
                ),
                if (_dailyNoteStatus == 'Gagal menyimpan' ||
                    _dailyNoteStatus == 'Gagal memuat')
                  TextButton(
                    onPressed: _dailyNoteStatus == 'Gagal memuat'
                        ? () => ref
                              .read(launcherSettingsProvider.notifier)
                              .reload()
                        : _saveDailyNote,
                    child: const Text('Coba lagi'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _saveDailyNote() async {
    final revision = ++_dailyNoteRevision;
    final date = _dailyNoteDate;
    final value = _dailyNote;
    setState(() => _dailyNoteStatus = 'Menyimpan…');
    final saved = await ref
        .read(launcherSettingsProvider.notifier)
        .setDailyNote(date, value);
    if (mounted && revision == _dailyNoteRevision && date == _dailyNoteDate) {
      setState(
        () => _dailyNoteStatus = saved ? 'Tersimpan' : 'Gagal menyimpan',
      );
    }
  }

  // ── Chronological List View Fallback ──────────────────────────────────────
  Widget _buildChronologicalListView(
    AsyncValue<List<Activity>> activitiesState,
    _HomeThemeColors tc,
  ) {
    if (activitiesState.hasError || activitiesState.isLoading) {
      return _scheduleStatusPill(
        activitiesState.hasError
            ? 'Jadwal tidak dapat dimuat. Coba lagi.'
            : 'Memuat jadwal…',
        tc,
      );
    }
    final nonSleep = _blocksFromActivities(
      activitiesState.valueOrNull ?? const [],
    )..sort((a, b) => a.startHour.compareTo(b.startHour));

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
          'Belum ada jadwal hari ini.',
          textAlign: TextAlign.center,
          style: TextStyle(color: tc.textSecondary, fontSize: 13),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tc.stroke, width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Blok Waktu',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: tc.textPrimary,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.schedule_rounded, size: 16),
                  label: const Text('Ke Jam'),
                  style: TextButton.styleFrom(
                    foregroundColor: tc.accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                  onPressed: () => setState(() => _isListView = false),
                ),
              ],
            ),
          ),
          Divider(color: tc.stroke, height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                    final durationMins = math.max(
                      1,
                      ((b.endHour - b.startHour) * 60).round(),
                    );
                    _startTimer(
                      b.name,
                      durationMins,
                      source: 'block',
                      sourceId: b.id,
                      identity: b.identity,
                    );
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
                  b.isDone ? '${b.name} (selesai)' : b.name,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: b.isDone ? tc.textMuted : tc.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${_formatHour(b.startHour)} - ${_formatHour(b.endHour)}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: tc.textSecondary,
                  ),
                ),
                onTap: () => _openBlockDetailSheet(b),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION: UNIFIED PRESET & HABIT SECTIONS (Sadar Prototype & Lampiran 1)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildUnifiedPresetSection(_HomeThemeColors tc) {
    if (_identities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'Blok waktu',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: tc.textPrimary,
          ),
        ),
      );
    }
    final activeIdentity = _identities.firstWhere(
      (id) => id.name.toLowerCase() == _selectedPresetIdentity.toLowerCase(),
      orElse: () => _identities.first,
    );

    final presets = _presets
        .where(
          (p) => p.identity.toLowerCase() == activeIdentity.name.toLowerCase(),
        )
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tc.stroke, width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Preset Blok Waktu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: tc.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              // Filter pill for user-created identities.
              InkWell(
                onTap: _openPresetIdentityFilterSheet,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tc.cardElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: activeIdentity.color.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: activeIdentity.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Identitas: ${activeIdentity.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: activeIdentity.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: activeIdentity.color,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              // Round (+) Button for adding preset
              InkWell(
                onTap: () => _openNewPresetForIdentitySheet(activeIdentity),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: tc.cardElevated,
                    shape: BoxShape.circle,
                    border: Border.all(color: tc.stroke),
                  ),
                  child: Icon(Icons.add, color: tc.textPrimary, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (presets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Belum ada preset untuk ${activeIdentity.name}. Ketuk + di atas.',
                  style: TextStyle(color: tc.textSecondary, fontSize: 12),
                ),
              ),
            )
          else
            ...presets.map((p) => _buildPresetRow(p, activeIdentity.color, tc)),
        ],
      ),
    );
  }

  Widget _buildUnifiedHabitSection(_HomeThemeColors tc) {
    final habits = _habits.where((h) {
      if (_selectedHabitIdentity == 'Semua') return true;
      return h.identity.toLowerCase() == _selectedHabitIdentity.toLowerCase();
    }).toList();

    final doneCount = habits.where((h) => h.isDone).length;
    final totalCount = habits.length;

    return Container(
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tc.stroke, width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Kebiasaan & Rutinitas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: tc.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              if (totalCount > 0)
                Text(
                  '$doneCount dari $totalCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: tc.textSecondary,
                  ),
                ),
              // Filter pill: Semua ▾
              InkWell(
                onTap: _openHabitFilterSheet,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tc.cardElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tc.stroke),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedHabitIdentity,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tc.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: tc.textSecondary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Round (+) Button for adding habit
              InkWell(
                onTap: () {
                  final identity = _identities.firstWhere(
                    (id) =>
                        _selectedHabitIdentity != 'Semua' &&
                        id.name.toLowerCase() ==
                            _selectedHabitIdentity.toLowerCase(),
                    orElse: () => _identities.isNotEmpty
                        ? _identities.first
                        : IdentityItem(
                            id: 'fokus',
                            name: 'Fokus',
                            color: AppPalette.accent,
                          ),
                  );
                  _openNewHabitForIdentitySheet(identity);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: tc.cardElevated,
                    shape: BoxShape.circle,
                    border: Border.all(color: tc.stroke),
                  ),
                  child: Icon(Icons.add, color: tc.textPrimary, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (habits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Belum ada kebiasaan di sini. Ketuk + untuk membuat.',
                  style: TextStyle(color: tc.textSecondary, fontSize: 12),
                ),
              ),
            )
          else
            ...habits.map(
              (h) => _buildHabitRow(h, _colorForIdentity(h.identity), tc),
            ),
        ],
      ),
    );
  }

  void _openPresetIdentityFilterSheet() {
    final tc = _HomeThemeColors.fromPalette(
      ref.read(launcherSettingsProvider).themePalette,
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: tc.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pilih Identitas Preset',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.text,
                ),
              ),
              const SizedBox(height: 12),
              ..._identities.map(
                (id) => ListTile(
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: id.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    id.name,
                    style: TextStyle(
                      color: tc.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing:
                      _selectedPresetIdentity.toLowerCase() ==
                          id.name.toLowerCase()
                      ? Icon(Icons.check, color: tc.accent, size: 18)
                      : null,
                  onTap: () {
                    setState(() => _selectedPresetIdentity = id.name);
                    Navigator.pop(ctx);
                  },
                ),
              ),
              Divider(color: tc.stroke),
              ListTile(
                leading: Icon(Icons.add_circle_outline, color: tc.accent),
                title: Text(
                  'Tambah Identitas Baru',
                  style: TextStyle(
                    color: tc.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateNewIdentityDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openHabitFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppPalette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Filter Kebiasaan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.text,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.apps_rounded,
                  color: AppPalette.textDim,
                ),
                title: const Text(
                  'Semua',
                  style: TextStyle(
                    color: AppPalette.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: _selectedHabitIdentity == 'Semua'
                    ? const Icon(
                        Icons.check,
                        color: Color(0xFF5FD0A5),
                        size: 18,
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedHabitIdentity = 'Semua');
                  Navigator.pop(ctx);
                },
              ),
              ..._identities.map(
                (id) => ListTile(
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: id.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    id.name,
                    style: const TextStyle(
                      color: AppPalette.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing:
                      _selectedHabitIdentity.toLowerCase() ==
                          id.name.toLowerCase()
                      ? const Icon(
                          Icons.check,
                          color: Color(0xFF5FD0A5),
                          size: 18,
                        )
                      : null,
                  onTap: () {
                    setState(() => _selectedHabitIdentity = id.name);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresetRow(
    PresetItem p,
    Color identityColor,
    _HomeThemeColors tc,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // ▶ Play Button (Starts Timer & Records Block on Finish)
          InkWell(
            key: ValueKey('preset_play_${p.id}'),
            onTap: () => _startTimer(
              p.name,
              p.minutes,
              source: 'preset',
              sourceId: p.id,
              identity: p.identity,
            ),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: identityColor, width: 1.5),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: identityColor,
                size: 20,
              ),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: tc.textPrimary,
                  ),
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

  Widget _buildHabitRow(
    HabitModel h,
    Color identityColor,
    _HomeThemeColors tc,
  ) {
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
                      h.isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
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
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        h.isDaily ? 'Harian' : 'Sekali saja',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: h.isDaily
                              ? const Color(0xFF5FD0A5)
                              : const Color(0xFF8FB8E8),
                        ),
                      ),
                      if (hasTimer)
                        Text(
                          '${elapsedSecs ~/ 60} / ${h.minutes}m',
                          style: TextStyle(
                            fontSize: 10,
                            color: tc.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  if (hasTimer) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: tc.stroke,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          identityColor,
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildHomeDateCue(_HomeThemeColors tc) {
    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final date = _currentTime;
    final gregorian =
        '${weekdays[date.weekday - 1]}, ${date.day} '
        '${months[date.month - 1]} ${date.year}';
    final hijri = HijriCalendarHelper.formatHijri(date);

    return Semantics(
      key: const ValueKey('home-date-hijri'),
      label: '$gregorian. Hijriah $hijri.',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.calendar_today_rounded, color: tc.textMuted, size: 15),
            const SizedBox(width: 7),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gregorian,
                    style: TextStyle(
                      color: tc.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Hijriah · $hijri',
                    style: TextStyle(color: tc.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusGoalCue(String goal, _HomeThemeColors tc) {
    final hasGoal = goal.trim().isNotEmpty;
    return Semantics(
      button: true,
      label: hasGoal
          ? 'Tujuan hari ini: $goal. Ubah tujuan.'
          : 'Tambahkan tujuan hari ini',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _editFocusGoal,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: tc.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tc.stroke),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TUJUAN HARI INI',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: tc.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasGoal ? goal : 'Apa yang ingin kamu jaga hari ini?',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: hasGoal ? 19 : 16,
                        height: 1.35,
                        fontWeight: hasGoal ? FontWeight.w600 : FontWeight.w400,
                        color: hasGoal ? tc.textPrimary : tc.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                hasGoal ? Icons.edit_outlined : Icons.add_rounded,
                color: tc.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editFocusGoal() async {
    final settings = ref.read(launcherSettingsProvider);
    final controller = TextEditingController(text: settings.focusGoal);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tujuan hari ini'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(alignLabelWithHint: true),
          onSubmitted: (_) => Navigator.of(dialogContext).pop(controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    final saved = await ref
        .read(launcherSettingsProvider.notifier)
        .setFocusGoal(result);
    if (!mounted) return;
    _showToast(
      saved ? 'Tujuan disimpan' : 'Gagal menyimpan tujuan. Coba lagi.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 2: FOCUS TIMER HUB & FULLSCREEN ZEN MODE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTimerScreen(ThemeData theme) {
    final timer =
        _activeTimer ??
        ActiveTimer(
          label: 'Fokus bebas',
          totalSeconds: 25 * 60,
          leftSeconds: 25 * 60,
          startHour: _hourNow(),
        );
    final isIdle = !timer.hasStarted;

    return Scaffold(
      backgroundColor: AppPalette.bg,
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
                        color: AppPalette.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppPalette.stroke),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppPalette.text,
                        size: 22,
                      ),
                    ),
                  ),

                  // Fullscreen Zen Button
                  IconButton(
                    icon: const Icon(
                      Icons.fullscreen_rounded,
                      color: AppPalette.accent,
                      size: 28,
                    ),
                    tooltip: 'Mode Zen Layar Penuh (Lockscreen)',
                    onPressed: () =>
                        setState(() => _currentScreen = 'fullscreen_focus'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title & Status
              Text(
                timer.label,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timer.source != null
                    ? 'Saat selesai, hasilnya dicatat otomatis ke jam.'
                    : 'Timer bebas, tidak mencatat apa pun ke jam.',
                style: const TextStyle(fontSize: 13, color: AppPalette.textDim),
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
                    color: AppPalette.text,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppPalette.accent
                                  : AppPalette.stroke,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            '$m mnt',
                            style: TextStyle(
                              color: selected
                                  ? AppPalette.accent
                                  : AppPalette.text,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
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
                onPressed: () => _toggleTimer(timer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: AppPalette.card,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  timer.isRunning
                      ? 'Jeda'
                      : timer.hasStarted
                      ? 'Lanjut'
                      : 'Mulai',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Finish Now Button
              ElevatedButton(
                onPressed: () => _finishTimer(autoComplete: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.stroke,
                  foregroundColor: AppPalette.text,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Selesai sekarang',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),

              // Cancel Button
              TextButton(
                onPressed: () async {
                  final session = ref.read(timerEngineProvider);
                  final sharedNonHabit =
                      session.restoreError != null ||
                      (session.sourceKind != null &&
                          session.sourceKind != TimerSessionSourceKind.habit);
                  if (sharedNonHabit) {
                    if (session.isSavePending) {
                      _showToast(
                        session.restoreError ??
                            'Sesi belum tersimpan. Coba lagi sebelum membatalkan.',
                      );
                      return;
                    }
                    try {
                      await ref.read(timerEngineProvider.notifier).cancel();
                    } catch (_) {
                      if (mounted) {
                        _showToast(
                          'Timer belum berhasil dibatalkan. Ketuk coba lagi.',
                        );
                      }
                      return;
                    }
                  }
                  if (!mounted) return;
                  setState(() {
                    _activeTimer = null;
                    _currentScreen = 'home';
                  });
                },
                child: const Text(
                  'Batalkan timer',
                  style: TextStyle(color: AppPalette.textDim),
                ),
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
    final timer =
        _activeTimer ??
        ActiveTimer(
          label: 'Fokus',
          totalSeconds: 25 * 60,
          leftSeconds: 25 * 60,
          startHour: _hourNow(),
        );

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
                  icon: const Icon(
                    Icons.fullscreen_exit_rounded,
                    color: Colors.white70,
                    size: 30,
                  ),
                  onPressed: () => setState(() => _currentScreen = 'timer'),
                ),
              ),
              const Spacer(),

              Center(
                child: Text(
                  timer.label,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
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
                    color: AppPalette.accent,
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
                      timer.isRunning
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: AppPalette.accent,
                    ),
                    onPressed: () => _toggleTimer(timer),
                  ),
                  IconButton(
                    iconSize: 48,
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF5FD0A5),
                    ),
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
      backgroundColor: AppPalette.bg,
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
                        color: AppPalette.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppPalette.stroke),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppPalette.text,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Catatan Harian',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildNoteChip(
                      'Kemarin',
                      _notesFilter == 'date' &&
                          _selectedNoteDate == _dateKey(-1),
                      () {
                        setState(() {
                          _notesFilter = 'date';
                          _selectedNoteDate = _dateKey(-1);
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildNoteChip(
                      'Hari ini',
                      _notesFilter == 'date' &&
                          _selectedNoteDate == _dateKey(0),
                      () {
                        setState(() {
                          _notesFilter = 'date';
                          _selectedNoteDate = _dateKey(0);
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildNoteChip('Penting', _notesFilter == 'important', () {
                      setState(() => _notesFilter = 'important');
                    }),
                    const SizedBox(width: 8),
                    _buildNoteChip(
                      'Tanggal ${_formatDateShort(_selectedNoteDate)}',
                      false,
                      _openDatePickerSheet,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Journal Templates Chips
              if (_notesFilter != 'important') ...[
                const Text(
                  'Template Jurnal:',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppPalette.textDim,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTemplateChip(
                        'Niat Pagi',
                        'Niat Pagi:\n1. Goal utama:\n2. Sikap yang kuinginkan:\n3. Rasa syukur:',
                        noteInputCtrl,
                      ),
                      const SizedBox(width: 8),
                      _buildTemplateChip(
                        'Refleksi Malam',
                        'Refleksi Malam:\n- Yang sudah terlaksana:\n- Pelajaran hari ini:\n- Hal yang disyukuri:',
                        noteInputCtrl,
                      ),
                      const SizedBox(width: 8),
                      _buildTemplateChip(
                        'Langkah Berani',
                        '1 Langkah berani hari ini yang mengubah masa depan:',
                        noteInputCtrl,
                      ),
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
                          style: TextStyle(
                            color: AppPalette.textDim,
                            fontSize: 14,
                          ),
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
                              color: AppPalette.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppPalette.stroke),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n.text,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppPalette.text,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDateShort(n.dateKey),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppPalette.textDim,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    n.isImportant
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: n.isImportant
                                        ? AppPalette.accent
                                        : AppPalette.textDim,
                                  ),
                                  onPressed: () => setState(
                                    () => n.isImportant = !n.isImportant,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppPalette.textDim,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => _notes.removeWhere(
                                        (item) => item.id == n.id,
                                      ),
                                    );
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
                  style: const TextStyle(color: AppPalette.text),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppPalette.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppPalette.stroke),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppPalette.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    final t = noteInputCtrl.text.trim();
                    if (t.isEmpty) return;
                    setState(() {
                      _notes.insert(
                        0,
                        NoteItem(
                          id: _nextId++,
                          dateKey: _selectedNoteDate,
                          text: t,
                        ),
                      );
                    });
                    noteInputCtrl.clear();
                    _showToast('Catatan disimpan');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.accent,
                    foregroundColor: AppPalette.card,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Simpan Catatan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateChip(
    String label,
    String templateContent,
    TextEditingController ctrl,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ctrl.text = templateContent;
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppPalette.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppPalette.stroke),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppPalette.text,
            fontWeight: FontWeight.w600,
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
          color: AppPalette.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppPalette.accent : AppPalette.stroke,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppPalette.accent : AppPalette.text,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN 4: JELAS (FUTURE SELF & GRATITUDE) VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildJelasScreen(ThemeData theme) {
    final visionHabit = _habits.firstWhere(
      (h) => h.isVision,
      orElse: () => _habits.first,
    );

    return Scaffold(
      backgroundColor: AppPalette.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            // Top Bar
            Wrap(
              spacing: 4,
              runSpacing: 0,
              children: [
                InkWell(
                  onTap: () => setState(() => _currentScreen = 'home'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppPalette.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppPalette.stroke),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppPalette.text,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Jelas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Vision Quote
            const Text(
              'Jernihkan tujuan, jadilah dirimu di masa depan. Setelah kesulitan datang kemudahan. Sedikit itu lebih. Yang sederhana itu dahsyat. Lihat itu, setiap saat.',
              style: TextStyle(
                fontSize: 14,
                color: AppPalette.textDim,
                height: 1.5,
              ),
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
                    colors: [AppPalette.stroke, Color(0xFF2A2418)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppPalette.stroke),
                ),
                alignment: Alignment.center,
                child: _futureSelfVisionImage != null
                    ? Image.network(_futureSelfVisionImage!, fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_outlined,
                            color: AppPalette.textDim,
                            size: 32,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Ketuk untuk menaruh gambar masa depanmu',
                            style: TextStyle(
                              color: AppPalette.textDim,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // 3-Minute Visualization Button
            ElevatedButton(
              onPressed: () {
                _startTimer(
                  'Visualisasi masa depan',
                  3,
                  source: 'habit',
                  sourceId: visionHabit.id,
                  identity: 'Masa depan',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.accent,
                foregroundColor: AppPalette.card,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Mulai visualisasi 3 menit',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              visionHabit.isDone
                  ? 'Sudah dilakukan hari ini'
                  : 'Belum dilakukan hari ini',
              style: TextStyle(
                fontSize: 12,
                color: visionHabit.isDone
                    ? const Color(0xFF5FD0A5)
                    : AppPalette.textDim,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // 3 Top Emotions Checklist (Lampiran 3)
            const Text(
              '3 emosi utama',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppPalette.text,
              ),
            ),
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
                onTap: () =>
                    setState(() => _topEmotions[idx] = !_topEmotions[idx]),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isChecked
                              ? const Color(0xFF5FD0A5)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF5FD0A5),
                            width: 1.5,
                          ),
                        ),
                        child: isChecked
                            ? const Icon(
                                Icons.check,
                                color: AppPalette.bg,
                                size: 18,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppPalette.text,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Gratitude Journal (3 Items)
            const Text(
              'Jurnal syukur, 3 hal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppPalette.text,
              ),
            ),
            const SizedBox(height: 10),
            ...[0, 1, 2].map((i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  maxLines: 2,
                  style: const TextStyle(color: AppPalette.text, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppPalette.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppPalette.stroke),
                    ),
                  ),
                  onChanged: (val) => _gratitudeEntries[i] = val,
                ),
              );
            }),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                final nonEmpty = _gratitudeEntries
                    .where((s) => s.trim().isNotEmpty)
                    .toList();
                if (nonEmpty.isEmpty) {
                  _showToast('Tulis minimal satu hal');
                  return;
                }
                setState(() {
                  _notes.insert(
                    0,
                    NoteItem(
                      id: _nextId++,
                      dateKey: _dateKey(0),
                      text: 'Syukur: ${nonEmpty.join("; ")}',
                    ),
                  );
                  _gratitudeEntries[0] = '';
                  _gratitudeEntries[1] = '';
                  _gratitudeEntries[2] = '';
                });
                _showToast('Disimpan ke catatan hari ini');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.stroke,
                foregroundColor: AppPalette.text,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Simpan syukur ke catatan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
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
  Future<void> _openFocusTimerHub() async {
    await ref.read(timerEngineProvider.notifier).waitUntilRestored();
    if (!mounted) return;
    final activeSession = ref.read(timerEngineProvider);
    final tc = _HomeThemeColors.fromPalette(
      ref.read(launcherSettingsProvider).themePalette,
    );
    final timedHabits = _habits
        .where((h) => h.minutes != null && h.minutes! > 0)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        if (activeSession.isActive || activeSession.isSavePending) {
          final status = activeSession.isSavePending
              ? 'Sesi menunggu penyimpanan'
              : activeSession.recoveryUncertain
              ? 'Sesi dijeda untuk ditinjau'
              : activeSession.isPaused
              ? 'Sesi dijeda'
              : 'Sesi sedang berjalan';
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: tc.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activeSession.habitName.isEmpty
                      ? 'Fokus bebas'
                      : activeSession.habitName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: tc.accent,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (mounted) setState(() => _currentScreen = 'timer');
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Buka sesi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: tc.accent,
                    foregroundColor: tc.bg,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pusat Timer Fokus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih kebiasaan atau mulai fokus bebas langsung:',
                  style: TextStyle(fontSize: 12, color: AppPalette.textDim),
                ),
                const SizedBox(height: 16),

                // Lanjutkan Kebiasaan Ber-timer
                if (timedHabits.isNotEmpty) ...[
                  const Text(
                    'Lanjutkan Kebiasaan:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...timedHabits.map((h) {
                    final col = _colorForIdentity(h.identity);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: col, width: 1.5),
                        ),
                        child: Icon(Icons.play_arrow_rounded, color: col),
                      ),
                      title: Text(
                        h.title,
                        style: const TextStyle(
                          color: AppPalette.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${(h.elapsedSeconds ~/ 60)} / ${h.minutes}m progres',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppPalette.textDim,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _startTimer(
                          h.title,
                          h.minutes ?? 15,
                          source: 'habit',
                          sourceId: h.id,
                          identity: h.identity,
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // Quick Chips Free Focus
                const Text(
                  'Fokus Bebas Cepat:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.accent,
                  ),
                ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppPalette.stroke),
                        ),
                        child: Text(
                          '$m mnt',
                          style: const TextStyle(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
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
    final naturalBaseColors = [
      const Color(0xFF6B9080), // Sage Green
      const Color(0xFF4A5568), // Muted Slate
      const Color(0xFF4682B4), // Dusty Ocean
      const Color(0xFFC27D60), // Terracotta Clay
      const Color(0xFF52796F), // Forest Moss
      const Color(0xFFA39274), // Warm Sand
      AppPalette.textDim, // Soft Charcoal
    ];
    Color selectedColor = naturalBaseColors.first;
    double spectrumHue = 180.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Identitas Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Buat bidang identitas baru untuk mengelompokkan blok & kebiasaanmu:',
                    style: TextStyle(fontSize: 12, color: AppPalette.textDim),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    key: const ValueKey('new_identity_name_field'),
                    controller: nameCtrl,
                    style: const TextStyle(color: AppPalette.text),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppPalette.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppPalette.stroke),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 7 Natural Base Colors
                  const Text(
                    '7 Warna Dasar Natural:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.textDim,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: naturalBaseColors.map((c) {
                      final isSel = selectedColor.value == c.value;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedColor = c),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: isSel
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Interactive HSL Spectrum Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Atau Spektrum Bebas (HSL):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.textDim,
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: spectrumHue,
                    min: 0.0,
                    max: 360.0,
                    activeColor: selectedColor,
                    onChanged: (val) {
                      setSheetState(() {
                        spectrumHue = val;
                        selectedColor = HSVColor.fromAHSV(
                          1.0,
                          val,
                          0.55,
                          0.75,
                        ).toColor();
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isNotEmpty) {
                        setState(() {
                          _identities.add(
                            IdentityItem(
                              id: name.toLowerCase().replaceAll(' ', '_'),
                              name: name,
                              color: selectedColor,
                            ),
                          );
                          _selectedPresetIdentity = name;
                          _selectedHabitIdentity = name;
                        });
                        Navigator.pop(ctx);
                        _showToast('Identitas $name ditambahkan!');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.accent,
                      foregroundColor: AppPalette.card,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Buat Identitas',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          },
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
      backgroundColor: AppPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Preset Baru • ${identity.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.text,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: AppPalette.text),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppPalette.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppPalette.stroke),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Sleek Interactive Duration Selector with Chips & Steppers!
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Durasi:',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppPalette.textDim,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$selectedMinutes menit',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: identity.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: AppPalette.textDim,
                        ),
                        onPressed: () {
                          if (selectedMinutes > 5) {
                            setSheetState(() => selectedMinutes -= 5);
                          }
                        },
                      ),
                      ...[15, 25, 30, 45, 60, 90].map((m) {
                        final isSel = selectedMinutes == m;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () =>
                                setSheetState(() => selectedMinutes = m),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSel ? identity.color : AppPalette.bg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSel
                                      ? identity.color
                                      : AppPalette.stroke,
                                ),
                              ),
                              child: Text(
                                '$m',
                                style: TextStyle(
                                  color: isSel
                                      ? AppPalette.bg
                                      : AppPalette.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: AppPalette.textDim,
                        ),
                        onPressed: () =>
                            setSheetState(() => selectedMinutes += 5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      final n = nameCtrl.text.trim();
                      if (n.isNotEmpty) {
                        setState(() {
                          _presets.add(
                            PresetItem(
                              id: _nextId++,
                              name: n,
                              minutes: selectedMinutes,
                              identity: identity.name,
                            ),
                          );
                        });
                        Navigator.pop(ctx);
                        _showToast('Preset $n disimpan!');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: identity.color,
                      foregroundColor: AppPalette.bg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Simpan Preset',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
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
      backgroundColor: AppPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Kebiasaan Baru • ${identity.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.text,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: AppPalette.text),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppPalette.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppPalette.stroke),
                      ),
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
                          onSelected: (val) =>
                              setSheetState(() => isDaily = true),
                          selectedColor: const Color(
                            0xFF5FD0A5,
                          ).withOpacity(0.25),
                          backgroundColor: AppPalette.bg,
                          labelStyle: TextStyle(
                            color: isDaily
                                ? const Color(0xFF5FD0A5)
                                : AppPalette.textDim,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Text('Sekali Saja (One-Time)'),
                          ),
                          selected: !isDaily,
                          onSelected: (val) =>
                              setSheetState(() => isDaily = false),
                          selectedColor: const Color(
                            0xFF8FB8E8,
                          ).withOpacity(0.25),
                          backgroundColor: AppPalette.bg,
                          labelStyle: TextStyle(
                            color: !isDaily
                                ? const Color(0xFF8FB8E8)
                                : AppPalette.textDim,
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
                    title: const Text(
                      'Aktifkan Timer Fokus',
                      style: TextStyle(color: AppPalette.text, fontSize: 14),
                    ),
                    value: hasTimer,
                    activeColor: identity.color,
                    onChanged: (val) => setSheetState(() => hasTimer = val),
                  ),

                  if (hasTimer) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Target Waktu:',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppPalette.textDim,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$durationMinutes menit',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: identity.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: AppPalette.textDim,
                          ),
                          onPressed: () {
                            if (durationMinutes > 5) {
                              setSheetState(() => durationMinutes -= 5);
                            }
                          },
                        ),
                        ...[10, 15, 20, 30, 45].map((m) {
                          final isSel = durationMinutes == m;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () =>
                                  setSheetState(() => durationMinutes = m),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel ? identity.color : AppPalette.bg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel
                                        ? identity.color
                                        : AppPalette.stroke,
                                  ),
                                ),
                                child: Text(
                                  '$m',
                                  style: TextStyle(
                                    color: isSel
                                        ? AppPalette.bg
                                        : AppPalette.text,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: AppPalette.textDim,
                          ),
                          onPressed: () =>
                              setSheetState(() => durationMinutes += 5),
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
                          _habits.add(
                            HabitModel(
                              id: _nextId++,
                              title: title,
                              identity: identity.name,
                              isDaily: isDaily,
                              minutes: hasTimer ? durationMinutes : null,
                            ),
                          );
                        });
                        Navigator.pop(ctx);
                        _showToast('Kebiasaan disimpan');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: identity.color,
                      foregroundColor: AppPalette.bg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Simpan Kebiasaan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
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
  void _openScheduleFromClock() {
    HapticFeedback.selectionClick();
    _openScheduleToClockSheet(
      title: '',
      initialDurationMinutes: 60,
      identity: '',
    );
  }

  void _openGoalAssistant(IntentGoal? goal) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppPalette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppPalette.stroke),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: AiChatPanel(
          initialGoal: goal?.title,
          goalId: goal?.id,
          expectedGoalRevision: goal?.revision,
          onOpenAiSettings: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const SettingsScreen(focusAiConfiguration: true),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openScheduleToClockSheet({
    String title = '',
    int initialDurationMinutes = 60,
    String identity = '',
    Color? identityColor,
    Task? inboxTask,
    Habit? initialHabit,
  }) async {
    late final List<Habit> persistedHabits;
    try {
      persistedHabits = widget.useSampleData
          ? <Habit>[]
          : await ref.read(sadarRepoProvider).getHabits();
    } catch (_) {
      if (mounted) _showToast('Kebiasaan belum dimuat. Coba lagi.');
      return;
    }
    if (!mounted) return;
    final eligibleHabits = persistedHabits
        .where(
          (h) =>
              !h.isArchived &&
              h.habitType == 'timed' &&
              h.unit == HabitUnit.min &&
              h.target > 0,
        )
        .toList();
    final scheduleHabits = widget.useSampleData
        ? _habits
        : eligibleHabits
              .map(
                (h) => HabitModel(
                  id: h.id,
                  title: h.name,
                  identity: '',
                  minutes: h.target,
                ),
              )
              .toList();
    int? selectedHabitId = initialHabit?.id;

    final settings = ref.read(launcherSettingsProvider);
    final tc = _HomeThemeColors.fromPalette(settings.themePalette);

    bool isSaving = false;
    final isBlankCapture =
        initialHabit == null && inboxTask == null && title.trim().isEmpty;
    bool isCustomInput = isBlankCapture;
    final inboxTasks = _inboxTasks;
    final hasReusableItems =
        inboxTasks.isNotEmpty ||
        scheduleHabits.isNotEmpty ||
        _presets.isNotEmpty;
    Task? selectedTask = inboxTask;
    String selectedTitle = initialHabit?.name ?? title.trim();
    if (selectedTitle.isEmpty && !isBlankCapture) {
      if (inboxTasks.isNotEmpty) {
        selectedTask = inboxTasks.first;
        selectedTitle = selectedTask.title;
      } else if (scheduleHabits.isNotEmpty) {
        selectedTitle = scheduleHabits.first.title;
        selectedHabitId = widget.useSampleData ? null : scheduleHabits.first.id;
      } else if (_presets.isNotEmpty) {
        selectedTitle = _presets.first.name;
      } else {
        selectedTitle = 'Fokus Utama';
      }
    }
    final titleCtrl = TextEditingController(text: selectedTitle);

    final now = widget.now?.call() ?? DateTime.now();
    var startH = ((now.hour * 60 + now.minute) ~/ 30 + 1) / 2.0;
    while (_findConflict(startH, startH + initialDurationMinutes / 60.0) !=
            null &&
        startH < 23.5) {
      startH += 0.5;
    }

    int duration = initialHabit?.target ?? initialDurationMinutes;
    String selectedIdentity = identity;
    String? errorMessage;
    String scheduleHourLabel(double hour) =>
        hour >= 24 ? 'Besok ${_formatHour(hour)}' : _formatHour(hour);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: tc.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final activeColor = _colorForIdentity(selectedIdentity);

            return PopScope(
              canPop: !isSaving,
              child: AbsorbPointer(
                absorbing: isSaving,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    16,
                    18,
                    MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: activeColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Pasang ke Focus Clock',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: tc.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (hasReusableItems)
                              InkWell(
                                onTap: () => setSheetState(() {
                                  isCustomInput = !isCustomInput;
                                  selectedTask = null;
                                  selectedHabitId = null;
                                }),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCustomInput
                                        ? tc.accent.withOpacity(0.2)
                                        : tc.cardElevated,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCustomInput
                                          ? tc.accent
                                          : tc.stroke,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 44,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isCustomInput
                                            ? Icons.list_alt_rounded
                                            : Icons.edit_note_rounded,
                                        size: 14,
                                        color: isCustomInput
                                            ? tc.accent
                                            : tc.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isCustomInput
                                            ? 'Pilih yang Ada'
                                            : '+ Kustom',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isCustomInput
                                              ? tc.accent
                                              : tc.textSecondary,
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
                          style: TextStyle(
                            fontSize: 12,
                            color: tc.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── EXISTING ITEMS FIRST (When not in custom mode) ──
                        if (!isCustomInput) ...[
                          // 1. Dari Dump Inbox
                          if (inboxTasks.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.inbox_rounded,
                                  size: 14,
                                  color: tc.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Dari Dump Inbox:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: tc.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: inboxTasks.map((task) {
                                final isSel = selectedTask?.id == task.id;
                                return InkWell(
                                  onTap: () {
                                    setSheetState(() {
                                      selectedTask = task;
                                      selectedHabitId = null;
                                      selectedTitle = task.title;
                                      titleCtrl.text = task.title;
                                      errorMessage = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? tc.accent.withOpacity(0.2)
                                          : tc.cardElevated,
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
                                          Icon(
                                            Icons.check_rounded,
                                            size: 13,
                                            color: tc.accent,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          task.title,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSel
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSel
                                                ? tc.accent
                                                : tc.textPrimary,
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
                          if (scheduleHabits.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.repeat_rounded,
                                  size: 14,
                                  color: tc.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Dari Kebiasaan & Rutinitas:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: tc.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: scheduleHabits.map((h) {
                                  final isSel = widget.useSampleData
                                      ? selectedTitle == h.title
                                      : selectedHabitId == h.id;
                                  final hColor = _colorForIdentity(h.identity);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: InkWell(
                                      onTap: () {
                                        setSheetState(() {
                                          selectedTask = null;
                                          selectedHabitId = widget.useSampleData
                                              ? null
                                              : h.id;
                                          selectedTitle = h.title;
                                          titleCtrl.text = h.title;
                                          selectedIdentity = h.identity;
                                          if (h.minutes != null &&
                                              h.minutes! > 0) {
                                            duration = h.minutes!;
                                          }
                                          errorMessage = null;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSel
                                              ? hColor.withOpacity(0.2)
                                              : tc.cardElevated,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                              decoration: BoxDecoration(
                                                color: hColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              h.title,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isSel
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: isSel
                                                    ? hColor
                                                    : tc.textPrimary,
                                              ),
                                            ),
                                            if (h.minutes != null) ...[
                                              const SizedBox(width: 4),
                                              Text(
                                                '(${h.minutes}m)',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: tc.textMuted,
                                                ),
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
                                Icon(
                                  Icons.layers_outlined,
                                  size: 14,
                                  color: tc.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Dari Preset Waktu:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: tc.textSecondary,
                                  ),
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
                                          selectedTask = null;
                                          selectedHabitId = null;
                                          selectedTitle = p.name;
                                          titleCtrl.text = p.name;
                                          selectedIdentity = p.identity;
                                          duration = p.minutes;
                                          errorMessage = null;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSel
                                              ? pColor.withOpacity(0.2)
                                              : tc.cardElevated,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isSel ? pColor : tc.stroke,
                                            width: isSel ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Text(
                                          '${p.name} (${p.minutes}m)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSel
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSel
                                                ? pColor
                                                : tc.textPrimary,
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
                            onTap: () => setSheetState(() {
                              isCustomInput = true;
                              selectedHabitId = null;
                              selectedTask = null;
                            }),
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
                                  Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                    color: tc.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+ Tulis Kegiatan Kustom Manual',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: tc.accent,
                                    ),
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
                            style: TextStyle(
                              color: tc.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            onChanged: (v) => setSheetState(() {
                              selectedTask = null;
                              selectedHabitId = null;
                              selectedTitle = v;
                            }),
                            decoration: InputDecoration(
                              labelText: 'Apa yang perlu kamu lakukan?',
                              labelStyle: TextStyle(
                                color: tc.textSecondary,
                                fontSize: 13,
                              ),
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

                          if (_identities.isNotEmpty) ...[
                            Text(
                              'Pilih Identitas:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: tc.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 34,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _identities.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, i) {
                                  final id = _identities[i];
                                  final isSel =
                                      id.name.toLowerCase() ==
                                      selectedIdentity.toLowerCase();
                                  return InkWell(
                                    onTap: () => setSheetState(
                                      () => selectedIdentity = id.name,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? id.color.withOpacity(0.2)
                                            : tc.bg,
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
                                            decoration: BoxDecoration(
                                              color: id.color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            id.name,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSel
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSel
                                                  ? id.color
                                                  : tc.textPrimary,
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
                        ],
                        const SizedBox(height: 14),

                        // ── TIME BADGE & RANGE SLIDER ──
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: activeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: activeColor.withOpacity(0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    color: activeColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${scheduleHourLabel(startH)} — ${scheduleHourLabel(startH + duration / 60.0)}',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: activeColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$duration menit',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: tc.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Set the exact start time without moving the clock.
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Mulai pukul',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: tc.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final totalMinutes = (startH * 60)
                                    .round()
                                    .clamp(0, 1439);
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                    hour: totalMinutes ~/ 60,
                                    minute: totalMinutes % 60,
                                  ),
                                  builder: (context, child) => MediaQuery(
                                    data: MediaQuery.of(
                                      context,
                                    ).copyWith(alwaysUse24HourFormat: true),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) {
                                  setSheetState(() {
                                    startH = picked.hour + picked.minute / 60;
                                    errorMessage = null;
                                  });
                                }
                              },
                              icon: const Icon(
                                Icons.schedule_rounded,
                                size: 18,
                              ),
                              label: Text(scheduleHourLabel(startH)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: activeColor,
                                side: BorderSide(color: activeColor),
                                minimumSize: const Size(96, 44),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Durasi',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: tc.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '$duration menit',
                              style: TextStyle(
                                fontSize: 12,
                                color: activeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
                                  onTap: () =>
                                      setSheetState(() => duration = d),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSel ? activeColor : tc.bg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSel ? activeColor : tc.stroke,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                      minHeight: 44,
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
                            style: const TextStyle(
                              color: Color(0xFFE88F7D),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Submit Button
                        ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  setSheetState(() {
                                    isSaving = true;
                                    errorMessage = null;
                                  });
                                  final actName =
                                      selectedTitle.trim().isNotEmpty
                                      ? selectedTitle.trim()
                                      : (titleCtrl.text.trim().isNotEmpty
                                            ? titleCtrl.text.trim()
                                            : 'Kegiatan Baru');
                                  final en = startH + duration / 60.0;
                                  final res = await _scheduleInboxTask(
                                    selectedTask,
                                    startH,
                                    duration,
                                    selectedIdentity,
                                    title: actName,
                                    habitId: selectedHabitId,
                                  );
                                  if (!ctx.mounted || !mounted) return;
                                  if (res != null) {
                                    setSheetState(() {
                                      isSaving = false;
                                      errorMessage = res;
                                    });
                                  } else {
                                    setSheetState(() => isSaving = false);
                                    Navigator.pop(ctx);
                                    _showToast(
                                      '$actName berhasil dipasang di jam ${scheduleHourLabel(startH)}-${scheduleHourLabel(en)}',
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tc.accent,
                            foregroundColor: tc.bg,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pasang ke Focus Clock',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: tc.bg,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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

  // ── Task & Habit Dump Section ─────────────────────────────────────────────
  Widget _buildTaskDumpSection(_HomeThemeColors tc) {
    final state = widget.useSampleData
        ? null
        : ref.watch(eisenhowerTasksProvider);
    final tasks = _inboxTasks;
    final store = widget.useSampleData ? null : ref.read(taskRepoProvider).isar;
    final unavailable =
        !widget.useSampleData && (store == null || !store.isDurable);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inbox_rounded, color: tc.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kotak masuk kegiatan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tc.textPrimary,
                  ),
                ),
              ),
              if (tasks.isNotEmpty)
                Text(
                  '${tasks.length} kegiatan',
                  style: TextStyle(fontSize: 12, color: tc.textSecondary),
                ),
            ],
          ),
          if (tasks.isEmpty &&
              !unavailable &&
              state?.hasError != true &&
              state?.isLoading != true) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 0,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: tc.accent,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _openQuickDumpTaskDialog(tc),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Tambah'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: tc.accent,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _openScheduleToClockSheet,
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: const Text('Jadwalkan'),
                ),
              ],
            ),
          ] else if (tasks.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 0,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: tc.accent,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _openQuickDumpTaskDialog(tc),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Tambah'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: tc.accent,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _openScheduleToClockSheet,
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: const Text('Jadwalkan'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (unavailable)
            const Text('Penyimpanan tugas tidak tersedia.')
          else if (state?.isLoading == true)
            const Text('Memuat tugas…')
          else if (state?.hasError == true)
            const Text('Gagal memuat tugas. Coba lagi.')
          else
            ...tasks.map((task) => _buildDumpedTaskRow(task, tc)),
        ],
      ),
    );
  }

  Widget _buildDumpedTaskRow(Task task, _HomeThemeColors tc) {
    final compactActions =
        MediaQuery.sizeOf(context).width < 380 ||
        MediaQuery.textScalerOf(context).scale(14) > 18;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tc.stroke.withOpacity(0.65))),
      ),
      child: Row(
        children: [
          Icon(Icons.circle_outlined, color: tc.textSecondary, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: tc.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // 1-Tap Quick Schedule Sekarang
          InkWell(
            onTap: _inboxBusy.contains(task.id)
                ? null
                : () async {
                    setState(() => _inboxBusy.add(task.id));
                    final now = widget.now?.call() ?? DateTime.now();
                    final start =
                        (now.hour * 60 +
                            now.minute +
                            (now.second > 0 || now.millisecond > 0 ? 1 : 0)) /
                        60.0;
                    final err = await _scheduleInboxTask(task, start, 60, '');
                    if (!mounted) return;
                    setState(() => _inboxBusy.remove(task.id));
                    _showToast(err ?? '"${task.title}" dijadwalkan');
                  },
            borderRadius: BorderRadius.circular(8),
            child: Tooltip(
              message: 'Mulai tugas sekarang',
              child: Container(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tc.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tc.stroke),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 13, color: tc.accent),
                    if (!compactActions) ...[
                      const SizedBox(width: 2),
                      Text(
                        'Sekarang',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tc.accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Buka Popup Jadwal dengan task terpasang
          InkWell(
            onTap: () => _openScheduleToClockSheet(
              title: task.title,
              inboxTask: task,
              initialDurationMinutes: 60,
              identity: '',
            ),
            borderRadius: BorderRadius.circular(8),
            child: Tooltip(
              message: 'Pilih jam dan durasi',
              child: Container(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tc.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.watch_later_outlined,
                      size: 12,
                      color: tc.background,
                    ),
                    if (!compactActions) ...[
                      const SizedBox(width: 3),
                      Text(
                        'Pasang',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: tc.background,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: tc.textSecondary),
            tooltip: 'Hapus dari Dump',
            padding: const EdgeInsets.only(left: 4),
            constraints: BoxConstraints(
              minWidth: compactActions ? 44 : 24,
              minHeight: compactActions ? 44 : 24,
            ),
            onPressed: _inboxBusy.contains(task.id)
                ? null
                : () async {
                    setState(() => _inboxBusy.add(task.id));
                    try {
                      if (widget.useSampleData) {
                        _dumpedTasks.removeWhere((t) => t.id == task.id);
                      } else {
                        final store = ref.read(taskRepoProvider).isar;
                        if (store == null || !store.isDurable) {
                          throw StateError('storage unavailable');
                        }
                        await ref.read(taskRepoProvider).delete(task.id);
                      }
                      if (mounted) _showToast('Tugas dihapus dari dump');
                    } catch (_) {
                      if (mounted) {
                        _showToast('Gagal menghapus tugas. Coba lagi.');
                      }
                    } finally {
                      if (mounted) setState(() => _inboxBusy.remove(task.id));
                    }
                  },
          ),
        ],
      ),
    );
  }

  Future<int?> _openQuickDumpTaskDialog(
    _HomeThemeColors tc, {
    bool startToday = false,
  }) async {
    final ctrl = TextEditingController();
    bool saving = false;
    String? error;
    ModalRoute<int>? dialogRoute;
    final taskId = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogRoute = ModalRoute.of<int>(ctx);
        return StatefulBuilder(
          builder: (ctx, setDialogState) => PopScope(
            canPop: !saving,
            child: AlertDialog(
              backgroundColor: tc.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: tc.stroke),
              ),
              title: Text(
                startToday
                    ? 'Tambah tindakan hari ini'
                    : 'Catat Cepat ke Dump Inbox',
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: TextField(
                key: const ValueKey('home-quick-task-input'),
                controller: ctrl,
                enabled: !saving,
                autofocus: true,
                style: TextStyle(color: tc.textPrimary),
                decoration: InputDecoration(
                  errorText: error,
                  filled: true,
                  fillColor: tc.cardAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: tc.stroke),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: tc.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final t = ctrl.text.trim();
                          if (t.isEmpty) return;
                          setDialogState(() {
                            saving = true;
                            error = null;
                          });
                          try {
                            late final int taskId;
                            if (widget.useSampleData) {
                              taskId = _nextId++;
                              setState(
                                () => _dumpedTasks.insert(
                                  0,
                                  Task()
                                    ..id = taskId
                                    ..title = t
                                    ..createdAt = DateTime.now(),
                                ),
                              );
                            } else {
                              final repo = ref.read(taskRepoProvider);
                              if (repo.isar == null || !repo.isar!.isDurable) {
                                throw StateError('storage unavailable');
                              }
                              taskId = await repo.add(
                                Task()
                                  ..title = t
                                  ..createdAt = DateTime.now(),
                              );
                            }
                            if (!ctx.mounted || !mounted) return;
                            setDialogState(() => saving = false);
                            Navigator.pop(ctx, taskId);
                            if (!startToday) {
                              _showToast('Tugas ditambahkan ke dump');
                            }
                          } catch (_) {
                            if (ctx.mounted) {
                              setDialogState(() {
                                saving = false;
                                error = 'Gagal menyimpan. Coba lagi.';
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tc.accent,
                    foregroundColor: tc.background,
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
        );
      },
    );
    await dialogRoute?.completed;
    ctrl.dispose();
    return taskId;
  }

  // ── 7. Habit Actions Popover (Ya, Tidak, Mulai, Catatan, Gambar) ──
  void _openHabitActionsSheet(HabitModel h) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                h.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.text,
                ),
              ),
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
                  _buildHabitActionButton(
                    Icons.play_arrow_rounded,
                    'Mulai',
                    () {
                      Navigator.pop(ctx);
                      _startTimer(
                        h.isVision ? 'Visualisasi masa depan' : h.title,
                        h.minutes ?? 15,
                        source: 'habit',
                        sourceId: h.id,
                        identity: h.identity,
                      );
                    },
                  ),
                  _buildHabitActionButton(
                    Icons.edit_note_rounded,
                    'Catatan',
                    () {
                      Navigator.pop(ctx);
                      _openHabitReflectionSheet(h);
                    },
                  ),
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
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE88F7D),
                ),
                title: const Text(
                  'Hapus kebiasaan',
                  style: TextStyle(color: Color(0xFFE88F7D)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(
                    () => _habits.removeWhere((item) => item.id == h.id),
                  );
                  _showToast('Kebiasaan dihapus');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHabitActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 60,
        height: 64,
        decoration: BoxDecoration(
          color: AppPalette.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.stroke),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppPalette.text, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppPalette.textDim),
            ),
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
      backgroundColor: AppPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Refleksi Kebiasaan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                h.title,
                style: const TextStyle(color: AppPalette.textDim, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 4,
                style: const TextStyle(color: AppPalette.text),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppPalette.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppPalette.stroke),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () {
                  final t = ctrl.text.trim();
                  if (t.isNotEmpty) {
                    setState(() {
                      _notes.insert(
                        0,
                        NoteItem(
                          id: _nextId++,
                          dateKey: _dateKey(0),
                          text: '[${h.title}] $t',
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                    _showToast('Catatan disimpan');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: AppPalette.card,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Simpan ke Catatan Hari Ini',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 8. Block Detail Sheet ──
  void _openBlockDetailSheet(BlockItem b) {
    final tc = _HomeThemeColors.fromPalette(
      ref.read(launcherSettingsProvider).themePalette,
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: tc.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                b.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: tc.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatHour(b.startHour)} sampai ${_formatHour(b.endHour)} (${_formatDuration(b.endHour - b.startHour)})',
                style: const TextStyle(fontSize: 13, color: AppPalette.textDim),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppPalette.accent,
                ),
                title: const Text(
                  'Mulai timer',
                  style: TextStyle(color: AppPalette.text),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  final mins = math.max(
                    1,
                    ((b.endHour - b.startHour) * 60).round(),
                  );
                  _startTimer(
                    b.name,
                    mins,
                    source: 'block',
                    sourceId: b.id,
                    identity: b.identity,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  b.isDone
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline_rounded,
                  color: const Color(0xFF5FD0A5),
                ),
                title: Text(
                  b.isDone ? 'Batalkan selesai' : 'Tandai selesai',
                  style: const TextStyle(color: AppPalette.text),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final isDone = !b.isDone;
                  if (widget.useSampleData) {
                    setState(() => b.isDone = isDone);
                  } else if (b.activity != null) {
                    try {
                      await ref
                          .read(activityRepoProvider)
                          .markComplete(b.activity!, isDone);
                    } catch (_) {
                      if (mounted) {
                        _showToast('Perubahan belum tersimpan. Coba lagi.');
                      }
                      return;
                    }
                  }
                  if (mounted) {
                    _showToast(isDone ? 'Blok ditandai selesai' : 'Dibatalkan');
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE88F7D),
                ),
                title: const Text(
                  'Hapus dari jam',
                  style: TextStyle(color: Color(0xFFE88F7D)),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (widget.useSampleData) {
                    setState(
                      () => _blocks.removeWhere((item) => item.id == b.id),
                    );
                  } else if (b.activity != null) {
                    try {
                      await ref
                          .read(activityRepoProvider)
                          .deleteSingleInstance(b.activity!, b.activity!.date);
                    } catch (_) {
                      if (mounted) {
                        _showToast('Blok belum terhapus. Coba lagi.');
                      }
                      return;
                    }
                  }
                  if (mounted) _showToast('Blok dihapus');
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
      backgroundColor: AppPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final q = query.toLowerCase().trim();

            final matchedBlocks = _blocks
                .where((b) => !b.isSleep && b.name.toLowerCase().contains(q))
                .toList();
            final matchedHabits = _habits
                .where((h) => h.title.toLowerCase().contains(q))
                .toList();
            final matchedPresets = _presets
                .where((p) => p.name.toLowerCase().contains(q))
                .toList();
            final matchedNotes = _notes
                .where((n) => n.text.toLowerCase().contains(q))
                .toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SizedBox(
                height: 480,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Cari aktivitas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      style: const TextStyle(color: AppPalette.text),
                      decoration: InputDecoration(
                        hintText: 'Ketik untuk mencari...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppPalette.textDim,
                        ),
                        filled: true,
                        fillColor: AppPalette.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppPalette.stroke,
                          ),
                        ),
                      ),
                      onChanged: (val) => setSheetState(() => query = val),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: q.isEmpty
                          ? const Center(
                              child: Text(
                                'Cari blok, kebiasaan, preset, atau catatan.',
                                style: TextStyle(color: AppPalette.textDim),
                              ),
                            )
                          : ListView(
                              children: [
                                ...matchedBlocks.map(
                                  (b) => ListTile(
                                    title: Text(
                                      b.name,
                                      style: const TextStyle(
                                        color: AppPalette.text,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${_formatHour(b.startHour)} - ${_formatHour(b.endHour)}',
                                      style: const TextStyle(
                                        color: AppPalette.textDim,
                                      ),
                                    ),
                                    trailing: const Text(
                                      'Blok',
                                      style: TextStyle(
                                        color: AppPalette.accent,
                                        fontSize: 11,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _openBlockDetailSheet(b);
                                    },
                                  ),
                                ),
                                ...matchedHabits.map(
                                  (h) => ListTile(
                                    title: Text(
                                      h.title,
                                      style: const TextStyle(
                                        color: AppPalette.text,
                                      ),
                                    ),
                                    trailing: const Text(
                                      'Kebiasaan',
                                      style: TextStyle(
                                        color: Color(0xFF5FD0A5),
                                        fontSize: 11,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _openHabitActionsSheet(h);
                                    },
                                  ),
                                ),
                                ...matchedPresets.map(
                                  (p) => ListTile(
                                    title: Text(
                                      p.name,
                                      style: const TextStyle(
                                        color: AppPalette.text,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${p.minutes} menit',
                                      style: const TextStyle(
                                        color: AppPalette.textDim,
                                      ),
                                    ),
                                    trailing: const Text(
                                      'Preset',
                                      style: TextStyle(
                                        color: Color(0xFF8FB8E8),
                                        fontSize: 11,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _openAddToClockSheet(p);
                                    },
                                  ),
                                ),
                                ...matchedNotes.map(
                                  (n) => ListTile(
                                    title: Text(
                                      n.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppPalette.text,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _formatDateShort(n.dateKey),
                                      style: const TextStyle(
                                        color: AppPalette.textDim,
                                      ),
                                    ),
                                    trailing: const Text(
                                      'Catatan',
                                      style: TextStyle(
                                        color: Color(0xFFC3A6F0),
                                        fontSize: 11,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      setState(() {
                                        _selectedNoteDate = n.dateKey;
                                        _notesFilter = 'date';
                                        _currentScreen = 'catatan';
                                      });
                                    },
                                  ),
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

  // ── 10. Menu Sheet ──
  void _openMenuSheet() {
    final settings = ref.read(launcherSettingsProvider);
    final showPrayer = settings.widgetDisplayMode == 'prayer';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.text,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuRow(Icons.home_outlined, 'Beranda', () {
                  Navigator.pop(ctx);
                  setState(() => _currentScreen = 'home');
                }),
                _buildMenuRow(Icons.search_rounded, 'Cari jadwal', () {
                  Navigator.pop(ctx);
                  _openSearchSheet();
                }),
                _buildMenuRow(
                  _isListView
                      ? Icons.schedule_rounded
                      : Icons.format_list_bulleted_rounded,
                  _isListView ? 'Lihat jam analog' : 'Lihat daftar jadwal',
                  () {
                    Navigator.pop(ctx);
                    setState(() => _isListView = !_isListView);
                  },
                ),
                _buildMenuRow(
                  Icons.center_focus_strong_outlined,
                  'Jelas: visual dan syukur',
                  () {
                    Navigator.pop(ctx);
                    setState(() => _currentScreen = 'jelas');
                  },
                ),
                _buildMenuRow(Icons.book_outlined, 'Catatan Harian', () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedNoteDate = _dateKey(0);
                    _notesFilter = 'date';
                    _currentScreen = 'catatan';
                  });
                }),
                _buildMenuRow(
                  Icons.person_add_alt_1_outlined,
                  'Tambah Identitas Baru',
                  () {
                    Navigator.pop(ctx);
                    _openCreateNewIdentityDialog();
                  },
                ),
                _buildMenuRow(
                  Icons.palette_outlined,
                  'Pilih Tema Focus Clock',
                  () {
                    Navigator.pop(ctx);
                    _openThemePickerSheet();
                  },
                ),
                _buildMenuRow(
                  !settings.showPrayerTimes
                      ? Icons.settings_outlined
                      : showPrayer
                      ? Icons.schedule_rounded
                      : Icons.mosque_outlined,
                  !settings.showPrayerTimes
                      ? 'Atur tampilan waktu salat'
                      : showPrayer
                      ? 'Tampilkan agenda Focus Clock'
                      : 'Tampilkan waktu salat',
                  () async {
                    Navigator.pop(ctx);
                    if (!settings.showPrayerTimes) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FitrahSettingsScreen(),
                        ),
                      );
                      return;
                    }
                    HapticFeedback.selectionClick();
                    final saved = await ref
                        .read(launcherSettingsProvider.notifier)
                        .setWidgetDisplayMode(
                          showPrayer ? 'focus_clock' : 'prayer',
                        );
                    if (!mounted) return;
                    if (!saved) {
                      _showToast('Pilihan belum tersimpan. Coba lagi.');
                    }
                  },
                ),
                _buildMenuRow(Icons.apps_rounded, 'Buka Apps Drawer', () {
                  Navigator.pop(ctx);
                  widget.onOpenAppDrawer();
                }),
                _buildMenuRow(
                  Icons.settings_suggest_outlined,
                  'Pengaturan Focus Clock',
                  () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                _buildMenuRow(
                  Icons.settings_outlined,
                  'Pengaturan Launcher',
                  () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FitrahSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuRow(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppPalette.accent),
      title: Text(
        title,
        style: const TextStyle(
          color: AppPalette.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppPalette.textDim),
      onTap: onTap,
    );
  }

  // ── Theme Picker Sheet (5 Natural Palettes) ──
  void _openThemePickerSheet() {
    final settings = ref.read(launcherSettingsProvider);
    final currentPalette = settings.themePalette;
    final tc = _HomeThemeColors.fromPalette(currentPalette);

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
        'name': 'Bookpaper',
        'desc': 'Arang Obsidian dengan aksen Bookpaper',
        'accent': AppPalette.accent,
        'bg': AppPalette.bg,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: tc.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_outlined, color: tc.accent, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pilih Tema Tampilan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: tc.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: tc.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Warna natural & ramah mata untuk fokus seharian tanpa silau',
                style: TextStyle(fontSize: 12, color: tc.textSecondary),
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
                    color: isSelected
                        ? accent.withOpacity(0.12)
                        : tc.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? accent : tc.stroke,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
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
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected ? accent : tc.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      desc,
                      style: TextStyle(fontSize: 11, color: tc.textSecondary),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: accent,
                            size: 20,
                          )
                        : null,
                    onTap: () async {
                      final saved = await ref
                          .read(launcherSettingsProvider.notifier)
                          .setThemePalette(key);
                      if (!mounted || !ctx.mounted) return;
                      if (saved) {
                        setState(() {});
                        Navigator.pop(ctx);
                        _showToast('Tema diubah ke $name');
                      } else {
                        _showToast('Tema belum tersimpan. Coba lagi.');
                      }
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
  void _openPrayerScheduleSheet(
    List<Map<String, dynamic>> prayers,
    int nextIndex,
    _HomeThemeColors tc,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: tc.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Waktu salat',
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < prayers.length; i++)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Icon(
                    Icons.mosque_outlined,
                    color: i == nextIndex ? tc.accent : tc.textSecondary,
                  ),
                  title: Text(
                    prayers[i]['name'] as String,
                    style: TextStyle(color: tc.textPrimary),
                  ),
                  trailing: Text(
                    prayers[i]['time'] as String,
                    style: TextStyle(
                      color: i == nextIndex ? tc.accent : tc.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openPrayerActionSheet(i, prayers[i]);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPrayerActionSheet(int index, Map<String, dynamic> prayer) {
    final name = prayer['name'] as String;
    final time = prayer['time'] as String;
    final pHour = prayer['hour'] as double;
    final isDone = _prayerDone[index] == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$name $time',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.text,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: Icon(
                  isDone
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline_rounded,
                  color: const Color(0xFF5FD0A5),
                ),
                title: Text(
                  isDone ? 'Batalkan tanda sudah salat' : 'Tandai sudah salat',
                  style: const TextStyle(color: AppPalette.text),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _prayerDone[index] = !isDone);
                  _showToast(
                    isDone
                        ? 'Batal tandai $name'
                        : '$name ditandai sudah salat',
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.add_alarm_rounded,
                  color: AppPalette.accent,
                ),
                title: const Text(
                  'Tambah blok 15 menit ke jam',
                  style: TextStyle(color: AppPalette.text),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final res = await _addBlock(pHour, pHour + 0.25, name, null);
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
      backgroundColor: AppPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pilih tanggal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.text,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(7, (i) {
                final k = _dateKey(-i);
                final label = i == 0 ? 'Hari ini' : '$i hari lalu';
                return ListTile(
                  title: Text(
                    _formatDateShort(k),
                    style: const TextStyle(
                      color: AppPalette.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Text(
                    label,
                    style: const TextStyle(color: AppPalette.textDim),
                  ),
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
