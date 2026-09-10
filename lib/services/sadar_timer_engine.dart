import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../data/repositories/sadar_repository.dart';
import '../models/habit.dart';
import '../models/habit_entry.dart';
import '../models/timer_session.dart';
import '../providers/providers.dart';
import '../providers/sadar_providers.dart';
import 'notification_service.dart';

class TimerState {
  final int habitId;
  final String habitName;
  final int targetSeconds;
  final int remainingSeconds;
  final TimerStateStatus status;
  final bool isFloating;

  const TimerState({
    this.habitId = 0,
    this.habitName = '',
    this.targetSeconds = 0,
    this.remainingSeconds = 0,
    this.status = TimerStateStatus.idle,
    this.isFloating = false,
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
    _restoreSavedSession();
  }

  final SadarRepository _repo;
  final NotificationService? _notifier;
  Timer? _ticker;

  DateTime? _startedAt;
  int _accumulatedSeconds = 0;
  Size? _savedWindowSize;

  Future<void> _restoreSavedSession() async {
    final saved = await _repo.getActiveTimerSession();
    if (saved == null || saved.status == TimerStateStatus.idle) return;

    final now = DateTime.now();
    _accumulatedSeconds = saved.accumulatedDurationSeconds;

    if (saved.status == TimerStateStatus.running && saved.startedAt != null) {
      final elapsedSinceStart = now.difference(saved.startedAt!).inSeconds;
      final totalElapsed = _accumulatedSeconds + elapsedSinceStart;
      final remaining = (saved.targetSeconds - totalElapsed).clamp(0, saved.targetSeconds);

      if (remaining <= 0) {
        // Completed while app was closed
        state = TimerState(
          habitId: saved.habitId,
          habitName: saved.habitName,
          targetSeconds: saved.targetSeconds,
          remainingSeconds: 0,
          status: TimerStateStatus.completed,
        );
        await _completeSession(autoRecord: true);
        return;
      } else {
        _startedAt = saved.startedAt;
        state = TimerState(
          habitId: saved.habitId,
          habitName: saved.habitName,
          targetSeconds: saved.targetSeconds,
          remainingSeconds: remaining,
          status: TimerStateStatus.running,
        );
        _startTicker();
      }
    } else if (saved.status == TimerStateStatus.paused) {
      final remaining = (saved.targetSeconds - _accumulatedSeconds).clamp(0, saved.targetSeconds);
      state = TimerState(
        habitId: saved.habitId,
        habitName: saved.habitName,
        targetSeconds: saved.targetSeconds,
        remainingSeconds: remaining,
        status: TimerStateStatus.paused,
      );
    }
  }

  void start(Habit habit) {
    final targetSec = (habit.target > 0 ? habit.target : 20) * 60;
    _startedAt = DateTime.now();
    _accumulatedSeconds = 0;

    state = TimerState(
      habitId: habit.id,
      habitName: habit.name,
      targetSeconds: targetSec,
      remainingSeconds: targetSec,
      status: TimerStateStatus.running,
    );

    _persistState();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == TimerStateStatus.running && _startedAt != null) {
        final elapsed = _accumulatedSeconds + DateTime.now().difference(_startedAt!).inSeconds;
        final remaining = (state.targetSeconds - elapsed).clamp(0, state.targetSeconds);

        if (remaining <= 0) {
          _ticker?.cancel();
          state = TimerState(
            habitId: state.habitId,
            habitName: state.habitName,
            targetSeconds: state.targetSeconds,
            remainingSeconds: 0,
            status: TimerStateStatus.completed,
            isFloating: state.isFloating,
          );
          _completeSession(autoRecord: true);
        } else {
          state = TimerState(
            habitId: state.habitId,
            habitName: state.habitName,
            targetSeconds: state.targetSeconds,
            remainingSeconds: remaining,
            status: TimerStateStatus.running,
            isFloating: state.isFloating,
          );
        }
      }
    });
  }

  void pause() {
    if (state.status != TimerStateStatus.running) return;

    if (_startedAt != null) {
      _accumulatedSeconds += DateTime.now().difference(_startedAt!).inSeconds;
      _startedAt = null;
    }

    _ticker?.cancel();
    state = TimerState(
      habitId: state.habitId,
      habitName: state.habitName,
      targetSeconds: state.targetSeconds,
      remainingSeconds: (state.targetSeconds - _accumulatedSeconds).clamp(0, state.targetSeconds),
      status: TimerStateStatus.paused,
      isFloating: state.isFloating,
    );

    _persistState();
  }

  void resume() {
    if (state.status != TimerStateStatus.paused) return;

    _startedAt = DateTime.now();
    state = TimerState(
      habitId: state.habitId,
      habitName: state.habitName,
      targetSeconds: state.targetSeconds,
      remainingSeconds: state.remainingSeconds,
      status: TimerStateStatus.running,
      isFloating: state.isFloating,
    );

    _persistState();
    _startTicker();
  }

  void finishEarly() {
    _ticker?.cancel();
    state = TimerState(
      habitId: state.habitId,
      habitName: state.habitName,
      targetSeconds: state.targetSeconds,
      remainingSeconds: 0,
      status: TimerStateStatus.completed,
      isFloating: state.isFloating,
    );
    _completeSession(autoRecord: true);
  }

  void cancel() {
    _ticker?.cancel();
    _startedAt = null;
    _accumulatedSeconds = 0;
    state = const TimerState();
    _repo.clearTimerSession();

    if (state.isFloating) {
      restoreNormalWindow();
    }
  }

  Future<void> _completeSession({bool autoRecord = true}) async {
    _ticker?.cancel();
    await _repo.clearTimerSession();

    try {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    } catch (_) {}

    if (_notifier != null && state.habitName.isNotEmpty) {
      _notifier.showNotification(
        id: 8888,
        title: 'Selesai: ${state.habitName}',
        body: 'Waktu fokus selesai. Satu tindakan bermakna telah terpenuhi hari ini.',
      );
    }

    if (autoRecord && state.habitId > 0) {
      final now = DateTime.now();
      final dateStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final completedMinutes = (state.targetSeconds / 60).ceil();

      await _repo.recordEntryStatus(
        habitId: state.habitId,
        dateString: dateStr,
        status: HabitStatus.yes,
        valueCompleted: completedMinutes,
      );
    }
  }

  void _persistState() {
    final session = TimerSession()
      ..habitId = state.habitId
      ..habitName = state.habitName
      ..targetSeconds = state.targetSeconds
      ..startedAt = _startedAt
      ..accumulatedDurationSeconds = _accumulatedSeconds
      ..status = state.status;

    _repo.saveTimerSession(session);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Desktop Floating Always-on-Top Timer (Windows / Desktop)
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> toggleFloatingWindow() async {
    if (kIsWeb || !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;

    if (state.isFloating) {
      await restoreNormalWindow();
    } else {
      await makeFloatingWindow();
    }
  }

  Future<void> makeFloatingWindow() async {
    if (kIsWeb || !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;

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
    if (kIsWeb || !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;

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

final timerEngineProvider =
    StateNotifierProvider<SadarTimerEngine, TimerState>((ref) {
  final repo = ref.watch(sadarRepoProvider);
  NotificationService? notifier;
  try {
    notifier = ref.watch(notificationServiceProvider);
  } catch (_) {}
  return SadarTimerEngine(repo, notifier);
});
