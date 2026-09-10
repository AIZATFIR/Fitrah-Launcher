// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_reflection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailyReflectionCollection on Isar {
  IsarCollection<DailyReflection> get dailyReflections => this.collection();
}

const DailyReflectionSchema = CollectionSchema(
  name: r'DailyReflection',
  id: 329460378031511,
  properties: {
    r'completedCount': PropertySchema(
      id: 0,
      name: r'completedCount',
      type: IsarType.long,
    ),
    r'dateString': PropertySchema(
      id: 1,
      name: r'dateString',
      type: IsarType.string,
    ),
    r'feeling': PropertySchema(
      id: 2,
      name: r'feeling',
      type: IsarType.byte,
      enumMap: _DailyReflectionfeelingEnumValueMap,
    ),
    r'note': PropertySchema(
      id: 3,
      name: r'note',
      type: IsarType.string,
    ),
    r'proudOfToday': PropertySchema(
      id: 4,
      name: r'proudOfToday',
      type: IsarType.string,
    ),
    r'totalCount': PropertySchema(
      id: 5,
      name: r'totalCount',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 6,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _dailyReflectionEstimateSize,
  serialize: _dailyReflectionSerialize,
  deserialize: _dailyReflectionDeserialize,
  deserializeProp: _dailyReflectionDeserializeProp,
  idName: r'id',
  indexes: {
    r'dateString': IndexSchema(
      id: 3858744797826177,
      name: r'dateString',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dateString',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _dailyReflectionGetId,
  getLinks: _dailyReflectionGetLinks,
  attach: _dailyReflectionAttach,
  version: '3.1.0+1',
);

int _dailyReflectionEstimateSize(
  DailyReflection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateString.length * 3;
  bytesCount += 3 + object.note.length * 3;
  bytesCount += 3 + object.proudOfToday.length * 3;
  return bytesCount;
}

void _dailyReflectionSerialize(
  DailyReflection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.completedCount);
  writer.writeString(offsets[1], object.dateString);
  writer.writeByte(offsets[2], object.feeling.index);
  writer.writeString(offsets[3], object.note);
  writer.writeString(offsets[4], object.proudOfToday);
  writer.writeLong(offsets[5], object.totalCount);
  writer.writeDateTime(offsets[6], object.updatedAt);
}

DailyReflection _dailyReflectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailyReflection();
  object.completedCount = reader.readLong(offsets[0]);
  object.dateString = reader.readString(offsets[1]);
  object.feeling =
      _DailyReflectionfeelingValueEnumMap[reader.readByteOrNull(offsets[2])] ??
          ReflectionFeeling.notSatisfied;
  object.id = id;
  object.note = reader.readString(offsets[3]);
  object.proudOfToday = reader.readString(offsets[4]);
  object.totalCount = reader.readLong(offsets[5]);
  object.updatedAt = reader.readDateTime(offsets[6]);
  return object;
}

P _dailyReflectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (_DailyReflectionfeelingValueEnumMap[
              reader.readByteOrNull(offset)] ??
          ReflectionFeeling.notSatisfied) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _DailyReflectionfeelingEnumValueMap = {
  'notSatisfied': 0,
  'okay': 1,
  'good': 2,
  'proud': 3,
};
const _DailyReflectionfeelingValueEnumMap = {
  0: ReflectionFeeling.notSatisfied,
  1: ReflectionFeeling.okay,
  2: ReflectionFeeling.good,
  3: ReflectionFeeling.proud,
};

Id _dailyReflectionGetId(DailyReflection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailyReflectionGetLinks(DailyReflection object) {
  return [];
}

void _dailyReflectionAttach(
    IsarCollection<dynamic> col, Id id, DailyReflection object) {
  object.id = id;
}

extension DailyReflectionQueryWhereSort
    on QueryBuilder<DailyReflection, DailyReflection, QWhere> {
  QueryBuilder<DailyReflection, DailyReflection, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DailyReflectionQueryWhere
    on QueryBuilder<DailyReflection, DailyReflection, QWhereClause> {
  QueryBuilder<DailyReflection, DailyReflection, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterWhereClause>
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

  QueryBuilder<DailyReflection, DailyReflection, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterWhereClause> idBetween(
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

  QueryBuilder<DailyReflection, DailyReflection, QAfterWhereClause>
      dateStringEqualTo(String dateString) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dateString',
        value: [dateString],
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterWhereClause>
      dateStringNotEqualTo(String dateString) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateString',
              lower: [],
              upper: [dateString],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateString',
              lower: [dateString],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateString',
              lower: [dateString],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateString',
              lower: [],
              upper: [dateString],
              includeUpper: false,
            ));
      }
    });
  }
}

extension DailyReflectionQueryFilter
    on QueryBuilder<DailyReflection, DailyReflection, QFilterCondition> {
  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      completedCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      completedCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      completedCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      completedCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      dateStringEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      dateStringGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      dateStringLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      dateStringBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateString',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      dateStringStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      dateStringEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      dateStringContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateString',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      dateStringMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateString',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      dateStringIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateString',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      dateStringIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateString',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      feelingEqualTo(ReflectionFeeling value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'feeling',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      feelingGreaterThan(
    ReflectionFeeling value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'feeling',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      feelingLessThan(
    ReflectionFeeling value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'feeling',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      feelingBetween(
    ReflectionFeeling lower,
    ReflectionFeeling upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'feeling',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      noteEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      noteGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      noteLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      noteBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudOfTodayEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proudOfToday',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudOfTodayGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'proudOfToday',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudOfTodayLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'proudOfToday',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudOfTodayBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'proudOfToday',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudOfTodayStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'proudOfToday',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudOfTodayEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'proudOfToday',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudOfTodayContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'proudOfToday',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudOfTodayMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'proudOfToday',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudOfTodayIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proudOfToday',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudOfTodayIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'proudOfToday',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      totalCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      totalCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      totalCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      totalCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
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

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
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

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
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

extension DailyReflectionQueryObject
    on QueryBuilder<DailyReflection, DailyReflection, QFilterCondition> {}

extension DailyReflectionQueryLinks
    on QueryBuilder<DailyReflection, DailyReflection, QFilterCondition> {}

extension DailyReflectionQuerySortBy
    on QueryBuilder<DailyReflection, DailyReflection, QSortBy> {
  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      sortByCompletedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedCount', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      sortByCompletedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedCount', Sort.desc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      sortByDateString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      sortByDateStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.desc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy> sortByFeeling() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feeling', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      sortByFeelingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feeling', Sort.desc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      sortByProudOfToday() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proudOfToday', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      sortByProudOfTodayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proudOfToday', Sort.desc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      sortByTotalCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCount', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      sortByTotalCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCount', Sort.desc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DailyReflectionQuerySortThenBy
    on QueryBuilder<DailyReflection, DailyReflection, QSortThenBy> {
  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      thenByCompletedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedCount', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      thenByCompletedCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedCount', Sort.desc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      thenByDateString() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      thenByDateStringDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateString', Sort.desc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy> thenByFeeling() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feeling', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      thenByFeelingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'feeling', Sort.desc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      thenByProudOfToday() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proudOfToday', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      thenByProudOfTodayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proudOfToday', Sort.desc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      thenByTotalCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCount', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      thenByTotalCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCount', Sort.desc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DailyReflectionQueryWhereDistinct
    on QueryBuilder<DailyReflection, DailyReflection, QDistinct> {
  QueryBuilder<DailyReflection, DailyReflection, QDistinct>
      distinctByCompletedCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedCount');
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QDistinct>
      distinctByDateString({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateString', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QDistinct>
      distinctByFeeling() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'feeling');
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QDistinct>
      distinctByProudOfToday({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'proudOfToday', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QDistinct>
      distinctByTotalCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCount');
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension DailyReflectionQueryProperty
    on QueryBuilder<DailyReflection, DailyReflection, QQueryProperty> {
  QueryBuilder<DailyReflection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailyReflection, int, QQueryOperations>
      completedCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedCount');
    });
  }

  QueryBuilder<DailyReflection, String, QQueryOperations> dateStringProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateString');
    });
  }

  QueryBuilder<DailyReflection, ReflectionFeeling, QQueryOperations>
      feelingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'feeling');
    });
  }

  QueryBuilder<DailyReflection, String, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<DailyReflection, String, QQueryOperations>
      proudOfTodayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'proudOfToday');
    });
  }

  QueryBuilder<DailyReflection, int, QQueryOperations> totalCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCount');
    });
  }

  QueryBuilder<DailyReflection, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
