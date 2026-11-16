import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/data/isar_service.dart';
import 'package:fitrah_launcher/data/store/focus_store.dart';
import 'package:fitrah_launcher/data/store/native_focus_store.dart';
import 'package:fitrah_launcher/domain/goal_plan_proposal.dart';
import 'package:fitrah_launcher/features/ai_chat/ai_chat_sheet.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/services/ai_goal_plan_proposal.dart';
import 'package:fitrah_launcher/services/goal_plan_application_service.dart';
import 'package:flutter/material.dart';
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

  test('rejects invalid plan limits before application', () {
    expect(
      () => WeeklyPracticeBlock(
        weekday: 8,
        startMinute: 400,
        durationMinutes: 30,
      ),
      throwsArgumentError,
    );
    expect(
      () => PlanProposal(
        goal: GoalUnderstanding(title: 'Learn'),
        assumptions: const [],
        blocks: [
          WeeklyPracticeBlock(
            weekday: 1,
            startMinute: 400,
            durationMinutes: 30,
          ),
        ],
      ),
      throwsArgumentError,
    );
  });

  late Directory dir;
  late Isar db;
  late FocusStore store;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('goal_plan_');
    db = (await IsarService.openAt(dir.path)).isar!;
    store = NativeFocusStore(db);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  PlanProposal plan({String title = 'Win the LKS'}) => PlanProposal(
    goal: GoalUnderstanding(
      title: title,
      targetDate: '2027-07-15',
      why: 'Build skill',
    ),
    assumptions: const ['School mornings are unavailable.'],
    blocks: [
      WeeklyPracticeBlock(weekday: 1, startMinute: 600, durationMinutes: 60),
      WeeklyPracticeBlock(weekday: 3, startMinute: 600, durationMinutes: 60),
    ],
  );

  test(
    'applies goal, linked timed habit, and recurring activities atomically and idempotently',
    () async {
      final service = GoalPlanApplicationService(
        store,
        now: () => DateTime(2026, 11, 16, 8),
      );
      final proposal = plan();
      final first = await service.apply(
        operationId: 'operation-1',
        proposal: proposal,
      );
      final retry = await service.apply(
        operationId: 'operation-1',
        proposal: proposal,
      );

      expect(retry, first);
      expect(await store.habits.count(), 1);
      expect(await store.activitys.count(), 2);
      final activities = await store.activitys.all();
      expect(activities.every((a) => a.habitId == first.habitId), isTrue);
      expect(activities.every((a) => a.recurrence == 'weekly'), isTrue);
      expect(await store.focusIntentDocuments.count(), 1);
    },
  );

  test('rejects changed payload with a reused operation id', () async {
    final service = GoalPlanApplicationService(
      store,
      now: () => DateTime(2026, 11, 16, 8),
    );
    await service.apply(operationId: 'operation-1', proposal: plan());
    await expectLater(
      service.apply(
        operationId: 'operation-1',
        proposal: plan(title: 'Different goal'),
      ),
      throwsStateError,
    );
    expect(await store.habits.count(), 1);
  });

  test(
    'reports recurring commitment conflicts and does not write on approval',
    () async {
      final existing = Activity()
        ..title = 'Class'
        ..date = DateTime(2026, 11, 16)
        ..ampmHalf = AmPmHalf.am
        ..startMinute = 620
        ..endMinute = 650
        ..recurrence = 'weekly'
        ..colorValue = 0xff000000
        ..createdAt = DateTime(2026, 11, 16)
        ..updatedAt = DateTime(2026, 11, 16);
      await store.writeTxn(() => store.activitys.put(existing));
      final service = GoalPlanApplicationService(
        store,
        now: () => DateTime(2026, 11, 16, 8),
      );
      final conflicts = await service.previewConflicts(plan());
      expect(conflicts.any((conflict) => conflict.contains('Class')), isTrue);
      await expectLater(
        service.apply(operationId: 'operation-2', proposal: plan()),
        throwsStateError,
      );
      expect(await store.habits.count(), 0);
      expect(await store.activitys.count(), 1);
    },
  );

  test(
    'exclusion on the planned date suppresses a same-date conflict',
    () async {
      final existing = Activity()
        ..title = 'Class'
        ..date = DateTime(2026, 11, 16)
        ..ampmHalf = AmPmHalf.am
        ..startMinute = 620
        ..endMinute = 650
        ..recurrence = 'none'
        ..excludedDates = [DateTime(2026, 11, 16)]
        ..colorValue = 0xff000000
        ..createdAt = DateTime(2026, 11, 16)
        ..updatedAt = DateTime(2026, 11, 16);
      await store.writeTxn(() => store.activitys.put(existing));
      final service = GoalPlanApplicationService(
        store,
        now: () => DateTime(2026, 11, 16, 8),
      );

      expect(await service.previewConflicts(plan()), isEmpty);
    },
  );

  test(
    'recurring proposal checks future same-weekday one-time commitments',
    () async {
      final existing = Activity()
        ..title = 'Future class'
        ..date = DateTime(2026, 11, 23)
        ..ampmHalf = AmPmHalf.am
        ..startMinute = 620
        ..endMinute = 650
        ..recurrence = 'none'
        ..colorValue = 0xff000000
        ..createdAt = DateTime(2026, 11, 16)
        ..updatedAt = DateTime(2026, 11, 16);
      await store.writeTxn(() => store.activitys.put(existing));
      final service = GoalPlanApplicationService(
        store,
        now: () => DateTime(2026, 11, 16, 8),
      );

      expect(
        (await service.previewConflicts(
          plan(),
        )).any((conflict) => conflict.contains('Future class')),
        isTrue,
      );
    },
  );

  testWidgets('goal plan review requires explicit apply or cancel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    var writes = 0;
    final service = GoalPlanApplicationService(
      _PreviewStore(),
      now: () => DateTime(2026, 11, 16, 8),
    );
    final proposal = AiGoalPlanProposal(
      proposal: plan(),
      apply: (edited) async => writes++,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GoalPlanReviewCard(
              proposal: proposal,
              service: service,
              onChanged: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Batal'));
    await tester.pump();
    expect(proposal.isPending, isFalse);
    expect(writes, 0);

    final approved = AiGoalPlanProposal(
      proposal: plan(),
      apply: (edited) async => writes++,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GoalPlanReviewCard(
              proposal: approved,
              service: service,
              onChanged: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Terapkan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(approved.isApplied, isTrue);
    expect(writes, 1);
  });

  test('stale goal revision is rejected without writes', () async {
    final service = GoalPlanApplicationService(
      store,
      now: () => DateTime(2026, 11, 16, 8),
    );
    await expectLater(
      service.apply(
        operationId: 'operation-3',
        proposal: plan(),
        goalId: 'missing',
        expectedGoalRevision: 4,
      ),
      throwsStateError,
    );
    expect(await store.habits.count(), 0);
  });

  test('an activity write failure rolls the complete plan back', () async {
    final service = GoalPlanApplicationService(
      _FailActivityWrite(store),
      now: () => DateTime(2026, 11, 16, 8),
    );
    await expectLater(
      service.apply(operationId: 'operation-fail', proposal: plan()),
      throwsStateError,
    );
    expect(await store.habits.count(), 0);
    expect(await store.activitys.count(), 0);
    expect(await store.focusIntentDocuments.count(), 0);
  });
}

class _FailActivityWrite extends FocusStore {
  _FailActivityWrite(this.inner);
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
    if (row is Activity) throw StateError('injected activity failure');
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

class _PreviewStore extends FocusStore {
  @override
  bool get isDurable => true;
  @override
  Future<List<T>> all<T>() async => <T>[];
  @override
  Future<T?> get<T>(int id) async => null;
  @override
  Future<int> put<T>(T row) async => throw UnimplementedError();
  @override
  Future<bool> delete<T>(int id) async => false;
  @override
  Future<void> clear() async {}
  @override
  Future<R> txn<R>(Future<R> Function() action) => action();
  @override
  Future<R> writeTxn<R>(Future<R> Function() action) => action();
  @override
  Stream<void> watch() => const Stream<void>.empty();
  @override
  Future<void> close() async {}
}
