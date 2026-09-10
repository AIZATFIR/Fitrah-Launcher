import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/features/sadar/sadar_home_screen.dart';
import 'package:focus_clock/features/sadar/widgets/daily_fulfillment_banner.dart';
import 'package:focus_clock/features/sadar/widgets/horizontal_timeline_grid.dart';
import 'package:focus_clock/models/habit.dart';

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

      await tester.pumpAndSettle();

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

      await tester.pumpAndSettle();

      expect(find.text('Quranic Arabic'), findsOneWidget);
      expect(find.text('French'), findsOneWidget);
      expect(find.text('KEBIASAAN'), findsOneWidget);
    });

    testWidgets('SadarHomeScreen displays header, habits, and FAB', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SadarHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SADAR'), findsOneWidget);
      expect(find.text('Way of Life'), findsOneWidget);
      expect(find.text('Kebiasaan Baru'), findsOneWidget);
    });
  });
}
