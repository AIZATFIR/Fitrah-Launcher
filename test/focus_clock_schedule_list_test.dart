import 'package:fitrah_launcher/core/time_math.dart';
import 'package:fitrah_launcher/features/focusclock/focusclock_tab.dart';
import 'package:fitrah_launcher/models/activity.dart';
import 'package:fitrah_launcher/models/app_settings.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('clock offers a labeled schedule list without dial gestures', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final date = DateTime(2026, 11, 21);
    final activity = Activity()
      ..id = 41
      ..title = 'Latihan LKS'
      ..date = date
      ..startMinute = 540
      ..endMinute = 600
      ..ampmHalf = AmPmHalf.am
      ..colorValue = 0xffd8bd74;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => Stream.value(AppSettings())),
          currentDateProvider.overrideWith((ref) => date),
          currentTimeProvider.overrideWith(
            (ref) => Stream.value(DateTime(2026, 11, 21, 8)),
          ),
          ampmHalfProvider.overrideWith((ref) => AmPmHalf.am),
          activitiesByHalfProvider.overrideWith(
            (ref) => Stream.value([activity]),
          ),
          activitiesByDateProvider.overrideWith(
            (ref) => Stream.value([activity]),
          ),
          tasksByHalfProvider.overrideWith((ref) => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: FocusClockTab())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Menu Fokus'));
    await tester.pumpAndSettle();
    expect(find.text('Jadwal'), findsOneWidget);

    await tester.tap(find.text('Jadwal'));
    await tester.pumpAndSettle();

    expect(find.text('Latihan LKS'), findsOneWidget);
    expect(find.textContaining('9:00 AM'), findsOneWidget);
    final row = tester.getSemantics(
      find.byKey(const ValueKey('focus-clock-schedule-41')),
    );
    expect(row.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(row.label, contains('Latihan LKS'));
    expect(row.label, contains('9:00 AM'));
  });
}
