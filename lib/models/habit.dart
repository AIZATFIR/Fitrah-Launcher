import 'package:isar/isar.dart';

part 'habit.g.dart';

enum HabitUnit {
  min,
  count,
  binary,
}

enum ThingType {
  habit,    // Repeated action
  task,     // One-time action
  practice, // Time-based intentional activity
}

@collection
class Habit {
  Id id = Isar.autoIncrement;

  late String name;
  String iconKey = '🎯'; // emoji symbol
  int target = 20; // target quantity (e.g. 20 for 20m, 1 for 1 session)

  @enumerated
  HabitUnit unit = HabitUnit.min;

  @enumerated
  ThingType thingType = ThingType.habit;

  String category = 'General';
  String? preferredTime; // optional e.g. "Morning", "19:00"

  bool timerEnabled = true;
  late int colorValue;
  String recurrence = 'daily'; // 'daily' | 'weekdays' | 'custom'
  int orderIndex = 0;
  bool isArchived = false;

  late DateTime createdAt;
  DateTime? updatedAt;
}
