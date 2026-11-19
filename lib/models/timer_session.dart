import 'package:isar_community/isar.dart';

part 'timer_session.g.dart';

enum TimerStateStatus { idle, running, paused, completed }

// Append new values to keep persisted integer indexes stable.
enum TimerSessionSourceKind { habit, free, preset, activity, yptHabit }

@collection
class TimerSession {
  Id id = 1; // Singleton active session ID

  int habitId = 0;
  String? sessionId;
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
  String? goalId;
  String? goalTitleSnapshot;
  int targetSeconds = 0;
  int hybridSetCount = 0;
  int hybridWorkSeconds = 0;
  int hybridRestSeconds = 0;

  /// Monotonic compare-and-swap token for durable active-session writes.
  int revision = 0;

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
