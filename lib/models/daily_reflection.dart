import 'package:isar/isar.dart';

part 'daily_reflection.g.dart';

enum ReflectionFeeling {
  notSatisfied,
  okay,
  good,
  proud,
}

@collection
class DailyReflection {
  Id id = Isar.autoIncrement;

  @Index()
  late String dateString; // 'YYYY-MM-DD'

  @enumerated
  ReflectionFeeling feeling = ReflectionFeeling.good;

  String proudOfToday = ''; // "What did I do today that I'm glad I did?"
  String note = ''; // Optional reflection note

  int completedCount = 0;
  int totalCount = 0;

  late DateTime updatedAt;
}
