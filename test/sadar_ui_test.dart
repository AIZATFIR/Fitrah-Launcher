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
          ..name = 'Quranic Arabic'
          ..iconKey = '📖'
          ..target = 15
          ..unit = HabitUnit.min
          ..colorValue = 0xFF10B981
          ..createdAt = DateTime.now(),
        Habit()
          ..id = 2
          ..name = 'French'
          ..iconKey = '🇫🇷'
          ..target = 20
          ..unit = HabitUnit.min
          ..colorValue = 0xFF3B82F6
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

      expect(find.text('Quranic Arabic'), findsOneWidget);
      expect(find.text('French'), findsOneWidget);
      expect(find.text('KEBIASAAN'), findsOneWidget);
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
