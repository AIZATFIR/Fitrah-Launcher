import 'dart:async';
import '../store/focus_store.dart';
import '../store/native_focus_store.dart';
import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';

import '../../core/time_math.dart';
import '../../models/habit.dart';
import '../../models/habit_entry.dart';
import '../../models/daily_reflection.dart';
import '../../models/timer_session.dart';
import '../../models/activity.dart';
import '../../models/terminal_focus_session.dart';

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

  double get ratio =>
      totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;
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
  SadarRepository(Isar? isar)
    : this.store(isar == null ? null : NativeFocusStore(isar));
  SadarRepository.store(this._isar) {
    if (_isar == null) {
      for (final h in _defaultHabits()) {
        _memHabits[h.id] = h;
      }
    }
  }

  final FocusStore? _isar;

  // In-Memory storage for tests / fallback
  final Map<int, Habit> _memHabits = {};
  final Map<String, HabitEntry> _memEntries = {}; // Key: "$habitId-$dateString"
  final Map<String, DailyReflection> _memReflections = {}; // Key: "$dateString"
  final Map<String, TerminalFocusSession> _memTerminalSessions = {};
  int _memHabitIdCounter = 100;
  int _memEntryIdCounter = 1000;

  final StreamController<void> _habitsStreamCtrl =
      StreamController<void>.broadcast();
  final StreamController<void> _entriesStreamCtrl =
      StreamController<void>.broadcast();

  // ──────────────────────────────────────────────────────────────────────────
  // Habits
  // ──────────────────────────────────────────────────────────────────────────

  Stream<List<Habit>> watchHabits() {
    if (_isar == null) {
      return _watchMemHabits();
    }
    return _isar.habits
        .select(
          where: (x) => x.isArchived == false,
          compare: (a, b) {
            final c0 = a.orderIndex.compareTo(b.orderIndex);
            if (c0 != 0) return c0;
            return a.createdAt.compareTo(b.createdAt);
          },
        )
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
        .select(
          where: (x) => x.isArchived == false,
          compare: (a, b) {
            final c0 = a.orderIndex.compareTo(b.orderIndex);
            if (c0 != 0) return c0;
            return a.createdAt.compareTo(b.createdAt);
          },
        )
        .findAll();
  }

  Future<List<Habit>> getArchivedHabits() async {
    if (_isar == null) {
      final list = _memHabits.values.where((h) => h.isArchived).toList();
      list.sort(
        (a, b) =>
            (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt),
      );
      return list;
    }
    return _isar.habits
        .select(
          where: (x) => x.isArchived == true,
          compare: (a, b) {
            return (b.updatedAt ?? b.createdAt).compareTo(
              a.updatedAt ?? a.createdAt,
            );
          },
        )
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

  Future<void> reorderHabits(List<int> habitIds) async {
    if (_isar == null) {
      for (int i = 0; i < habitIds.length; i++) {
        final h = _memHabits[habitIds[i]];
        if (h != null) {
          h.orderIndex = i;
        }
      }
      _habitsStreamCtrl.add(null);
      return;
    }
    await _isar.writeTxn(() async {
      for (int i = 0; i < habitIds.length; i++) {
        final h = await _isar.habits.get(habitIds[i]);
        if (h != null) {
          h.orderIndex = i;
          await _isar.habits.put(h);
        }
      }
    });
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

  Stream<List<HabitEntry>> watchEntriesForDateRange(
    String startDate,
    String endDate,
  ) {
    if (_isar == null) {
      return _watchMemEntries(startDate, endDate);
    }
    return _isar.habitEntrys
        .select(
          where: (x) =>
              x.dateString.compareTo(startDate) >= 0 &&
              x.dateString.compareTo(endDate) <= 0,
        )
        .watch(fireImmediately: true);
  }

  Stream<List<HabitEntry>> _watchMemEntries(
    String startDate,
    String endDate,
  ) async* {
    yield _getMemEntriesList(startDate, endDate);
    await for (final _ in _entriesStreamCtrl.stream) {
      yield _getMemEntriesList(startDate, endDate);
    }
  }

  List<HabitEntry> _getMemEntriesList(String startDate, String endDate) {
    return _memEntries.values
        .where(
          (e) =>
              e.dateString.compareTo(startDate) >= 0 &&
              e.dateString.compareTo(endDate) <= 0,
        )
        .toList();
  }

  Future<List<HabitEntry>> getEntriesForDateRange(
    String startDate,
    String endDate,
  ) async {
    if (_isar == null) {
      return _getMemEntriesList(startDate, endDate);
    }
    return _isar.habitEntrys
        .select(
          where: (x) =>
              x.dateString.compareTo(startDate) >= 0 &&
              x.dateString.compareTo(endDate) <= 0,
        )
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
    bool preserveDuration = false,
    String? source,
    DateTime? completedAt,
    String? note,
  }) async {
    if (actualDurationMinutes != null && actualDurationMinutes < 0) {
      throw ArgumentError('Negative duration');
    }
    return _mutateHabitEntry(habitId, dateString, (entry, habit, isNew) {
      if (entry.progressionCompletionSnapshotJson != null) {
        throw StateError('Gunakan aksi progression untuk membatalkan langkah.');
      }
      _retainLegacyTimerSeconds(entry);
      entry.status = status;
      if (valueCompleted != null) entry.valueCompleted = valueCompleted;
      if (entry.targetSnapshot <= 0) {
        entry.targetSnapshot = targetSnapshot ?? habit?.target ?? 0;
      }
      if ((!preserveDuration || isNew) && actualDurationMinutes != null) {
        entry.actualDurationMinutes = actualDurationMinutes;
      }
      entry.completedAt =
          completedAt ?? (status == HabitStatus.yes ? DateTime.now() : null);
      entry.source = source ?? 'manual';
      if (note != null) entry.note = note;
    });
  }

  void _retainLegacyTimerSeconds(HabitEntry entry) {
    // Retain recoverable timer evidence before a manual edit changes its source.
    if (entry.source == 'timer' &&
        entry.actualDurationSeconds == 0 &&
        entry.actualDurationMinutes > 0) {
      entry.actualDurationSeconds = entry.actualDurationMinutes * 60;
    }
  }

  Future<HabitEntry> _mutateHabitEntry(
    int habitId,
    String dateString,
    void Function(HabitEntry entry, Habit? habit, bool isNew) mutate,
  ) async {
    Future<HabitEntry> write() async {
      final habit = await getHabitById(habitId);
      final key = '$habitId-$dateString';
      final existing = _isar == null
          ? _memEntries[key]
          : await _isar.habitEntrys
                .select(
                  where: (x) =>
                      x.habitId == habitId && x.dateString == dateString,
                )
                .findFirst();
      final now = DateTime.now();
      final entry =
          existing ??
          (HabitEntry()
            ..habitId = habitId
            ..dateString = dateString
            ..createdAt = now);
      mutate(entry, habit, existing == null);
      entry.updatedAt = now;
      if (_isar == null) {
        if (existing == null) entry.id = _memEntryIdCounter++;
        _memEntries[key] = entry;
        _entriesStreamCtrl.add(null);
      } else {
        await _isar.habitEntrys.put(entry);
      }
      return entry;
    }

    return _isar == null ? write() : _isar.writeTxn(write);
  }

  Future<HabitEntry> updateHabitEntryNote({
    required int habitId,
    required String dateString,
    required String note,
  }) => _mutateHabitEntry(habitId, dateString, (entry, habit, isNew) {
    if (isNew && habit == null) throw StateError('Habit tidak tersedia.');
    entry.note = note;
  });

  Future<HabitEntry> setHabitCount({
    required int habitId,
    required String dateString,
    required int value,
  }) async {
    if (value < 0 || value > 9999) {
      throw ArgumentError('Masukkan jumlah 0–9999.');
    }
    return _writeHabitCount(habitId, dateString, (_) => value);
  }

  Future<HabitEntry> _writeHabitCount(
    int habitId,
    String dateString,
    int Function(int) nextValue,
  ) => _mutateHabitEntry(habitId, dateString, (entry, habit, isNew) {
    if (habit == null ||
        habit.isArchived ||
        habit.habitType == 'progression' ||
        habit.habitType == 'hybrid' ||
        habit.habitType == 'binary' ||
        (habit.habitType != 'count' && habit.unit != HabitUnit.count) ||
        habit.unit == HabitUnit.binary) {
      throw StateError('Habit jumlah tidak tersedia.');
    }
    final value = nextValue(entry.valueCompleted);
    _retainLegacyTimerSeconds(entry);
    if (entry.targetSnapshot <= 0) entry.targetSnapshot = habit.target;
    entry.valueCompleted = value;
    entry.status = entry.targetSnapshot > 0 && value >= entry.targetSnapshot
        ? HabitStatus.yes
        : HabitStatus.unmarked;
    entry.completedAt = entry.status == HabitStatus.yes ? DateTime.now() : null;
    entry.source = 'manual';
  });

  Future<void> advanceProgression(int habitId) async {
    final habit = await getHabitById(habitId);
    if (habit == null) return;
    final totalSteps = habit.progressionSteps.length;
    if (totalSteps <= 0) return;
    habit.currentProgressionIndex =
        (habit.currentProgressionIndex + 1) % totalSteps;
    await upsertHabit(habit);
  }

  /// Records the current progression step and advances the cursor once for a
  /// date. Duplicate taps return false and never advance another step.
  Future<bool> completeProgressionStep({
    required int habitId,
    required String dateString,
  }) async {
    if (_isar == null) {
      final habit = _memHabits[habitId];
      if (habit == null ||
          habit.isArchived ||
          habit.effectiveHabitType != 'progression') {
        throw StateError('Progression habit tidak tersedia.');
      }
      final key = '$habitId-$dateString';
      final existing = _memEntries[key];
      if (existing?.status == HabitStatus.yes) return false;

      final now = DateTime.now();
      final entry =
          existing ??
          (HabitEntry()
            ..id = _memEntryIdCounter++
            ..habitId = habitId
            ..dateString = dateString
            ..createdAt = now);
      final steps = habit.progressionSteps;
      final stepIndex = habit.currentProgressionIndex.clamp(
        0,
        steps.length - 1,
      );
      final step = steps[stepIndex];
      _retainLegacyTimerSeconds(entry);
      entry.progressionCompletionSnapshotJson = _progressionSnapshot(
        habit,
        entry,
        stepIndex,
      ).encode();
      entry
        ..status = HabitStatus.yes
        ..valueCompleted = step.target
        ..targetSnapshot = step.target
        ..completedAt = now
        ..source = 'manual'
        ..updatedAt = now;
      habit
        ..currentProgressionIndex = (stepIndex + 1) % steps.length
        ..updatedAt = now;
      _memEntries[key] = entry;
      _entriesStreamCtrl.add(null);
      return true;
    }

    return _isar.writeTxn(() async {
      final habit = await _isar.habits.get(habitId);
      if (habit == null ||
          habit.isArchived ||
          habit.effectiveHabitType != 'progression') {
        throw StateError('Progression habit tidak tersedia.');
      }
      final existing = await _isar.habitEntrys
          .select(
            where: (entry) =>
                entry.habitId == habitId && entry.dateString == dateString,
          )
          .findFirst();
      if (existing?.status == HabitStatus.yes) return false;

      final now = DateTime.now();
      final entry =
          existing ??
          (HabitEntry()
            ..habitId = habitId
            ..dateString = dateString
            ..createdAt = now);
      final steps = habit.progressionSteps;
      final stepIndex = habit.currentProgressionIndex.clamp(
        0,
        steps.length - 1,
      );
      final step = steps[stepIndex];
      _retainLegacyTimerSeconds(entry);
      entry.progressionCompletionSnapshotJson = _progressionSnapshot(
        habit,
        entry,
        stepIndex,
      ).encode();
      entry
        ..status = HabitStatus.yes
        ..valueCompleted = step.target
        ..targetSnapshot = step.target
        ..completedAt = now
        ..source = 'manual'
        ..updatedAt = now;
      habit
        ..currentProgressionIndex = (stepIndex + 1) % steps.length
        ..updatedAt = now;
      await _isar.habits.put(habit);
      await _isar.habitEntrys.put(entry);
      return true;
    });
  }

  ProgressionCompletionSnapshot _progressionSnapshot(
    Habit habit,
    HabitEntry entry,
    int stepIndex,
  ) {
    final step = habit.progressionSteps[stepIndex];
    return ProgressionCompletionSnapshot(
      stepIndex: stepIndex,
      nextIndex: (stepIndex + 1) % habit.progressionSteps.length,
      step: ProgressionStep.fromJson(step.toJson()),
      previousStatus: entry.status,
      previousValueCompleted: entry.valueCompleted,
      previousTargetSnapshot: entry.targetSnapshot,
      previousCompletedAt: entry.completedAt,
      previousSource: entry.source,
    );
  }

  /// Undo only the latest progression completion while the plan/cursor still
  /// match its saved snapshot. Other habit evidence and notes stay intact.
  Future<bool> undoProgressionStep({
    required int habitId,
    required String dateString,
  }) async {
    bool canUndo(Habit habit, HabitEntry entry, List<HabitEntry> history) {
      if (habit.isArchived ||
          habit.effectiveHabitType != 'progression' ||
          entry.status != HabitStatus.yes) {
        return false;
      }
      final snapshot = entry.progressionCompletionSnapshot;
      final completedAt = entry.completedAt;
      final steps = habit.progressionSteps;
      if (snapshot == null ||
          completedAt == null ||
          snapshot.stepIndex >= steps.length ||
          snapshot.nextIndex != (snapshot.stepIndex + 1) % steps.length ||
          habit.currentProgressionIndex != snapshot.nextIndex ||
          !_sameProgressionStep(steps[snapshot.stepIndex], snapshot.step)) {
        return false;
      }
      return !history.any(
        (other) =>
            other.id != entry.id &&
            other.habitId == habitId &&
            other.status == HabitStatus.yes &&
            other.progressionCompletionSnapshotJson != null &&
            other.completedAt != null &&
            !other.completedAt!.isBefore(completedAt),
      );
    }

    void restore(Habit habit, HabitEntry entry) {
      final snapshot = entry.progressionCompletionSnapshot!;
      entry
        ..status = snapshot.previousStatus
        ..valueCompleted = snapshot.previousValueCompleted
        ..targetSnapshot = snapshot.previousTargetSnapshot
        ..completedAt = snapshot.previousCompletedAt
        ..source = snapshot.previousSource
        ..progressionCompletionSnapshotJson = null
        ..updatedAt = DateTime.now();
      habit
        ..currentProgressionIndex = snapshot.stepIndex
        ..updatedAt = DateTime.now();
    }

    if (_isar == null) {
      final habit = _memHabits[habitId];
      final entry = _memEntries['$habitId-$dateString'];
      if (habit == null || entry == null) return false;
      final history = _memEntries.values
          .where((item) => item.habitId == habitId)
          .toList();
      if (!canUndo(habit, entry, history)) return false;
      restore(habit, entry);
      _habitsStreamCtrl.add(null);
      _entriesStreamCtrl.add(null);
      return true;
    }

    return _isar.writeTxn(() async {
      final habit = await _isar.habits.get(habitId);
      final entry = await _isar.habitEntrys
          .select(
            where: (item) =>
                item.habitId == habitId && item.dateString == dateString,
          )
          .findFirst();
      if (habit == null || entry == null) return false;
      final history = await _isar.habitEntrys
          .select(where: (item) => item.habitId == habitId)
          .findAll();
      if (!canUndo(habit, entry, history)) return false;
      restore(habit, entry);
      await _isar.habits.put(habit);
      await _isar.habitEntrys.put(entry);
      return true;
    });
  }

  bool _sameProgressionStep(ProgressionStep a, ProgressionStep b) =>
      a.dayName == b.dayName &&
      a.title == b.title &&
      a.target == b.target &&
      a.unit == b.unit &&
      a.isRest == b.isRest;

  Future<HabitEntry> incrementHabitCount({
    required int habitId,
    required String dateString,
    required int delta,
  }) async {
    return _writeHabitCount(
      habitId,
      dateString,
      (current) => (current + delta).clamp(0, 9999),
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
          .select(
            where: (x) =>
                x.dateString == dateString && x.status == HabitStatus.yes,
          )
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
    return _isar.dailyReflections
        .select(where: (x) => x.dateString == dateString)
        .findFirst();
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
            minutes += entry.valueCompleted > 0
                ? entry.valueCompleted
                : h.target;
          }
        }
      } else {
        final entries = await _isar.habitEntrys
            .select(
              where: (x) => x.habitId == h.id && x.status == HabitStatus.yes,
            )
            .findAll();
        days = entries.length;
        for (final e in entries) {
          minutes += e.valueCompleted > 0 ? e.valueCompleted : h.target;
        }
      }
      stats.add(
        RepetitionStat(habit: h, totalDays: days, totalMinutes: minutes),
      );
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
        habitCompletedCounts[e.habitId] =
            (habitCompletedCounts[e.habitId] ?? 0) + 1;
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
  TimerSession? _observedSession;
  bool _sameSession(TimerSession a, TimerSession b) =>
      a.startedAt == b.startedAt &&
      a.habitId == b.habitId &&
      a.sourceKindIndex == b.sourceKindIndex &&
      a.activityId == b.activityId;
  void _requireObservedSession(TimerSession? current) {
    if (current == null ||
        _observedSession == null ||
        !_sameSession(current, _observedSession!) ||
        current.revision != _observedSession!.revision) {
      throw StateError('The active session changed. Reopen the timer.');
    }
  }

  Future<TimerSession?> getActiveTimerSession() async {
    if (_isar == null) {
      return _memTimerSession;
    }
    _observedSession = await _isar.timerSessions.get(1);
    return _observedSession;
  }

  Future<List<TerminalFocusSession>> getTerminalFocusSessionsForDate(
    String date,
  ) async {
    final rows = _isar == null
        ? _memTerminalSessions.values.toList()
        : await _isar.terminalFocusSessions.all();
    rows.removeWhere((row) => _dateOnly(row.completedAt) != date);
    rows.sort((a, b) => a.completedAt.compareTo(b.completedAt));
    return rows;
  }

  Stream<List<TerminalFocusSession>> watchTerminalFocusSessionsForDate(
    String date,
  ) async* {
    yield await getTerminalFocusSessionsForDate(date);
    if (_isar == null) {
      await for (final _ in _entriesStreamCtrl.stream) {
        yield await getTerminalFocusSessionsForDate(date);
      }
    } else {
      await for (final _ in _isar.watch()) {
        yield await getTerminalFocusSessionsForDate(date);
      }
    }
  }

  String _dateOnly(DateTime value) => _formatDate(value);

  Future<void> saveTimerSession(TimerSession session) async {
    session.id = 1;
    session.sessionId ??= const Uuid().v4();
    if (_isar == null) {
      final current = _memTimerSession;
      if (current != null) {
        if (!_sameSession(current, session)) {
          throw StateError('An active timer session already exists.');
        }
        if (session.revision != current.revision) {
          throw StateError('This timer checkpoint is stale. Reopen the timer.');
        }
        session.revision = current.revision + 1;
      } else {
        session.revision++;
      }
      session.updatedAt = DateTime.now();
      _memTimerSession = session;
      return;
    }
    await _isar.writeTxn(() async {
      final current = await _isar.timerSessions.get(1);
      if (current != null) {
        _requireObservedSession(current);
        if (!_sameSession(current, session)) {
          throw StateError('An active timer session already exists.');
        }
        if (session.revision != current.revision) {
          throw StateError('This timer checkpoint is stale. Reopen the timer.');
        }
        session.revision = current.revision + 1;
      } else if (_observedSession != null) {
        throw StateError('This timer session already ended.');
      } else {
        session.revision++;
      }
      session.updatedAt = DateTime.now();
      if (current == null) await _bindScheduledHabit(session);
      await putTimerSessionInTxn(session);
    });
    _observedSession = await _isar.timerSessions.get(1);
  }

  /// Creates the QuickTimer Activity and active session as one durable write.
  Future<int> createActivityAndStartTimerSession(
    Activity activity,
    TimerSession session,
  ) async {
    if (_isar == null) {
      throw StateError('Atomic Activity timer start requires durable storage.');
    }
    session.id = 1;
    session.sessionId ??= const Uuid().v4();
    session.updatedAt = DateTime.now();
    return _isar.writeTxn(() async {
      if (await _isar.timerSessions.get(1) != null) {
        throw StateError('An active timer session already exists.');
      }
      session.revision++;
      final activityId = await _isar.activitys.put(activity);
      session.activityId = activityId;
      await _bindScheduledHabit(session);
      await putTimerSessionInTxn(session);
      _observedSession = session;
      return activityId;
    });
  }

  Future<void> _bindScheduledHabit(TimerSession session) async {
    if (session.activityId == null) return;
    final activity = await _isar!.activitys.get(session.activityId!);
    if (activity == null) {
      throw StateError('The scheduled Activity no longer exists.');
    }
    final id = activity.habitId;
    if (id == null) return;
    final habit = await _isar.habits.get(id);
    if (habit == null ||
        habit.isArchived ||
        habit.habitType != 'timed' ||
        habit.unit != HabitUnit.min ||
        habit.target <= 0) {
      throw StateError('The scheduled timed habit is unavailable.');
    }
    session.habitId = id;
    session.habitTargetSnapshot = habit.target;
  }

  void _applyTimerContribution(
    HabitEntry entry,
    int seconds,
    int target,
    DateTime at, {
    bool timed = true,
    int? completedUnitCount,
  }) {
    final previous = entry.actualDurationSeconds > 0
        ? entry.actualDurationSeconds
        : entry.source == 'timer'
        ? entry.actualDurationMinutes * 60
        : 0;
    final total = previous + seconds;
    if (entry.targetSnapshot <= 0) entry.targetSnapshot = target;
    final manual =
        entry.source != 'timer' && entry.status != HabitStatus.unmarked;
    if (timed && !manual) {
      entry.status =
          total >= entry.targetSnapshot * 60 && entry.targetSnapshot > 0
          ? HabitStatus.yes
          : HabitStatus.unmarked;
      entry.valueCompleted = total ~/ 60;
    }
    if (completedUnitCount != null && !manual) {
      entry.valueCompleted = (entry.valueCompleted + completedUnitCount).clamp(
        0,
        target,
      );
      entry.status = target > 0 && entry.valueCompleted >= target
          ? HabitStatus.yes
          : HabitStatus.unmarked;
      entry.source = 'timer';
    }
    entry.actualDurationSeconds = total;
    entry.actualDurationMinutes = total ~/ 60;
    entry.completedAt = at;
    if (timed && !manual) entry.source = 'timer';
    entry.updatedAt = at;
  }

  Future<void> putTimerSessionInTxn(TimerSession session) async {
    await _isar!.timerSessions.put(session);
  }

  TerminalFocusSession _terminalRow(
    TimerSession session, {
    required int seconds,
    required DateTime completedAt,
    required TerminalSessionStatus status,
  }) {
    final row = TerminalFocusSession()
      ..sessionId =
          session.sessionId ??
          'legacy-${session.updatedAt.microsecondsSinceEpoch}'
      ..sourceKind =
          (session.sourceKind ??
                  (session.habitId > 0
                      ? TimerSessionSourceKind.habit
                      : TimerSessionSourceKind.free))
              .name
      ..titleSnapshot = session.habitName.isEmpty
          ? 'Fokus bebas'
          : session.habitName
      ..sourceIdentity = session.sourceIdentity
      ..goalId = session.goalId
      ..goalTitleSnapshot = session.goalTitleSnapshot
      ..habitId = session.habitId > 0 ? session.habitId : null
      ..activityId = session.activityId
      ..startedAt = session.startedAt ?? completedAt
      ..completedAt = completedAt
      ..actualDurationSeconds = status == TerminalSessionStatus.cancelled
          ? 0
          : seconds
      ..status = status;
    row.validate();
    return row;
  }

  Future<void> _putTerminalInTxn(TerminalFocusSession row) async {
    if (_isar == null) {
      _memTerminalSessions.putIfAbsent(row.sessionId, () => row);
    } else {
      final duplicate = await _isar.terminalFocusSessions
          .select(where: (item) => item.sessionId == row.sessionId)
          .findFirst();
      if (duplicate == null) await _isar.terminalFocusSessions.put(row);
    }
  }

  Future<void> clearTimerSession() async {
    if (_isar == null) {
      final current = _memTimerSession;
      if (current != null) {
        final row = _terminalRow(
          current,
          seconds: 0,
          completedAt: DateTime.now(),
          status: TerminalSessionStatus.cancelled,
        );
        _memTerminalSessions.putIfAbsent(row.sessionId, () => row);
        _entriesStreamCtrl.add(null);
      }
      _memTimerSession = null;
      return;
    }
    await _isar.writeTxn(() async {
      final current = await _isar.timerSessions.get(1);
      if (current == null) return;
      _requireObservedSession(current);
      await _putTerminalInTxn(
        _terminalRow(
          current,
          seconds: 0,
          completedAt: DateTime.now(),
          status: TerminalSessionStatus.cancelled,
        ),
      );
      await _isar.timerSessions.delete(1);
    });
    _observedSession = null;
  }

  /// Commits a completed focus session and removes its active record together.
  /// A failed native write leaves the session available for recovery on restart.
  Future<HabitEntry> completeTimerSession({
    required int habitId,
    String? sessionId,
    required String dateString,
    required int actualDurationMinutes,
    int? actualDurationSeconds,
    required int targetSnapshot,
    int? completedUnitCount,
    required DateTime completedAt,
  }) async {
    final now = DateTime.now();
    final secondsToAdd = actualDurationSeconds ?? actualDurationMinutes * 60;
    if (secondsToAdd < 0) throw ArgumentError("Negative duration");
    final habit = await getHabitById(habitId);
    final timed =
        habit == null ||
        (habit.habitType == 'timed' && habit.unit == HabitUnit.min);

    if (_isar == null) {
      final active = _memTimerSession;
      final stableId = sessionId ?? active?.sessionId;
      if (stableId != null && _memTerminalSessions.containsKey(stableId)) {
        if (active?.sessionId == stableId) _memTimerSession = null;
        final committedEntry = _memEntries['$habitId-$dateString'];
        if (committedEntry != null) return committedEntry;
      }
      if (active != null) {
        final terminal = _terminalRow(
          active,
          seconds: secondsToAdd,
          completedAt: completedAt,
          status: TerminalSessionStatus.completed,
        );
        _memTerminalSessions[terminal.sessionId] = terminal;
      }
      final key = '$habitId-$dateString';
      final existing = _memEntries[key];
      final entry =
          existing ??
          (HabitEntry()
            ..id = _memEntryIdCounter++
            ..habitId = habitId
            ..dateString = dateString
            ..createdAt = now);
      _applyTimerContribution(
        entry,
        secondsToAdd,
        targetSnapshot,
        completedAt,
        timed: timed,
        completedUnitCount: completedUnitCount,
      );
      _memEntries[key] = entry;
      _memTimerSession = null;
      _entriesStreamCtrl.add(null);
      return entry;
    }

    return _isar.writeTxn(() async {
      final current = await _isar.timerSessions.get(1);
      final stableId = sessionId ?? current?.sessionId;
      if (stableId != null) {
        final committed = await _isar.terminalFocusSessions
            .select(where: (row) => row.sessionId == stableId)
            .findFirst();
        if (committed != null) {
          final committedEntry = await _isar.habitEntrys
              .select(
                where: (row) =>
                    row.habitId == habitId && row.dateString == dateString,
              )
              .findFirst();
          if (current?.sessionId == stableId) {
            _requireObservedSession(current);
            await _isar.timerSessions.delete(1);
            _observedSession = null;
          }
          if (committedEntry != null) return committedEntry;
        }
      }
      final existing = await _isar.habitEntrys
          .select(
            where: (x) => x.habitId == habitId && x.dateString == dateString,
          )
          .findFirst();

      if (current == null) {
        if (existing != null) {
          _observedSession = null;
          return existing;
        }
        throw StateError('This timer session already ended.');
      }
      _requireObservedSession(current);
      final entry =
          existing ??
          (HabitEntry()
            ..habitId = habitId
            ..dateString = dateString
            ..createdAt = now);
      _applyTimerContribution(
        entry,
        secondsToAdd,
        targetSnapshot,
        completedAt,
        timed: timed,
        completedUnitCount: completedUnitCount,
      );

      await _isar.habitEntrys.put(entry);
      await _putTerminalInTxn(
        _terminalRow(
          current,
          seconds: secondsToAdd,
          completedAt: completedAt,
          status: TerminalSessionStatus.completed,
        ),
      );
      await _isar.timerSessions.delete(1);
      _observedSession = null;
      return entry;
    });
  }

  /// Marks only the Activity linked by ID and clears its timer in one commit.
  Future<void> completeActivityTimerSession({
    required int activityId,
    required int actualDurationSeconds,
    required DateTime completedAt,
  }) async {
    if (_isar == null) {
      throw StateError('Activity timer completion requires durable storage.');
    }
    await _isar.writeTxn(() async {
      final session = await _isar.timerSessions.get(1);
      if (session == null) return;
      _requireObservedSession(session);
      final terminal = _terminalRow(
        session,
        seconds: actualDurationSeconds,
        completedAt: completedAt,
        status: TerminalSessionStatus.completed,
      );
      final alreadyCommitted = await _isar.terminalFocusSessions
          .select(where: (row) => row.sessionId == terminal.sessionId)
          .findFirst();
      if (alreadyCommitted != null) {
        await _isar.timerSessions.delete(1);
        return;
      }
      final activity = await _isar.activitys.get(activityId);
      if (activity == null) {
        throw StateError('The linked Activity no longer exists.');
      }
      if (session.activityId != activityId) {
        throw StateError('The Activity does not match the active session.');
      }
      if (actualDurationSeconds < 0) throw ArgumentError('Negative duration');
      if (session.habitId > 0) {
        final date =
            session.attributionLocalDate ??
            (session.startedAt ?? completedAt).toIso8601String().substring(
              0,
              10,
            );
        final existing = await _isar.habitEntrys
            .select(
              where: (e) =>
                  e.habitId == session.habitId && e.dateString == date,
            )
            .findFirst();
        final entry =
            existing ??
            (HabitEntry()
              ..habitId = session.habitId
              ..dateString = date
              ..createdAt = completedAt);
        final target =
            session.habitTargetSnapshot ?? existing?.targetSnapshot ?? 0;
        if (target <= 0) {
          throw StateError('The habit target snapshot is missing.');
        }
        _applyTimerContribution(
          entry,
          actualDurationSeconds,
          target,
          completedAt,
        );
        await _isar.habitEntrys.put(entry);
      }
      final startedAt = session.startedAt ?? completedAt;
      final originalHabitId = session.habitId > 0 ? session.habitId : null;
      final sourceChanged = activity.habitId != originalHabitId;
      if (sourceChanged ||
          (activity.recurrence != 'none' &&
              DateTime(
                    activity.date.year,
                    activity.date.month,
                    activity.date.day,
                  ) !=
                  DateTime(startedAt.year, startedAt.month, startedAt.day))) {
        final occurrence = Activity()
          ..habitId = originalHabitId
          ..presetId = activity.presetId
          ..iconKey = activity.iconKey
          ..title = activity.title
          ..startMinute = activity.startMinute
          ..endMinute = activity.endMinute
          ..ampmHalf = activity.ampmHalf
          ..date = DateTime(startedAt.year, startedAt.month, startedAt.day)
          ..description = activity.description
          ..colorValue = activity.colorValue
          ..recurrence = 'none'
          ..groupId = activity.groupId
          ..importance = activity.importance
          ..deadline = activity.deadline
          ..isCompleted = true
          ..isLocked = activity.isLocked
          ..excludedDates = [...activity.excludedDates]
          ..actualDurationSeconds = actualDurationSeconds
          ..createdAt = completedAt
          ..updatedAt = completedAt;
        await _isar.activitys.put(occurrence);
      } else {
        activity
          ..isCompleted = true
          ..actualDurationSeconds =
              activity.actualDurationSeconds + actualDurationSeconds
          ..updatedAt = completedAt;
        await _isar.activitys.put(activity);
      }
      await _putTerminalInTxn(terminal);
      await _isar.timerSessions.delete(1);
    });
    _observedSession = null;
  }

  /// Creates the Home preset's completed Activity and clears its session atomically.
  Future<void> completePresetTimerSession({
    required String title,
    required String? identity,
    required int? colorValue,
    required DateTime startedAt,
    required int actualDurationSeconds,
    required DateTime completedAt,
  }) async {
    if (_isar == null) {
      throw StateError('Preset timer completion requires durable storage.');
    }
    await _isar.writeTxn(() async {
      final session = await _isar.timerSessions.get(1);
      if (session == null) return;
      _requireObservedSession(session);
      if (session.sourceKind != TimerSessionSourceKind.preset) {
        throw StateError('The active timer is not a Home preset session.');
      }
      final terminal = _terminalRow(
        session,
        seconds: actualDurationSeconds,
        completedAt: completedAt,
        status: TerminalSessionStatus.completed,
      );
      final alreadyCommitted = await _isar.terminalFocusSessions
          .select(where: (row) => row.sessionId == terminal.sessionId)
          .findFirst();
      if (alreadyCommitted != null) {
        await _isar.timerSessions.delete(1);
        return;
      }
      final spanMinutes = (actualDurationSeconds / 60).ceil().clamp(1, 1440);
      final endAt = startedAt.add(Duration(minutes: spanMinutes));
      final segments = splitSpan(startedAt, endAt);
      final groupId = segments.length > 1
          ? 'focus_${startedAt.microsecondsSinceEpoch}'
          : null;
      for (var index = 0; index < segments.length; index++) {
        final segment = segments[index];
        final activity = Activity()
          ..title = title
          ..startMinute = segment.start
          ..endMinute = segment.end
          ..ampmHalf = segment.half
          ..date = segment.date
          ..colorValue = colorValue ?? 0xFFE8C07D
          ..description = identity == null || identity.isEmpty
              ? ''
              : 'Identitas: $identity'
          ..recurrence = 'none'
          ..groupId = groupId
          ..isCompleted = true
          ..actualDurationSeconds = index == 0 ? actualDurationSeconds : 0
          ..createdAt = completedAt
          ..updatedAt = completedAt;
        await _isar.activitys.put(activity);
      }
      await _putTerminalInTxn(terminal);
      await _isar.timerSessions.delete(1);
    });
    _observedSession = null;
  }

  Future<void> completeFreeTimerSession({
    required int actualDurationSeconds,
    required DateTime completedAt,
  }) async {
    if (actualDurationSeconds < 0) throw ArgumentError('Negative duration');
    if (_isar == null) {
      final session = _memTimerSession;
      if (session == null) return;
      final row = _terminalRow(
        session,
        seconds: actualDurationSeconds,
        completedAt: completedAt,
        status: TerminalSessionStatus.completed,
      );
      _memTerminalSessions.putIfAbsent(row.sessionId, () => row);
      _memTimerSession = null;
      _entriesStreamCtrl.add(null);
      return;
    }
    await _isar.writeTxn(() async {
      final session = await _isar.timerSessions.get(1);
      if (session == null) return;
      _requireObservedSession(session);
      final terminal = _terminalRow(
        session,
        seconds: actualDurationSeconds,
        completedAt: completedAt,
        status: TerminalSessionStatus.completed,
      );
      final existing = await _isar.terminalFocusSessions
          .select(where: (row) => row.sessionId == terminal.sessionId)
          .findFirst();
      if (existing == null) await _putTerminalInTxn(terminal);
      await _isar.timerSessions.delete(1);
    });
    _observedSession = null;
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
      ..iconKey = 'computer'
      ..target = 45
      ..unit = HabitUnit.min
      ..timerEnabled = true
      ..colorValue =
          0xFF48C774 // Vibrant Green
      ..orderIndex = 0
      ..createdAt = DateTime.now(),
    Habit()
      ..id = 2
      ..name = 'Olahraga / Exercise'
      ..iconKey = 'running'
      ..target = 30
      ..unit = HabitUnit.min
      ..timerEnabled = true
      ..colorValue = 0xFF48C774
      ..orderIndex = 1
      ..createdAt = DateTime.now(),
    Habit()
      ..id = 3
      ..name = '1 ayat Al quran (smkdutalib, jalan yg benar, pencerahan)'
      ..iconKey = 'prayer'
      ..target = 10
      ..unit = HabitUnit.min
      ..timerEnabled = true
      ..colorValue = 0xFF48C774
      ..orderIndex = 2
      ..createdAt = DateTime.now(),
    Habit()
      ..id = 4
      ..name = '10 min Open Laptop and throw my phone'
      ..iconKey = 'computer'
      ..target = 10
      ..unit = HabitUnit.min
      ..timerEnabled = true
      ..colorValue = 0xFF48C774
      ..orderIndex = 3
      ..createdAt = DateTime.now(),
    Habit()
      ..id = 5
      ..name =
          '1 module AI 50% - Dicoding - Portofolio, skill, knowledge, advantage'
      ..iconKey = 'study'
      ..target = 45
      ..unit = HabitUnit.min
      ..timerEnabled = true
      ..colorValue = 0xFF48C774
      ..orderIndex = 4
      ..createdAt = DateTime.now(),
    Habit()
      ..id = 6
      ..name = 'Grind Physique (abs, shoulder, Hand group, back)'
      ..iconKey = 'strength'
      ..target = 30
      ..unit = HabitUnit.min
      ..timerEnabled = true
      ..colorValue = 0xFF48C774
      ..orderIndex = 5
      ..createdAt = DateTime.now(),
    Habit()
      ..id = 7
      ..name = '1 Kalaam harian (Paham Rahmat tuhan)'
      ..iconKey = 'reflection'
      ..target = 15
      ..unit = HabitUnit.min
      ..timerEnabled = true
      ..colorValue = 0xFF48C774
      ..orderIndex = 6
      ..createdAt = DateTime.now(),
    Habit()
      ..id = 8
      ..name = 'Baca 5 halaman (growth, lebih pintar)'
      ..iconKey = 'study'
      ..target = 20
      ..unit = HabitUnit.min
      ..timerEnabled = true
      ..colorValue = 0xFF48C774
      ..orderIndex = 7
      ..createdAt = DateTime.now(),
    Habit()
      ..id = 9
      ..name = 'Tonton 2 Watch later edukasi (growth, lebih pintar)'
      ..iconKey = 'thinking'
      ..target = 25
      ..unit = HabitUnit.min
      ..timerEnabled = true
      ..colorValue = 0xFF48C774
      ..orderIndex = 8
      ..createdAt = DateTime.now(),
  ];
}
