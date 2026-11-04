import 'package:flutter_test/flutter_test.dart';
import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/models/habit.dart';
import 'package:fitrah_launcher/models/habit_entry.dart';
import 'package:fitrah_launcher/models/timer_session.dart';
import 'package:fitrah_launcher/services/sadar_timer_engine.dart';

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

    tearDown(() async {
      await engine.cancel();
      engine.dispose();
    });

    test('Initial state is IDLE with 0 seconds', () {
      expect(engine.state.status, TimerStateStatus.idle);
      expect(engine.state.remainingSeconds, 0);
      expect(engine.state.isRunning, false);
      expect(engine.state.isActive, false);
    });

    test(
      'startup restore prevents a new timer from replacing the saved one',
      () async {
        engine.dispose();
        final saved = TimerSession()
          ..habitId = habit.id
          ..habitName = habit.name
          ..targetSeconds = 20 * 60
          ..startedAt = DateTime.now()
          ..accumulatedDurationSeconds = 90
          ..status = TimerStateStatus.paused
          ..updatedAt = DateTime.now();
        await repo.saveTimerSession(saved);
        engine = SadarTimerEngine(repo);

        final otherHabit = Habit()
          ..id = 43
          ..name = 'Reading'
          ..target = 30
          ..unit = HabitUnit.min
          ..createdAt = DateTime.now();

        final didStart = await engine.start(otherHabit);

        expect(didStart, isFalse);
        expect(engine.state.status, TimerStateStatus.paused);
        expect(engine.state.habitId, habit.id);
        expect(engine.state.remainingSeconds, 20 * 60 - 90);
      },
    );

    test('start attaches to an active session for the same habit', () async {
      await engine.start(habit);

      final attached = await engine.start(habit);

      expect(attached, isTrue);
      expect(engine.state.habitId, habit.id);
      expect(await repo.getActiveTimerSession(), isNotNull);
    });

    test('a failed start write does not leave a running timer', () async {
      final failingEngine = SadarTimerEngine(_FailingTimerSessionRepository());
      addTearDown(failingEngine.dispose);

      await expectLater(failingEngine.start(habit), throwsA(isA<StateError>()));

      expect(failingEngine.state.status, TimerStateStatus.idle);
      expect(failingEngine.state.isActive, isFalse);
    });

    test('failed completion stays pending and can be retried', () async {
      final retryRepo = _FailOnceTimerCompletionRepository();
      final retryEngine = SadarTimerEngine(retryRepo);
      addTearDown(retryEngine.dispose);
      await retryEngine.start(habit);

      await expectLater(retryEngine.finishEarly(), throwsA(isA<StateError>()));

      expect(retryEngine.state.status, TimerStateStatus.completed);
      expect(retryEngine.state.isSavePending, isTrue);
      expect(await retryRepo.getActiveTimerSession(), isNotNull);

      await retryEngine.cancel();
      expect(retryEngine.state.isSavePending, isTrue);
      expect(await retryRepo.getActiveTimerSession(), isNotNull);

      await retryEngine.retryCompletion();

      expect(retryEngine.state.isSavePending, isFalse);
      expect(await retryRepo.getActiveTimerSession(), isNull);
      final entries = await retryRepo.getEntriesForDateRange(
        DateTime.now().toIso8601String().substring(0, 10),
        DateTime.now().toIso8601String().substring(0, 10),
      );
      expect(entries, hasLength(1));
    });

    test('failed pause write keeps the timer running', () async {
      final pauseRepo = _FailOnSaveRepository(failOnSaveNumber: 2);
      final pauseEngine = SadarTimerEngine(pauseRepo);
      addTearDown(pauseEngine.dispose);
      await pauseEngine.start(habit);

      await expectLater(pauseEngine.pause(), throwsA(isA<StateError>()));

      expect(pauseEngine.state.isRunning, isTrue);
      expect(
        (await pauseRepo.getActiveTimerSession())?.status,
        TimerStateStatus.running,
      );
    });

    test('failed cancel keeps the active session visible', () async {
      final cancelRepo = _FailOnClearRepository();
      final cancelEngine = SadarTimerEngine(cancelRepo);
      addTearDown(cancelEngine.dispose);
      await cancelEngine.start(habit);

      await expectLater(cancelEngine.cancel(), throwsA(isA<StateError>()));

      expect(cancelEngine.state.isRunning, isTrue);
      expect(
        (await cancelRepo.getActiveTimerSession())?.status,
        TimerStateStatus.running,
      );
    });

    test('Transitions from IDLE to RUNNING on start()', () async {
      final didStart = await engine.start(habit);
      expect(didStart, isTrue);
      expect(engine.state.status, TimerStateStatus.running);
      expect(engine.state.habitId, 42);
      expect(engine.state.targetSeconds, 20 * 60);
      expect(engine.state.remainingSeconds, 20 * 60);
      expect(engine.state.isRunning, true);
      expect(engine.state.isActive, true);
    });

    test('Transitions RUNNING -> PAUSED -> RUNNING correctly', () async {
      await engine.start(habit);
      expect(engine.state.isRunning, true);

      await engine.pause();
      expect(engine.state.status, TimerStateStatus.paused);
      expect(engine.state.isPaused, true);
      expect(engine.state.isRunning, false);
      expect(engine.state.isActive, true);

      await engine.resume();
      expect(engine.state.status, TimerStateStatus.running);
      expect(engine.state.isRunning, true);
    });

    test(
      'Rejects invalid transitions (e.g. pause when idle, resume when running)',
      () async {
        // Pause when idle
        expect(engine.state.status, TimerStateStatus.idle);
        await engine.pause();
        expect(engine.state.status, TimerStateStatus.idle);

        // Resume when idle
        await engine.resume();
        expect(engine.state.status, TimerStateStatus.idle);

        // Start, then resume when already running
        await engine.start(habit);
        expect(engine.state.status, TimerStateStatus.running);
        await engine.resume();
        expect(engine.state.status, TimerStateStatus.running);
      },
    );

    test(
      'FinishEarly transitions to COMPLETED and records daily entry',
      () async {
        await engine.start(habit);
        await engine.finishEarly();

        expect(engine.state.status, TimerStateStatus.completed);
        expect(engine.state.remainingSeconds, 0);
        expect(engine.state.isCompleted, true);
        expect(engine.state.isActive, false);

        // Check daily entries recorded
        final now = DateTime.now();
        final dateStr =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final entries = await repo.getEntriesForDateRange(dateStr, dateStr);
        expect(entries.isNotEmpty, true);
        expect(entries.first.habitId, 42);
        expect(entries.first.source, 'timer');
        expect(entries.first.targetSnapshot, 20);
      },
    );

    test('Rapid duplicate finishEarly() calls are idempotent', () async {
      await engine.start(habit);

      // Call finishEarly rapidly multiple times concurrently
      await Future.wait([
        engine.finishEarly(),
        engine.finishEarly(),
        engine.finishEarly(),
      ]);

      final now = DateTime.now();
      final dateStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final entries = await repo.getEntriesForDateRange(dateStr, dateStr);

      // Must remain exactly one entry
      expect(entries.length, 1);
      expect(entries.first.habitId, 42);
    });

    test('Cancel clears active session and returns to IDLE', () async {
      await engine.start(habit);
      expect(engine.state.isActive, true);

      await engine.cancel();
      expect(engine.state.status, TimerStateStatus.idle);
      expect(engine.state.habitId, 0);
      expect(engine.state.remainingSeconds, 0);

      final saved = await repo.getActiveTimerSession();
      expect(saved, isNull);
    });
  });
}

class _FailingTimerSessionRepository extends SadarRepository {
  _FailingTimerSessionRepository() : super(null);

  @override
  Future<void> saveTimerSession(TimerSession session) async {
    throw StateError('storage unavailable');
  }
}

class _FailOnceTimerCompletionRepository extends SadarRepository {
  _FailOnceTimerCompletionRepository() : super(null);

  bool _failNext = true;

  @override
  Future<HabitEntry> completeTimerSession({
    required int habitId,
    required String dateString,
    required int actualDurationMinutes,
    required int targetSnapshot,
    required DateTime completedAt,
  }) async {
    if (_failNext) {
      _failNext = false;
      throw StateError('temporary storage failure');
    }
    return super.completeTimerSession(
      habitId: habitId,
      dateString: dateString,
      actualDurationMinutes: actualDurationMinutes,
      targetSnapshot: targetSnapshot,
      completedAt: completedAt,
    );
  }
}

class _FailOnSaveRepository extends SadarRepository {
  _FailOnSaveRepository({required this.failOnSaveNumber}) : super(null);

  final int failOnSaveNumber;
  int _saveCount = 0;

  @override
  Future<void> saveTimerSession(TimerSession session) async {
    _saveCount++;
    if (_saveCount == failOnSaveNumber) {
      throw StateError('temporary storage failure');
    }
    await super.saveTimerSession(session);
  }
}

class _FailOnClearRepository extends SadarRepository {
  _FailOnClearRepository() : super(null);

  @override
  Future<void> clearTimerSession() async {
    throw StateError('temporary storage failure');
  }
}
