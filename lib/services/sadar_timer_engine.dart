import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../data/repositories/sadar_repository.dart';
import '../models/activity.dart';
import '../models/habit.dart';
import '../models/timer_session.dart';
import '../providers/providers.dart';
import '../providers/sadar_providers.dart';
import 'notification_service.dart';

const timerRecoveryNotice =
    'Waktu sejak aplikasi terakhir berjalan belum dihitung. Lanjutkan untuk menghitung lagi.';

class TimerState {
  final int habitId;
  final int? habitTargetSnapshot;
  final String habitName;
  final TimerSessionSourceKind? sourceKind;
  final int? activityId;
  final int targetSeconds;
  final int remainingSeconds;
  final int actualDurationSeconds;
  final TimerStateStatus status;
  final String? restoreError;
  final bool isFloating;
  final bool isSavePending;
  final bool recoveryUncertain;

  const TimerState({
    this.habitId = 0,
    this.habitTargetSnapshot,
    this.habitName = '',
    this.sourceKind,
    this.activityId,
    this.targetSeconds = 0,
    this.remainingSeconds = 0,
    this.actualDurationSeconds = 0,
    this.status = TimerStateStatus.idle,
    this.restoreError,
    this.isFloating = false,
    this.isSavePending = false,
    this.recoveryUncertain = false,
  });

  bool get isRunning => status == TimerStateStatus.running;
  bool get isPaused => status == TimerStateStatus.paused;
  bool get isCompleted => status == TimerStateStatus.completed;
  bool get isActive => isRunning || isPaused;
  bool get isOverdue =>
      sourceKind == TimerSessionSourceKind.yptHabit &&
      remainingSeconds == 0 &&
      actualDurationSeconds >= targetSeconds &&
      isActive;

  double get progress => targetSeconds > 0
      ? ((targetSeconds - remainingSeconds) / targetSeconds).clamp(0.0, 1.0)
      : 0.0;
}

class _AndroidClockSnapshot {
  const _AndroidClockSnapshot(this.bootCount, this.elapsedRealtimeMillis);

  final int bootCount;
  final int elapsedRealtimeMillis;
}

typedef TimerClockSnapshotReader = Future<Map<String, int>?> Function();

class SadarTimerEngine extends StateNotifier<TimerState> {
  SadarTimerEngine(this._repo, [this._notifier, this._clockSnapshotReader])
    : super(const TimerState()) {
    _restoreFuture = _restoreSavedSession();
  }

  final SadarRepository _repo;
  final NotificationService? _notifier;
  final TimerClockSnapshotReader? _clockSnapshotReader;
  late final Future<void> _restoreFuture;
  Timer? _ticker;
  Stopwatch? _segmentClock;
  _AndroidClockSnapshot? _androidClockSnapshot;
  static const _androidClockChannel = MethodChannel('fitrah_launcher/apps');

  TimerState get currentState => state;

  DateTime? _startedAt;
  DateTime? _sessionStartedAt;
  String? _attributionLocalDate;
  int _accumulatedSeconds = 0;
  Size? _savedWindowSize;
  int? _pendingActualDurationSeconds;
  String? _sourceIdentity;
  int? _sourceColorValue;

  Future<void> _restoreSavedSession() async {
    final saved = await _repo.getActiveTimerSession();
    if (saved == null || saved.status == TimerStateStatus.idle) return;

    if (!saved.hasValidSourceKind) {
      state = TimerState(
        habitId: saved.habitId,
        habitTargetSnapshot: saved.habitTargetSnapshot,
        habitName: saved.habitName,
        targetSeconds: saved.targetSeconds,
        remainingSeconds:
            (saved.targetSeconds - saved.accumulatedDurationSeconds).clamp(
              0,
              saved.targetSeconds,
            ),
        actualDurationSeconds: saved.accumulatedDurationSeconds,
        status: TimerStateStatus.paused,
        isSavePending: true,
        restoreError:
            'Timer ini memakai sumber yang tidak dikenali. Data sesi tetap disimpan; mulai timer baru dinonaktifkan.',
      );
      return;
    }

    final now = DateTime.now();
    _androidClockSnapshot = await _readAndroidClockSnapshot();
    final sourceKind =
        saved.sourceKind ??
        (saved.habitId > 0
            ? TimerSessionSourceKind.habit
            : TimerSessionSourceKind.free);
    _sourceIdentity = saved.sourceIdentity;
    _sourceColorValue = saved.sourceColorValue;
    _accumulatedSeconds = saved.accumulatedDurationSeconds;
    _sessionStartedAt = saved.startedAt;
    _attributionLocalDate =
        saved.attributionLocalDate ??
        _formatLocalDate(saved.startedAt ?? DateTime.now());

    if (saved.status == TimerStateStatus.running && saved.startedAt != null) {
      final runningSince = saved.runningSince ?? saved.startedAt!;
      // Only a matching boot identity can prove elapsed time across restore.
      final sameBoot =
          _androidClockSnapshot != null &&
          saved.clockBootCount == _androidClockSnapshot!.bootCount &&
          saved.clockElapsedRealtimeMillis != null;
      final validSameBootSnapshot =
          sameBoot &&
          saved.clockElapsedRealtimeMillis! <=
              _androidClockSnapshot!.elapsedRealtimeMillis;
      if (!validSameBootSnapshot) {
        final remaining = (saved.targetSeconds - _accumulatedSeconds).clamp(
          0,
          saved.targetSeconds,
        );
        state = TimerState(
          habitId: saved.habitId,
          habitTargetSnapshot: saved.habitTargetSnapshot,
          habitName: saved.habitName,
          sourceKind: sourceKind,
          activityId: saved.activityId,
          targetSeconds: saved.targetSeconds,
          remainingSeconds: remaining,
          actualDurationSeconds: _accumulatedSeconds,
          status: TimerStateStatus.paused,
          recoveryUncertain: true,
        );
        return;
      }
      final elapsedSinceStart = validSameBootSnapshot
          ? math.max(
              0,
              (_androidClockSnapshot!.elapsedRealtimeMillis -
                      saved.clockElapsedRealtimeMillis!) ~/
                  1000,
            )
          : math.max(0, now.difference(runningSince).inSeconds);
      final totalElapsed = _accumulatedSeconds + elapsedSinceStart;
      final remaining = (saved.targetSeconds - totalElapsed).clamp(
        0,
        saved.targetSeconds,
      );

      if (remaining <= 0) {
        if (sourceKind == TimerSessionSourceKind.yptHabit) {
          _accumulatedSeconds = totalElapsed;
          _startedAt = now;
          _androidClockSnapshot = await _readAndroidClockSnapshot();
          _segmentClock = Stopwatch()..start();
          state = TimerState(
            habitId: saved.habitId,
            habitTargetSnapshot: saved.habitTargetSnapshot,
            habitName: saved.habitName,
            sourceKind: sourceKind,
            activityId: saved.activityId,
            targetSeconds: saved.targetSeconds,
            remainingSeconds: 0,
            actualDurationSeconds: totalElapsed,
            status: TimerStateStatus.running,
          );
          _startTicker();
          return;
        }
        // Completed while app was closed
        state = TimerState(
          habitId: saved.habitId,
          habitTargetSnapshot: saved.habitTargetSnapshot,
          habitName: saved.habitName,
          sourceKind: sourceKind,
          activityId: saved.activityId,
          targetSeconds: saved.targetSeconds,
          remainingSeconds: 0,
          actualDurationSeconds: totalElapsed,
          status: TimerStateStatus.completed,
          isSavePending: true,
        );
        _pendingActualDurationSeconds = totalElapsed;
        try {
          await _completeSession(
            autoRecord: true,
            actualDurationSeconds: totalElapsed,
          );
        } catch (error) {
          debugPrint('Timer completion will retry: $error');
        }
        return;
      } else {
        // Use monotonic time for this live process; wall time is only needed
        // to estimate the interval that elapsed while the app was closed.
        _accumulatedSeconds = totalElapsed;
        _startedAt = now;
        _androidClockSnapshot = await _readAndroidClockSnapshot();
        _segmentClock = Stopwatch()..start();
        state = TimerState(
          habitId: saved.habitId,
          habitTargetSnapshot: saved.habitTargetSnapshot,
          habitName: saved.habitName,
          sourceKind: sourceKind,
          activityId: saved.activityId,
          targetSeconds: saved.targetSeconds,
          remainingSeconds: remaining,
          actualDurationSeconds: totalElapsed,
          status: TimerStateStatus.running,
        );
        _startTicker();
      }
    } else if (saved.status == TimerStateStatus.paused) {
      final remaining = (saved.targetSeconds - _accumulatedSeconds).clamp(
        0,
        saved.targetSeconds,
      );
      state = TimerState(
        habitId: saved.habitId,
        habitTargetSnapshot: saved.habitTargetSnapshot,
        habitName: saved.habitName,
        sourceKind: sourceKind,
        activityId: saved.activityId,
        targetSeconds: saved.targetSeconds,
        remainingSeconds: remaining,
        actualDurationSeconds: _accumulatedSeconds,
        status: TimerStateStatus.paused,
      );
    } else if (saved.status == TimerStateStatus.completed) {
      state = TimerState(
        habitId: saved.habitId,
        habitTargetSnapshot: saved.habitTargetSnapshot,
        habitName: saved.habitName,
        sourceKind: sourceKind,
        activityId: saved.activityId,
        targetSeconds: saved.targetSeconds,
        remainingSeconds: 0,
        actualDurationSeconds: saved.accumulatedDurationSeconds,
        status: TimerStateStatus.completed,
        isSavePending: true,
      );
      _pendingActualDurationSeconds = saved.accumulatedDurationSeconds;
      try {
        await _completeSession(
          autoRecord:
              saved.habitId > 0 ||
              saved.activityId != null ||
              sourceKind == TimerSessionSourceKind.preset,
          actualDurationSeconds: saved.accumulatedDurationSeconds,
        );
      } catch (error) {
        debugPrint('Timer completion will retry: $error');
      }
    }
  }

  Future<void> waitUntilRestored() => _restoreFuture;

  Future<bool> start(Habit habit) =>
      _startHabit(habit, TimerSessionSourceKind.habit);

  Future<bool> startYpt(Habit habit) =>
      _startHabit(habit, TimerSessionSourceKind.yptHabit);

  Future<bool> _startHabit(
    Habit habit,
    TimerSessionSourceKind sourceKind,
  ) async {
    await _restoreFuture;
    if (state.isActive) {
      return state.habitId == habit.id && state.sourceKind == sourceKind;
    }
    if (state.isSavePending || _isCompleting) return false;

    final previousState = state;
    final targetSec = (habit.target > 0 ? habit.target : 20) * 60;
    _androidClockSnapshot = await _readAndroidClockSnapshot();
    _startedAt = DateTime.now();
    _segmentClock = Stopwatch()..start();
    _sessionStartedAt = _startedAt;
    _attributionLocalDate = _formatLocalDate(_startedAt!);
    _accumulatedSeconds = 0;
    _sourceIdentity = null;
    _sourceColorValue = null;

    state = TimerState(
      habitId: habit.id,
      habitTargetSnapshot:
          habit.habitType == 'timed' && habit.unit == HabitUnit.min
          ? habit.target
          : null,
      habitName: habit.name,
      sourceKind: sourceKind,
      targetSeconds: targetSec,
      remainingSeconds: targetSec,
      status: TimerStateStatus.running,
    );

    try {
      await _persistState();
    } catch (_) {
      _startedAt = null;
      _segmentClock = null;
      _androidClockSnapshot = null;
      _sessionStartedAt = null;
      _attributionLocalDate = null;
      _accumulatedSeconds = 0;
      state = previousState;
      rethrow;
    }
    _startTicker();
    return true;
  }

  Future<bool> startNonHabit({
    required String title,
    required int targetSeconds,
    required TimerSessionSourceKind sourceKind,
    int? activityId,
    String? sourceIdentity,
    int? sourceColorValue,
    Activity? activityToCreate,
  }) async {
    if (sourceKind == TimerSessionSourceKind.habit || targetSeconds <= 0) {
      throw ArgumentError(
        'A non-habit session needs a positive duration and source.',
      );
    }
    await _restoreFuture;
    if (state.isActive || state.isSavePending || _isCompleting) return false;

    final previousState = state;
    final previousIdentity = _sourceIdentity;
    final previousColorValue = _sourceColorValue;
    _androidClockSnapshot = await _readAndroidClockSnapshot();
    _startedAt = DateTime.now();
    _segmentClock = Stopwatch()..start();
    _sessionStartedAt = _startedAt;
    _attributionLocalDate = _formatLocalDate(_startedAt!);
    _accumulatedSeconds = 0;
    _sourceIdentity = sourceIdentity;
    _sourceColorValue = sourceColorValue;
    state = TimerState(
      habitName: title,
      targetSeconds: targetSeconds,
      remainingSeconds: targetSeconds,
      status: TimerStateStatus.running,
      sourceKind: sourceKind,
      activityId: activityId,
    );
    try {
      if (activityToCreate == null) {
        final session = _buildSession();
        await _repo.saveTimerSession(session);
        state = TimerState(
          habitId: session.habitId,
          habitTargetSnapshot: session.habitTargetSnapshot,
          habitName: title,
          targetSeconds: targetSeconds,
          remainingSeconds: targetSeconds,
          status: TimerStateStatus.running,
          sourceKind: sourceKind,
          activityId: activityId,
        );
      } else {
        final session = _buildSession();
        final activityId = await _repo.createActivityAndStartTimerSession(
          activityToCreate,
          session,
        );
        state = TimerState(
          habitId: session.habitId,
          habitTargetSnapshot: session.habitTargetSnapshot,
          habitName: title,
          targetSeconds: targetSeconds,
          remainingSeconds: targetSeconds,
          status: TimerStateStatus.running,
          sourceKind: sourceKind,
          activityId: activityId,
        );
      }
    } catch (_) {
      _startedAt = null;
      _segmentClock = null;
      _androidClockSnapshot = null;
      _sessionStartedAt = null;
      _attributionLocalDate = null;
      _accumulatedSeconds = 0;
      _sourceIdentity = previousIdentity;
      _sourceColorValue = previousColorValue;
      state = previousState;
      rethrow;
    }
    _startTicker();
    return true;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == TimerStateStatus.running && _startedAt != null) {
        final elapsed = _elapsedSeconds();
        final remaining = (state.targetSeconds - elapsed).clamp(
          0,
          state.targetSeconds,
        );

        if (remaining <= 0 &&
            state.sourceKind == TimerSessionSourceKind.yptHabit) {
          state = TimerState(
            habitId: state.habitId,
            habitTargetSnapshot: state.habitTargetSnapshot,
            habitName: state.habitName,
            sourceKind: state.sourceKind,
            targetSeconds: state.targetSeconds,
            remainingSeconds: 0,
            actualDurationSeconds: elapsed,
            status: TimerStateStatus.running,
            isFloating: state.isFloating,
          );
        } else if (remaining <= 0) {
          _ticker?.cancel();
          state = TimerState(
            habitId: state.habitId,
            habitTargetSnapshot: state.habitTargetSnapshot,
            habitName: state.habitName,
            sourceKind: state.sourceKind,
            activityId: state.activityId,
            targetSeconds: state.targetSeconds,
            remainingSeconds: 0,
            actualDurationSeconds: elapsed,
            status: TimerStateStatus.completed,
            isFloating: state.isFloating,
            isSavePending: true,
          );
          _pendingActualDurationSeconds = elapsed;
          unawaited(
            _completeSession(
              autoRecord: true,
              actualDurationSeconds: elapsed,
            ).catchError((Object error) {
              debugPrint('Timer completion will retry: $error');
            }),
          );
        } else {
          state = TimerState(
            habitId: state.habitId,
            habitTargetSnapshot: state.habitTargetSnapshot,
            habitName: state.habitName,
            sourceKind: state.sourceKind,
            activityId: state.activityId,
            targetSeconds: state.targetSeconds,
            remainingSeconds: remaining,
            actualDurationSeconds: elapsed,
            status: TimerStateStatus.running,
            isFloating: state.isFloating,
          );
        }
      }
    });
  }

  Future<void> pause() async {
    if (state.status != TimerStateStatus.running) return;

    final previousState = state;
    final elapsedAtPause = _elapsedSeconds();
    if (_startedAt != null) {
      _accumulatedSeconds = elapsedAtPause;
      _startedAt = null;
      _segmentClock = null;
      _androidClockSnapshot = null;
    }

    _ticker?.cancel();
    state = TimerState(
      habitId: state.habitId,
      habitTargetSnapshot: state.habitTargetSnapshot,
      habitName: state.habitName,
      sourceKind: state.sourceKind,
      activityId: state.activityId,
      targetSeconds: state.targetSeconds,
      remainingSeconds: (state.targetSeconds - _accumulatedSeconds).clamp(
        0,
        state.targetSeconds,
      ),
      actualDurationSeconds: _accumulatedSeconds,
      status: TimerStateStatus.paused,
      isFloating: state.isFloating,
    );

    try {
      await _persistState();
    } catch (_) {
      // Resume from the exact duration already measured before persistence
      // failed, using a fresh monotonic segment.
      _androidClockSnapshot = await _readAndroidClockSnapshot();
      _startedAt = DateTime.now();
      _segmentClock = Stopwatch()..start();
      state = previousState;
      _startTicker();
      rethrow;
    }
  }

  Future<void> resume() async {
    if (state.restoreError != null) throw StateError(state.restoreError!);
    if (state.status != TimerStateStatus.paused) return;

    final previousState = state;
    _androidClockSnapshot = await _readAndroidClockSnapshot();
    _startedAt = DateTime.now();
    _segmentClock = Stopwatch()..start();
    _sessionStartedAt ??= _startedAt;
    _attributionLocalDate ??= _formatLocalDate(_sessionStartedAt!);
    state = TimerState(
      habitId: state.habitId,
      habitTargetSnapshot: state.habitTargetSnapshot,
      habitName: state.habitName,
      sourceKind: state.sourceKind,
      activityId: state.activityId,
      targetSeconds: state.targetSeconds,
      remainingSeconds: state.remainingSeconds,
      actualDurationSeconds: _accumulatedSeconds,
      status: TimerStateStatus.running,
      isFloating: state.isFloating,
      recoveryUncertain: false,
    );

    try {
      await _persistState();
    } catch (_) {
      _startedAt = null;
      _segmentClock = null;
      _androidClockSnapshot = null;
      state = previousState;
      rethrow;
    }
    _startTicker();
  }

  Future<void> extendBy(int seconds) async {
    if (state.restoreError != null) throw StateError(state.restoreError!);
    if (state.recoveryUncertain) {
      throw StateError('Lanjutkan sesi dulu sebelum menambah durasi.');
    }
    if (!state.isActive || seconds <= 0) return;
    final previousState = state;
    state = TimerState(
      habitId: state.habitId,
      habitTargetSnapshot: state.habitTargetSnapshot,
      habitName: state.habitName,
      sourceKind: state.sourceKind,
      activityId: state.activityId,
      targetSeconds: state.targetSeconds + seconds,
      remainingSeconds: state.remainingSeconds + seconds,
      actualDurationSeconds: state.actualDurationSeconds,
      status: state.status,
      isFloating: state.isFloating,
      recoveryUncertain: state.recoveryUncertain,
    );
    try {
      await _persistState();
    } catch (_) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> finishEarly() async {
    if (state.restoreError != null) throw StateError(state.restoreError!);
    if (!state.isActive) return;
    final actualDurationSeconds = _startedAt == null
        ? _accumulatedSeconds
        : _elapsedSeconds();
    _ticker?.cancel();
    state = TimerState(
      habitId: state.habitId,
      habitTargetSnapshot: state.habitTargetSnapshot,
      habitName: state.habitName,
      sourceKind: state.sourceKind,
      activityId: state.activityId,
      targetSeconds: state.targetSeconds,
      remainingSeconds: 0,
      actualDurationSeconds: actualDurationSeconds,
      status: TimerStateStatus.completed,
      isFloating: state.isFloating,
      isSavePending: true,
    );
    _accumulatedSeconds = actualDurationSeconds;
    _startedAt = null;
    _segmentClock = null;
    _androidClockSnapshot = null;
    _pendingActualDurationSeconds = actualDurationSeconds;
    await _completeSession(
      autoRecord: true,
      actualDurationSeconds: actualDurationSeconds,
    );
  }

  Future<void> retryCompletion() async {
    if (state.restoreError != null) throw StateError(state.restoreError!);
    if (!state.isSavePending || _isCompleting) return;
    await _completeSession(
      autoRecord:
          state.habitId > 0 ||
          state.activityId != null ||
          state.sourceKind == TimerSessionSourceKind.preset,
      actualDurationSeconds: _pendingActualDurationSeconds,
    );
  }

  Future<void> cancel() async {
    if (state.isSavePending) return;
    final wasFloating = state.isFloating;
    _ticker?.cancel();
    try {
      await _repo.clearTimerSession();
    } catch (_) {
      if (state.isRunning) _startTicker();
      rethrow;
    }

    _startedAt = null;
    _segmentClock = null;
    _androidClockSnapshot = null;
    _sessionStartedAt = null;
    _attributionLocalDate = null;
    _accumulatedSeconds = 0;
    _sourceIdentity = null;
    _sourceColorValue = null;
    state = const TimerState();

    if (wasFloating) {
      await restoreNormalWindow();
    }
  }

  bool _isCompleting = false;

  Future<void> _completeSession({
    bool autoRecord = true,
    int? actualDurationSeconds,
  }) async {
    if (_isCompleting) return;
    _isCompleting = true;

    try {
      _ticker?.cancel();

      if (autoRecord && state.activityId != null) {
        await _repo.completeActivityTimerSession(
          activityId: state.activityId!,
          actualDurationSeconds:
              actualDurationSeconds ?? state.actualDurationSeconds,
          completedAt: DateTime.now(),
        );
      } else if (autoRecord && state.habitId > 0) {
        final now = DateTime.now();
        // Attribute the session to the date it was started, including pauses.
        final dateStr = _attributionLocalDate ?? _formatLocalDate(now);
        final actualMinutes = actualDurationSeconds == null
            ? (state.targetSeconds / 60).ceil()
            : (actualDurationSeconds / 60).floor();
        final targetMinutes = (state.targetSeconds / 60).ceil();
        await _repo.completeTimerSession(
          habitId: state.habitId,
          dateString: dateStr,
          actualDurationMinutes: actualMinutes,
          actualDurationSeconds: actualDurationSeconds,
          targetSnapshot: state.habitTargetSnapshot ?? targetMinutes,
          completedAt: now,
        );
      } else if (autoRecord &&
          state.sourceKind == TimerSessionSourceKind.preset) {
        await _repo.completePresetTimerSession(
          title: state.habitName,
          identity: _sourceIdentity,
          colorValue: _sourceColorValue,
          startedAt: _sessionStartedAt ?? DateTime.now(),
          actualDurationSeconds:
              actualDurationSeconds ?? state.actualDurationSeconds,
          completedAt: DateTime.now(),
        );
      } else {
        await _repo.clearTimerSession();
      }

      state = TimerState(
        habitId: state.habitId,
        habitTargetSnapshot: state.habitTargetSnapshot,
        habitName: state.habitName,
        sourceKind: state.sourceKind,
        activityId: state.activityId,
        targetSeconds: state.targetSeconds,
        remainingSeconds: state.remainingSeconds,
        actualDurationSeconds: state.actualDurationSeconds,
        status: state.status,
        isFloating: state.isFloating,
        isSavePending: false,
      );
      _sessionStartedAt = null;
      _attributionLocalDate = null;
      _pendingActualDurationSeconds = null;
      _sourceIdentity = null;
      _sourceColorValue = null;

      try {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.heavyImpact();
      } catch (_) {}

      if (_notifier != null && state.habitName.isNotEmpty) {
        _notifier.showNotification(
          id: 8888,
          title: 'Selesai: ${state.habitName}',
          body: 'Waktu fokus telah dicatat.',
        );
      }
    } finally {
      _isCompleting = false;
    }
  }

  Future<void> _persistState() async {
    await _repo.saveTimerSession(_buildSession());
  }

  int _elapsedSeconds() =>
      _accumulatedSeconds + (_segmentClock?.elapsed.inSeconds ?? 0);

  Future<_AndroidClockSnapshot?> _readAndroidClockSnapshot() async {
    if (kIsWeb || (_clockSnapshotReader == null && !Platform.isAndroid)) {
      return null;
    }
    try {
      final values = _clockSnapshotReader != null
          ? await _clockSnapshotReader()
          : await _androidClockChannel.invokeMapMethod<String, int>(
              'getTimerClockSnapshot',
            );
      final bootCount = values?['bootCount'];
      final elapsedRealtimeMillis = values?['elapsedRealtimeMillis'];
      if (bootCount == null || elapsedRealtimeMillis == null) return null;
      return _AndroidClockSnapshot(bootCount, elapsedRealtimeMillis);
    } catch (_) {
      // Clock snapshots improve restore fidelity but must never block timers
      // on platforms where the Android bridge is unavailable.
      return null;
    }
  }

  TimerSession _buildSession() => TimerSession()
    ..habitId = state.habitId
    ..habitTargetSnapshot = state.habitTargetSnapshot
    ..habitName = state.habitName
    ..sourceKind = state.sourceKind
    ..activityId = state.activityId
    ..sourceIdentity = _sourceIdentity
    ..sourceColorValue = _sourceColorValue
    ..targetSeconds = state.targetSeconds
    ..startedAt = _sessionStartedAt ?? _startedAt
    ..attributionLocalDate = _attributionLocalDate
    ..runningSince = state.isRunning ? _startedAt : null
    ..clockBootCount = _androidClockSnapshot?.bootCount
    ..clockElapsedRealtimeMillis = _androidClockSnapshot?.elapsedRealtimeMillis
    ..accumulatedDurationSeconds = _accumulatedSeconds
    ..status = state.status;

  String _formatLocalDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // ──────────────────────────────────────────────────────────────────────────
  // Desktop Floating Always-on-Top Timer (Windows / Desktop)
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> toggleFloatingWindow() async {
    if (kIsWeb ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return;
    }

    if (state.isFloating) {
      await restoreNormalWindow();
    } else {
      await makeFloatingWindow();
    }
  }

  Future<void> makeFloatingWindow() async {
    if (kIsWeb ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return;
    }

    try {
      _savedWindowSize = await windowManager.getSize();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSize(const Size(280, 150));
      await windowManager.setResizable(false);
      state = TimerState(
        habitId: state.habitId,
        habitTargetSnapshot: state.habitTargetSnapshot,
        habitName: state.habitName,
        sourceKind: state.sourceKind,
        activityId: state.activityId,
        actualDurationSeconds: state.actualDurationSeconds,
        restoreError: state.restoreError,
        isSavePending: state.isSavePending,
        targetSeconds: state.targetSeconds,
        remainingSeconds: state.remainingSeconds,
        status: state.status,
        isFloating: true,
        recoveryUncertain: state.recoveryUncertain,
      );
    } catch (e) {
      debugPrint('makeFloatingWindow error: $e');
    }
  }

  Future<void> restoreNormalWindow() async {
    if (kIsWeb ||
        !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return;
    }

    try {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setSize(_savedWindowSize ?? const Size(820, 720));
      await windowManager.setResizable(true);
      state = TimerState(
        habitId: state.habitId,
        habitTargetSnapshot: state.habitTargetSnapshot,
        habitName: state.habitName,
        sourceKind: state.sourceKind,
        activityId: state.activityId,
        actualDurationSeconds: state.actualDurationSeconds,
        restoreError: state.restoreError,
        isSavePending: state.isSavePending,
        targetSeconds: state.targetSeconds,
        remainingSeconds: state.remainingSeconds,
        status: state.status,
        isFloating: false,
        recoveryUncertain: state.recoveryUncertain,
      );
    } catch (e) {
      debugPrint('restoreNormalWindow error: $e');
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final timerEngineProvider = StateNotifierProvider<SadarTimerEngine, TimerState>(
  (ref) {
    final repo = ref.watch(sadarRepoProvider);
    NotificationService? notifier;
    try {
      notifier = ref.watch(notificationServiceProvider);
    } catch (_) {}
    return SadarTimerEngine(repo, notifier);
  },
);
