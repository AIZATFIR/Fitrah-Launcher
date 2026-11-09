// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_session.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetTimerSessionCollection on Isar {
  IsarCollection<TimerSession> get timerSessions => this.collection();
}

const TimerSessionSchema = CollectionSchema(
  name: r'TimerSession',
  id: -(718289766589889 * 10000 + 3431),
  properties: {
    r'accumulatedDurationSeconds': PropertySchema(
      id: 0,
      name: r'accumulatedDurationSeconds',
      type: IsarType.long,
    ),
    r'activityId': PropertySchema(
      id: 1,
      name: r'activityId',
      type: IsarType.long,
    ),
    r'attributionLocalDate': PropertySchema(
      id: 2,
      name: r'attributionLocalDate',
      type: IsarType.string,
    ),
    r'habitId': PropertySchema(id: 3, name: r'habitId', type: IsarType.long),
    r'habitName': PropertySchema(
      id: 4,
      name: r'habitName',
      type: IsarType.string,
    ),
    r'habitTargetSnapshot': PropertySchema(
      id: 5,
      name: r'habitTargetSnapshot',
      type: IsarType.long,
    ),
    r'pausedAt': PropertySchema(
      id: 6,
      name: r'pausedAt',
      type: IsarType.dateTime,
    ),
    r'runningSince': PropertySchema(
      id: 7,
      name: r'runningSince',
      type: IsarType.dateTime,
    ),
    r'sourceColorValue': PropertySchema(
      id: 8,
      name: r'sourceColorValue',
      type: IsarType.long,
    ),
    r'sourceIdentity': PropertySchema(
      id: 9,
      name: r'sourceIdentity',
      type: IsarType.string,
    ),
    r'sourceKindIndex': PropertySchema(
      id: 10,
      name: r'sourceKindIndex',
      type: IsarType.long,
    ),
    r'startedAt': PropertySchema(
      id: 11,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 12,
      name: r'status',
      type: IsarType.byte,
      enumMap: _TimerSessionstatusEnumValueMap,
    ),
    r'targetSeconds': PropertySchema(
      id: 13,
      name: r'targetSeconds',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 14,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _timerSessionEstimateSize,
  serialize: _timerSessionSerialize,
  deserialize: _timerSessionDeserialize,
  deserializeProp: _timerSessionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _timerSessionGetId,
  getLinks: _timerSessionGetLinks,
  attach: _timerSessionAttach,
  version: '3.4.1',
);

int _timerSessionEstimateSize(
  TimerSession object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.attributionLocalDate;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.habitName.length * 3;
  {
    final value = object.sourceIdentity;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _timerSessionSerialize(
  TimerSession object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accumulatedDurationSeconds);
  writer.writeLong(offsets[1], object.activityId);
  writer.writeString(offsets[2], object.attributionLocalDate);
  writer.writeLong(offsets[3], object.habitId);
  writer.writeString(offsets[4], object.habitName);
  writer.writeLong(offsets[5], object.habitTargetSnapshot);
  writer.writeDateTime(offsets[6], object.pausedAt);
  writer.writeDateTime(offsets[7], object.runningSince);
  writer.writeLong(offsets[8], object.sourceColorValue);
  writer.writeString(offsets[9], object.sourceIdentity);
  writer.writeLong(offsets[10], object.sourceKindIndex);
  writer.writeDateTime(offsets[11], object.startedAt);
  writer.writeByte(offsets[12], object.status.index);
  writer.writeLong(offsets[13], object.targetSeconds);
  writer.writeDateTime(offsets[14], object.updatedAt);
}

TimerSession _timerSessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TimerSession();
  object.accumulatedDurationSeconds = reader.readLong(offsets[0]);
  object.activityId = reader.readLongOrNull(offsets[1]);
  object.attributionLocalDate = reader.readStringOrNull(offsets[2]);
  object.habitId = reader.readLong(offsets[3]);
  object.habitName = reader.readString(offsets[4]);
  object.habitTargetSnapshot = reader.readLongOrNull(offsets[5]);
  object.id = id;
  object.pausedAt = reader.readDateTimeOrNull(offsets[6]);
  object.runningSince = reader.readDateTimeOrNull(offsets[7]);
  object.sourceColorValue = reader.readLongOrNull(offsets[8]);
  object.sourceIdentity = reader.readStringOrNull(offsets[9]);
  object.sourceKindIndex = reader.readLongOrNull(offsets[10]);
  object.startedAt = reader.readDateTimeOrNull(offsets[11]);
  object.status =
      _TimerSessionstatusValueEnumMap[reader.readByteOrNull(offsets[12])] ??
      TimerStateStatus.idle;
  object.targetSeconds = reader.readLong(offsets[13]);
  object.updatedAt = reader.readDateTime(offsets[14]);
  return object;
}

P _timerSessionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (_TimerSessionstatusValueEnumMap[reader.readByteOrNull(offset)] ??
              TimerStateStatus.idle)
          as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TimerSessionstatusEnumValueMap = {
  'idle': 0,
  'running': 1,
  'paused': 2,
  'completed': 3,
};
const _TimerSessionstatusValueEnumMap = {
  0: TimerStateStatus.idle,
  1: TimerStateStatus.running,
  2: TimerStateStatus.paused,
  3: TimerStateStatus.completed,
};

Id _timerSessionGetId(TimerSession object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _timerSessionGetLinks(TimerSession object) {
  return [];
}

void _timerSessionAttach(
  IsarCollection<dynamic> col,
  Id id,
  TimerSession object,
) {
  object.id = id;
}

extension TimerSessionQueryWhereSort
    on QueryBuilder<TimerSession, TimerSession, QWhere> {
  QueryBuilder<TimerSession, TimerSession, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TimerSessionQueryWhere
    on QueryBuilder<TimerSession, TimerSession, QWhereClause> {
  QueryBuilder<TimerSession, TimerSession, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<TimerSession, TimerSession, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterWhereClause> idBetween(
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
}

extension TimerSessionQueryFilter
    on QueryBuilder<TimerSession, TimerSession, QFilterCondition> {
  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  accumulatedDurationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'accumulatedDurationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  accumulatedDurationSecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'accumulatedDurationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  accumulatedDurationSecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'accumulatedDurationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  accumulatedDurationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'accumulatedDurationSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  activityIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'activityId'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  activityIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'activityId'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  activityIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'activityId', value: value),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  attributionLocalDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'attributionLocalDate'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  attributionLocalDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'attributionLocalDate'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  attributionLocalDateEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'attributionLocalDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  attributionLocalDateGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'attributionLocalDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  attributionLocalDateLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'attributionLocalDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  attributionLocalDateBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'attributionLocalDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  attributionLocalDateStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'attributionLocalDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  attributionLocalDateEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'attributionLocalDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  attributionLocalDateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'attributionLocalDate',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  attributionLocalDateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'attributionLocalDate',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  attributionLocalDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'attributionLocalDate', value: ''),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  attributionLocalDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'attributionLocalDate',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'habitId', value: value),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitIdGreaterThan(int value, {bool include = false}) {
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitIdLessThan(int value, {bool include = false}) {
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitIdBetween(
    int lower,
    int upper, {
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'habitName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'habitName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'habitName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'habitName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'habitName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'habitName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'habitName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'habitName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'habitName', value: ''),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'habitName', value: ''),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitTargetSnapshotIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'habitTargetSnapshot'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitTargetSnapshotIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'habitTargetSnapshot'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitTargetSnapshotEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'habitTargetSnapshot', value: value),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitTargetSnapshotGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'habitTargetSnapshot',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitTargetSnapshotLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'habitTargetSnapshot',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  habitTargetSnapshotBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'habitTargetSnapshot',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition> idBetween(
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  pausedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'pausedAt'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  pausedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'pausedAt'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  pausedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pausedAt', value: value),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  pausedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pausedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  pausedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pausedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  pausedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pausedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  runningSinceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'runningSince'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  runningSinceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'runningSince'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  runningSinceEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'runningSince', value: value),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  runningSinceGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'runningSince',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  runningSinceLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'runningSince',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  runningSinceBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'runningSince',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceColorValueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceColorValue'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceColorValueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceColorValue'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceColorValueEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceColorValue', value: value),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceColorValueGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceColorValue',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceColorValueLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceColorValue',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceColorValueBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceColorValue',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceIdentityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceIdentity'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceIdentityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceIdentity'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceIdentityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceIdentity', value: ''),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceIdentityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceIdentity', value: ''),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceKindIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceKindIndex'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceKindIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceKindIndex'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceKindIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceKindIndex', value: value),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceKindIndexGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceKindIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceKindIndexLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceKindIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  sourceKindIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceKindIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  startedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'startedAt'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  startedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'startedAt'),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  startedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startedAt', value: value),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  startedAtGreaterThan(DateTime? value, {bool include = false}) {
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  startedAtLessThan(DateTime? value, {bool include = false}) {
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  startedAtBetween(
    DateTime? lower,
    DateTime? upper, {
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition> statusEqualTo(
    TimerStateStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: value),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  statusGreaterThan(TimerStateStatus value, {bool include = false}) {
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  statusLessThan(TimerStateStatus value, {bool include = false}) {
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition> statusBetween(
    TimerStateStatus lower,
    TimerStateStatus upper, {
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

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  targetSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'targetSeconds', value: value),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  targetSecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'targetSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  targetSecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'targetSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  targetSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'targetSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension TimerSessionQueryObject
    on QueryBuilder<TimerSession, TimerSession, QFilterCondition> {}

extension TimerSessionQueryLinks
    on QueryBuilder<TimerSession, TimerSession, QFilterCondition> {}

extension TimerSessionQuerySortBy
    on QueryBuilder<TimerSession, TimerSession, QSortBy> {
  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  sortByAccumulatedDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accumulatedDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  sortByAccumulatedDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accumulatedDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> sortByActivityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  sortByActivityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  sortByAttributionLocalDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attributionLocalDate', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  sortByAttributionLocalDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attributionLocalDate', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> sortByHabitId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitId', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> sortByHabitIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitId', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> sortByHabitName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitName', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> sortByHabitNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitName', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  sortByHabitTargetSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitTargetSnapshot', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  sortByHabitTargetSnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitTargetSnapshot', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> sortByPausedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pausedAt', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> sortByPausedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pausedAt', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> sortByRunningSince() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runningSince', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  sortByRunningSinceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runningSince', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  sortBySourceColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceColorValue', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  sortBySourceColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceColorValue', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  sortBySourceIdentity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceIdentity', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  sortBySourceIdentityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceIdentity', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  sortBySourceKindIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceKindIndex', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  sortBySourceKindIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceKindIndex', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> sortByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> sortByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> sortByTargetSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetSeconds', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  sortByTargetSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetSeconds', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension TimerSessionQuerySortThenBy
    on QueryBuilder<TimerSession, TimerSession, QSortThenBy> {
  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  thenByAccumulatedDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accumulatedDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  thenByAccumulatedDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accumulatedDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByActivityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  thenByActivityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activityId', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  thenByAttributionLocalDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attributionLocalDate', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  thenByAttributionLocalDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attributionLocalDate', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByHabitId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitId', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByHabitIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitId', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByHabitName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitName', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByHabitNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitName', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  thenByHabitTargetSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitTargetSnapshot', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  thenByHabitTargetSnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitTargetSnapshot', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByPausedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pausedAt', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByPausedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pausedAt', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByRunningSince() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runningSince', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  thenByRunningSinceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'runningSince', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  thenBySourceColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceColorValue', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  thenBySourceColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceColorValue', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  thenBySourceIdentity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceIdentity', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  thenBySourceIdentityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceIdentity', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  thenBySourceKindIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceKindIndex', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  thenBySourceKindIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceKindIndex', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByTargetSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetSeconds', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy>
  thenByTargetSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetSeconds', Sort.desc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension TimerSessionQueryWhereDistinct
    on QueryBuilder<TimerSession, TimerSession, QDistinct> {
  QueryBuilder<TimerSession, TimerSession, QDistinct>
  distinctByAccumulatedDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accumulatedDurationSeconds');
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct> distinctByActivityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activityId');
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct>
  distinctByAttributionLocalDate({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'attributionLocalDate',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct> distinctByHabitId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'habitId');
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct> distinctByHabitName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'habitName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct>
  distinctByHabitTargetSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'habitTargetSnapshot');
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct> distinctByPausedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pausedAt');
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct> distinctByRunningSince() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'runningSince');
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct>
  distinctBySourceColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceColorValue');
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct> distinctBySourceIdentity({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sourceIdentity',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct>
  distinctBySourceKindIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceKindIndex');
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct> distinctByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAt');
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct>
  distinctByTargetSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetSeconds');
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension TimerSessionQueryProperty
    on QueryBuilder<TimerSession, TimerSession, QQueryProperty> {
  QueryBuilder<TimerSession, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TimerSession, int, QQueryOperations>
  accumulatedDurationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accumulatedDurationSeconds');
    });
  }

  QueryBuilder<TimerSession, int?, QQueryOperations> activityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activityId');
    });
  }

  QueryBuilder<TimerSession, String?, QQueryOperations>
  attributionLocalDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attributionLocalDate');
    });
  }

  QueryBuilder<TimerSession, int, QQueryOperations> habitIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'habitId');
    });
  }

  QueryBuilder<TimerSession, String, QQueryOperations> habitNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'habitName');
    });
  }

  QueryBuilder<TimerSession, int?, QQueryOperations>
  habitTargetSnapshotProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'habitTargetSnapshot');
    });
  }

  QueryBuilder<TimerSession, DateTime?, QQueryOperations> pausedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pausedAt');
    });
  }

  QueryBuilder<TimerSession, DateTime?, QQueryOperations>
  runningSinceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'runningSince');
    });
  }

  QueryBuilder<TimerSession, int?, QQueryOperations>
  sourceColorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceColorValue');
    });
  }

  QueryBuilder<TimerSession, String?, QQueryOperations>
  sourceIdentityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceIdentity');
    });
  }

  QueryBuilder<TimerSession, int?, QQueryOperations> sourceKindIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceKindIndex');
    });
  }

  QueryBuilder<TimerSession, DateTime?, QQueryOperations> startedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAt');
    });
  }

  QueryBuilder<TimerSession, TimerStateStatus, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<TimerSession, int, QQueryOperations> targetSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetSeconds');
    });
  }

  QueryBuilder<TimerSession, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
