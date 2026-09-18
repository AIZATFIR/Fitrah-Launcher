import 'dart:convert';
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

class ProgressionStep {
  final String dayName;
  final String title;
  final int target;
  final String unit;
  final bool isRest;

  const ProgressionStep({
    required this.dayName,
    required this.title,
    this.target = 20,
    this.unit = 'reps',
    this.isRest = false,
  });

  Map<String, dynamic> toJson() => {
    'dayName': dayName,
    'title': title,
    'target': target,
    'unit': unit,
    'isRest': isRest,
  };

  factory ProgressionStep.fromJson(Map<String, dynamic> json) => ProgressionStep(
    dayName: json['dayName'] as String? ?? 'Hari',
    title: json['title'] as String? ?? 'Latihan',
    target: (json['target'] as num?)?.toInt() ?? 20,
    unit: json['unit'] as String? ?? 'reps',
    isRest: json['isRest'] as bool? ?? false,
  );
}

final List<ProgressionStep> defaultBodybuildingSteps = [
  const ProgressionStep(dayName: 'Senin', title: 'Push Up', target: 20, unit: 'reps', isRest: false),
  const ProgressionStep(dayName: 'Selasa', title: 'Pull Up', target: 15, unit: 'reps', isRest: false),
  const ProgressionStep(dayName: 'Rabu', title: 'Rest & Recovery', target: 0, unit: '', isRest: true),
  const ProgressionStep(dayName: 'Kamis', title: 'Squat', target: 30, unit: 'reps', isRest: false),
  const ProgressionStep(dayName: 'Jumat', title: 'Dips / Triceps', target: 25, unit: 'reps', isRest: false),
  const ProgressionStep(dayName: 'Sabtu', title: 'Core / Plank', target: 3, unit: 'sets', isRest: false),
  const ProgressionStep(dayName: 'Minggu', title: 'Rest Day', target: 0, unit: '', isRest: true),
];

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

  /// Type of habit:
  /// - 'timed': YPT/Focus session with optional allowed apps & strict lock
  /// - 'count': simple count/repetition/checklist target
  /// - 'progression': bodybuilding/dynamic daily routine, only advances when completed
  /// - 'hybrid': combination (sets x duration per set)
  String habitType = 'timed';

  /// Packages allowed during timed focus session
  List<String> allowedPackages = [];

  /// Serialized list of ProgressionStep for bodybuilding mode
  String? progressionPlanJson;

  /// Current step index in progression (0-based)
  int currentProgressionIndex = 0;

  /// For hybrid mode: number of sets
  int hybridSets = 3;

  /// For hybrid mode: duration in seconds per set
  int hybridDurationSeconds = 60;

  /// For hybrid mode: rest duration between sets
  int hybridRestSeconds = 30;

  String category = 'General';
  String? preferredTime; // optional e.g. "Morning", "19:00"

  bool timerEnabled = true;
  late int colorValue;
  String recurrence = 'daily'; // 'daily' | 'weekdays' | 'custom'
  int orderIndex = 0;
  bool isArchived = false;

  late DateTime createdAt;
  DateTime? updatedAt;

  @ignore
  List<ProgressionStep> get progressionSteps {
    if (progressionPlanJson == null || progressionPlanJson!.trim().isEmpty) {
      return defaultBodybuildingSteps;
    }
    try {
      final decoded = jsonDecode(progressionPlanJson!) as List<dynamic>;
      return decoded.map((e) => ProgressionStep.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return defaultBodybuildingSteps;
    }
  }

  @ignore
  ProgressionStep get currentStep {
    final steps = progressionSteps;
    if (steps.isEmpty) {
      return ProgressionStep(dayName: 'Hari 1', title: name, target: target, isRest: false);
    }
    final idx = currentProgressionIndex.clamp(0, steps.length - 1);
    return steps[idx];
  }

  @ignore
  String get effectiveHabitType {
    final t = habitType.trim().toLowerCase();
    if (t == 'timed' || t == 'count' || t == 'progression' || t == 'hybrid') {
      return t;
    }
    if (timerEnabled || unit == HabitUnit.min) {
      return 'timed';
    }
    return 'count';
  }
}
