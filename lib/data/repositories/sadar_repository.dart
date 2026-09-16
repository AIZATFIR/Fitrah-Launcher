import 'dart:async';
import 'package:isar/isar.dart';

import '../../models/habit.dart';
import '../../models/habit_entry.dart';
import '../../models/daily_reflection.dart';
import '../../models/timer_session.dart';

class RepetitionStat {
  final Habit habit;
  final int totalDays;
  final int totalMinutes;

  const RepetitionStat({
    required this.habit,
    required this.totalDays,
    required this.totalMinutes,
  });
}

class DailyFulfillmentSummary {
  final String dateString;
  final int completedCount;
  final int totalCount;

  const DailyFulfillmentSummary({
    required this.dateString,
    required this.completedCount,
    required this.totalCount,
  });

  double get ratio => totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;
  bool get isFulfilled => completedCount > 0 && completedCount >= totalCount;
}

class AwarenessStats {
  final Map<int, int> habitCompletedCounts;
  final Map<int, int> habitMissedCounts;
  final List<Habit> neglectedHabits;
  final List<Habit> consistentHabits;

  const AwarenessStats({
    required this.habitCompletedCounts,
    required this.habitMissedCounts,
    required this.neglectedHabits,
    required this.consistentHabits,
  });
}

class SadarRepository {
  SadarRepository(this._isar) {
    if (_isar == null) {
      for (final h in _defaultHabits()) {
        _memHabits[h.id] = h;
      }
    }
  }

  final Isar? _isar;

  // In-Memory storage for tests / fallback
  final Map<int, Habit> _memHabits = {};
  final Map<String, HabitEntry> _memEntries = {}; // Key: "$habitId-$dateString"
  final Map<String, DailyReflection> _memReflections = {}; // Key: "$dateString"
  int _memHabitIdCounter = 100;
  int _memEntryIdCounter = 1000;

  final StreamController<void> _habitsStreamCtrl = StreamController<void>.broadcast();
  final StreamController<void> _entriesStreamCtrl = StreamController<void>.broadcast();

  // ──────────────────────────────────────────────────────────────────────────
  // Habits
  // ──────────────────────────────────────────────────────────────────────────

  Stream<List<Habit>> watchHabits() {
    if (_isar == null) {
      return _watchMemHabits();
    }
    return _isar.habits
        .filter()
        .isArchivedEqualTo(false)
        .sortByOrderIndex()
        .thenByCreatedAt()
        .watch(fireImmediately: true);
  }

  Stream<List<Habit>> _watchMemHabits() async* {
    yield _getMemHabitsList();
    await for (final _ in _habitsStreamCtrl.stream) {
      yield _getMemHabitsList();
    }
  }

  List<Habit> _getMemHabitsList() {
    final list = _memHabits.values.where((h) => !h.isArchived).toList();
    list.sort((a, b) {
      final ord = a.orderIndex.compareTo(b.orderIndex);
      if (ord != 0) return ord;
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  Future<List<Habit>> getHabits() async {
    if (_isar == null) {
      return _getMemHabitsList();
    }
    return _isar.habits
        .filter()
        .isArchivedEqualTo(false)
        .sortByOrderIndex()
        .thenByCreatedAt()
        .findAll();
  }

  Future<int> upsertHabit(Habit habit) async {
    habit.updatedAt = DateTime.now();
    if (_isar == null) {
      if (habit.id == Isar.autoIncrement || habit.id <= 0) {
        habit.id = _memHabitIdCounter++;
      }
      _memHabits[habit.id] = habit;
      _habitsStreamCtrl.add(null);
      return habit.id;
    }
    return _isar.writeTxn(() => _isar.habits.put(habit));
  }

  Future<bool> deleteHabit(int id, {bool hardDelete = false}) async {
    if (_isar == null) {
      if (hardDelete) {
        _memHabits.remove(id);
      } else {
        final h = _memHabits[id];
        if (h != null) h.isArchived = true;
      }
      _habitsStreamCtrl.add(null);
      return true;
    }

    if (hardDelete) {
      return _isar.writeTxn(() => _isar.habits.delete(id));
    } else {
      final h = await _isar.habits.get(id);
      if (h != null) {
        h.isArchived = true;
        h.updatedAt = DateTime.now();
        await _isar.writeTxn(() => _isar.habits.put(h));
        return true;
      }
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Habit Entries
  // ──────────────────────────────────────────────────────────────────────────

  Stream<List<HabitEntry>> watchEntriesForDateRange(String startDate, String endDate) {
    if (_isar == null) {
      return _watchMemEntries(startDate, endDate);
    }
    return _isar.habitEntrys
        .filter()
        .dateStringBetween(startDate, endDate)
        .watch(fireImmediately: true);
  }

  Stream<List<HabitEntry>> _watchMemEntries(String startDate, String endDate) async* {
    yield _getMemEntriesList(startDate, endDate);
    await for (final _ in _entriesStreamCtrl.stream) {
      yield _getMemEntriesList(startDate, endDate);
    }
  }

  List<HabitEntry> _getMemEntriesList(String startDate, String endDate) {
    return _memEntries.values
        .where((e) => e.dateString.compareTo(startDate) >= 0 && e.dateString.compareTo(endDate) <= 0)
        .toList();
  }

  Future<List<HabitEntry>> getEntriesForDateRange(String startDate, String endDate) async {
    if (_isar == null) {
      return _getMemEntriesList(startDate, endDate);
    }
    return _isar.habitEntrys
        .filter()
        .dateStringBetween(startDate, endDate)
        .findAll();
  }

  Future<Habit?> getHabitById(int id) async {
    if (_isar == null) return _memHabits[id];
    return _isar.habits.get(id);
  }

  Future<HabitEntry> recordEntryStatus({
    required int habitId,
    required String dateString,
    required HabitStatus status,
    int? valueCompleted,
    int? targetSnapshot,
    int? actualDurationMinutes,
    String? source,
    DateTime? completedAt,
    String? note,
  }) async {
    final now = DateTime.now();
    final habit = await getHabitById(habitId);
    final resolvedTargetSnapshot = targetSnapshot ?? habit?.target ?? 0;
    final resolvedActualDuration = actualDurationMinutes ?? valueCompleted ?? (status == HabitStatus.yes ? resolvedTargetSnapshot : 0);
    final resolvedSource = source ?? 'manual';
    final resolvedCompletedAt = completedAt ?? (status == HabitStatus.yes ? now : null);

    if (_isar == null) {
      final key = '$habitId-$dateString';
      final existing = _memEntries[key];
      final entry = existing ?? (HabitEntry()
        ..id = _memEntryIdCounter++
        ..habitId = habitId
        ..dateString = dateString
        ..createdAt = now);

      entry.status = status;
      if (valueCompleted != null) entry.valueCompleted = valueCompleted;
      entry.targetSnapshot = entry.targetSnapshot > 0 ? entry.targetSnapshot : resolvedTargetSnapshot;
      entry.actualDurationMinutes = resolvedActualDuration;
      entry.completedAt = resolvedCompletedAt;
      entry.source = resolvedSource;
      if (note != null) entry.note = note;
      entry.updatedAt = now;

      _memEntries[key] = entry;
      _entriesStreamCtrl.add(null);
      return entry;
    }

    return _isar.writeTxn(() async {
      final existing = await _isar.habitEntrys
          .filter()
          .habitIdEqualTo(habitId)
          .dateStringEqualTo(dateString)
          .findFirst();

      final entry = existing ?? (HabitEntry()
        ..habitId = habitId
        ..dateString = dateString
        ..createdAt = now);

      entry.status = status;
      if (valueCompleted != null) entry.valueCompleted = valueCompleted;
      entry.targetSnapshot = entry.targetSnapshot > 0 ? entry.targetSnapshot : resolvedTargetSnapshot;
      entry.actualDurationMinutes = resolvedActualDuration;
      entry.completedAt = resolvedCompletedAt;
      entry.source = resolvedSource;
      if (note != null) entry.note = note;
      entry.updatedAt = now;

      await _isar.habitEntrys.put(entry);
      return entry;
    });
  }

  Future<void> advanceProgression(int habitId) async {
    final habit = await getHabitById(habitId);
    if (habit == null) return;
    final totalSteps = habit.progressionSteps.length;
    if (totalSteps <= 0) return;
    habit.currentProgressionIndex = (habit.currentProgressionIndex + 1) % totalSteps;
    await upsertHabit(habit);
  }

  Future<HabitEntry> incrementHabitCount({
    required int habitId,
    required String dateString,
    required int delta,
  }) async {
    final habit = await getHabitById(habitId);
    final target = habit?.target ?? 1;
    final currentEntries = await getEntriesForDateRange(dateString, dateString);
    final existing = currentEntries.where((e) => e.habitId == habitId).firstOrNull;
    final currentVal = existing?.valueCompleted ?? 0;
    final newVal = (currentVal + delta).clamp(0, 9999);
    final newStatus = newVal >= target ? HabitStatus.yes : (newVal > 0 ? HabitStatus.unmarked : HabitStatus.unmarked);

    return recordEntryStatus(
      habitId: habitId,
      dateString: dateString,
      status: newStatus,
      valueCompleted: newVal,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Daily Fulfillment & Awareness Stats
  // ──────────────────────────────────────────────────────────────────────────

  Future<DailyFulfillmentSummary> getDailyFulfillment(String dateString) async {
    final habits = await getHabits();
    final totalCount = habits.length;

    int completed = 0;
    if (_isar == null) {
      for (final h in habits) {
        final entry = _memEntries['${h.id}-$dateString'];
        if (entry != null && entry.status == HabitStatus.yes) {
          completed++;
        }
      }
    } else {
      final entries = await _isar.habitEntrys
          .filter()
          .dateStringEqualTo(dateString)
          .statusEqualTo(HabitStatus.yes)
          .findAll();
      completed = entries.length;
    }

    return DailyFulfillmentSummary(
      dateString: dateString,
      completedCount: completed,
      totalCount: totalCount,
    );
  }

  Future<DailyReflection?> getDailyReflection(String dateString) async {
    if (_isar == null) {
      return _memReflections[dateString];
    }
    return _isar.dailyReflections.filter().dateStringEqualTo(dateString).findFirst();
  }

  Future<void> saveDailyReflection(DailyReflection reflection) async {
    reflection.updatedAt = DateTime.now();
    if (_isar == null) {
      _memReflections[reflection.dateString] = reflection;
      return;
    }
    await _isar.writeTxn(() => _isar.dailyReflections.put(reflection));
  }

  Future<List<RepetitionStat>> getWhatIRepeat() async {
    final habits = await getHabits();
    final stats = <RepetitionStat>[];

    for (final h in habits) {
      int days = 0;
      int minutes = 0;
      if (_isar == null) {
        for (final entry in _memEntries.values) {
          if (entry.habitId == h.id && entry.status == HabitStatus.yes) {
            days++;
            minutes += entry.valueCompleted > 0 ? entry.valueCompleted : h.target;
          }
        }
      } else {
        final entries = await _isar.habitEntrys
            .filter()
            .habitIdEqualTo(h.id)
            .statusEqualTo(HabitStatus.yes)
            .findAll();
        days = entries.length;
        for (final e in entries) {
          minutes += e.valueCompleted > 0 ? e.valueCompleted : h.target;
        }
      }
      stats.add(RepetitionStat(
        habit: h,
        totalDays: days,
        totalMinutes: minutes,
      ));
    }

    stats.sort((a, b) => b.totalDays.compareTo(a.totalDays));
    return stats;
  }

  Future<AwarenessStats> getAwarenessStats({int daysBack = 30}) async {
    final habits = await getHabits();
    final habitCompletedCounts = <int, int>{};
    final habitMissedCounts = <int, int>{};

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: daysBack));
    final startStr = _formatDate(startDate);
    final endStr = _formatDate(now);

    final entries = await getEntriesForDateRange(startStr, endStr);

    for (final e in entries) {
      if (e.status == HabitStatus.yes) {
        habitCompletedCounts[e.habitId] = (habitCompletedCounts[e.habitId] ?? 0) + 1;
      } else if (e.status == HabitStatus.no) {
        habitMissedCounts[e.habitId] = (habitMissedCounts[e.habitId] ?? 0) + 1;
      }
    }

    final consistent = <Habit>[];
    final neglected = <Habit>[];

    for (final h in habits) {
      final done = habitCompletedCounts[h.id] ?? 0;
      final missed = habitMissedCounts[h.id] ?? 0;
      if (done >= (daysBack * 0.4).round()) {
        consistent.add(h);
      } else if (missed > done || done == 0) {
        neglected.add(h);
      }
    }

    return AwarenessStats(
      habitCompletedCounts: habitCompletedCounts,
      habitMissedCounts: habitMissedCounts,
      neglectedHabits: neglected,
      consistentHabits: consistent,
    );
  }

  TimerSession? _memTimerSession;

  Future<TimerSession?> getActiveTimerSession() async {
    if (_isar == null) {
      return _memTimerSession;
    }
    return _isar.timerSessions.get(1);
  }

  Future<void> saveTimerSession(TimerSession session) async {
    session.id = 1;
    session.updatedAt = DateTime.now();
    if (_isar == null) {
      _memTimerSession = session;
      return;
    }
    await _isar.writeTxn(() => _isar.timerSessions.put(session));
  }

  Future<void> clearTimerSession() async {
    if (_isar == null) {
      _memTimerSession = null;
      return;
    }
    await _isar.writeTxn(() => _isar.timerSessions.delete(1));
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<Habit> _defaultHabits() => [
    Habit()
      ..id = 1
      ..name = 'Fokus / Deep Work'
      ..iconKey = '💻'
      ..target = 45
      ..unit = HabitUnit.min
      ..timerEnabled = true
      ..colorValue = 0xFF10B981 // Emerald
      ..orderIndex = 0
      ..createdAt = DateTime.now(),
    Habit()
      ..id = 2
      ..name = 'Olahraga / Exercise'
      ..iconKey = '🏃'
      ..target = 30
      ..unit = HabitUnit.min
      ..timerEnabled = true
      ..colorValue = 0xFFF97316 // Orange
      ..orderIndex = 1
      ..createdAt = DateTime.now(),
    Habit()
      ..id = 3
      ..name = 'Membaca / Reading'
      ..iconKey = '📚'
      ..target = 20
      ..unit = HabitUnit.min
      ..timerEnabled = true
      ..colorValue = 0xFF8B5CF6 // Purple
      ..orderIndex = 2
      ..createdAt = DateTime.now(),
    Habit()
      ..id = 4
      ..name = 'Meditasi / Mindfulness'
      ..iconKey = '🧘'
      ..target = 15
      ..unit = HabitUnit.min
      ..timerEnabled = true
      ..colorValue = 0xFF06B6D4 // Cyan
      ..orderIndex = 3
      ..createdAt = DateTime.now(),
    Habit()
      ..id = 5
      ..name = 'Belajar Bahasa'
      ..iconKey = '🌐'
      ..target = 20
      ..unit = HabitUnit.min
      ..timerEnabled = true
      ..colorValue = 0xFF3B82F6 // Blue
      ..orderIndex = 4
      ..createdAt = DateTime.now(),
  ];
}
