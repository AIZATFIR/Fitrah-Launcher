import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../data/repositories/sadar_repository.dart';
import '../models/habit.dart';
import '../models/timer_session.dart';
import '../providers/providers.dart';
import '../providers/sadar_providers.dart';
import 'notification_service.dart';

class TimerState {
  final int habitId;
  final String habitName;
  final int targetSeconds;
  final int remainingSeconds;
  final int actualDurationSeconds;
  final TimerStateStatus status;
  final bool isFloating;
  final bool isSavePending;

  const TimerState({
    this.habitId = 0,
    this.habitName = '',
    this.targetSeconds = 0,
    this.remainingSeconds = 0,
    this.actualDurationSeconds = 0,
    this.status = TimerStateStatus.idle,
    this.isFloating = false,
    this.isSavePending = false,
  });

  bool get isRunning => status == TimerStateStatus.running;
  bool get isPaused => status == TimerStateStatus.paused;
  bool get isCompleted => status == TimerStateStatus.completed;
  bool get isActive => isRunning || isPaused;

  double get progress => targetSeconds > 0
      ? ((targetSeconds - remainingSeconds) / targetSeconds).clamp(0.0, 1.0)
      : 0.0;
}

class SadarTimerEngine extends StateNotifier<TimerState> {
  SadarTimerEngine(this._repo, [this._notifier]) : super(const TimerState()) {
    _restoreFuture = _restoreSavedSession();
  }

  final SadarRepository _repo;
  final NotificationService? _notifier;
  late final Future<void> _restoreFuture;
  Timer? _ticker;

  TimerState get currentState => state;

  DateTime? _startedAt;
  DateTime? _sessionStartedAt;
  int _accumulatedSeconds = 0;
  Size? _savedWindowSize;
  int? _pendingActualDurationSeconds;

  Future<void> _restoreSavedSession() async {
    final saved = await _repo.getActiveTimerSession();
    if (saved == null || saved.status == TimerStateStatus.idle) return;

    final now = DateTime.now();
    _accumulatedSeconds = saved.accumulatedDurationSeconds;

    if (saved.status == TimerStateStatus.running && saved.startedAt != null) {
      _sessionStartedAt = saved.startedAt;
      final elapsedSinceStart = now.difference(saved.startedAt!).inSeconds;
      final totalElapsed = _accumulatedSeconds + elapsedSinceStart;
      final remaining = (saved.targetSeconds - totalElapsed).clamp(
        0,
        saved.targetSeconds,
      );

      if (remaining <= 0) {
        // Completed while app was closed
        state = TimerState(
          habitId: saved.habitId,
          habitName: saved.habitName,
          targetSeconds: saved.targetSeconds,
          remainingSeconds: 0,
          actualDurationSeconds: saved.targetSeconds,
          status: TimerStateStatus.completed,
          isSavePending: true,
        );
        _pendingActualDurationSeconds = null;
        try {
          await _completeSession(autoRecord: true);
        } catch (error) {
          debugPrint('Timer completion will retry: $error');
        }
        return;
      } else {
        _startedAt = saved.startedAt;
        state = TimerState(
          habitId: saved.habitId,
          habitName: saved.habitName,
          targetSeconds: saved.targetSeconds,
          remainingSeconds: remaining,
          actualDurationSeconds: totalElapsed,
          status: TimerStateStatus.running,
        );
        _startTicker();
      }
    } else if (saved.status == TimerStateStatus.paused) {
      _sessionStartedAt = saved.startedAt;
      final remaining = (saved.targetSeconds - _accumulatedSeconds).clamp(
        0,
        saved.targetSeconds,
      );
      state = TimerState(
        habitId: saved.habitId,
        habitName: saved.habitName,
        targetSeconds: saved.targetSeconds,
        remainingSeconds: remaining,
        actualDurationSeconds: _accumulatedSeconds,
        status: TimerStateStatus.paused,
      );
    } else if (saved.status == TimerStateStatus.completed) {
      _sessionStartedAt = saved.startedAt;
      state = TimerState(
        habitId: saved.habitId,
        habitName: saved.habitName,
        targetSeconds: saved.targetSeconds,
        remainingSeconds: 0,
        actualDurationSeconds: saved.accumulatedDurationSeconds,
        status: TimerStateStatus.completed,
        isSavePending: true,
      );
      _pendingActualDurationSeconds = saved.accumulatedDurationSeconds;
      try {
        await _completeSession(
          autoRecord: saved.habitId > 0,
          actualDurationSeconds: saved.accumulatedDurationSeconds,
        );
      } catch (error) {
        debugPrint('Timer completion will retry: $error');
      }
    }
  }

  Future<bool> start(Habit habit) async {
    await _restoreFuture;
    if (state.isActive) return state.habitId == habit.id;
    if (state.isSavePending || _isCompleting) return false;

    final previousState = state;
    final targetSec = (habit.target > 0 ? habit.target : 20) * 60;
    _startedAt = DateTime.now();
    _sessionStartedAt = _startedAt;
    _accumulatedSeconds = 0;

    state = TimerState(
      habitId: habit.id,
      habitName: habit.name,
      targetSeconds: targetSec,
      remainingSeconds: targetSec,
      status: TimerStateStatus.running,
    );

    try {
      await _persistState();
    } catch (_) {
      _startedAt = null;
      _sessionStartedAt = null;
      _accumulatedSeconds = 0;
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
        final elapsed =
            _accumulatedSeconds +
            DateTime.now().difference(_startedAt!).inSeconds;
        final remaining = (state.targetSeconds - elapsed).clamp(
          0,
          state.targetSeconds,
        );

        if (remaining <= 0) {
          _ticker?.cancel();
          state = TimerState(
            habitId: state.habitId,
            habitName: state.habitName,
            targetSeconds: state.targetSeconds,
            remainingSeconds: 0,
            actualDurationSeconds: elapsed,
            status: TimerStateStatus.completed,
            isFloating: state.isFloating,
            isSavePending: true,
          );
          _pendingActualDurationSeconds = null;
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
            habitName: state.habitName,
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
    final previousStartedAt = _startedAt;
    final previousAccumulatedSeconds = _accumulatedSeconds;
    if (_startedAt != null) {
      _accumulatedSeconds += DateTime.now().difference(_startedAt!).inSeconds;
      _startedAt = null;
    }

    _ticker?.cancel();
    state = TimerState(
      habitId: state.habitId,
      habitName: state.habitName,
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
      _startedAt = previousStartedAt;
      _accumulatedSeconds = previousAccumulatedSeconds;
      state = previousState;
      _startTicker();
      rethrow;
    }
  }

  Future<void> resume() async {
    if (state.status != TimerStateStatus.paused) return;

    final previousState = state;
    _startedAt = DateTime.now();
    _sessionStartedAt ??= _startedAt;
    state = TimerState(
      habitId: state.habitId,
      habitName: state.habitName,
      targetSeconds: state.targetSeconds,
      remainingSeconds: state.remainingSeconds,
      actualDurationSeconds: _accumulatedSeconds,
      status: TimerStateStatus.running,
      isFloating: state.isFloating,
    );

    try {
      await _persistState();
    } catch (_) {
      _startedAt = null;
      state = previousState;
      rethrow;
    }
    _startTicker();
  }

  Future<void> finishEarly() async {
    if (!state.isActive) return;
    final now = DateTime.now();
    final actualDurationSeconds =
        _accumulatedSeconds +
        (_startedAt == null ? 0 : now.difference(_startedAt!).inSeconds);
    _ticker?.cancel();
    state = TimerState(
      habitId: state.habitId,
      habitName: state.habitName,
      targetSeconds: state.targetSeconds,
      remainingSeconds: 0,
      actualDurationSeconds: actualDurationSeconds,
      status: TimerStateStatus.completed,
      isFloating: state.isFloating,
      isSavePending: true,
    );
    _accumulatedSeconds = actualDurationSeconds;
    _startedAt = null;
    _pendingActualDurationSeconds = actualDurationSeconds;
    await _completeSession(
      autoRecord: true,
      actualDurationSeconds: actualDurationSeconds,
    );
  }

  Future<void> retryCompletion() async {
    if (!state.isSavePending || _isCompleting) return;
    await _completeSession(
      autoRecord: state.habitId > 0,
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
    _sessionStartedAt = null;
    _accumulatedSeconds = 0;
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

      if (autoRecord && state.habitId > 0) {
        final now = DateTime.now();
        // Attribute the session to the date it was started, including pauses.
        final sessionStartDate = _sessionStartedAt ?? _startedAt ?? now;
        final dateStr =
            '${sessionStartDate.year.toString().padLeft(4, '0')}-${sessionStartDate.month.toString().padLeft(2, '0')}-${sessionStartDate.day.toString().padLeft(2, '0')}';
        final actualMinutes = actualDurationSeconds == null
            ? (state.targetSeconds / 60).ceil()
            : (actualDurationSeconds / 60).floor();
        final targetMinutes = (state.targetSeconds / 60).ceil();
        await _repo.completeTimerSession(
          habitId: state.habitId,
          dateString: dateStr,
          actualDurationMinutes: actualMinutes,
          targetSnapshot: targetMinutes,
          completedAt: now,
        );
      } else {
        await _repo.clearTimerSession();
      }

      state = TimerState(
        habitId: state.habitId,
        habitName: state.habitName,
        targetSeconds: state.targetSeconds,
        remainingSeconds: state.remainingSeconds,
        actualDurationSeconds: state.actualDurationSeconds,
        status: state.status,
        isFloating: state.isFloating,
        isSavePending: false,
      );
      _sessionStartedAt = null;
      _pendingActualDurationSeconds = null;

      try {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.heavyImpact();
      } catch (_) {}

      if (_notifier != null && state.habitName.isNotEmpty) {
        _notifier.showNotification(
          id: 8888,
          title: 'Selesai: ${state.habitName}',
          body:
              'Waktu fokus selesai. Satu tindakan bermakna telah terpenuhi hari ini.',
        );
      }
    } finally {
      _isCompleting = false;
    }
  }

  Future<void> _persistState() async {
    final session = TimerSession()
      ..habitId = state.habitId
      ..habitName = state.habitName
      ..targetSeconds = state.targetSeconds
      ..startedAt = _startedAt ?? _sessionStartedAt
      ..accumulatedDurationSeconds = _accumulatedSeconds
      ..status = state.status;

    await _repo.saveTimerSession(session);
  }

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
        habitName: state.habitName,
        targetSeconds: state.targetSeconds,
        remainingSeconds: state.remainingSeconds,
        status: state.status,
        isFloating: true,
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
        habitName: state.habitName,
        targetSeconds: state.targetSeconds,
        remainingSeconds: state.remainingSeconds,
        status: state.status,
        isFloating: false,
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
