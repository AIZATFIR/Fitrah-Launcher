import 'package:isar_community/isar.dart';

part 'timer_session.g.dart';

enum TimerStateStatus { idle, running, paused, completed }

enum TimerSessionSourceKind { habit, free, preset, activity }

@collection
class TimerSession {
  Id id = 1; // Singleton active session ID

  int habitId = 0;
  String habitName = '';
  int? sourceKindIndex;
  int? activityId;

  @ignore
  TimerSessionSourceKind? get sourceKind =>
      sourceKindIndex == null ||
          sourceKindIndex! < 0 ||
          sourceKindIndex! >= TimerSessionSourceKind.values.length
      ? null
      : TimerSessionSourceKind.values[sourceKindIndex!];

  @ignore
  bool get hasValidSourceKind =>
      sourceKindIndex == null ||
      (sourceKindIndex! >= 0 &&
          sourceKindIndex! < TimerSessionSourceKind.values.length);

  set sourceKind(TimerSessionSourceKind? value) =>
      sourceKindIndex = value?.index;
  String? sourceIdentity;
  int? sourceColorValue;
  int targetSeconds = 0;
  DateTime? startedAt;
  DateTime? runningSince;
  DateTime? pausedAt;
  int accumulatedDurationSeconds = 0;

  @enumerated
  TimerStateStatus status = TimerStateStatus.idle;

  late DateTime updatedAt;
}
