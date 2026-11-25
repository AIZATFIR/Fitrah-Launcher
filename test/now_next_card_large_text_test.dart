import 'package:fitrah_launcher/features/focusclock/widgets/now_next_card.dart';
import 'package:fitrah_launcher/models/app_settings.dart';
import 'package:fitrah_launcher/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('free-time summary wraps instead of truncating at 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = DateTime(2026, 11, 21);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => Stream.value(AppSettings())),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: NowNextCard(activities: const [], now: today, date: today),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final summary = find.text('Tidak ada jadwal tersisa');
    expect(summary, findsOneWidget);
    await tester.tap(find.byTooltip('Buka Input Niat'));
    await tester.pumpAndSettle();
    final intentField = tester.widget<TextField>(find.byType(TextField));
    expect(intentField.controller?.text, isEmpty);
    expect(intentField.decoration?.hintText, isNull);
    expect(find.text('Belajar 30 mnt'), findsNothing);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: summary, matching: find.byType(RichText)),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(paragraph.size.height, greaterThan(30));
    expect(tester.takeException(), isNull);
  });
}
