import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/features/sadar/widgets/desktop_floating_timer.dart';
import 'package:fitrah_launcher/features/sadar/widgets/sadar_timer_view.dart';
import 'package:fitrah_launcher/models/habit.dart';
import 'package:fitrah_launcher/models/timer_session.dart';
import 'package:fitrah_launcher/providers/sadar_providers.dart';
import 'package:fitrah_launcher/services/sadar_timer_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SadarRepository repository;
  late ProviderContainer container;
  late Habit habit;

  setUp(() {
    repository = SadarRepository(null);
    container = ProviderContainer(
      overrides: [sadarRepoProvider.overrideWithValue(repository)],
    );
    habit = Habit()
      ..id = 42
      ..name = 'Latihan LKS'
      ..target = 20
      ..unit = HabitUnit.min
      ..colorValue = 0xFF8BAE9A
      ..createdAt = DateTime.now();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    container.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('habit timer view starts and pauses the shared session', (
    tester,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: SadarTimerView(habit: habit, onClose: () {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    expect(container.read(timerEngineProvider).isRunning, isTrue);
    expect(find.text('20:00'), findsOneWidget);

    await tester.tap(find.text('Jeda'));
    await tester.pump();

    expect(container.read(timerEngineProvider).isPaused, isTrue);
    expect(find.text('JEDA'), findsOneWidget);
  });

  testWidgets('finishing the view writes the shared habit entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: SadarTimerView(habit: habit, onClose: () {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));
    await tester.tap(find.text('Selesai'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    final date = DateTime.now().toIso8601String().substring(0, 10);
    final entries = await repository.getEntriesForDateRange(date, date);
    expect(entries, hasLength(1));
    expect(entries.single.habitId, habit.id);
    expect(entries.single.source, 'timer');
    expect(find.textContaining('Catatan ini sudah tersimpan.'), findsOneWidget);
  });

  testWidgets('uncertain recovery notice keeps Continue and Finish available', (
    tester,
  ) async {
    await repository.saveTimerSession(
      TimerSession()
        ..habitId = habit.id
        ..habitName = habit.name
        ..sourceKind = TimerSessionSourceKind.habit
        ..targetSeconds = 1200
        ..startedAt = DateTime.now().subtract(const Duration(hours: 2))
        ..runningSince = DateTime.now().subtract(const Duration(hours: 2))
        ..accumulatedDurationSeconds = 37
        ..status = TimerStateStatus.running
        ..updatedAt = DateTime.now(),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: SadarTimerView(habit: habit, onClose: () {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(timerRecoveryNotice), findsOneWidget);
    expect(find.text('Lanjutkan'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('19:23'), findsOneWidget);
  });

  testWidgets('desktop floating timer shows recovery notice', (tester) async {
    await repository.saveTimerSession(
      TimerSession()
        ..habitId = habit.id
        ..habitName = habit.name
        ..sourceKind = TimerSessionSourceKind.habit
        ..targetSeconds = 1200
        ..startedAt = DateTime.now().subtract(const Duration(hours: 2))
        ..runningSince = DateTime.now().subtract(const Duration(hours: 2))
        ..accumulatedDurationSeconds = 37
        ..status = TimerStateStatus.running
        ..updatedAt = DateTime.now(),
    );
    await container.read(timerEngineProvider.notifier).waitUntilRestored();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DesktopFloatingTimer()),
      ),
    );

    expect(find.text(timerRecoveryNotice), findsOneWidget);
    expect(find.text('19:23'), findsOneWidget);
  });
}
