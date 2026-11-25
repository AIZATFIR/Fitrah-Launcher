import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:fitrah_launcher/data/isar_service.dart';
import 'package:fitrah_launcher/data/store/focus_store.dart';
import 'package:fitrah_launcher/data/store/native_focus_store.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/models/habit.dart';
import 'package:fitrah_launcher/models/habit_entry.dart';
import 'package:fitrah_launcher/models/timer_session.dart';
import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/services/sadar_timer_engine.dart';
import 'package:fitrah_launcher/services/home_schedule_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (Platform.isLinux) {
      final config =
          jsonDecode(
                await File('.dart_tool/package_config.json').readAsString(),
              )
              as Map<String, dynamic>;
      final package = (config['packages'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((p) => p['name'] == 'isar_community_flutter_libs');
      final root = Uri.parse(package['rootUri'] as String);
      await Isar.initializeIsarCore(
        libraries: {ffi.Abi.current(): '${root.path}/linux/libisar.so'},
      );
    }
  });
  late Directory dir;
  late Isar db;
  late FocusStore store;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('home_schedule_');
    db = (await IsarService.openAt(dir.path)).isar!;
    store = NativeFocusStore(db);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  final at = DateTime(2026, 11, 7, 10);
  Future<Habit> habit({
    int target = 45,
    String type = 'timed',
    HabitUnit unit = HabitUnit.min,
  }) async {
    final h = Habit()
      ..name = 'LKS'
      ..target = target
      ..habitType = type
      ..unit = unit
      ..createdAt = at
      ..colorValue = 0;
    h.id = await store.writeTxn(() => store.habits.put(h));
    return h;
  }

  Future<Activity> schedule(
    Habit h, {
    DateTime? start,
    int duration = 45,
  }) async => (await HomeScheduleService(store).schedule(
    habitId: h.id,
    title: 'ignored',
    start: start ?? at,
    durationMinutes: duration,
    now: at,
    colorValue: 0,
  )).first;
  Future<TimerSession> start(
    SadarRepository repo,
    Activity a, {
    int seconds = 0,
  }) async {
    final session = TimerSession()
      ..activityId = a.id
      ..sourceKind = TimerSessionSourceKind.activity
      ..habitName = a.title
      ..targetSeconds = 2700
      ..startedAt = at
      ..attributionLocalDate = '2026-11-07'
      ..status = TimerStateStatus.paused
      ..accumulatedDurationSeconds = seconds
      ..updatedAt = at;
    await repo.saveTimerSession(session);
    return session;
  }

  Future<void> finish(SadarRepository repo, Activity a, int seconds) =>
      repo.completeActivityTimerSession(
        activityId: a.id,
        actualDurationSeconds: seconds,
        completedAt: at,
      );

  for (final hour in [11, 23]) {
    test('exact chosen same-name habit survives boundary $hour', () async {
      final first = await habit();
      final selected = await habit();
      final blocks = await HomeScheduleService(store).schedule(
        habitId: selected.id,
        title: 'ignored',
        start: DateTime(2026, 11, 7, hour, 30),
        durationMinutes: 60,
        now: at,
        colorValue: 0,
      );
      expect(blocks.length, 2);
      expect(
        blocks.every((a) => a.habitId == selected.id && a.habitId != first.id),
        isTrue,
      );
      expect(
        blocks.map((a) => a.endMinute - a.startMinute).reduce((a, b) => a + b),
        60,
      );
      expect(blocks.first.groupId, blocks.last.groupId);
    });
  }
  test(
    'unsupported and archived source/conflict leave no orphan schedule',
    () async {
      final h = await habit(type: 'count', unit: HabitUnit.count);
      await expectLater(schedule(h), throwsStateError);
      h.habitType = 'timed';
      h.unit = HabitUnit.min;
      h.isArchived = true;
      await store.writeTxn(() => store.habits.put(h));
      await expectLater(schedule(h), throwsStateError);
      expect(await store.activitys.count(), 0);
      h.isArchived = false;
      await store.writeTxn(() => store.habits.put(h));
      await schedule(h);
      await expectLater(schedule(h), throwsStateError);
      expect(await store.activitys.count(), 1);
    },
  );
  test(
    'start snapshots durable identity, cannot replace active session, and rejects archived source',
    () async {
      final h = await habit();
      final a = await schedule(h);
      final repo = SadarRepository(db);
      final engine = SadarTimerEngine(repo);
      await engine.waitUntilRestored();
      expect(
        await engine.startNonHabit(
          title: a.title,
          targetSeconds: 2700,
          sourceKind: TimerSessionSourceKind.activity,
          activityId: a.id,
        ),
        isTrue,
      );
      expect(engine.currentState.habitId, h.id);
      expect(engine.currentState.habitTargetSnapshot, 45);
      expect(
        await engine.startNonHabit(
          title: 'other',
          targetSeconds: 60,
          sourceKind: TimerSessionSourceKind.free,
        ),
        isFalse,
      );
      await engine.pause();
      engine.dispose();
      final restored = SadarTimerEngine(SadarRepository(db));
      await restored.waitUntilRestored();
      expect(restored.currentState.habitTargetSnapshot, 45);
      expect(restored.currentState.activityId, a.id);
      await restored.cancel();
      restored.dispose();
      h.isArchived = true;
      await store.writeTxn(() => store.habits.put(h));
      await expectLater(start(repo, a), throwsStateError);
      expect(await store.timerSessions.count(), 0);
    },
  );
  test(
    'scheduled habit floating and normal transitions retain session and finish evidence',
    () async {
      const channel = MethodChannel('window_manager');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getBounds') {
              return {'x': 0.0, 'y': 0.0, 'width': 820.0, 'height': 720.0};
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final h = await habit();
      final a = await schedule(h);
      final repo = SadarRepository(db);
      await start(repo, a, seconds: 480);
      final engine = SadarTimerEngine(SadarRepository(db));
      await engine.waitUntilRestored();
      addTearDown(engine.dispose);
      void expectIdentity(bool floating) {
        final state = engine.currentState;
        expect(state.isFloating, floating);
        expect(state.activityId, a.id);
        expect(state.sourceKind, TimerSessionSourceKind.activity);
        expect(state.habitId, h.id);
        expect(state.habitTargetSnapshot, 45);
        expect(state.actualDurationSeconds, 480);
        expect(state.isSavePending, isFalse);
        expect(state.isPaused, isTrue);
        expect(state.restoreError, isNull);
      }

      await engine.makeFloatingWindow();
      expectIdentity(true);
      await engine.restoreNormalWindow();
      expectIdentity(false);
      await engine.resume();
      await engine.pause();
      expect((await store.timerSessions.get(1))!.activityId, a.id);
      await engine.finishEarly();
      expect((await store.activitys.get(a.id))!.actualDurationSeconds, 480);
      final entry = (await store.habitEntrys.all()).single;
      expect(entry.habitId, h.id);
      expect(entry.actualDurationSeconds, 480);
      expect(entry.status, HabitStatus.unmarked);
      expect(await store.timerSessions.count(), 0);
    },
  );

  test(
    'unchanged block retains exact ID and evidence after pause/reopen and repeated sessions',
    () async {
      final h = await habit();
      final a = await schedule(h);
      final repo = SadarRepository(db);
      await start(repo, a, seconds: 480);
      final engine = SadarTimerEngine(SadarRepository(db));
      await engine.waitUntilRestored();
      await engine.finishEarly();
      engine.dispose();
      expect((await store.activitys.get(a.id))!.actualDurationSeconds, 480);
      expect((await store.activitys.get(a.id))!.habitId, h.id);
      expect((await store.habitEntrys.all()).single.actualDurationSeconds, 480);
      expect(
        (await store.habitEntrys.all()).single.status,
        HabitStatus.unmarked,
      );
      expect(await store.activitys.count(), 1);
      final next = SadarRepository(db);
      await start(next, a);
      await finish(next, a, 30);
      await finish(next, a, 30);
      expect((await store.activitys.get(a.id))!.actualDurationSeconds, 510);
      expect((await store.habitEntrys.all()).single.actualDurationSeconds, 510);
    },
  );

  test('failed habit schedule write leaves no orphan segments', () async {
    final h = await habit();
    final failing = _FailAfterWrite(store)..fail = true;
    await expectLater(
      HomeScheduleService(failing).schedule(
        habitId: h.id,
        title: h.name,
        start: DateTime(2026, 11, 7, 23, 30),
        durationMinutes: 60,
        now: at,
        colorValue: 0,
      ),
      throwsStateError,
    );
    expect(await store.activitys.count(), 0);
  });

  test(
    '480 seconds stays partial after restore and source edits; exact seconds accumulate once',
    () async {
      final h = await habit();
      final replacement = await habit();
      final a = await schedule(h);
      var repo = SadarRepository(db);
      await start(repo, a, seconds: 480);
      h.name = 'Renamed';
      h.target = 5;
      h.isArchived = true;
      a.habitId = replacement.id;
      await store.writeTxn(() async {
        await store.habits.put(h);
        await store.activitys.put(a);
      });
      final engine = SadarTimerEngine(SadarRepository(db));
      await engine.waitUntilRestored();
      expect(engine.currentState.habitId, h.id);
      expect(engine.currentState.habitTargetSnapshot, 45);
      await engine.finishEarly();
      engine.dispose();
      var entry = (await store.habitEntrys.all()).single;
      expect(entry.habitId, h.id);
      expect(entry.actualDurationSeconds, 480);
      expect(entry.targetSnapshot, 45);
      expect(entry.status, HabitStatus.unmarked);
      expect((await store.activitys.get(a.id))!.actualDurationSeconds, 0);
      expect((await store.activitys.get(a.id))!.habitId, replacement.id);
      final actual = (await store.activitys.all()).singleWhere(
        (row) => row.id != a.id,
      );
      expect(actual.habitId, h.id);
      expect(actual.actualDurationSeconds, 480);
      await finish(repo, a, 480);
      expect((await store.habitEntrys.all()).single.actualDurationSeconds, 480);
      // Restore source and change target: frozen occurrence remains 45, new session snapshot is 5.
      h.isArchived = false;
      a.habitId = h.id;
      await store.writeTxn(() async {
        await store.habits.put(h);
        await store.activitys.put(a);
      });
      repo = SadarRepository(db);
      for (final seconds in [30, 30, 2160]) {
        await start(repo, a);
        await finish(repo, a, seconds);
      }
      entry = (await store.habitEntrys.all()).single;
      expect(entry.actualDurationSeconds, 2700);
      expect(entry.targetSnapshot, 45);
      expect(entry.status, HabitStatus.yes);
    },
  );
  test(
    'zero evidence never fulfills and missing Activity leaves session pending',
    () async {
      final h = await habit();
      final a = await schedule(h);
      final repo = SadarRepository(db);
      await start(repo, a);
      await finish(repo, a, 0);
      expect(
        (await store.habitEntrys.all()).single.status,
        HabitStatus.unmarked,
      );
      await start(repo, a);
      await store.writeTxn(() => store.activitys.delete(a.id));
      await expectLater(finish(repo, a, 480), throwsStateError);
      expect(await store.timerSessions.count(), 1);
      expect((await store.habitEntrys.all()).single.actualDurationSeconds, 0);
    },
  );
  test(
    'failure after habit write rolls back all records, retry credits once',
    () async {
      final h = await habit();
      final a = await schedule(h);
      final failing = _FailAfterWrite(store);
      final repo = SadarRepository.store(failing);
      await start(repo, a);
      failing.fail = true;
      await expectLater(finish(repo, a, 480), throwsStateError);
      expect(await store.habitEntrys.count(), 0);
      expect((await store.activitys.get(a.id))!.actualDurationSeconds, 0);
      expect(await store.timerSessions.count(), 1);
      failing.fail = false;
      await finish(repo, a, 480);
      await finish(repo, a, 480);
      expect((await store.habitEntrys.all()).single.actualDurationSeconds, 480);
      expect(await store.timerSessions.count(), 0);
    },
  );
  test(
    'manual target minutes never become measured and count units never advance',
    () async {
      final repo = SadarRepository(db);
      final h = await habit();
      await repo.recordEntryStatus(
        habitId: h.id,
        dateString: '2026-11-07',
        status: HabitStatus.yes,
        valueCompleted: 45,
      );
      final a = await schedule(h);
      await start(repo, a);
      await finish(repo, a, 30);
      final entry = (await store.habitEntrys.all()).single;
      expect(entry.actualDurationSeconds, 30);
      expect(entry.valueCompleted, 45);
      expect(entry.status, HabitStatus.yes);
      final count = await habit(
        type: 'count',
        unit: HabitUnit.count,
        target: 10,
      );
      await repo.saveTimerSession(
        TimerSession()
          ..habitId = count.id
          ..habitName = count.name
          ..targetSeconds = 600
          ..startedAt = at
          ..status = TimerStateStatus.paused
          ..updatedAt = at,
      );
      await repo.completeTimerSession(
        habitId: count.id,
        dateString: '2026-11-07',
        actualDurationMinutes: 10,
        actualDurationSeconds: 600,
        targetSnapshot: 10,
        completedAt: at,
      );
      final countEntry = (await store.habitEntrys.all()).firstWhere(
        (e) => e.habitId == count.id,
      );
      expect(countEntry.valueCompleted, 0);
      expect(countEntry.status, HabitStatus.unmarked);
      expect(countEntry.actualDurationSeconds, 600);
    },
  );
  test(
    'baseline native schema upgrades without losing values or inventing links',
    () async {
      await db.close();
      final compressed = await File(
        'test/fixtures/migrations/pre_habit_schedule_4e20c90.isar.gz',
      ).readAsBytes();
      await File(
        '${dir.path}/default.isar',
      ).writeAsBytes(gzip.decode(compressed));
      db = (await IsarService.openAt(dir.path)).isar!;
      store = NativeFocusStore(db);
      expect((await store.habits.get(17))!.target, 45);
      final a = (await store.activitys.get(23))!;
      expect(a.actualDurationSeconds, 42);
      expect(a.habitId, isNull);
      final e = (await store.habitEntrys.get(31))!;
      expect(e.actualDurationSeconds, 480);
      final s = (await store.timerSessions.get(1))!;
      expect(s.status, TimerStateStatus.paused);
      expect(s.accumulatedDurationSeconds, 480);
      expect(s.habitTargetSnapshot, isNull);
    },
  );
}

class _FailAfterWrite extends FocusStore {
  _FailAfterWrite(this.inner);
  final FocusStore inner;
  bool fail = false;
  @override
  bool get isDurable => inner.isDurable;
  @override
  Future<List<T>> all<T>() => inner.all<T>();
  @override
  Future<T?> get<T>(int id) => inner.get<T>(id);
  @override
  Future<int> put<T>(T row) async {
    final id = await inner.put<T>(row);
    if (fail && (row is HabitEntry || row is Activity)) {
      throw StateError('injected failure');
    }
    return id;
  }

  @override
  Future<bool> delete<T>(int id) => inner.delete<T>(id);
  @override
  Future<void> clear() => inner.clear();
  @override
  Future<R> txn<R>(Future<R> Function() action) => inner.txn(action);
  @override
  Future<R> writeTxn<R>(Future<R> Function() action) => inner.writeTxn(action);
  @override
  Stream<void> watch() => inner.watch();
  @override
  Future<void> close() => inner.close();
}
