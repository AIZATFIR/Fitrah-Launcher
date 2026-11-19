import 'dart:convert';
import 'package:isar_community/isar.dart';

import 'habit.dart';

part 'habit_entry.g.dart';

enum HabitStatus { unmarked, yes, no, skip }

class ProgressionCompletionSnapshot {
  const ProgressionCompletionSnapshot({
    required this.stepIndex,
    required this.nextIndex,
    required this.step,
    required this.previousStatus,
    required this.previousValueCompleted,
    required this.previousTargetSnapshot,
    required this.previousCompletedAt,
    required this.previousSource,
  });

  final int stepIndex;
  final int nextIndex;
  final ProgressionStep step;
  final HabitStatus previousStatus;
  final int previousValueCompleted;
  final int previousTargetSnapshot;
  final DateTime? previousCompletedAt;
  final String previousSource;

  String encode() => jsonEncode({
    'version': 1,
    'stepIndex': stepIndex,
    'nextIndex': nextIndex,
    'step': step.toJson(),
    'previousStatus': previousStatus.name,
    'previousValueCompleted': previousValueCompleted,
    'previousTargetSnapshot': previousTargetSnapshot,
    'previousCompletedAt': previousCompletedAt?.toIso8601String(),
    'previousSource': previousSource,
  });

  static ProgressionCompletionSnapshot decode(String value) {
    final map = jsonDecode(value);
    if (map is! Map<String, dynamic> || map['version'] != 1) {
      throw const FormatException('Invalid progression completion snapshot.');
    }
    final stepMap = map['step'];
    if (stepMap is! Map<String, dynamic>) {
      throw const FormatException('Invalid progression step snapshot.');
    }
    final statusName = map['previousStatus'];
    final status = HabitStatus.values
        .where((x) => x.name == statusName)
        .firstOrNull;
    if (status == null) {
      throw const FormatException('Invalid previous progression status.');
    }
    final completedAt = map['previousCompletedAt'];
    return ProgressionCompletionSnapshot(
      stepIndex: _snapshotInt(map['stepIndex']),
      nextIndex: _snapshotInt(map['nextIndex']),
      step: ProgressionStep.fromJson(stepMap),
      previousStatus: status,
      previousValueCompleted: _snapshotInt(map['previousValueCompleted']),
      previousTargetSnapshot: _snapshotInt(map['previousTargetSnapshot']),
      previousCompletedAt: completedAt == null
          ? null
          : DateTime.tryParse(completedAt as String) ??
                (throw const FormatException('Invalid completion timestamp.')),
      previousSource: map['previousSource'] as String,
    );
  }

  static int _snapshotInt(Object? value) {
    if (value is! int || value < 0) {
      throw const FormatException('Invalid progression snapshot integer.');
    }
    return value;
  }
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

  /// Exact measured seconds contributed by completed timer sessions.
  int actualDurationSeconds = 0;

  /// Exact timestamp when this entry was marked completed
  DateTime? completedAt;

  /// Source of the completion ('manual', 'timer', 'focus_clock')
  String source = 'manual';

  String? note; // optional short reflection note

  /// Immutable step and prior-entry state used for safe progression undo/history.
  String? progressionCompletionSnapshotJson;

  @ignore
  ProgressionCompletionSnapshot? get progressionCompletionSnapshot {
    final value = progressionCompletionSnapshotJson;
    if (value == null) return null;
    try {
      return ProgressionCompletionSnapshot.decode(value);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  DateTime? createdAt;

  late DateTime updatedAt;
}
