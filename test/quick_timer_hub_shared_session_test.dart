import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/models/timer_session.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:fitrah_launcher/providers/sadar_providers.dart';
import 'package:fitrah_launcher/services/notification_service.dart';
import 'package:fitrah_launcher/services/sadar_timer_engine.dart';
import 'package:fitrah_launcher/widgets/quick_timer_hub.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('QuickTimerHub displays a session started by the shared owner', (
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

    await container
        .read(timerEngineProvider.notifier)
        .startNonHabit(
          title: 'Home preset session',
          targetSeconds: 900,
          sourceKind: TimerSessionSourceKind.preset,
        );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: QuickTimerHub())),
      ),
    );
    await tester.pump();

    expect(find.text('Home preset session'), findsOneWidget);
    expect(find.textContaining('tersisa'), findsOneWidget);
    expect(find.byTooltip('Jeda'), findsOneWidget);
    expect(
      container.read(timerEngineProvider).sourceKind,
      TimerSessionSourceKind.preset,
    );
    await container.read(timerEngineProvider.notifier).cancel();
  });

  testWidgets('QuickTimerHub starts and persists an Activity-linked session', (
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
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: QuickTimerHub())),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Quick activity');
    await tester.tap(find.text('Mulai 30m'));
    await tester.pump(const Duration(milliseconds: 100));

    final session = await repository.getActiveTimerSession();
    final activities = await container
        .read(activityRepoProvider)
        .getByDate(DateTime.now());
    expect(session?.sourceKind, TimerSessionSourceKind.activity);
    expect(session?.activityId, isNotNull);
    expect(activities.single.id, session?.activityId);
    expect(session?.habitName, 'Quick activity');
    expect(container.read(timerEngineProvider).isRunning, isTrue);
    await container.read(timerEngineProvider.notifier).cancel();
  });

  testWidgets('QuickTimerHub shows invalid restored source error', (
    tester,
  ) async {
    final repository = SadarRepository(null);
    await repository.saveTimerSession(
      TimerSession()
        ..sourceKindIndex = 999
        ..habitName = 'Unknown source timer'
        ..targetSeconds = 900
        ..status = TimerStateStatus.paused
        ..updatedAt = DateTime.now(),
    );
    final container = ProviderContainer(
      overrides: [
        isarProvider.overrideWithValue(null),
        sadarRepoProvider.overrideWithValue(repository),
        notificationServiceProvider.overrideWithValue(NotificationService()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: QuickTimerHub())),
      ),
    );
    await tester.pump();

    expect(find.textContaining('sumber yang tidak dikenali'), findsOneWidget);
    expect(container.read(timerEngineProvider).restoreError, isNotNull);
    expect(await repository.getActiveTimerSession(), isNotNull);
  });
}
