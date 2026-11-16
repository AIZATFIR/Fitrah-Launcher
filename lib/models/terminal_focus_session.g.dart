// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terminal_focus_session.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetTerminalFocusSessionCollection on Isar {
  IsarCollection<TerminalFocusSession> get terminalFocusSessions =>
      this.collection();
}

const TerminalFocusSessionSchema = CollectionSchema(
  name: r'TerminalFocusSession',
  id: -(69836181059176 * 10000 + 6530),
  properties: {
    r'activityId': PropertySchema(
      id: 0,
      name: r'activityId',
      type: IsarType.long,
    ),
    r'actualDurationSeconds': PropertySchema(
      id: 1,
      name: r'actualDurationSeconds',
      type: IsarType.long,
    ),
    r'completedAt': PropertySchema(
      id: 2,
      name: r'completedAt',
      type: IsarType.dateTime,
    ),
    r'goalId': PropertySchema(id: 10, name: r'goalId', type: IsarType.string),
    r'goalTitleSnapshot': PropertySchema(
      id: 11,
      name: r'goalTitleSnapshot',
      type: IsarType.string,
    ),
    r'habitId': PropertySchema(id: 3, name: r'habitId', type: IsarType.long),
    r'sessionId': PropertySchema(
      id: 4,
      name: r'sessionId',
      type: IsarType.string,
    ),
    r'sourceIdentity': PropertySchema(
      id: 5,
      name: r'sourceIdentity',
      type: IsarType.string,
    ),
    r'sourceKind': PropertySchema(
      id: 6,
      name: r'sourceKind',
      type: IsarType.string,
    ),
    r'startedAt': PropertySchema(
      id: 7,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 8,
      name: r'status',
      type: IsarType.byte,
      enumMap: _TerminalFocusSessionstatusEnumValueMap,
    ),
    r'titleSnapshot': PropertySchema(
      id: 9,
      name: r'titleSnapshot',
      type: IsarType.string,
    ),
  },

  estimateSize: _terminalFocusSessionEstimateSize,
  serialize: _terminalFocusSessionSerialize,
  deserialize: _terminalFocusSessionDeserialize,
  deserializeProp: _terminalFocusSessionDeserializeProp,
  idName: r'id',
  indexes: {
    r'sessionId': IndexSchema(
      id: 694951858504792 * 10000 + 3839,
      name: r'sessionId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sessionId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _terminalFocusSessionGetId,
  getLinks: _terminalFocusSessionGetLinks,
  attach: _terminalFocusSessionAttach,
  version: '3.4.1',
);

int _terminalFocusSessionEstimateSize(
  TerminalFocusSession object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.goalId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.goalTitleSnapshot;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sessionId.length * 3;
  {
    final value = object.sourceIdentity;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sourceKind.length * 3;
  bytesCount += 3 + object.titleSnapshot.length * 3;
  return bytesCount;
}

void _terminalFocusSessionSerialize(
  TerminalFocusSession object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.activityId);
  writer.writeLong(offsets[1], object.actualDurationSeconds);
  writer.writeDateTime(offsets[2], object.completedAt);
  writer.writeString(offsets[3], object.goalId);
  writer.writeString(offsets[4], object.goalTitleSnapshot);
  writer.writeLong(offsets[5], object.habitId);
  writer.writeString(offsets[6], object.sessionId);
  writer.writeString(offsets[7], object.sourceIdentity);
  writer.writeString(offsets[8], object.sourceKind);
  writer.writeDateTime(offsets[9], object.startedAt);
  writer.writeByte(offsets[10], object.status.index);
  writer.writeString(offsets[11], object.titleSnapshot);
}

TerminalFocusSession _terminalFocusSessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TerminalFocusSession();
  object.activityId = reader.readLongOrNull(offsets[0]);
  object.actualDurationSeconds = reader.readLong(offsets[1]);
  object.completedAt = reader.readDateTime(offsets[2]);
  object.goalId = reader.readStringOrNull(offsets[3]);
  object.goalTitleSnapshot = reader.readStringOrNull(offsets[4]);
  object.habitId = reader.readLongOrNull(offsets[5]);
  object.id = id;
  object.sessionId = reader.readString(offsets[6]);
  object.sourceIdentity = reader.readStringOrNull(offsets[7]);
  object.sourceKind = reader.readString(offsets[8]);
  object.startedAt = reader.readDateTime(offsets[9]);
  object.status =
      _TerminalFocusSessionstatusValueEnumMap[reader.readByteOrNull(
        offsets[10],
      )] ??
      TerminalSessionStatus.completed;
  object.titleSnapshot = reader.readString(offsets[11]);
  return object;
}

P _terminalFocusSessionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (_TerminalFocusSessionstatusValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              TerminalSessionStatus.completed)
          as P;
    case 9:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TerminalFocusSessionstatusEnumValueMap = {
  'completed': 0,
  'cancelled': 1,
};
const _TerminalFocusSessionstatusValueEnumMap = {
  0: TerminalSessionStatus.completed,
  1: TerminalSessionStatus.cancelled,
};

Id _terminalFocusSessionGetId(TerminalFocusSession object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _terminalFocusSessionGetLinks(
  TerminalFocusSession object,
) {
  return [];
}

void _terminalFocusSessionAttach(
  IsarCollection<dynamic> col,
  Id id,
  TerminalFocusSession object,
) {
  object.id = id;
}

extension TerminalFocusSessionByIndex on IsarCollection<TerminalFocusSession> {
  Future<TerminalFocusSession?> getBySessionId(String sessionId) {
    return getByIndex(r'sessionId', [sessionId]);
  }

  TerminalFocusSession? getBySessionIdSync(String sessionId) {
    return getByIndexSync(r'sessionId', [sessionId]);
  }

  Future<bool> deleteBySessionId(String sessionId) {
    return deleteByIndex(r'sessionId', [sessionId]);
  }

  bool deleteBySessionIdSync(String sessionId) {
    return deleteByIndexSync(r'sessionId', [sessionId]);
  }

  Future<List<TerminalFocusSession?>> getAllBySessionId(
    List<String> sessionIdValues,
  ) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'sessionId', values);
  }

  List<TerminalFocusSession?> getAllBySessionIdSync(
    List<String> sessionIdValues,
  ) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'sessionId', values);
  }

  Future<int> deleteAllBySessionId(List<String> sessionIdValues) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'sessionId', values);
  }

  int deleteAllBySessionIdSync(List<String> sessionIdValues) {
    final values = sessionIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'sessionId', values);
  }

  Future<Id> putBySessionId(TerminalFocusSession object) {
    return putByIndex(r'sessionId', object);
  }

  Id putBySessionIdSync(TerminalFocusSession object, {bool saveLinks = true}) {
    return putByIndexSync(r'sessionId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySessionId(List<TerminalFocusSession> objects) {
    return putAllByIndex(r'sessionId', objects);
  }

  List<Id> putAllBySessionIdSync(
    List<TerminalFocusSession> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'sessionId', objects, saveLinks: saveLinks);
  }
}

extension TerminalFocusSessionQueryWhereSort
    on QueryBuilder<TerminalFocusSession, TerminalFocusSession, QWhere> {
  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TerminalFocusSessionQueryWhere
    on QueryBuilder<TerminalFocusSession, TerminalFocusSession, QWhereClause> {
  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterWhereClause>
  sessionIdEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'sessionId', value: [sessionId]),
      );
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterWhereClause>
  sessionIdNotEqualTo(String sessionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'sessionId',
                lower: [],
                upper: [sessionId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'sessionId',
                lower: [sessionId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'sessionId',
                lower: [sessionId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'sessionId',
                lower: [],
                upper: [sessionId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension TerminalFocusSessionQueryFilter
    on
        QueryBuilder<
          TerminalFocusSession,
          TerminalFocusSession,
          QFilterCondition
        > {
  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  activityIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'activityId'),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  activityIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'activityId'),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  activityIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'activityId', value: value),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  activityIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'activityId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  activityIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'activityId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  activityIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'activityId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  actualDurationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'actualDurationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  actualDurationSecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'actualDurationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  actualDurationSecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'actualDurationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  actualDurationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'actualDurationSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  completedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'completedAt', value: value),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  completedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'completedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  completedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'completedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  completedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'completedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'goalId'),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'goalId'),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'goalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'goalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'goalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'goalId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'goalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'goalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'goalId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'goalId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'goalId', value: ''),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'goalId', value: ''),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalTitleSnapshotIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'goalTitleSnapshot'),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalTitleSnapshotIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'goalTitleSnapshot'),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalTitleSnapshotEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'goalTitleSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalTitleSnapshotGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'goalTitleSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalTitleSnapshotLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'goalTitleSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalTitleSnapshotBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'goalTitleSnapshot',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalTitleSnapshotStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'goalTitleSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalTitleSnapshotEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'goalTitleSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalTitleSnapshotContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'goalTitleSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalTitleSnapshotMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'goalTitleSnapshot',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalTitleSnapshotIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'goalTitleSnapshot', value: ''),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  goalTitleSnapshotIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'goalTitleSnapshot', value: ''),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  habitIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'habitId'),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  habitIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'habitId'),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  habitIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'habitId', value: value),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  habitIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'habitId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  habitIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'habitId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  habitIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'habitId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sessionIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sessionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sessionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sessionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sessionId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sessionIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sessionIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sessionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sessionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sessionId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sessionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sessionId', value: ''),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sessionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sessionId', value: ''),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceIdentityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceIdentity'),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceIdentityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceIdentity'),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceIdentityEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceIdentity',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceIdentityGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceIdentity',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceIdentityLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceIdentity',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceIdentityBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceIdentity',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceIdentityStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceIdentity',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceIdentityEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceIdentity',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceIdentityContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceIdentity',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceIdentityMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceIdentity',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceIdentityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceIdentity', value: ''),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceIdentityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceIdentity', value: ''),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceKindEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceKindGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceKindLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceKindBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceKind',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceKindStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceKindEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceKindContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceKind',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceKindMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceKind',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceKindIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceKind', value: ''),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  sourceKindIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceKind', value: ''),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  startedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startedAt', value: value),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  startedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  startedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  startedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  statusEqualTo(TerminalSessionStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: value),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  statusGreaterThan(TerminalSessionStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  statusLessThan(TerminalSessionStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  statusBetween(
    TerminalSessionStatus lower,
    TerminalSessionStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  titleSnapshotEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'titleSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  titleSnapshotGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'titleSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  titleSnapshotLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'titleSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  titleSnapshotBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'titleSnapshot',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  titleSnapshotStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'titleSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  titleSnapshotEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'titleSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  titleSnapshotContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'titleSnapshot',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  titleSnapshotMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'titleSnapshot',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  titleSnapshotIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'titleSnapshot', value: ''),
      );
    });
  }

  QueryBuilder<
    TerminalFocusSession,
    TerminalFocusSession,
    QAfterFilterCondition
  >
  titleSnapshotIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'titleSnapshot', value: ''),
      );
    });
  }
}

extension TerminalFocusSessionQueryObject
    on
        QueryBuilder<
          TerminalFocusSession,
          TerminalFocusSession,
          QFilterCondition
        > {}

extension TerminalFocusSessionQueryLinks
    on
        QueryBuilder<
          TerminalFocusSession,
          TerminalFocusSession,
          QFilterCondition
        > {}

extension TerminalFocusSessionQuerySortBy
    on QueryBuilder<TerminalFocusSession, TerminalFocusSession, QSortBy> {
  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByActivityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByActivityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByActualDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByActualDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByGoalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByGoalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByGoalTitleSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalTitleSnapshot', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByGoalTitleSnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalTitleSnapshot', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByHabitId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitId', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByHabitIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitId', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortBySourceIdentity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceIdentity', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortBySourceIdentityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceIdentity', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortBySourceKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceKind', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortBySourceKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceKind', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByTitleSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleSnapshot', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  sortByTitleSnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleSnapshot', Sort.desc);
    });
  }
}

extension TerminalFocusSessionQuerySortThenBy
    on QueryBuilder<TerminalFocusSession, TerminalFocusSession, QSortThenBy> {
  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByActivityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByActivityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByActualDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByActualDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actualDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByGoalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByGoalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalId', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByGoalTitleSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalTitleSnapshot', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByGoalTitleSnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'goalTitleSnapshot', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByHabitId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitId', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByHabitIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitId', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenBySessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenBySessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionId', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenBySourceIdentity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceIdentity', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenBySourceIdentityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceIdentity', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenBySourceKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceKind', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenBySourceKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceKind', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByTitleSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleSnapshot', Sort.asc);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QAfterSortBy>
  thenByTitleSnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titleSnapshot', Sort.desc);
    });
  }
}

extension TerminalFocusSessionQueryWhereDistinct
    on QueryBuilder<TerminalFocusSession, TerminalFocusSession, QDistinct> {
  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QDistinct>
  distinctByActivityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activityId');
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QDistinct>
  distinctByActualDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actualDurationSeconds');
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QDistinct>
  distinctByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAt');
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QDistinct>
  distinctByGoalId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'goalId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QDistinct>
  distinctByGoalTitleSnapshot({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'goalTitleSnapshot',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QDistinct>
  distinctByHabitId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'habitId');
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QDistinct>
  distinctBySessionId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QDistinct>
  distinctBySourceIdentity({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sourceIdentity',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QDistinct>
  distinctBySourceKind({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceKind', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QDistinct>
  distinctByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAt');
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QDistinct>
  distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalFocusSession, QDistinct>
  distinctByTitleSnapshot({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'titleSnapshot',
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension TerminalFocusSessionQueryProperty
    on
        QueryBuilder<
          TerminalFocusSession,
          TerminalFocusSession,
          QQueryProperty
        > {
  QueryBuilder<TerminalFocusSession, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TerminalFocusSession, int?, QQueryOperations>
  activityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activityId');
    });
  }

  QueryBuilder<TerminalFocusSession, int, QQueryOperations>
  actualDurationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actualDurationSeconds');
    });
  }

  QueryBuilder<TerminalFocusSession, DateTime, QQueryOperations>
  completedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAt');
    });
  }

  QueryBuilder<TerminalFocusSession, String?, QQueryOperations>
  goalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'goalId');
    });
  }

  QueryBuilder<TerminalFocusSession, String?, QQueryOperations>
  goalTitleSnapshotProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'goalTitleSnapshot');
    });
  }

  QueryBuilder<TerminalFocusSession, int?, QQueryOperations> habitIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'habitId');
    });
  }

  QueryBuilder<TerminalFocusSession, String, QQueryOperations>
  sessionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionId');
    });
  }

  QueryBuilder<TerminalFocusSession, String?, QQueryOperations>
  sourceIdentityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceIdentity');
    });
  }

  QueryBuilder<TerminalFocusSession, String, QQueryOperations>
  sourceKindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceKind');
    });
  }

  QueryBuilder<TerminalFocusSession, DateTime, QQueryOperations>
  startedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAt');
    });
  }

  QueryBuilder<TerminalFocusSession, TerminalSessionStatus, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<TerminalFocusSession, String, QQueryOperations>
  titleSnapshotProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'titleSnapshot');
    });
  }
}
