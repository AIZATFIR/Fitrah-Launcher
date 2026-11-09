import 'package:fitrah_launcher/data/repositories/sadar_repository.dart';
import 'package:fitrah_launcher/features/launcher/services/app_launcher_service.dart';
import 'package:fitrah_launcher/features/launcher/widgets/niagara_unified_stream_view.dart';
import 'package:fitrah_launcher/models/habit.dart';
import 'package:fitrah_launcher/providers/sadar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('legacy Sadar actions have at least 48dp targets', (
    tester,
  ) async {
    final repo = SadarRepository(null);
    for (final habit in await repo.getHabits()) {
      await repo.deleteHabit(habit.id, hardDelete: true);
    }
    for (final name in ['First', 'Second']) {
      await repo.upsertHabit(
        Habit()
          ..name = name
          ..target = 10
          ..colorValue = 0xff8bae9a
          ..createdAt = DateTime.now(),
      );
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sadarRepoProvider.overrideWithValue(repo),
          installedAppsFutureProvider.overrideWith(
            (_) async => const [
              InstalledApp(appName: 'Test App', packageName: 'test.app'),
            ],
          ),
        ],
        child: MaterialApp(
          home: NiagaraUnifiedStreamView(onOpenFocusClock: () {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    for (final label in ['SADAR', '0/2 selesai (0%)', '🎯 Second']) {
      final target = find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container && widget.constraints?.minHeight == 48,
        ),
      );
      expect(target, findsOneWidget, reason: label);
      expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });
}
