import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/features/sadar/widgets/sadar_timer_view.dart';
import 'package:fitrah_launcher/features/launcher/widgets/focus_clock_home_view.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:fitrah_launcher/providers/sadar_providers.dart';
import 'package:fitrah_launcher/services/sadar_timer_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget homeWithActivities(List<Activity> activities) => ProviderScope(
    overrides: [
      activitiesByDateProvider.overrideWith((ref) => Stream.value(activities)),
    ],
    child: const MaterialApp(
      home: FocusClockHomeView(onOpenFocusClock: _noop, onOpenAppDrawer: _noop),
    ),
  );

  testWidgets(
    'fresh Home shows an honest empty schedule without demo identity',
    (tester) async {
      await tester.pumpWidget(homeWithActivities(const []));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada jadwal'), findsOneWidget);
      expect(find.textContaining('Programmer'), findsNothing);
      expect(find.textContaining('Tidur'), findsNothing);
    },
  );

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
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Latihan LKS'), findsWidgets);
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
    expect(find.textContaining('Terjadwal sekarang · Sesi yang sudah selesai'), findsNothing);
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
    for (var attempt = 0;
        attempt < 10 && playButtons.evaluate().isEmpty;
        attempt++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    expect(playButtons, findsWidgets);
    await tester.tap(playButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byType(SadarTimerView), findsOneWidget);
    expect(container.read(timerEngineProvider).isRunning, isTrue);
    await container.read(timerEngineProvider.notifier).cancel();
  });
}

void _noop() {}
