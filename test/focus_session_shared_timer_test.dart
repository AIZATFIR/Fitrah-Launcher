import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/features/focusclock/widgets/focus_session_view.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/models/timer_session.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:fitrah_launcher/providers/sadar_providers.dart';
import 'package:fitrah_launcher/services/notification_service.dart';
import 'package:fitrah_launcher/services/sadar_timer_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FocusSessionView starts and pauses the shared Activity timer', (
    tester,
  ) async {
    final repository = SadarRepository(null);
    final container = ProviderContainer(
      overrides: [
        isarProvider.overrideWithValue(null),
        sadarRepoProvider.overrideWithValue(repository),
        notificationServiceProvider.overrideWithValue(NotificationService()),
      ],
    );
    addTearDown(container.dispose);

    final now = DateTime.now();
    final minute = (now.hour % 12) * 60 + now.minute;
    final activity = Activity()
      ..id = 431
      ..title = 'Latihan LKS'
      ..startMinute = minute
      ..endMinute = (minute + 30).clamp(0, 720)
      ..ampmHalf = now.hour < 12 ? AmPmHalf.am : AmPmHalf.pm
      ..date = DateTime(now.year, now.month, now.day)
      ..colorValue = const Color(0xFF8BAE9A).value
      ..createdAt = now
      ..updatedAt = now;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: FocusSessionView(activity: activity, onClose: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final engine = container.read(timerEngineProvider.notifier);
    expect(container.read(timerEngineProvider).isRunning, isTrue);
    expect(
      container.read(timerEngineProvider).sourceKind,
      TimerSessionSourceKind.activity,
    );
    expect(container.read(timerEngineProvider).activityId, activity.id);
    expect((await repository.getActiveTimerSession())?.activityId, activity.id);

    await tester.tap(find.text('Jeda'));
    await tester.pump();

    expect(container.read(timerEngineProvider).isPaused, isTrue);
    expect(
      (await repository.getActiveTimerSession())?.status,
      TimerStateStatus.paused,
    );
    await engine.cancel();
  });

  for (final dayOffset in [-1, 1]) {
    testWidgets('block on another date retains full duration $dayOffset', (
      tester,
    ) async {
      final repo = SadarRepository(null);
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWithValue(null),
          sadarRepoProvider.overrideWithValue(repo),
          notificationServiceProvider.overrideWithValue(NotificationService()),
        ],
      );
      addTearDown(container.dispose);
      final now = DateTime.now();
      final minute = (now.hour % 12) * 60 + now.minute;
      final start = minute > 0 ? minute - 1 : 0;
      final end = (minute + 15).clamp(start + 1, 720);
      final a = Activity()
        ..id = 99
        ..title = 'Other date'
        ..startMinute = start
        ..endMinute = end
        ..ampmHalf = halfOfNow(now)
        ..date = DateTime(now.year, now.month, now.day + dayOffset)
        ..colorValue = 0xff123456
        ..createdAt = now
        ..updatedAt = now;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: FocusSessionView(activity: a, onClose: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        container.read(timerEngineProvider).targetSeconds,
        (end - start) * 60,
      );
      await container.read(timerEngineProvider.notifier).cancel();
    });
  }

  testWidgets('FocusSessionView shows a storage error when start fails', (
    tester,
  ) async {
    final repository = _FailingStartRepository();
    final container = ProviderContainer(
      overrides: [
        isarProvider.overrideWithValue(null),
        sadarRepoProvider.overrideWithValue(repository),
        notificationServiceProvider.overrideWithValue(NotificationService()),
      ],
    );
    addTearDown(container.dispose);

    final now = DateTime.now();
    final minute = (now.hour % 12) * 60 + now.minute;
    final activity = Activity()
      ..id = 432
      ..title = 'Latihan tersimpan'
      ..startMinute = minute
      ..endMinute = (minute + 30).clamp(0, 720)
      ..ampmHalf = now.hour < 12 ? AmPmHalf.am : AmPmHalf.pm
      ..date = DateTime(now.year, now.month, now.day)
      ..colorValue = const Color(0xFF8BAE9A).value
      ..createdAt = now
      ..updatedAt = now;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: FocusSessionView(activity: activity, onClose: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Timer belum tersimpan'), findsOneWidget);
    expect(container.read(timerEngineProvider).isActive, isFalse);
  });
}

class _FailingStartRepository extends SadarRepository {
  _FailingStartRepository() : super(null);

  @override
  Future<void> saveTimerSession(TimerSession session) async {
    throw StateError('disk penuh');
  }
}
