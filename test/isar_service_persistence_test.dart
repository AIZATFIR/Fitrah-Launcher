import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/data/isar_service.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/models/app_settings.dart';
import 'package:fitrah_launcher/models/habit.dart';
import 'package:fitrah_launcher/models/habit_entry.dart';
import 'package:fitrah_launcher/models/preset.dart';
import 'package:fitrah_launcher/models/timer_session.dart';
import 'package:fitrah_launcher/models/terminal_focus_session.dart';
import 'package:fitrah_launcher/services/sadar_timer_engine.dart';
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
      final packages = config['packages'] as List<dynamic>;
      final isarPackage = packages.cast<Map<String, dynamic>>().firstWhere(
        (package) => package['name'] == 'isar_community_flutter_libs',
      );
      final packageRoot = Uri.parse(isarPackage['rootUri'] as String);
      final libraryPath = switch (ffi.Abi.current()) {
        ffi.Abi.linuxX64 || ffi.Abi.linuxArm64 => 'linux/libisar.so',
        ffi.Abi.macosArm64 || ffi.Abi.macosX64 => 'macos/libisar.dylib',
        ffi.Abi.windowsArm64 || ffi.Abi.windowsX64 => 'windows/isar.dll',
        _ => throw UnsupportedError(
          'Isar native test unsupported on this ABI.',
        ),
      };
      final library = File('${packageRoot.path}/$libraryPath');
      await Isar.initializeIsarCore(
        libraries: {ffi.Abi.current(): library.path},
      );
    }
  });

  test(
    'fresh store only seeds settings and preserves activity after reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'focus_clock_isar_',
      );
      addTearDown(() => directory.delete(recursive: true));

      final firstOpen = await IsarService.openAt(directory.path);
      final firstDb = firstOpen.isar!;

      expect(await firstDb.appSettings.count(), 1);
      expect(await firstDb.presets.count(), 0);
      expect(await firstDb.habits.count(), 0);
      expect(await firstDb.activitys.count(), 0);

      final now = DateTime(2026, 11, 4, 9);
      final activity = Activity()
        ..title = 'Latihan LKS'
        ..startMinute = 9 * 60
        ..endMinute = 10 * 60
        ..ampmHalf = AmPmHalf.am
        ..date = dateOnly(now)
        ..colorValue = 0xFF8BAE9A
        ..createdAt = now
        ..updatedAt = now;
      final id = await firstDb.writeTxn(() => firstDb.activitys.put(activity));

      final repository = SadarRepository(firstDb);
      final session = TimerSession()
        ..habitId = 42
        ..habitName = 'Latihan LKS'
        ..targetSeconds = 1200
        ..startedAt = now
        ..status = TimerStateStatus.completed
        ..accumulatedDurationSeconds = 615
        ..updatedAt = now;
      await repository.saveTimerSession(session);
      await repository.completeTimerSession(
        habitId: 42,
        dateString: '2026-11-04',
        actualDurationMinutes: 10,
        targetSnapshot: 20,
        completedAt: now,
      );
      await repository.saveTimerSession(
        TimerSession()
          ..habitId = 42
          ..habitName = 'Latihan LKS'
          ..targetSeconds = 1200
          ..startedAt = now.add(const Duration(hours: 1))
          ..status = TimerStateStatus.completed
          ..accumulatedDurationSeconds = 8 * 60
          ..updatedAt = now,
      );
      await repository.completeTimerSession(
        habitId: 42,
        dateString: '2026-11-04',
        actualDurationMinutes: 8,
        targetSnapshot: 20,
        completedAt: now.add(const Duration(hours: 1)),
      );
      await repository.saveTimerSession(
        TimerSession()
          ..habitId = 42
          ..habitName = 'Latihan LKS'
          ..targetSeconds = 1200
          ..startedAt = now
          ..attributionLocalDate = '2026-11-04'
          ..status = TimerStateStatus.paused
          ..updatedAt = now,
      );

      await firstDb.close();

      final secondOpen = await IsarService.openAt(directory.path);
      addTearDown(() => secondOpen.isar!.close());
      final restored = await secondOpen.isar!.activitys.get(id);

      expect(restored, isNotNull);
      expect(restored!.title, 'Latihan LKS');
      expect(restored.startMinute, 540);
      expect(restored.date, dateOnly(now));
      expect(await secondOpen.isar!.activitys.count(), 1);
      expect(await secondOpen.isar!.appSettings.count(), 1);
      final restoredEntry = await secondOpen.isar!.habitEntrys
          .filter()
          .habitIdEqualTo(42)
          .dateStringEqualTo('2026-11-04')
          .findFirst();
      expect(restoredEntry?.actualDurationMinutes, 18);
      expect(restoredEntry?.actualDurationSeconds, 18 * 60);
      expect(restoredEntry?.valueCompleted, 18);
      expect(restoredEntry?.targetSnapshot, 20);
      final restoredSession = await secondOpen.isar!.timerSessions.get(1);
      expect(restoredSession?.attributionLocalDate, '2026-11-04');
      final terminalRows = await secondOpen.isar!.terminalFocusSessions
          .where()
          .findAll();
      expect(terminalRows, hasLength(2));
      expect(terminalRows.map((row) => row.sessionId).toSet(), hasLength(2));
    },
  );

  test('goal attribution schema preserves old property IDs and reopens', () async {
    final timerIds = TimerSessionSchema.properties.map(
      (name, property) => MapEntry(name, property.id),
    );
    expect(timerIds['habitId'], 5);
    expect(timerIds['habitName'], 6);
    expect(timerIds['updatedAt'], 17);
    expect(timerIds['goalId'], 18);
    expect(timerIds['goalTitleSnapshot'], 19);
    final terminalIds = TerminalFocusSessionSchema.properties.map(
      (name, property) => MapEntry(name, property.id),
    );
    expect(terminalIds['habitId'], 3);
    expect(terminalIds['titleSnapshot'], 9);
    expect(terminalIds['goalId'], 10);
    expect(terminalIds['goalTitleSnapshot'], 11);

    final directory = await Directory.systemTemp.createTemp(
      'focus_clock_goal_attribution_schema_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final first = await IsarService.openAt(directory.path);
    final now = DateTime(2026, 11, 16, 9);
    await first.isar!.writeTxn(() async {
      await first.isar!.timerSessions.put(
        TimerSession()
          ..sessionId = 'attributed-active'
          ..goalId = '22222222-2222-4222-8222-222222222222'
          ..goalTitleSnapshot = 'Win nationals'
          ..habitName = 'LKS'
          ..startedAt = now
          ..status = TimerStateStatus.paused
          ..updatedAt = now,
      );
      final terminal = TerminalFocusSession()
        ..sessionId = 'attributed-terminal'
        ..sourceKind = 'habit'
        ..titleSnapshot = 'LKS'
        ..goalId = '22222222-2222-4222-8222-222222222222'
        ..goalTitleSnapshot = 'Win nationals'
        ..startedAt = now
        ..completedAt = now
        ..actualDurationSeconds = 60
        ..status = TerminalSessionStatus.completed;
      await first.isar!.terminalFocusSessions.put(terminal);
    });
    await first.isar!.close();

    final reopened = await IsarService.openAt(directory.path);
    addTearDown(() => reopened.isar!.close());
    final active = await reopened.isar!.timerSessions.get(1);
    expect(active?.goalId, '22222222-2222-4222-8222-222222222222');
    expect(active?.goalTitleSnapshot, 'Win nationals');
    final terminal = await reopened.isar!.terminalFocusSessions
        .where()
        .findFirst();
    expect(terminal?.goalId, active?.goalId);
    expect(terminal?.goalTitleSnapshot, active?.goalTitleSnapshot);
  });

  test('unavailable store keeps timer session for recovery', () async {
    final directory = await Directory.systemTemp.createTemp(
      'focus_clock_failed_timer_',
    );
    addTearDown(() => directory.delete(recursive: true));

    final opened = await IsarService.openAt(directory.path);
    final db = opened.isar!;
    final repository = SadarRepository(db);
    final session = TimerSession()
      ..habitId = 42
      ..habitName = 'Latihan LKS'
      ..targetSeconds = 1200
      ..startedAt = DateTime(2026, 11, 4, 9)
      ..status = TimerStateStatus.completed
      ..accumulatedDurationSeconds = 615
      ..updatedAt = DateTime(2026, 11, 4, 9);
    await repository.saveTimerSession(session);
    await db.close();

    await expectLater(
      repository.completeTimerSession(
        habitId: 42,
        dateString: '2026-11-04',
        actualDurationMinutes: 10,
        targetSnapshot: 20,
        completedAt: DateTime(2026, 11, 4, 9, 11),
      ),
      throwsA(anything),
    );

    final reopened = await IsarService.openAt(directory.path);
    addTearDown(() => reopened.isar!.close());
    expect(await reopened.isar!.timerSessions.get(1), isNotNull);
    expect(await reopened.isar!.habitEntrys.count(), 0);
  });

  test(
    'activity timer completion updates only its exact Activity and retains actual seconds',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'focus_clock_activity_timer_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final opened = await IsarService.openAt(directory.path);
      addTearDown(() => opened.isar!.close());
      final db = opened.isar!;
      final now = DateTime(2026, 11, 4, 9);
      Activity makeActivity(String title) => Activity()
        ..title = title
        ..startMinute = 540
        ..endMinute = 600
        ..ampmHalf = AmPmHalf.am
        ..date = dateOnly(now)
        ..colorValue = 0xFF8BAE9A
        ..createdAt = now
        ..updatedAt = now;
      final linkedId = await db.writeTxn(
        () => db.activitys.put(makeActivity('Linked')),
      );
      final unrelatedId = await db.writeTxn(
        () => db.activitys.put(makeActivity('Unrelated')),
      );
      final repository = SadarRepository(db);
      await repository.saveTimerSession(
        TimerSession()
          ..activityId = linkedId
          ..sourceKind = TimerSessionSourceKind.activity
          ..habitName = 'Linked'
          ..targetSeconds = 2700
          ..startedAt = now
          ..accumulatedDurationSeconds = 503
          ..status = TimerStateStatus.completed
          ..updatedAt = now,
      );

      await repository.completeActivityTimerSession(
        activityId: linkedId,
        actualDurationSeconds: 503,
        completedAt: now.add(const Duration(minutes: 9)),
      );

      expect((await db.activitys.get(linkedId))!.isCompleted, isTrue);
      expect((await db.activitys.get(linkedId))!.actualDurationSeconds, 503);
      expect((await db.activitys.get(unrelatedId))!.isCompleted, isFalse);
      expect((await db.activitys.get(unrelatedId))!.actualDurationSeconds, 0);
      expect(await repository.getActiveTimerSession(), isNull);
      final terminal =
          (await db.terminalFocusSessions.where().findAll()).single;
      expect(terminal.sourceKind, 'activity');
      expect(terminal.titleSnapshot, 'Linked');
      expect(terminal.actualDurationSeconds, 503);
      expect(terminal.status.name, 'completed');
    },
  );

  test(
    'missing linked Activity leaves the active timer available for retry',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'focus_clock_missing_activity_timer_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final opened = await IsarService.openAt(directory.path);
      addTearDown(() => opened.isar!.close());
      final repository = SadarRepository(opened.isar!);
      await opened.isar!.writeTxn(
        () => opened.isar!.timerSessions.put(
          TimerSession()
            ..activityId = 9876
            ..sourceKind = TimerSessionSourceKind.activity
            ..habitName = 'Missing'
            ..targetSeconds = 900
            ..status = TimerStateStatus.completed
            ..updatedAt = DateTime.now(),
        ),
      );
      await repository.getActiveTimerSession();

      await expectLater(
        repository.completeActivityTimerSession(
          activityId: 9876,
          actualDurationSeconds: 12,
          completedAt: DateTime.now(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(await repository.getActiveTimerSession(), isNotNull);
    },
  );

  test('paused non-habit source survives a store reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'focus_clock_paused_non_habit_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final firstOpen = await IsarService.openAt(directory.path);
    final now = DateTime(2026, 11, 4, 9);
    await firstOpen.isar!.writeTxn(
      () => firstOpen.isar!.timerSessions.put(
        TimerSession()
          ..sourceKind = TimerSessionSourceKind.activity
          ..activityId = 456
          ..habitName = 'Read exact activity'
          ..targetSeconds = 1800
          ..startedAt = now
          ..accumulatedDurationSeconds = 321
          ..status = TimerStateStatus.paused
          ..updatedAt = now,
      ),
    );
    await firstOpen.isar!.close();

    final reopened = await IsarService.openAt(directory.path);
    addTearDown(() => reopened.isar!.close());
    final restored = await SadarRepository(
      reopened.isar!,
    ).getActiveTimerSession();
    expect(restored?.status, TimerStateStatus.paused);
    expect(restored?.sourceKind, TimerSessionSourceKind.activity);
    expect(restored?.activityId, 456);
    expect(restored?.accumulatedDurationSeconds, 321);
  });

  test(
    'preset Activity write failure keeps session; retry creates one Activity',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'focus_clock_preset_completion_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final opened = await IsarService.openAt(directory.path);
      addTearDown(() => opened.isar!.close());
      final repository = _FailOncePresetRepository(opened.isar!);
      final engine = SadarTimerEngine(repository);
      addTearDown(engine.dispose);

      await engine.startNonHabit(
        title: 'LKS ITSSB',
        targetSeconds: 2700,
        sourceKind: TimerSessionSourceKind.preset,
        sourceIdentity: 'Programmer',
        sourceColorValue: 0xFFE8C07D,
      );
      await expectLater(engine.finishEarly(), throwsA(isA<StateError>()));
      expect(engine.state.isSavePending, isTrue);
      expect(await repository.getActiveTimerSession(), isNotNull);
      expect(await opened.isar!.activitys.count(), 0);
      expect(await opened.isar!.terminalFocusSessions.count(), 0);

      await engine.retryCompletion();
      expect(engine.state.isSavePending, isFalse);
      expect(await repository.getActiveTimerSession(), isNull);
      expect(await opened.isar!.activitys.count(), 1);
      final activity = (await opened.isar!.activitys.where().findAll()).single;
      expect(activity.title, 'LKS ITSSB');
      expect(activity.isCompleted, isTrue);
      expect(activity.actualDurationSeconds, lessThan(2700));
      expect(activity.description, 'Identitas: Programmer');
      final terminal =
          (await opened.isar!.terminalFocusSessions.where().findAll()).single;
      expect(terminal.sourceKind, 'preset');
      expect(terminal.titleSnapshot, 'LKS ITSSB');
      expect(terminal.actualDurationSeconds, activity.actualDurationSeconds);

      await engine.retryCompletion();
      expect(await opened.isar!.activitys.count(), 1);
    },
  );

  test('Activity and timer start roll back together and retry once', () async {
    final directory = await Directory.systemTemp.createTemp(
      'focus_clock_atomic_activity_timer_start_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final opened = await IsarService.openAt(directory.path);
    addTearDown(() => opened.isar!.close());
    final repository = _FailOnceTimerStartRepository(opened.isar!);
    final engine = SadarTimerEngine(repository);
    addTearDown(engine.dispose);
    final now = DateTime.now();
    final activity = Activity()
      ..title = 'Quick activity'
      ..startMinute = now.hour * 60 + now.minute
      ..endMinute = (now.hour * 60 + now.minute + 30).clamp(0, 1440)
      ..ampmHalf = now.hour < 12 ? AmPmHalf.am : AmPmHalf.pm
      ..date = dateOnly(now)
      ..colorValue = 0xFF8BAE9A
      ..createdAt = now
      ..updatedAt = now;

    Future<bool> start() => engine.startNonHabit(
      title: activity.title,
      targetSeconds: 1800,
      sourceKind: TimerSessionSourceKind.activity,
      activityToCreate: activity,
    );

    await expectLater(start(), throwsA(isA<StateError>()));
    expect(await opened.isar!.activitys.count(), 0);
    expect(await repository.getActiveTimerSession(), isNull);
    expect(engine.state.isActive, isFalse);

    expect(await start(), isTrue);
    final saved = await repository.getActiveTimerSession();
    final activities = await opened.isar!.activitys.where().findAll();
    expect(activities, hasLength(1));
    expect(saved?.activityId, activities.single.id);
    expect(saved?.sourceKind, TimerSessionSourceKind.activity);
    await engine.cancel();
  });

  test('native free finish and cancellation persist terminal rows', () async {
    final directory = await Directory.systemTemp.createTemp(
      'focus_clock_free_terminal_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final opened = await IsarService.openAt(directory.path);
    addTearDown(() => opened.isar!.close());
    final repository = SadarRepository(opened.isar!);
    final engine = SadarTimerEngine(repository);
    addTearDown(engine.dispose);

    await engine.startNonHabit(
      title: 'Free focus',
      targetSeconds: 600,
      sourceKind: TimerSessionSourceKind.free,
    );
    await engine.finishEarly();
    final completed =
        (await opened.isar!.terminalFocusSessions.where().findAll()).single;
    expect(completed.sourceKind, 'free');
    expect(completed.titleSnapshot, 'Free focus');
    expect(completed.status.name, 'completed');
    expect(await repository.getActiveTimerSession(), isNull);

    await engine.startNonHabit(
      title: 'Cancelled focus',
      targetSeconds: 600,
      sourceKind: TimerSessionSourceKind.free,
    );
    await engine.cancel();
    final rows = await opened.isar!.terminalFocusSessions.where().findAll();
    expect(rows, hasLength(2));
    final cancelled = rows.singleWhere(
      (row) => row.titleSnapshot == 'Cancelled focus',
    );
    expect(cancelled.status.name, 'cancelled');
    expect(cancelled.actualDurationSeconds, 0);
  });
}

class _FailOncePresetRepository extends SadarRepository {
  _FailOncePresetRepository(super.isar);

  bool _failNext = true;

  @override
  Future<void> completePresetTimerSession({
    required String title,
    required String? identity,
    required int? colorValue,
    required DateTime startedAt,
    required int actualDurationSeconds,
    required DateTime completedAt,
  }) async {
    if (_failNext) {
      _failNext = false;
      throw StateError('injected Activity write failure');
    }
    return super.completePresetTimerSession(
      title: title,
      identity: identity,
      colorValue: colorValue,
      startedAt: startedAt,
      actualDurationSeconds: actualDurationSeconds,
      completedAt: completedAt,
    );
  }
}

class _FailOnceTimerStartRepository extends SadarRepository {
  _FailOnceTimerStartRepository(super.isar);

  bool _failNext = true;

  @override
  Future<void> putTimerSessionInTxn(TimerSession session) async {
    if (_failNext) {
      _failNext = false;
      throw StateError('injected timer session write failure');
    }
    return super.putTimerSessionInTxn(session);
  }
}
