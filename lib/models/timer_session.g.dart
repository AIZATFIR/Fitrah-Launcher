// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_session.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTimerSessionCollection on Isar {
  IsarCollection<TimerSession> get timerSessions => this.collection();
}

const TimerSessionSchema = CollectionSchema(
  name: r'TimerSession',
  id: -4159859870323604,
  properties: {
    r'accumulatedDurationSeconds': PropertySchema(
      id: 0,
      name: r'accumulatedDurationSeconds',
      type: IsarType.long,
    ),
    r'habitId': PropertySchema(
      id: 1,
      name: r'habitId',
      type: IsarType.long,
    ),
    r'habitName': PropertySchema(
      id: 2,
      name: r'habitName',
      type: IsarType.string,
    ),
    r'pausedAt': PropertySchema(
      id: 3,
      name: r'pausedAt',
      type: IsarType.dateTime,
    ),
    r'startedAt': PropertySchema(
      id: 4,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 5,
      name: r'status',
      type: IsarType.byte,
      enumMap: _TimerSessionstatusEnumValueMap,
    ),
    r'targetSeconds': PropertySchema(
      id: 6,
      name: r'targetSeconds',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 7,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
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
  version: '3.1.0+1',
);

int _timerSessionEstimateSize(
  TimerSession object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.habitName.length * 3;
  return bytesCount;
}

void _timerSessionSerialize(
  TimerSession object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accumulatedDurationSeconds);
  writer.writeLong(offsets[1], object.habitId);
  writer.writeString(offsets[2], object.habitName);
  writer.writeDateTime(offsets[3], object.pausedAt);
  writer.writeDateTime(offsets[4], object.startedAt);
  writer.writeByte(offsets[5], object.status.index);
  writer.writeLong(offsets[6], object.targetSeconds);
  writer.writeDateTime(offsets[7], object.updatedAt);
}

TimerSession _timerSessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TimerSession();
  object.accumulatedDurationSeconds = reader.readLong(offsets[0]);
  object.habitId = reader.readLong(offsets[1]);
  object.habitName = reader.readString(offsets[2]);
  object.id = id;
  object.pausedAt = reader.readDateTimeOrNull(offsets[3]);
  object.startedAt = reader.readDateTimeOrNull(offsets[4]);
  object.status =
      _TimerSessionstatusValueEnumMap[reader.readByteOrNull(offsets[5])] ??
          TimerStateStatus.idle;
  object.targetSeconds = reader.readLong(offsets[6]);
  object.updatedAt = reader.readDateTime(offsets[7]);
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
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (_TimerSessionstatusValueEnumMap[reader.readByteOrNull(offset)] ??
          TimerStateStatus.idle) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
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
    IsarCollection<dynamic> col, Id id, TimerSession object) {
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
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterWhereClause> idNotEqualTo(
      Id id) {
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
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
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
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TimerSessionQueryFilter
    on QueryBuilder<TimerSession, TimerSession, QFilterCondition> {
  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      accumulatedDurationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accumulatedDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      accumulatedDurationSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accumulatedDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      accumulatedDurationSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accumulatedDurationSeconds',
        value: value,
      ));
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
      return query.addFilterCondition(FilterCondition.between(
        property: r'accumulatedDurationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      habitIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'habitId',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      habitIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'habitId',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      habitIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'habitId',
        value: value,
      ));
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
      return query.addFilterCondition(FilterCondition.between(
        property: r'habitId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      habitNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'habitName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      habitNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'habitName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      habitNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'habitName',
        value: value,
        caseSensitive: caseSensitive,
      ));
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
      return query.addFilterCondition(FilterCondition.between(
        property: r'habitName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      habitNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'habitName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      habitNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'habitName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      habitNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'habitName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      habitNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'habitName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      habitNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'habitName',
        value: '',
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      habitNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'habitName',
        value: '',
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      pausedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pausedAt',
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      pausedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pausedAt',
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      pausedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pausedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      pausedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pausedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      pausedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pausedAt',
        value: value,
      ));
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
      return query.addFilterCondition(FilterCondition.between(
        property: r'pausedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      startedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startedAt',
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      startedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startedAt',
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      startedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      startedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      startedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
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
      return query.addFilterCondition(FilterCondition.between(
        property: r'startedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition> statusEqualTo(
      TimerStateStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      statusGreaterThan(
    TimerStateStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      statusLessThan(
    TimerStateStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition> statusBetween(
    TimerStateStatus lower,
    TimerStateStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      targetSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      targetSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      targetSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetSeconds',
        value: value,
      ));
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
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TimerSession, TimerSession, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
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
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
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

  QueryBuilder<TimerSession, TimerSession, QDistinct> distinctByHabitId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'habitId');
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct> distinctByHabitName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'habitName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TimerSession, TimerSession, QDistinct> distinctByPausedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pausedAt');
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

  QueryBuilder<TimerSession, DateTime?, QQueryOperations> pausedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pausedAt');
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
