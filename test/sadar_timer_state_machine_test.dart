import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/data/repositories/sadar_repository.dart';
import 'package:focus_clock/models/habit.dart';
import 'package:focus_clock/models/timer_session.dart';
import 'package:focus_clock/services/sadar_timer_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sadar Timer State Machine & Reliability Tests (PRD 3)', () {
    late SadarRepository repo;
    late SadarTimerEngine engine;
    late Habit habit;

    setUp(() {
      repo = SadarRepository(null);
      engine = SadarTimerEngine(repo);
      habit = Habit()
        ..id = 42
        ..name = 'Quranic Arabic'
        ..target = 20
        ..unit = HabitUnit.min
        ..createdAt = DateTime.now();
    });

    tearDown(() {
      engine.cancel();
      engine.dispose();
    });

    test('Initial state is IDLE with 0 seconds', () {
      expect(engine.state.status, TimerStateStatus.idle);
      expect(engine.state.remainingSeconds, 0);
      expect(engine.state.isRunning, false);
      expect(engine.state.isActive, false);
    });

    test('Transitions from IDLE to RUNNING on start()', () {
      engine.start(habit);
      expect(engine.state.status, TimerStateStatus.running);
      expect(engine.state.habitId, 42);
      expect(engine.state.targetSeconds, 20 * 60);
      expect(engine.state.remainingSeconds, 20 * 60);
      expect(engine.state.isRunning, true);
      expect(engine.state.isActive, true);
    });

    test('Transitions RUNNING -> PAUSED -> RUNNING correctly', () {
      engine.start(habit);
      expect(engine.state.isRunning, true);

      engine.pause();
      expect(engine.state.status, TimerStateStatus.paused);
      expect(engine.state.isPaused, true);
      expect(engine.state.isRunning, false);
      expect(engine.state.isActive, true);

      engine.resume();
      expect(engine.state.status, TimerStateStatus.running);
      expect(engine.state.isRunning, true);
    });

    test('Rejects invalid transitions (e.g. pause when idle, resume when running)', () {
      // Pause when idle
      expect(engine.state.status, TimerStateStatus.idle);
      engine.pause();
      expect(engine.state.status, TimerStateStatus.idle);

      // Resume when idle
      engine.resume();
      expect(engine.state.status, TimerStateStatus.idle);

      // Start, then resume when already running
      engine.start(habit);
      expect(engine.state.status, TimerStateStatus.running);
      engine.resume();
      expect(engine.state.status, TimerStateStatus.running);
    });

    test('FinishEarly transitions to COMPLETED and records daily entry', () async {
      engine.start(habit);
      await engine.finishEarly();

      expect(engine.state.status, TimerStateStatus.completed);
      expect(engine.state.remainingSeconds, 0);
      expect(engine.state.isCompleted, true);
      expect(engine.state.isActive, false);

      // Check daily entries recorded
      final now = DateTime.now();
      final dateStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final entries = await repo.getEntriesForDateRange(dateStr, dateStr);
      expect(entries.isNotEmpty, true);
      expect(entries.first.habitId, 42);
      expect(entries.first.source, 'timer');
      expect(entries.first.targetSnapshot, 20);
    });

    test('Rapid duplicate finishEarly() calls are idempotent', () async {
      engine.start(habit);

      // Call finishEarly rapidly multiple times concurrently
      await Future.wait([
        engine.finishEarly(),
        engine.finishEarly(),
        engine.finishEarly(),
      ]);

      final now = DateTime.now();
      final dateStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final entries = await repo.getEntriesForDateRange(dateStr, dateStr);

      // Must remain exactly one entry
      expect(entries.length, 1);
      expect(entries.first.habitId, 42);
    });

    test('Cancel clears active session and returns to IDLE', () async {
      engine.start(habit);
      expect(engine.state.isActive, true);

      engine.cancel();
      expect(engine.state.status, TimerStateStatus.idle);
      expect(engine.state.habitId, 0);
      expect(engine.state.remainingSeconds, 0);

      final saved = await repo.getActiveTimerSession();
      expect(saved, isNull);
    });
  });
}
