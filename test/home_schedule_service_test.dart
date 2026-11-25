import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/data/isar_service.dart';
import 'package:fitrah_launcher/data/store/focus_store.dart';
import 'package:fitrah_launcher/data/store/native_focus_store.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/models/task.dart';
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

  Future<int> addTask(String title) => store.writeTxn(
    () => store.tasks.put(
      Task()
        ..title = title
        ..createdAt = DateTime(2026, 11, 7),
    ),
  );
  Future<List<Activity>> schedule(
    int id,
    DateTime start, {
    FocusStore? using,
  }) => HomeScheduleService(using ?? store).schedule(
    taskId: id,
    title: 'ignored',
    start: start,
    durationMinutes: 60,
    now: start,
    colorValue: 0xff000000,
  );

  test(
    'same titles retain distinct identity and repeated submission fails',
    () async {
      final first = await addTask('Same');
      final second = await addTask('Same');
      final created = await schedule(second, DateTime(2026, 11, 7, 10));
      expect((await store.tasks.get(first))!.activityId, isNull);
      expect((await store.tasks.get(second))!.activityId, created.first.id);
      await expectLater(
        schedule(second, DateTime(2026, 11, 7, 12)),
        throwsStateError,
      );
      expect(await store.activitys.count(), 1);
    },
  );
  test(
    'transaction rolls back activity and task after a failed write',
    () async {
      final id = await addTask('Rollback');
      await expectLater(
        schedule(id, DateTime(2026, 11, 7, 10), using: _FailTaskWrite(store)),
        throwsStateError,
      );
      expect(await store.activitys.count(), 0);
      final task = (await store.tasks.get(id))!;
      expect(task.activityId, isNull);
      expect(task.startMinute, isNull);
    },
  );
  test('persisted conflicts reject scheduling without changing task', () async {
    final id = await addTask('Conflict');
    final now = DateTime(2026, 11, 7, 10);
    final existing = Activity()
      ..title = 'Busy'
      ..date = dateOnly(now)
      ..ampmHalf = AmPmHalf.am
      ..startMinute = 600
      ..endMinute = 630
      ..colorValue = 0
      ..createdAt = now
      ..updatedAt = now;
    await store.writeTxn(() => store.activitys.put(existing));
    await expectLater(schedule(id, now), throwsStateError);
    expect(await store.activitys.count(), 1);
    expect((await store.tasks.get(id))!.activityId, isNull);
  });
  for (final start in [
    DateTime(2026, 11, 7, 11, 30),
    DateTime(2026, 11, 7, 23, 30),
  ]) {
    test('splits a full hour across boundary at $start', () async {
      final id = await addTask('Split');
      final result = await schedule(id, start);
      expect(result, hasLength(2));
      expect(result.map((a) => a.endMinute - a.startMinute).toList(), [30, 30]);
      expect(result.first.endMinute, 720);
      expect(result.last.startMinute, 0);
      expect(result.first.groupId, isNotNull);
      expect(result.first.groupId, result.last.groupId);
      expect((await store.tasks.get(id))!.activityId, result.first.id);
      expect(
        result.last.date,
        start.hour == 23 ? DateTime(2026, 11, 8) : DateTime(2026, 11, 7),
      );
    });
  }
}

class _FailTaskWrite extends FocusStore {
  _FailTaskWrite(this.inner);
  final FocusStore inner;
  @override
  bool get isDurable => inner.isDurable;
  @override
  Future<List<T>> all<T>() => inner.all<T>();
  @override
  Future<T?> get<T>(int id) => inner.get<T>(id);
  @override
  Future<int> put<T>(T row) async {
    final id = await inner.put<T>(row);
    if (row is Task) throw StateError('injected failure');
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
