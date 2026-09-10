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
  id: 7755528018710024762,
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
    r'proudNote': PropertySchema(
      id: 2,
      name: r'proudNote',
      type: IsarType.string,
    ),
    r'totalCount': PropertySchema(
      id: 3,
      name: r'totalCount',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 4,
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
      id: 2390766547304188792,
      name: r'dateString',
      unique: true,
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
  bytesCount += 3 + object.proudNote.length * 3;
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
  writer.writeString(offsets[2], object.proudNote);
  writer.writeLong(offsets[3], object.totalCount);
  writer.writeDateTime(offsets[4], object.updatedAt);
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
  object.id = id;
  object.proudNote = reader.readString(offsets[2]);
  object.totalCount = reader.readLong(offsets[3]);
  object.updatedAt = reader.readDateTime(offsets[4]);
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
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

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

extension DailyReflectionByIndex on IsarCollection<DailyReflection> {
  Future<DailyReflection?> getByDateString(String dateString) {
    return getByIndex(r'dateString', [dateString]);
  }

  DailyReflection? getByDateStringSync(String dateString) {
    return getByIndexSync(r'dateString', [dateString]);
  }

  Future<bool> deleteByDateString(String dateString) {
    return deleteByIndex(r'dateString', [dateString]);
  }

  bool deleteByDateStringSync(String dateString) {
    return deleteByIndexSync(r'dateString', [dateString]);
  }

  Future<List<DailyReflection?>> getAllByDateString(
      List<String> dateStringValues) {
    final values = dateStringValues.map((e) => [e]).toList();
    return getAllByIndex(r'dateString', values);
  }

  List<DailyReflection?> getAllByDateStringSync(List<String> dateStringValues) {
    final values = dateStringValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'dateString', values);
  }

  Future<int> deleteAllByDateString(List<String> dateStringValues) {
    final values = dateStringValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'dateString', values);
  }

  int deleteAllByDateStringSync(List<String> dateStringValues) {
    final values = dateStringValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'dateString', values);
  }

  Future<Id> putByDateString(DailyReflection object) {
    return putByIndex(r'dateString', object);
  }

  Id putByDateStringSync(DailyReflection object, {bool saveLinks = true}) {
    return putByIndexSync(r'dateString', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDateString(List<DailyReflection> objects) {
    return putAllByIndex(r'dateString', objects);
  }

  List<Id> putAllByDateStringSync(List<DailyReflection> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'dateString', objects, saveLinks: saveLinks);
  }
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
      proudNoteEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proudNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudNoteGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'proudNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudNoteLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'proudNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudNoteBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'proudNote',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudNoteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'proudNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudNoteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'proudNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudNoteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'proudNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudNoteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'proudNote',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudNoteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proudNote',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterFilterCondition>
      proudNoteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'proudNote',
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

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      sortByProudNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proudNote', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      sortByProudNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proudNote', Sort.desc);
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

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      thenByProudNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proudNote', Sort.asc);
    });
  }

  QueryBuilder<DailyReflection, DailyReflection, QAfterSortBy>
      thenByProudNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proudNote', Sort.desc);
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

  QueryBuilder<DailyReflection, DailyReflection, QDistinct> distinctByProudNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'proudNote', caseSensitive: caseSensitive);
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

  QueryBuilder<DailyReflection, String, QQueryOperations> proudNoteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'proudNote');
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
