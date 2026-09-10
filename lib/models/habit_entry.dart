import 'package:isar/isar.dart';

part 'habit_entry.g.dart';

enum HabitStatus {
  unmarked,
  yes,
  no,
  skip,
}

@collection
class HabitEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late int habitId;

  /// Normalized date string in 'YYYY-MM-DD' format
  @Index()
  late String dateString;

  @enumerated
  HabitStatus status = HabitStatus.unmarked;

  int valueCompleted = 0; // minutes or count accomplished

  /// Target snapshot at the time of entry to ensure historical immutability (PRD 3 §59, §60)
  int targetSnapshot = 0;

  /// Actual duration in minutes spent on this habit
  int actualDurationMinutes = 0;

  /// Exact timestamp when this entry was marked completed
  DateTime? completedAt;

  /// Source of the completion ('manual', 'timer', 'focus_clock')
  String source = 'manual';

  String? note; // optional short reflection note

  DateTime? createdAt;

  late DateTime updatedAt;
}
