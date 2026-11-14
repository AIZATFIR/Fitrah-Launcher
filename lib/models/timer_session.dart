import 'package:isar_community/isar.dart';

part 'timer_session.g.dart';

enum TimerStateStatus { idle, running, paused, completed }

// Append new values to keep persisted integer indexes stable.
enum TimerSessionSourceKind { habit, free, preset, activity, yptHabit }

@collection
class TimerSession {
  Id id = 1; // Singleton active session ID

  int habitId = 0;
  int? habitTargetSnapshot;
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
  String? attributionLocalDate;
  DateTime? runningSince;
  DateTime? pausedAt;
  int? clockBootCount;
  int? clockElapsedRealtimeMillis;
  int accumulatedDurationSeconds = 0;

  @enumerated
  TimerStateStatus status = TimerStateStatus.idle;

  late DateTime updatedAt;
}
