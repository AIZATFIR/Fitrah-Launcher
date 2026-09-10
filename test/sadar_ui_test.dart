import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/features/sadar/sadar_home_screen.dart';
import 'package:focus_clock/features/sadar/widgets/daily_fulfillment_banner.dart';
import 'package:focus_clock/features/sadar/widgets/horizontal_timeline_grid.dart';
import 'package:focus_clock/models/habit.dart';
import 'package:focus_clock/services/secure_storage_service.dart';

class FakeSecureStorageService extends SecureStorageService {
  @override
  Future<bool> isSadarOnboardingDone() async => true;

  @override
  Future<void> setSadarOnboardingDone(bool done) async {}
}

void main() {
  group('Sadar UI Widget Tests', () {
    testWidgets('DailyFulfillmentBanner renders date and philosophy text', (tester) async {
      final date = DateTime(2026, 9, 11);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DailyFulfillmentBanner(
                selectedDate: date,
                isShowingAwareness: false,
                onToggleAwareness: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Did I live today'), findsOneWidget);
      expect(find.byType(DailyFulfillmentBanner), findsOneWidget);
    });

    testWidgets('HorizontalTimelineGrid displays habit names and cells', (tester) async {
      final habits = [
        Habit()
          ..id = 1
          ..name = 'Fokus / Deep Work'
          ..iconKey = '💻'
          ..target = 45
          ..unit = HabitUnit.min
          ..colorValue = 0xFF10B981
          ..createdAt = DateTime.now(),
        Habit()
          ..id = 2
          ..name = 'Olahraga / Exercise'
          ..iconKey = '🏃'
          ..target = 30
          ..unit = HabitUnit.min
          ..colorValue = 0xFFF97316
          ..createdAt = DateTime.now(),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HorizontalTimelineGrid(
                habits: habits,
                onEditHabit: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Fokus / Deep Work'), findsOneWidget);
      expect(find.text('Olahraga / Exercise'), findsOneWidget);
      expect(find.text('Minggu Ini'), findsOneWidget);
    });

    testWidgets('SadarHomeScreen displays header and all 4 navigation tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(FakeSecureStorageService()),
          ],
          child: const MaterialApp(
            home: SadarHomeScreen(),
          ),
        ),
      );

      // Pump for initial build and async storage check
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('SADAR'), findsOneWidget);
      expect(find.text('Way of Life'), findsOneWidget);
      expect(find.text('Hari Ini'), findsOneWidget);
      expect(find.text('Linimasa'), findsOneWidget);
      expect(find.text('Repetisi'), findsOneWidget);
      expect(find.text('Kesadaran'), findsOneWidget);

      // Switch to Repetisi tab
      await tester.tap(find.text('Repetisi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('WHAT YOU REPEAT'), findsOneWidget);

      // Switch to Kesadaran tab
      await tester.tap(find.text('Kesadaran'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('PRINSIP KESADARAN'), findsOneWidget);
    });
  });
}
