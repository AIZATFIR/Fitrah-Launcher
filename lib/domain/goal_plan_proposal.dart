import 'dart:convert';

import 'focus_intent.dart';

/// Provider-neutral understanding of a goal. It contains no repository command.
class GoalUnderstanding {
  GoalUnderstanding({required this.title, this.why, this.targetDate}) {
    if (title.trim().isEmpty || title.trim().length > 120) {
      throw ArgumentError.value(title, 'title', 'Must be 1–120 characters.');
    }
    if ((why?.length ?? 0) > 500) {
      throw ArgumentError.value(why, 'why', 'Must be at most 500 characters.');
    }
    if (targetDate != null) validLocalDate(targetDate);
  }

  final String title;
  final String? why;
  final String? targetDate;

  GoalUnderstanding copyWith({
    String? title,
    String? why,
    String? targetDate,
  }) => GoalUnderstanding(
    title: title ?? this.title,
    why: why ?? this.why,
    targetDate: targetDate ?? this.targetDate,
  );

  Map<String, Object?> toJson() => {
    'title': title.trim(),
    'why': why?.trim().isEmpty ?? true ? null : why!.trim(),
    'targetDate': targetDate,
  };

  factory GoalUnderstanding.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Goal must be an object.');
    return GoalUnderstanding(
      title: _string(value['title']),
      why: value['why'] == null ? null : _string(value['why']),
      targetDate: value['targetDate'] == null
          ? null
          : validLocalDate(value['targetDate']),
    );
  }
}

/// A recurring local-time block. `weekday` follows DateTime (Monday = 1).
class WeeklyPracticeBlock {
  WeeklyPracticeBlock({
    required this.weekday,
    required this.startMinute,
    required this.durationMinutes,
  }) {
    if (weekday < 1 || weekday > 7) {
      throw ArgumentError.value(weekday, 'weekday', 'Must be 1–7.');
    }
    if (startMinute < 0 || startMinute >= 1440) {
      throw ArgumentError.value(startMinute, 'startMinute', 'Must be 0–1439.');
    }
    if (durationMinutes < 15 || durationMinutes > 360) {
      throw ArgumentError.value(
        durationMinutes,
        'durationMinutes',
        'Must be 15–360.',
      );
    }
  }

  final int weekday;
  final int startMinute;
  final int durationMinutes;

  WeeklyPracticeBlock copyWith({
    int? weekday,
    int? startMinute,
    int? durationMinutes,
  }) => WeeklyPracticeBlock(
    weekday: weekday ?? this.weekday,
    startMinute: startMinute ?? this.startMinute,
    durationMinutes: durationMinutes ?? this.durationMinutes,
  );

  Map<String, Object?> toJson() => {
    'weekday': weekday,
    'startMinute': startMinute,
    'durationMinutes': durationMinutes,
  };

  factory WeeklyPracticeBlock.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Block must be an object.');
    return WeeklyPracticeBlock(
      weekday: _int(value['weekday']),
      startMinute: _int(value['startMinute']),
      durationMinutes: _int(value['durationMinutes']),
    );
  }
}

/// Editable proposal returned by any configured provider adapter.
class PlanProposal {
  PlanProposal({
    required this.goal,
    required List<String> assumptions,
    required List<WeeklyPracticeBlock> blocks,
    this.provider,
    this.model,
  }) : assumptions = List.unmodifiable(assumptions),
       blocks = List.unmodifiable(blocks) {
    if (this.assumptions.isEmpty ||
        this.assumptions.length > 12 ||
        this.assumptions.any(
          (a) => a.trim().isEmpty || a.trim().length > 200,
        )) {
      throw ArgumentError.value(
        assumptions,
        'assumptions',
        'Provide 1–12 assumptions of 1–200 characters.',
      );
    }
    if (this.blocks.isEmpty || this.blocks.length > 14) {
      throw ArgumentError.value(
        blocks,
        'blocks',
        'Provide 1–14 weekly blocks.',
      );
    }
    if ((provider?.length ?? 0) > 100 || (model?.length ?? 0) > 120) {
      throw ArgumentError('Provider/model metadata is too long.');
    }
  }

  final GoalUnderstanding goal;
  final List<String> assumptions;
  final List<WeeklyPracticeBlock> blocks;
  final String? provider;
  final String? model;

  PlanProposal copyWith({
    GoalUnderstanding? goal,
    List<String>? assumptions,
    List<WeeklyPracticeBlock>? blocks,
  }) => PlanProposal(
    goal: goal ?? this.goal,
    assumptions: assumptions ?? this.assumptions,
    blocks: blocks ?? this.blocks,
    provider: provider,
    model: model,
  );

  Map<String, Object?> toJson() => {
    'goal': goal.toJson(),
    'assumptions': assumptions.map((a) => a.trim()).toList(),
    'blocks': blocks.map((b) => b.toJson()).toList(),
    'provider': provider,
    'model': model,
  };

  String get fingerprintInput => jsonEncode(toJson());

  factory PlanProposal.fromJson(
    Object? value, {
    String? provider,
    String? model,
  }) {
    if (value is! Map) throw const FormatException('Plan must be an object.');
    final assumptions = value['assumptions'];
    final blocks = value['blocks'];
    if (assumptions is! List || blocks is! List) {
      throw const FormatException('Plan assumptions and blocks are required.');
    }
    return PlanProposal(
      goal: GoalUnderstanding.fromJson(value['goal']),
      assumptions: assumptions.map(_string).toList(),
      blocks: blocks.map(WeeklyPracticeBlock.fromJson).toList(),
      provider:
          provider ??
          (value['provider'] is String ? value['provider'] as String : null),
      model:
          model ?? (value['model'] is String ? value['model'] as String : null),
    );
  }
}

String _string(Object? value) {
  if (value is! String) throw const FormatException('Expected text.');
  return value;
}

int _int(Object? value) {
  if (value is! int) throw const FormatException('Expected integer.');
  return value;
}
