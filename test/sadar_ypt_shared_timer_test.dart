import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/features/sadar/widgets/sadar_ypt_focus_view.dart';
import 'package:fitrah_launcher/features/launcher/services/app_launcher_service.dart';
import 'package:fitrah_launcher/models/habit.dart';
import 'package:fitrah_launcher/models/habit_entry.dart';
import 'package:fitrah_launcher/models/timer_session.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:fitrah_launcher/providers/sadar_providers.dart';
import 'package:fitrah_launcher/services/notification_service.dart';
import 'package:fitrah_launcher/services/sadar_timer_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('YPT app-list failure is reachable at 320dp and 200% text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = SadarRepository(null);
    final container = ProviderContainer(
      overrides: [
        isarProvider.overrideWithValue(null),
        sadarRepoProvider.overrideWithValue(repository),
        notificationServiceProvider.overrideWithValue(NotificationService()),
        installedAppsFutureProvider.overrideWith(
          (_) async => throw StateError('temporary listing failure'),
        ),
      ],
    );
    addTearDown(() async {
      await container.read(timerEngineProvider.notifier).cancel();
      container.dispose();
    });
    final habit = Habit()
      ..id = 780
      ..name = 'Latihan LKS dengan judul yang panjang'
      ..target = 30
      ..allowedPackages = ['missing.app']
      ..colorValue = 0xff8bae9a
      ..createdAt = DateTime.now();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: SadarYptFocusView(habit: habit, onClose: () {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Coba lagi'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(container.read(timerEngineProvider).isRunning, isTrue);
    await container.read(timerEngineProvider.notifier).cancel();
  });

  testWidgets('YPT starts and pauses through the shared timer owner', (
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
    addTearDown(() async {
      await container.read(timerEngineProvider.notifier).cancel();
      container.dispose();
    });
    final habit = Habit()
      ..id = 781
      ..name = 'Latihan LKS'
      ..target = 30
      ..colorValue = const Color(0xFF8BAE9A).value
      ..createdAt = DateTime.now();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SadarYptFocusView(habit: habit, onClose: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(container.read(timerEngineProvider).isRunning, isTrue);
    expect(container.read(timerEngineProvider).habitId, habit.id);
    expect(
      container.read(timerEngineProvider).sourceKind,
      TimerSessionSourceKind.yptHabit,
    );
    expect((await repository.getActiveTimerSession())?.habitId, habit.id);

    await tester.tap(find.text('Jeda'));
    await tester.pump();

    expect(container.read(timerEngineProvider).isPaused, isTrue);
    expect(
      (await repository.getActiveTimerSession())?.status,
      TimerStateStatus.paused,
    );
    await container.read(timerEngineProvider.notifier).cancel();
  });

  testWidgets(
    'YPT keeps failed completion visible and retries the same session',
    (tester) async {
      final repository = _FailOnceCompletionRepository();
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWithValue(null),
          sadarRepoProvider.overrideWithValue(repository),
          notificationServiceProvider.overrideWithValue(NotificationService()),
        ],
      );
      var closeCount = 0;
      addTearDown(() async {
        await container.read(timerEngineProvider.notifier).cancel();
        container.dispose();
      });
      final habit = Habit()
        ..id = 782
        ..name = 'Latihan tersimpan'
        ..target = 30
        ..colorValue = const Color(0xFF8BAE9A).value
        ..createdAt = DateTime.now();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SadarYptFocusView(
                habit: habit,
                onClose: () => closeCount++,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Selesai'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(container.read(timerEngineProvider).isSavePending, isTrue);
      expect(closeCount, 0);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(await repository.getActiveTimerSession(), isNotNull);

      await tester.tap(find.text('Coba lagi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(repository.completionAttempts, 2);
      expect(container.read(timerEngineProvider).isSavePending, isFalse);
      expect(await repository.getActiveTimerSession(), isNull);
      expect(closeCount, 1);
    },
  );
}

class _FailOnceCompletionRepository extends SadarRepository {
  _FailOnceCompletionRepository() : super(null);

  int completionAttempts = 0;

  @override
  Future<HabitEntry> completeTimerSession({
    required int habitId,
    required String dateString,
    required int actualDurationMinutes,
    int? actualDurationSeconds,
    required int targetSnapshot,
    required DateTime completedAt,
  }) async {
    completionAttempts++;
    if (completionAttempts == 1) throw StateError('simulated write failure');
    return super.completeTimerSession(
      habitId: habitId,
      dateString: dateString,
      actualDurationMinutes: actualDurationMinutes,
      actualDurationSeconds: actualDurationSeconds,
      targetSnapshot: targetSnapshot,
      completedAt: completedAt,
    );
  }
}
