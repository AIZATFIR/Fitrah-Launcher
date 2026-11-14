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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('YPT checks usage access before enforcing an app whitelist', (
    tester,
  ) async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = previousPlatform);
    const channel = MethodChannel('fitrah_launcher/apps');
    final calls = <String>[];
    final lockscreenFlags = <bool>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'setLockscreenFocus') {
            lockscreenFlags.add(
              (call.arguments as Map<Object?, Object?>)['enabled'] as bool,
            );
          }
          if (call.method == 'checkUsageStatsPermission') return false;
          return true;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final repository = SadarRepository(null);
    final container = ProviderContainer(
      overrides: [
        isarProvider.overrideWithValue(null),
        sadarRepoProvider.overrideWithValue(repository),
        notificationServiceProvider.overrideWithValue(NotificationService()),
      ],
    );
    addTearDown(container.dispose);
    final habit = Habit()
      ..id = 783
      ..name = 'Latihan LKS'
      ..target = 30
      ..allowedPackages = ['com.example.study']
      ..colorValue = 0xff8bae9a
      ..createdAt = DateTime.now();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: SadarYptFocusView(habit: habit, onClose: () {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(calls, contains('checkUsageStatsPermission'));
    expect(find.text('Akses penggunaan belum aktif'), findsOneWidget);
    expect(container.read(timerEngineProvider).isActive, isFalse);
    expect(lockscreenFlags, isNot(contains(true)));

    await tester.tap(find.text('Buka pengaturan akses'));
    await tester.pump();
    expect(calls, contains('openUsageStatsSettings'));

    await tester.tap(find.text('Mulai tanpa batas aplikasi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(container.read(timerEngineProvider).isRunning, isTrue);
    expect(lockscreenFlags, contains(true));
    await tester.pump(const Duration(seconds: 3));
    expect(calls, isNot(contains('getForegroundApp')));
    await container.read(timerEngineProvider.notifier).cancel();
    debugDefaultTargetPlatformOverride = previousPlatform;
  });

  testWidgets('YPT app-list failure is reachable at 320dp and 200% text', (
    tester,
  ) async {
    const channel = MethodChannel('fitrah_launcher/apps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => true);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
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
    addTearDown(container.dispose);
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
    addTearDown(container.dispose);
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

  testWidgets('focus presets use the durable preset timer path', (
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
    final habit = Habit()
      ..id = 0
      ..name = 'Pomodoro Sprint'
      ..target = 25
      ..colorValue = 0xFFE8C07D
      ..createdAt = DateTime.now();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: SadarYptFocusView(
            habit: habit,
            onClose: () {},
            sessionSourceKind: TimerSessionSourceKind.preset,
            sourceIdentity: 'focus-preset:25',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      container.read(timerEngineProvider).sourceKind,
      TimerSessionSourceKind.preset,
    );
    expect(container.read(timerEngineProvider).habitId, 0);
    expect(
      (await repository.getActiveTimerSession())?.sourceKind,
      TimerSessionSourceKind.preset,
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
      addTearDown(container.dispose);
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
    String? sessionId,
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
      sessionId: sessionId,
      dateString: dateString,
      actualDurationMinutes: actualDurationMinutes,
      actualDurationSeconds: actualDurationSeconds,
      targetSnapshot: targetSnapshot,
      completedAt: completedAt,
    );
  }
}
