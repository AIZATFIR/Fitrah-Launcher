import 'focus_intent.dart';
import '../models/habit.dart';
import '../models/habit_entry.dart';
import '../models/task.dart';

enum IntentActionKind {
  timed,
  hybrid,
  progression,
  binary,
  count,
  task,
  unsupported,
  unavailable,
}

class TodayIntentProjection {
  const TodayIntentProjection({
    required this.title,
    required this.kind,
    this.habit,
    this.habitEntry,
    this.task,
    this.completed = false,
  });
  final String title;
  final IntentActionKind kind;
  final Habit? habit;
  final HabitEntry? habitEntry;
  final Task? task;
  final bool completed;
  static TodayIntentProjection? calculate({
    required IntentState state,
    required String actualDate,
    required List<Habit> habits,
    required List<Task> tasks,
    required List<HabitEntry> entries,
  }) {
    final choice = state.selectionFor(actualDate);
    final source = state.sourceFor(choice?.sourceId);
    if (source == null) return null;
    if (source.sourceStoreId != state.sourceStoreId) {
      return const TodayIntentProjection(
        title: 'Pilihan dari penyimpanan lain tidak tersedia',
        kind: IntentActionKind.unavailable,
      );
    }
    if (source.type == IntentSourceType.task) {
      final task = tasks.where((t) => t.id == source.legacyId).firstOrNull;
      return task == null
          ? const TodayIntentProjection(
              title: 'Tugas tidak tersedia',
              kind: IntentActionKind.unavailable,
            )
          : TodayIntentProjection(
              title: task.title,
              kind: IntentActionKind.task,
              task: task,
              completed: task.isCompleted,
            );
    }
    final habit = habits.where((h) => h.id == source.legacyId).firstOrNull;
    if (habit == null || habit.isArchived) {
      return const TodayIntentProjection(
        title: 'Habit tidak tersedia atau diarsipkan',
        kind: IntentActionKind.unavailable,
      );
    }
    final entry = entries
        .where((e) => e.habitId == habit.id && e.dateString == actualDate)
        .firstOrNull;
    final completed =
        entry?.status == HabitStatus.yes ||
        (habit.unit == HabitUnit.count &&
            (entry?.valueCompleted ?? 0) >=
                ((entry?.targetSnapshot ?? 0) > 0
                    ? entry!.targetSnapshot
                    : habit.target));
    final type = habit.habitType;
    final kind = type == 'hybrid'
        ? IntentActionKind.hybrid
        : type == 'progression'
        ? IntentActionKind.progression
        : (type == 'binary' || habit.unit == HabitUnit.binary)
        ? IntentActionKind.binary
        : (type == 'count' || habit.unit == HabitUnit.count)
        ? IntentActionKind.count
        : type == 'timed' && habit.unit == HabitUnit.min
        ? IntentActionKind.timed
        : IntentActionKind.unsupported;
    return TodayIntentProjection(
      title: habit.name,
      kind: kind,
      habit: habit,
      habitEntry: entry,
      completed: completed,
    );
  }
}
