import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/data/repositories/sadar_repository.dart';
import 'package:focus_clock/models/habit.dart';
import 'package:focus_clock/models/habit_entry.dart';
import 'package:focus_clock/models/daily_reflection.dart';
import 'package:focus_clock/models/timer_session.dart';

void main() {
  group('SadarRepository Tests', () {
    late SadarRepository repo;

    setUp(() {
      repo = SadarRepository(null); // Memory fallback mode for testing
    });

    test('Initial repository seeds starter habits', () async {
      final habits = await repo.getHabits();
      expect(habits.isNotEmpty, true);
      expect(habits.any((h) => h.name.contains('Fokus / Deep Work')), true);
      expect(habits.any((h) => h.name.contains('Olahraga / Exercise')), true);
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

    test('getWhatIRepeat aggregates repeated days and minutes', () async {
      final habits = await repo.getHabits();
      final h = habits.first;

      await repo.recordEntryStatus(habitId: h.id, dateString: '2026-09-01', status: HabitStatus.yes, valueCompleted: 20);
      await repo.recordEntryStatus(habitId: h.id, dateString: '2026-09-02', status: HabitStatus.yes, valueCompleted: 15);

      final repeatStats = await repo.getWhatIRepeat();
      expect(repeatStats.isNotEmpty, true);
      final stat = repeatStats.firstWhere((s) => s.habit.id == h.id);
      expect(stat.totalDays, 2);
      expect(stat.totalMinutes, 35);
    });

    test('DailyReflection saves and retrieves proudOfToday and feeling', () async {
      final reflection = DailyReflection()
        ..dateString = '2026-09-10'
        ..feeling = ReflectionFeeling.proud
        ..proudOfToday = 'Practiced Quranic Arabic even though tired.'
        ..note = 'Felt deeply focused after 10 minutes.';

      await repo.saveDailyReflection(reflection);

      final retrieved = await repo.getDailyReflection('2026-09-10');
      expect(retrieved, isNotNull);
      expect(retrieved!.feeling, ReflectionFeeling.proud);
      expect(retrieved.proudOfToday, 'Practiced Quranic Arabic even though tired.');
      expect(retrieved.note, 'Felt deeply focused after 10 minutes.');
    });

    test('TimerSession saves active session and clears on completion', () async {
      final session = TimerSession()
        ..habitId = 1
        ..habitName = 'Quranic Arabic'
        ..targetSeconds = 1200
        ..startedAt = DateTime.now()
        ..status = TimerStateStatus.running;

      await repo.saveTimerSession(session);

      var active = await repo.getActiveTimerSession();
      expect(active, isNotNull);
      expect(active!.habitName, 'Quranic Arabic');
      expect(active.status, TimerStateStatus.running);

      await repo.clearTimerSession();
      active = await repo.getActiveTimerSession();
      expect(active, isNull);
    });

    test('Historical immutability: changing habit target does not alter past entry targetSnapshot (PRD 3 §59, §60)', () async {
      final habit = Habit()
        ..name = 'French Practice'
        ..target = 15
        ..unit = HabitUnit.min
        ..createdAt = DateTime.now();

      final habitId = await repo.upsertHabit(habit);

      // Record entry when target is 15 min
      await repo.recordEntryStatus(
        habitId: habitId,
        dateString: '2026-09-01',
        status: HabitStatus.yes,
      );

      final entryBefore = (await repo.getEntriesForDateRange('2026-09-01', '2026-09-01')).first;
      expect(entryBefore.targetSnapshot, 15);

      // User later updates habit target to 45 min
      habit.target = 45;
      await repo.upsertHabit(habit);

      // Historical entry must remain untouched with targetSnapshot == 15
      final entryAfter = (await repo.getEntriesForDateRange('2026-09-01', '2026-09-01')).first;
      expect(entryAfter.targetSnapshot, 15);
    });

    test('Duplicate entry status recording is idempotent (PRD 3 §16)', () async {
      final habit = Habit()
        ..name = 'Morning Walk'
        ..target = 30
        ..createdAt = DateTime.now();

      final habitId = await repo.upsertHabit(habit);

      // Record multiple times for the same habit and date
      await repo.recordEntryStatus(habitId: habitId, dateString: '2026-09-05', status: HabitStatus.yes);
      await repo.recordEntryStatus(habitId: habitId, dateString: '2026-09-05', status: HabitStatus.yes);
      await repo.recordEntryStatus(habitId: habitId, dateString: '2026-09-05', status: HabitStatus.yes);

      final entries = await repo.getEntriesForDateRange('2026-09-05', '2026-09-05');
      expect(entries.length, 1);
      expect(entries.first.habitId, habitId);
      expect(entries.first.status, HabitStatus.yes);
    });
  });
}
