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

    test('invalid source index stays visible and blocks replacement', () async {
      engine.dispose();
      final saved = TimerSession()
        ..sourceKindIndex = 999
        ..habitName = 'Unknown source timer'
        ..targetSeconds = 900
        ..accumulatedDurationSeconds = 60
        ..status = TimerStateStatus.paused
        ..updatedAt = DateTime.now();
      await repo.saveTimerSession(saved);
      engine = SadarTimerEngine(repo);

      await engine.waitUntilRestored();
      final started = await engine.startNonHabit(
        title: 'Replacement',
        targetSeconds: 600,
        sourceKind: TimerSessionSourceKind.free,
      );
      await expectLater(engine.resume(), throwsA(isA<StateError>()));
      await expectLater(engine.finishEarly(), throwsA(isA<StateError>()));

      expect(started, isFalse);
      expect(engine.state.restoreError, isNotNull);
      expect(engine.state.isSavePending, isTrue);
      expect((await repo.getActiveTimerSession())?.sourceKindIndex, 999);
      expect(await repo.getActiveTimerSession(), isNotNull);
    });

    test('restores a YPT session without a clock identity as paused', () async {
      engine.dispose();
      final startedAt = DateTime.now().subtract(const Duration(minutes: 3));
      await repo.saveTimerSession(
        TimerSession()
          ..habitId = habit.id
          ..habitName = habit.name
          ..sourceKind = TimerSessionSourceKind.yptHabit
          ..targetSeconds = 60
          ..startedAt = startedAt
          ..runningSince = startedAt
          ..status = TimerStateStatus.running
          ..updatedAt = DateTime.now(),
      );
      engine = SadarTimerEngine(repo);

      await engine.waitUntilRestored();

      expect(engine.state.isPaused, isTrue);
      expect(engine.state.recoveryUncertain, isTrue);
      expect(engine.state.actualDurationSeconds, 0);
      expect(
        (await repo.getActiveTimerSession())?.sourceKind,
        TimerSessionSourceKind.yptHabit,
      );
    });

    test(
      'a missing clock identity does not infer time from a backward wall clock',
      () async {
        engine.dispose();
        final futureCheckpoint = DateTime.now().add(const Duration(hours: 1));
        await repo.saveTimerSession(
          TimerSession()
            ..habitId = habit.id
            ..habitName = habit.name
            ..sourceKind = TimerSessionSourceKind.habit
            ..targetSeconds = 600
            ..startedAt = futureCheckpoint
            ..runningSince = futureCheckpoint
            ..status = TimerStateStatus.running
            ..updatedAt = DateTime.now(),
        );
        engine = SadarTimerEngine(repo);

        await engine.waitUntilRestored();

        expect(engine.state.isPaused, isTrue);
        expect(engine.state.recoveryUncertain, isTrue);
        expect(engine.state.remainingSeconds, 600);
        expect(engine.state.actualDurationSeconds, 0);
      },
    );

    test(
      'forward clock jump cannot credit or complete an uncertain session',
      () async {
        engine.dispose();
        final date = '2026-11-14';
        await repo.saveTimerSession(
          TimerSession()
            ..habitId = habit.id
            ..habitName = habit.name
            ..sourceKind = TimerSessionSourceKind.habit
            ..targetSeconds = 60
            ..startedAt = DateTime.now().subtract(const Duration(days: 2))
            ..runningSince = DateTime.now().subtract(const Duration(days: 2))
            ..attributionLocalDate = date
            ..accumulatedDurationSeconds = 17
            ..status = TimerStateStatus.running
            ..updatedAt = DateTime.now(),
        );
        engine = SadarTimerEngine(repo);

        await engine.waitUntilRestored();

        expect(engine.state.isPaused, isTrue);
        expect(engine.state.recoveryUncertain, isTrue);
        expect(engine.state.actualDurationSeconds, 17);
        expect(engine.state.remainingSeconds, 43);
        expect(await repo.getEntriesForDateRange(date, date), isEmpty);
        expect(
          (await repo.getActiveTimerSession())?.status,
          TimerStateStatus.running,
        );

        await engine.finishEarly();

        expect(engine.state.actualDurationSeconds, 17);
        expect(await repo.getEntriesForDateRange(date, date), hasLength(1));
      },
    );

    test(
      'continue starts a fresh segment and clears uncertainty after save',
      () async {
        engine.dispose();
        await repo.saveTimerSession(
          TimerSession()
            ..habitId = habit.id
            ..habitName = habit.name
            ..sourceKind = TimerSessionSourceKind.habit
            ..targetSeconds = 600
            ..startedAt = DateTime.now().subtract(const Duration(hours: 4))
            ..runningSince = DateTime.now().subtract(const Duration(hours: 4))
            ..accumulatedDurationSeconds = 55
            ..status = TimerStateStatus.running
            ..updatedAt = DateTime.now(),
        );
        engine = SadarTimerEngine(repo);

        await engine.waitUntilRestored();
        expect(engine.state.recoveryUncertain, isTrue);

        await engine.resume();

        final persisted = await repo.getActiveTimerSession();
        expect(engine.state.isRunning, isTrue);
        expect(engine.state.recoveryUncertain, isFalse);
        expect(engine.state.actualDurationSeconds, 55);
        expect(persisted?.accumulatedDurationSeconds, 55);
        expect(persisted?.runningSince, isNotNull);
      },
    );

    test(
      'failed Continue keeps the paused checkpoint and uncertainty notice',
      () async {
        final failingRepo = _FailOnSaveRepository(failOnSaveNumber: 2);
        await failingRepo.saveTimerSession(
          TimerSession()
            ..habitId = habit.id
            ..habitName = habit.name
            ..sourceKind = TimerSessionSourceKind.habit
            ..targetSeconds = 600
            ..startedAt = DateTime.now().subtract(const Duration(hours: 1))
            ..runningSince = DateTime.now().subtract(const Duration(hours: 1))
            ..accumulatedDurationSeconds = 28
            ..status = TimerStateStatus.running
            ..updatedAt = DateTime.now(),
        );
        final failedContinueEngine = SadarTimerEngine(failingRepo);
        addTearDown(failedContinueEngine.dispose);
        await failedContinueEngine.waitUntilRestored();

        await expectLater(
          failedContinueEngine.resume(),
          throwsA(isA<StateError>()),
        );

        expect(failedContinueEngine.state.isPaused, isTrue);
        expect(failedContinueEngine.state.recoveryUncertain, isTrue);
        expect(failedContinueEngine.state.actualDurationSeconds, 28);
      },
    );

    test(
      'uncertain paused session must be continued before target extension',
      () async {
        engine.dispose();
        await repo.saveTimerSession(
          TimerSession()
            ..habitId = habit.id
            ..habitName = habit.name
            ..sourceKind = TimerSessionSourceKind.habit
            ..targetSeconds = 600
            ..startedAt = DateTime.now().subtract(const Duration(hours: 1))
            ..runningSince = DateTime.now().subtract(const Duration(hours: 1))
            ..accumulatedDurationSeconds = 28
            ..status = TimerStateStatus.running
            ..updatedAt = DateTime.now(),
        );
        engine = SadarTimerEngine(repo);

        await engine.waitUntilRestored();
        await expectLater(engine.extendBy(60), throwsA(isA<StateError>()));

        expect(engine.state.isPaused, isTrue);
        expect(engine.state.recoveryUncertain, isTrue);
        expect(engine.state.actualDurationSeconds, 28);
        expect(engine.state.targetSeconds, 600);

        await engine.resume();
        await engine.extendBy(60);
        expect(engine.state.isRunning, isTrue);
        expect(engine.state.recoveryUncertain, isFalse);
        expect(engine.state.targetSeconds, 660);
      },
    );

    test(
      'same-boot restore uses Android elapsed realtime over wall time',
      () async {
        engine.dispose();
        final futureCheckpoint = DateTime.now().add(const Duration(hours: 1));
        await repo.saveTimerSession(
          TimerSession()
            ..habitId = habit.id
            ..habitName = habit.name
            ..sourceKind = TimerSessionSourceKind.habit
            ..targetSeconds = 600
            ..startedAt = futureCheckpoint
            ..runningSince = futureCheckpoint
            ..clockBootCount = 12
            ..clockElapsedRealtimeMillis = 1000
            ..status = TimerStateStatus.running
            ..updatedAt = DateTime.now(),
        );
        engine = SadarTimerEngine(
          repo,
          null,
          () async => {'bootCount': 12, 'elapsedRealtimeMillis': 61_000},
        );

        await engine.waitUntilRestored();

        expect(engine.state.isRunning, isTrue);
        expect(engine.state.recoveryUncertain, isFalse);
        expect(engine.state.remainingSeconds, 540);
        expect(engine.state.actualDurationSeconds, 60);
      },
    );

    test(
      'a mismatched Android boot identity restores the saved checkpoint',
      () async {
        engine.dispose();
        await repo.saveTimerSession(
          TimerSession()
            ..habitId = habit.id
            ..habitName = habit.name
            ..sourceKind = TimerSessionSourceKind.habit
            ..targetSeconds = 600
            ..startedAt = DateTime.now().subtract(const Duration(hours: 2))
            ..runningSince = DateTime.now().subtract(const Duration(hours: 2))
            ..clockBootCount = 11
            ..clockElapsedRealtimeMillis = 5000
            ..accumulatedDurationSeconds = 71
            ..status = TimerStateStatus.running
            ..updatedAt = DateTime.now(),
        );
        engine = SadarTimerEngine(
          repo,
          null,
          () async => {
            'bootCount': 12,
            'elapsedRealtimeMillis': 60 * 60 * 1000,
          },
        );

        await engine.waitUntilRestored();

        expect(engine.state.isPaused, isTrue);
        expect(engine.state.recoveryUncertain, isTrue);
        expect(engine.state.actualDurationSeconds, 71);
        expect(engine.state.remainingSeconds, 529);
      },
    );

    test(
      'habit completion keeps the local date captured when the session began',
      () async {
        engine.dispose();
        final attributionDate = DateTime.now();
        final dateString = _dateString(attributionDate);
        final previousDate = attributionDate.subtract(const Duration(days: 1));
        await repo.saveTimerSession(
          TimerSession()
            ..habitId = habit.id
            ..habitName = habit.name
            ..sourceKind = TimerSessionSourceKind.habit
            ..targetSeconds = 20 * 60
            ..startedAt = previousDate
            ..attributionLocalDate = dateString
            ..accumulatedDurationSeconds = 5 * 60
            ..status = TimerStateStatus.paused
            ..updatedAt = DateTime.now(),
        );
        engine = SadarTimerEngine(repo);

        await engine.waitUntilRestored();
        await engine.finishEarly();

        expect(
          await repo.getEntriesForDateRange(dateString, dateString),
          hasLength(1),
        );
        final previousDateString = _dateString(previousDate);
        expect(
          await repo.getEntriesForDateRange(
            previousDateString,
            previousDateString,
          ),
          isEmpty,
        );
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
      final originalStart = (await repo.getActiveTimerSession())!.startedAt;
      expect(engine.state.isRunning, true);

      await engine.pause();
      expect(engine.state.status, TimerStateStatus.paused);
      expect(engine.state.isPaused, true);
      expect(engine.state.isRunning, false);
      expect(engine.state.isActive, true);

      await engine.resume();
      expect(engine.state.status, TimerStateStatus.running);
      expect(engine.state.isRunning, true);
      final resumed = await repo.getActiveTimerSession();
      expect(resumed?.startedAt, originalStart);
      expect(resumed?.runningSince, isNotNull);
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

    test(
      'non-habit timer is persisted and rejects overlapping starts',
      () async {
        final started = await engine.startNonHabit(
          title: 'Deep work',
          targetSeconds: 900,
          sourceKind: TimerSessionSourceKind.free,
        );

        final overlapping = await engine.startNonHabit(
          title: 'Another timer',
          targetSeconds: 600,
          sourceKind: TimerSessionSourceKind.preset,
        );

        expect(started, isTrue);
        expect(overlapping, isFalse);
        expect(engine.state.habitName, 'Deep work');
        expect(engine.state.isRunning, isTrue);
        final saved = await repo.getActiveTimerSession();
        expect(saved?.sourceKind, TimerSessionSourceKind.free);
      },
    );

    test(
      'paused non-habit session restores with its source and remaining time',
      () async {
        await engine.startNonHabit(
          title: 'Quick read',
          targetSeconds: 1200,
          sourceKind: TimerSessionSourceKind.activity,
          activityId: 73,
        );
        await engine.pause();
        engine.dispose();

        engine = SadarTimerEngine(repo);
        await engine.waitUntilRestored();

        expect(engine.state.isPaused, isTrue);
        expect(engine.state.habitId, 0);
        expect(engine.state.activityId, 73);
        expect(engine.state.sourceKind, TimerSessionSourceKind.activity);
        expect(engine.state.habitName, 'Quick read');
        expect(engine.state.remainingSeconds, lessThanOrEqualTo(1200));
      },
    );

    test(
      'failed Activity completion remains pending and retries the same ID',
      () async {
        final retryRepo = _FailOnceActivityTimerRepository();
        final retryEngine = SadarTimerEngine(retryRepo);
        addTearDown(retryEngine.dispose);
        await retryEngine.startNonHabit(
          title: 'Exact Activity',
          targetSeconds: 1800,
          sourceKind: TimerSessionSourceKind.activity,
          activityId: 88,
        );

        await expectLater(
          retryEngine.finishEarly(),
          throwsA(isA<StateError>()),
        );
        expect(retryEngine.state.isSavePending, isTrue);
        expect((await retryRepo.getActiveTimerSession())?.activityId, 88);

        await retryEngine.retryCompletion();
        expect(retryRepo.completedActivityId, 88);
        expect(retryEngine.state.isSavePending, isFalse);
        expect(await retryRepo.getActiveTimerSession(), isNull);
      },
    );
  });
}

String _dateString(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
    String? sessionId,
    required String dateString,
    required int actualDurationMinutes,
    int? actualDurationSeconds,
    required int targetSnapshot,
    required DateTime completedAt,
  }) async {
    if (_failNext) {
      _failNext = false;
      throw StateError('temporary storage failure');
    }
    return super.completeTimerSession(
      habitId: habitId,
      sessionId: sessionId,
      dateString: dateString,
      actualDurationMinutes: actualDurationMinutes,
      actualDurationSeconds: actualDurationSeconds,
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

class _FailOnceActivityTimerRepository extends SadarRepository {
  _FailOnceActivityTimerRepository() : super(null);

  bool _failNext = true;
  int? completedActivityId;

  @override
  Future<void> completeActivityTimerSession({
    required int activityId,
    required int actualDurationSeconds,
    required DateTime completedAt,
  }) async {
    if (_failNext) {
      _failNext = false;
      throw StateError('temporary storage failure');
    }
    completedActivityId = activityId;
    await clearTimerSession();
  }
}
