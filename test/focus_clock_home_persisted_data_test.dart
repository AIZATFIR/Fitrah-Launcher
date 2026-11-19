import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/domain/focus_intent.dart';
import 'package:fitrah_launcher/features/sadar/widgets/sadar_timer_view.dart';
import 'package:fitrah_launcher/features/launcher/widgets/focus_clock_home_view.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/models/timer_session.dart';
import 'package:fitrah_launcher/models/terminal_focus_session.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:fitrah_launcher/providers/intent_providers.dart';
import 'package:fitrah_launcher/providers/sadar_providers.dart';
import 'package:fitrah_launcher/services/sadar_timer_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ControllableTimerEngine extends SadarTimerEngine {
  _ControllableTimerEngine(super.repository);

  void emit(TimerState next) => state = next;
}

void main() {
  Widget homeWithActivities(List<Activity> activities) => ProviderScope(
    overrides: [
      activitiesByDateProvider.overrideWith((ref) => Stream.value(activities)),
    ],
    child: const MaterialApp(
      home: FocusClockHomeView(onOpenFocusClock: _noop, onOpenAppDrawer: _noop),
    ),
  );

  testWidgets('Home shows completed and cancelled focus history', (
    tester,
  ) async {
    final repository = SadarRepository.store(null);
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final completed = TerminalFocusSession()
      ..id = 1
      ..sessionId = 'home-complete'
      ..sourceKind = 'free'
      ..titleSnapshot = 'LKS snapshot'
      ..startedAt = now.subtract(const Duration(minutes: 15))
      ..completedAt = now
      ..actualDurationSeconds = 901
      ..status = TerminalSessionStatus.completed;
    final cancelled = TerminalFocusSession()
      ..id = 2
      ..sessionId = 'home-cancel'
      ..sourceKind = 'free'
      ..titleSnapshot = 'Cancelled session'
      ..startedAt = now.subtract(const Duration(minutes: 5))
      ..completedAt = now
      ..actualDurationSeconds = 0
      ..status = TerminalSessionStatus.cancelled;
    final container = ProviderContainer(
      overrides: [
        activitiesByDateProvider.overrideWith((ref) => Stream.value(const [])),
        sadarRepoProvider.overrideWithValue(repository),
        terminalFocusSessionsForDateProvider(
          date,
        ).overrideWith((ref) => Stream.value([completed, cancelled])),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: FocusClockHomeView(
            onOpenFocusClock: _noop,
            onOpenAppDrawer: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fokus hari ini · 15 menit 1 detik'), findsOneWidget);
    final tools = find.text('Catatan & alat');
    await tester.scrollUntilVisible(
      tools,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(tools);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('LKS snapshot'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Riwayat sesi'), findsOneWidget);
    expect(find.text('LKS snapshot'), findsOneWidget);
    expect(find.text('Cancelled session'), findsOneWidget);
    expect(find.text('Dibatalkan'), findsOneWidget);
  });

  testWidgets(
    'fresh Home shows an honest empty schedule without demo identity',
    (tester) async {
      await tester.pumpWidget(homeWithActivities(const []));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada jadwal'), findsOneWidget);
      expect(find.textContaining('Programmer'), findsNothing);
      expect(find.textContaining('Tidur'), findsNothing);
      expect(find.text('Kebiasaan & Rutinitas'), findsNothing);
    },
  );

  testWidgets('Hari Ini remains usable at 320dp and 200% text', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activitiesByDateProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          intentNowProvider.overrideWithValue(DateTime(2026, 11, 19, 10)),
          intentStateProvider.overrideWith(
            (ref) => Stream.value(
              IntentState(
                sourceStoreId: '11111111-1111-4111-8111-111111111111',
                legacyImported: true,
                goals: const [
                  IntentGoal(
                    id: '22222222-2222-4222-8222-222222222222',
                    title: 'Menang LKS Nasional IT Software Solution',
                    pinned: true,
                  ),
                ],
              ),
            ),
          ),
          intentSourceDataProvider.overrideWith(
            (ref) => Stream.value(const IntentSourceData([], [], [])),
          ),
          intentAgendaProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: const FocusClockHomeView(
            onOpenFocusClock: _noop,
            onOpenAppDrawer: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TUJUAN UTAMA'), findsOneWidget);
    expect(
      find.text('Menang LKS Nasional IT Software Solution'),
      findsOneWidget,
    );
    expect(find.text('Tambah kegiatan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('persisted activity appears in the same Home agenda', (
    tester,
  ) async {
    final now = DateTime.now();
    final half = now.hour < 12 ? AmPmHalf.am : AmPmHalf.pm;
    final minute = (now.hour % 12) * 60 + now.minute;
    final activity = Activity()
      ..id = 421
      ..title = 'Latihan LKS'
      ..startMinute = minute
      ..endMinute = (minute + 30).clamp(0, 720)
      ..ampmHalf = half
      ..date = dateOnly(now)
      ..colorValue = const Color(0xFF8BAE9A).value
      ..createdAt = now
      ..updatedAt = now;

    await tester.pumpWidget(homeWithActivities([activity]));
    await tester.pumpAndSettle();

    expect(find.text('Terjadwal sekarang · Latihan LKS'), findsOneWidget);
    expect(find.textContaining('Latihan LKS'), findsOneWidget);
    expect(find.textContaining('Programmer'), findsNothing);
  });

  testWidgets('completed activity is not presented as happening now', (
    tester,
  ) async {
    final now = DateTime.now();
    final half = now.hour < 12 ? AmPmHalf.am : AmPmHalf.pm;
    final minute = (now.hour % 12) * 60 + now.minute;
    final activity = Activity()
      ..id = 422
      ..title = 'Sesi yang sudah selesai'
      ..startMinute = minute
      ..endMinute = (minute + 30).clamp(0, 720)
      ..ampmHalf = half
      ..date = dateOnly(now)
      ..colorValue = const Color(0xFF8BAE9A).value
      ..isCompleted = true
      ..createdAt = now
      ..updatedAt = now;

    await tester.pumpWidget(homeWithActivities([activity]));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada kegiatan terjadwal sekarang'), findsOneWidget);
    expect(
      find.textContaining('Terjadwal sekarang · Sesi yang sudah selesai'),
      findsNothing,
    );
  });

  testWidgets('Home habit Play opens the shared Sadar session', (tester) async {
    final repository = SadarRepository(null);
    final container = ProviderContainer(
      overrides: [
        activitiesByDateProvider.overrideWith((ref) => Stream.value(const [])),
        sadarRepoProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: FocusClockHomeView(
            onOpenFocusClock: _noop,
            onOpenAppDrawer: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final playButtons = find.byTooltip('Mulai di Focus Clock');
    for (
      var attempt = 0;
      attempt < 10 && playButtons.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    expect(playButtons, findsWidgets);
    await tester.ensureVisible(playButtons.first);
    await tester.pumpAndSettle();
    await tester.tap(playButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byType(SadarTimerView), findsOneWidget);
    expect(container.read(timerEngineProvider).isRunning, isTrue);
    await container.read(timerEngineProvider.notifier).cancel();
  });

  testWidgets('Home observes a non-habit session from the shared owner', (
    tester,
  ) async {
    final repository = SadarRepository(null);
    final container = ProviderContainer(
      overrides: [
        activitiesByDateProvider.overrideWith((ref) => Stream.value(const [])),
        sadarRepoProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(timerEngineProvider.notifier)
        .startNonHabit(
          title: 'Shared preset timer',
          targetSeconds: 900,
          sourceKind: TimerSessionSourceKind.preset,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: FocusClockHomeView(
            onOpenFocusClock: _noop,
            onOpenAppDrawer: _noop,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Shared preset timer'), findsOneWidget);
    await container.read(timerEngineProvider.notifier).cancel();
  });

  testWidgets('completed timer state does not leave a Home mini timer', (
    tester,
  ) async {
    final repository = SadarRepository(null);
    final timer = _ControllableTimerEngine(repository);
    await timer.waitUntilRestored();
    timer.emit(
      const TimerState(
        habitId: 12,
        habitName: 'Completed goal session',
        sourceKind: TimerSessionSourceKind.habit,
        goalId: '123e4567-e89b-12d3-a456-426614174000',
        goalTitleSnapshot: 'Persisted goal',
        targetSeconds: 1800,
        remainingSeconds: 1200,
        status: TimerStateStatus.running,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        activitiesByDateProvider.overrideWith((ref) => Stream.value(const [])),
        sadarRepoProvider.overrideWithValue(repository),
        timerEngineProvider.overrideWith((ref) => timer),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: FocusClockHomeView(
            onOpenFocusClock: _noop,
            onOpenAppDrawer: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(timer.state.isRunning, isTrue);
    expect(find.byKey(const ValueKey('home-mini-timer')), findsOneWidget);
    timer.emit(
      const TimerState(
        habitId: 12,
        habitName: 'Completed goal session',
        sourceKind: TimerSessionSourceKind.habit,
        goalId: '123e4567-e89b-12d3-a456-426614174000',
        goalTitleSnapshot: 'Persisted goal',
        targetSeconds: 1800,
        status: TimerStateStatus.completed,
      ),
    );
    await tester.pump();
    expect(timer.state.isCompleted, isTrue);
    expect(find.byKey(const ValueKey('home-mini-timer')), findsNothing);
  });

  testWidgets('Home cancellation clears shared timer before hiding it', (
    tester,
  ) async {
    final repository = _FailOnceClearRepository();
    final container = ProviderContainer(
      overrides: [
        activitiesByDateProvider.overrideWith((ref) => Stream.value(const [])),
        sadarRepoProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
    });
    await container
        .read(timerEngineProvider.notifier)
        .startNonHabit(
          title: 'Cancelable preset',
          targetSeconds: 900,
          sourceKind: TimerSessionSourceKind.preset,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: FocusClockHomeView(
            onOpenFocusClock: _noop,
            onOpenAppDrawer: _noop,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Cancelable preset'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Batalkan timer'), findsOneWidget);

    await tester.tap(find.text('Batalkan timer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(await repository.getActiveTimerSession(), isNotNull);
    expect(find.text('Batalkan timer'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Batalkan timer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(await repository.getActiveTimerSession(), isNull);
    expect(find.text('Batalkan timer'), findsNothing);
  });
}

class _FailOnceClearRepository extends SadarRepository {
  _FailOnceClearRepository() : super(null);

  bool _failNext = true;

  @override
  Future<void> clearTimerSession() async {
    if (_failNext) {
      _failNext = false;
      throw StateError('injected clear failure');
    }
    return super.clearTimerSession();
  }
}

void _noop() {}
