import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/data/repositories/sadar_repository.dart';
import 'package:focus_clock/models/habit.dart';
import 'package:focus_clock/models/habit_entry.dart';

void main() {
  group('SadarRepository Tests', () {
    late SadarRepository repo;

    setUp(() {
      repo = SadarRepository(null); // Memory fallback mode for testing
    });

    test('Initial repository seeds starter habits', () async {
      final habits = await repo.getHabits();
      expect(habits.isNotEmpty, true);
      expect(habits.any((h) => h.name.contains('Quranic Arabic')), true);
      expect(habits.any((h) => h.name.contains('French')), true);
    });

    test('Can upsert a new habit and retrieve it', () async {
      final habit = Habit()
        ..name = 'Meditation'
        ..iconKey = '🧘'
        ..target = 10
        ..unit = HabitUnit.min
        ..timerEnabled = true
        ..colorValue = 0xFF10B981
        ..orderIndex = 99
        ..createdAt = DateTime.now();

      final id = await repo.upsertHabit(habit);
      expect(id > 0, true);

      final habits = await repo.getHabits();
      expect(habits.any((h) => h.name == 'Meditation'), true);
    });

    test('Recording entry status saves and updates correctly', () async {
      final habits = await repo.getHabits();
      final targetHabit = habits.first;
      const todayStr = '2026-09-10';

      // 1. Mark Yes
      await repo.recordEntryStatus(
        habitId: targetHabit.id,
        dateString: todayStr,
        status: HabitStatus.yes,
        valueCompleted: 20,
        note: 'Felt very calm and clear.',
      );

      var entries = await repo.getEntriesForDateRange(todayStr, todayStr);
      expect(entries.length, 1);
      expect(entries.first.habitId, targetHabit.id);
      expect(entries.first.status, HabitStatus.yes);
      expect(entries.first.note, 'Felt very calm and clear.');

      // 2. Update to Skip
      await repo.recordEntryStatus(
        habitId: targetHabit.id,
        dateString: todayStr,
        status: HabitStatus.skip,
      );

      entries = await repo.getEntriesForDateRange(todayStr, todayStr);
      expect(entries.length, 1);
      expect(entries.first.status, HabitStatus.skip);
      // Note is preserved if not overwritten
      expect(entries.first.note, 'Felt very calm and clear.');
    });

    test('Calculates daily fulfillment count accurately', () async {
      final habits = await repo.getHabits();
      expect(habits.length >= 3, true);

      const dateStr = '2026-09-11';

      // Mark two as yes, one as no, one as skip
      await repo.recordEntryStatus(
        habitId: habits[0].id,
        dateString: dateStr,
        status: HabitStatus.yes,
      );
      await repo.recordEntryStatus(
        habitId: habits[1].id,
        dateString: dateStr,
        status: HabitStatus.yes,
      );
      await repo.recordEntryStatus(
        habitId: habits[2].id,
        dateString: dateStr,
        status: HabitStatus.no,
      );

      final fulfillment = await repo.getDailyFulfillment(dateStr);
      expect(fulfillment.completedCount, 2);
      expect(fulfillment.totalCount, habits.length);
    });

    test('Awareness statistics reveal repetition and neglect', () async {
      final habits = await repo.getHabits();
      final h1 = habits[0];
      final h2 = habits[1];

      // Record 3 days for h1
      await repo.recordEntryStatus(habitId: h1.id, dateString: '2026-09-01', status: HabitStatus.yes);
      await repo.recordEntryStatus(habitId: h1.id, dateString: '2026-09-02', status: HabitStatus.yes);
      await repo.recordEntryStatus(habitId: h1.id, dateString: '2026-09-03', status: HabitStatus.yes);

      // Record 1 no for h2
      await repo.recordEntryStatus(habitId: h2.id, dateString: '2026-09-01', status: HabitStatus.no);

      final stats = await repo.getAwarenessStats();
      expect(stats.habitCompletedCounts[h1.id], 3);
      expect(stats.habitCompletedCounts[h2.id] ?? 0, 0);
    });
  });
}
