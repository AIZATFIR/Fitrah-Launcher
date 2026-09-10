import 'package:isar/isar.dart';

part 'timer_session.g.dart';

enum TimerStateStatus {
  idle,
  running,
  paused,
  completed,
}

@collection
class TimerSession {
  Id id = 1; // Singleton active session ID

  int habitId = 0;
  String habitName = '';
  int targetSeconds = 0;
  DateTime? startedAt;
  DateTime? pausedAt;
  int accumulatedDurationSeconds = 0;

  @enumerated
  TimerStateStatus status = TimerStateStatus.idle;

  late DateTime updatedAt;
}
