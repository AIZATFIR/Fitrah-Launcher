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

  String? note; // optional short reflection note

  late DateTime updatedAt;
}
