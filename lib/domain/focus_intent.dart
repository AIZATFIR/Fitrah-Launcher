import 'dart:convert';

/// Stable references never depend on a title or a mutable display name.
enum IntentSourceType { habit, task }

class IntentSource {
  const IntentSource({
    required this.id,
    required this.sourceStoreId,
    required this.type,
    required this.legacyId,
  });
  final String id;
  final String sourceStoreId;
  final IntentSourceType type;
  final int legacyId;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceStoreId': sourceStoreId,
    'type': type.name,
    'legacyId': legacyId,
  };
  factory IntentSource.fromJson(Map<String, dynamic> m) => IntentSource(
    id: _uuid(m['id']),
    sourceStoreId: _uuid(m['sourceStoreId']),
    type: IntentSourceType.values.byName(_text(m['type'])),
    legacyId: _integer(m['legacyId']),
  );
}

class IntentGoal {
  const IntentGoal({
    required this.id,
    required this.title,
    this.why,
    this.targetDate,
    this.pinned = false,
    this.archived = false,
    this.revision = 1,
  });
  final String id;
  final String title;
  final String? why;
  final String? targetDate;
  final bool pinned;
  final bool archived;
  final int revision;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'why': why,
    'targetDate': targetDate,
    'pinned': pinned,
    'archived': archived,
    'revision': revision,
  };
  factory IntentGoal.fromJson(Map<String, dynamic> m) => IntentGoal(
    id: _uuid(m['id']),
    title: _title(m['title']),
    why: m['why'] == null ? null : _optionalText(m['why'], 500),
    targetDate: m['targetDate'] == null
        ? null
        : validLocalDate(m['targetDate']),
    pinned: _bool(m['pinned']),
    archived: _bool(m['archived']),
    revision: _positive(m['revision']),
  );
}

class IntentPlanReceipt {
  const IntentPlanReceipt({
    required this.operationId,
    required this.fingerprint,
    required this.goalId,
    required this.habitId,
    required this.activityIds,
  });
  final String operationId;
  final String fingerprint;
  final String goalId;
  final int habitId;
  final List<int> activityIds;
  Map<String, dynamic> toJson() => {
    'operationId': operationId,
    'fingerprint': fingerprint,
    'goalId': goalId,
    'habitId': habitId,
    'activityIds': activityIds,
  };
  factory IntentPlanReceipt.fromJson(Map<String, dynamic> m) {
    final activities = m['activityIds'];
    if (activities is! List) {
      throw const FormatException('Invalid plan receipt');
    }
    return IntentPlanReceipt(
      operationId: _text(m['operationId']),
      fingerprint: _text(m['fingerprint']),
      goalId: _uuid(m['goalId']),
      habitId: _integer(m['habitId']),
      activityIds: List.unmodifiable(activities.map(_integer)),
    );
  }
}

class IntentLink {
  const IntentLink({required this.sourceId, required this.goalId});
  final String sourceId;
  final String goalId;
  Map<String, dynamic> toJson() => {'sourceId': sourceId, 'goalId': goalId};
  factory IntentLink.fromJson(Map<String, dynamic> m) =>
      IntentLink(sourceId: _uuid(m['sourceId']), goalId: _uuid(m['goalId']));
}

class TodaySelection {
  const TodaySelection({
    required this.localDate,
    required this.sourceId,
    required this.chosenAtUtc,
    this.scheduleBlockId,
    this.revision = 1,
  });
  final String localDate;
  // Null is a durable cleared choice, retaining revision and the historical date.
  final String? sourceId;
  final int? scheduleBlockId;
  final DateTime chosenAtUtc;
  final int revision;
  Map<String, dynamic> toJson() => {
    'localDate': localDate,
    'sourceId': sourceId,
    'scheduleBlockId': scheduleBlockId,
    'chosenAtUtc': chosenAtUtc.toUtc().toIso8601String(),
    'revision': revision,
  };
  factory TodaySelection.fromJson(Map<String, dynamic> m) {
    final date = validLocalDate(m['localDate']);
    final instant = DateTime.tryParse(_text(m['chosenAtUtc']));
    if (instant == null || !instant.isUtc) {
      throw const FormatException('Expected UTC choice instant');
    }
    return TodaySelection(
      localDate: date,
      sourceId: m['sourceId'] == null ? null : _uuid(m['sourceId']),
      scheduleBlockId: m['scheduleBlockId'] == null
          ? null
          : _integer(m['scheduleBlockId']),
      chosenAtUtc: instant,
      revision: _positive(m['revision']),
    );
  }
}

class IntentLegacyMapping {
  const IntentLegacyMapping({
    required this.sourceStoreId,
    required this.entityType,
    required this.legacyId,
    required this.stableId,
  });
  final String sourceStoreId, entityType, legacyId, stableId;
  Map<String, dynamic> toJson() => {
    'sourceStoreId': sourceStoreId,
    'entityType': entityType,
    'legacyId': legacyId,
    'stableId': stableId,
  };
  factory IntentLegacyMapping.fromJson(Map<String, dynamic> m) {
    if (m['entityType'] != 'goal' || m['legacyId'] != 'focusGoal') {
      throw const FormatException('Unknown legacy goal mapping');
    }
    return IntentLegacyMapping(
      sourceStoreId: _uuid(m['sourceStoreId']),
      entityType: 'goal',
      legacyId: 'focusGoal',
      stableId: _uuid(m['stableId']),
    );
  }
}

class IntentState {
  IntentState({
    required this.sourceStoreId,
    this.revision = 0,
    this.legacyImported = false,
    List<IntentLegacyMapping> legacyMappings = const [],
    List<IntentGoal> goals = const [],
    List<IntentSource> sources = const [],
    List<IntentLink> links = const [],
    List<TodaySelection> selections = const [],
    List<IntentPlanReceipt> planReceipts = const [],
  }) : legacyMappings = List.unmodifiable(legacyMappings),
       goals = List.unmodifiable(goals),
       sources = List.unmodifiable(sources),
       links = List.unmodifiable(links),
       selections = List.unmodifiable(selections),
       planReceipts = List.unmodifiable(planReceipts);
  final String sourceStoreId;
  final int revision;
  final bool legacyImported;
  final List<IntentLegacyMapping> legacyMappings;
  final List<IntentGoal> goals;
  final List<IntentSource> sources;
  final List<IntentLink> links;
  final List<TodaySelection> selections;
  final List<IntentPlanReceipt> planReceipts;
  IntentGoal? get pinnedGoal =>
      goals.where((g) => g.pinned && !g.archived).firstOrNull;
  TodaySelection? selectionFor(String localDate) =>
      selections.where((s) => s.localDate == localDate).firstOrNull;
  IntentSource? sourceFor(String? id) =>
      sources.where((s) => s.id == id).firstOrNull;
  IntentState copyWith({
    int? revision,
    bool? legacyImported,
    List<IntentLegacyMapping>? legacyMappings,
    List<IntentGoal>? goals,
    List<IntentSource>? sources,
    List<IntentLink>? links,
    List<TodaySelection>? selections,
    List<IntentPlanReceipt>? planReceipts,
  }) => IntentState(
    sourceStoreId: sourceStoreId,
    revision: revision ?? this.revision,
    legacyImported: legacyImported ?? this.legacyImported,
    legacyMappings: legacyMappings ?? this.legacyMappings,
    goals: goals ?? this.goals,
    sources: sources ?? this.sources,
    links: links ?? this.links,
    selections: selections ?? this.selections,
    planReceipts: planReceipts ?? this.planReceipts,
  );
  Map<String, dynamic> toJson() => {
    'version': 1,
    'sourceStoreId': sourceStoreId,
    'revision': revision,
    'legacyImported': legacyImported,
    'legacyMappings': legacyMappings.map((m) => m.toJson()).toList(),
    'goals': goals.map((g) => g.toJson()).toList(),
    'sources': sources.map((s) => s.toJson()).toList(),
    'links': links.map((l) => l.toJson()).toList(),
    'selections': selections.map((s) => s.toJson()).toList(),
    'planReceipts': planReceipts.map((r) => r.toJson()).toList(),
  };
  String encode() => jsonEncode(toJson());
  factory IntentState.decode(String raw) {
    try {
      return IntentState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Invalid intent document: $e');
    }
  }
  factory IntentState.fromJson(Map<String, dynamic> m) {
    if (m['version'] != 1) {
      throw const FormatException('Unsupported intent document version');
    }
    final state = IntentState(
      sourceStoreId: _uuid(m['sourceStoreId']),
      revision: _integer(m['revision']),
      legacyImported: _bool(m['legacyImported']),
      legacyMappings: _rows(m['legacyMappings'], IntentLegacyMapping.fromJson),
      goals: _rows(m['goals'], IntentGoal.fromJson),
      sources: _rows(m['sources'], IntentSource.fromJson),
      links: _rows(m['links'], IntentLink.fromJson),
      selections: _rows(m['selections'], TodaySelection.fromJson),
      planReceipts: m['planReceipts'] == null
          ? const []
          : _rows(m['planReceipts'], IntentPlanReceipt.fromJson),
    );
    if (state.revision < 0) throw const FormatException('Invalid revision');
    _unique(
      state.legacyMappings.map(
        (m) => '${m.sourceStoreId}/${m.entityType}/${m.legacyId}',
      ),
    );
    for (final mapping in state.legacyMappings) {
      if (!state.goals.any((g) => g.id == mapping.stableId)) {
        throw const FormatException('Dangling legacy goal mapping');
      }
    }
    _unique(state.goals.map((g) => g.id));
    _unique(state.sources.map((s) => s.id));
    _unique(
      state.sources.map(
        (s) => '${s.sourceStoreId}/${s.type.name}/${s.legacyId}',
      ),
    );
    _unique(state.links.map((l) => l.sourceId));
    _unique(state.selections.map((s) => s.localDate));
    _unique(state.planReceipts.map((r) => r.operationId));
    if (state.goals.where((g) => g.pinned).length > 1 ||
        state.goals.any((g) => g.pinned && g.archived)) {
      throw const FormatException('Invalid pinned goal');
    }
    for (final link in state.links) {
      if (!state.goals.any((g) => g.id == link.goalId) ||
          state.sourceFor(link.sourceId) == null) {
        throw const FormatException('Dangling goal link');
      }
    }
    for (final choice in state.selections) {
      if (choice.sourceId != null && state.sourceFor(choice.sourceId) == null) {
        throw const FormatException('Dangling daily choice');
      }
      if (choice.sourceId == null && choice.scheduleBlockId != null) {
        throw const FormatException('Cleared choice has schedule');
      }
    }
    return state;
  }
}

String intentLocalDate(DateTime now) =>
    '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
String validLocalDate(Object? value) {
  final text = _text(value);
  final parsed = DateTime.tryParse(text);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) ||
      parsed == null ||
      intentLocalDate(parsed) != text) {
    throw const FormatException('Invalid local date');
  }
  return text;
}

String _text(Object? v) {
  if (v is! String) throw const FormatException('Expected string');
  return v;
}

String _title(Object? v) {
  final s = _text(v).trim();
  if (s.isEmpty || s.length > 120) {
    throw const FormatException('Goal title must be 1–120 characters');
  }
  return s;
}

String _optionalText(Object? value, int maxLength) {
  final text = _text(value).trim();
  if (text.length > maxLength) throw const FormatException('Text is too long');
  return text;
}

String _uuid(Object? v) {
  final s = _text(v);
  if (!RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(s)) {
    throw const FormatException('Expected UUID');
  }
  return s;
}

int _integer(Object? v) {
  if (v is! int || v.abs() > 9007199254740991) {
    throw const FormatException('Expected exact integer');
  }
  return v;
}

int _positive(Object? v) {
  final n = _integer(v);
  if (n < 1) throw const FormatException('Expected positive revision');
  return n;
}

bool _bool(Object? v) {
  if (v is! bool) throw const FormatException('Expected boolean');
  return v;
}

List<T> _rows<T>(Object? v, T Function(Map<String, dynamic>) read) {
  if (v is! List) throw const FormatException('Expected list');
  return v.map((e) => read(e as Map<String, dynamic>)).toList();
}

void _unique(Iterable<String> values) {
  final list = values.toList();
  if (list.toSet().length != list.length) {
    throw const FormatException('Duplicate identity');
  }
}
