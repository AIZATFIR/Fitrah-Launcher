import 'package:isar/isar.dart';

part 'daily_reflection.g.dart';

@collection
class DailyReflection {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String dateString; // 'YYYY-MM-DD'

  String proudNote = '';
  int completedCount = 0;
  int totalCount = 0;

  late DateTime updatedAt;
}
