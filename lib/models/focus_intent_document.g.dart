// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_intent_document.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetFocusIntentDocumentCollection on Isar {
  IsarCollection<FocusIntentDocument> get focusIntentDocuments =>
      this.collection();
}

const FocusIntentDocumentSchema = CollectionSchema(
  name: r'FocusIntentDocument',
  id: 442823428906741 * 10000 + 4517,
  properties: {
    r'payload': PropertySchema(id: 0, name: r'payload', type: IsarType.string),
  },

  estimateSize: _focusIntentDocumentEstimateSize,
  serialize: _focusIntentDocumentSerialize,
  deserialize: _focusIntentDocumentDeserialize,
  deserializeProp: _focusIntentDocumentDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _focusIntentDocumentGetId,
  getLinks: _focusIntentDocumentGetLinks,
  attach: _focusIntentDocumentAttach,
  version: '3.4.1',
);

int _focusIntentDocumentEstimateSize(
  FocusIntentDocument object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.payload.length * 3;
  return bytesCount;
}

void _focusIntentDocumentSerialize(
  FocusIntentDocument object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.payload);
}

FocusIntentDocument _focusIntentDocumentDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FocusIntentDocument();
  object.id = id;
  object.payload = reader.readString(offsets[0]);
  return object;
}

P _focusIntentDocumentDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _focusIntentDocumentGetId(FocusIntentDocument object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _focusIntentDocumentGetLinks(
  FocusIntentDocument object,
) {
  return [];
}

void _focusIntentDocumentAttach(
  IsarCollection<dynamic> col,
  Id id,
  FocusIntentDocument object,
) {
  object.id = id;
}

extension FocusIntentDocumentQueryWhereSort
    on QueryBuilder<FocusIntentDocument, FocusIntentDocument, QWhere> {
  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FocusIntentDocumentQueryWhere
    on QueryBuilder<FocusIntentDocument, FocusIntentDocument, QWhereClause> {
  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterWhereClause>
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

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterWhereClause>
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
}

extension FocusIntentDocumentQueryFilter
    on
        QueryBuilder<
          FocusIntentDocument,
          FocusIntentDocument,
          QFilterCondition
        > {
  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterFilterCondition>
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

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterFilterCondition>
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

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterFilterCondition>
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

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterFilterCondition>
  payloadEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterFilterCondition>
  payloadGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterFilterCondition>
  payloadLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterFilterCondition>
  payloadBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'payload',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterFilterCondition>
  payloadStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterFilterCondition>
  payloadEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterFilterCondition>
  payloadContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterFilterCondition>
  payloadMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'payload',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterFilterCondition>
  payloadIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'payload', value: ''),
      );
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterFilterCondition>
  payloadIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'payload', value: ''),
      );
    });
  }
}

extension FocusIntentDocumentQueryObject
    on
        QueryBuilder<
          FocusIntentDocument,
          FocusIntentDocument,
          QFilterCondition
        > {}

extension FocusIntentDocumentQueryLinks
    on
        QueryBuilder<
          FocusIntentDocument,
          FocusIntentDocument,
          QFilterCondition
        > {}

extension FocusIntentDocumentQuerySortBy
    on QueryBuilder<FocusIntentDocument, FocusIntentDocument, QSortBy> {
  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterSortBy>
  sortByPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.asc);
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterSortBy>
  sortByPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.desc);
    });
  }
}

extension FocusIntentDocumentQuerySortThenBy
    on QueryBuilder<FocusIntentDocument, FocusIntentDocument, QSortThenBy> {
  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterSortBy>
  thenByPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.asc);
    });
  }

  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QAfterSortBy>
  thenByPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.desc);
    });
  }
}

extension FocusIntentDocumentQueryWhereDistinct
    on QueryBuilder<FocusIntentDocument, FocusIntentDocument, QDistinct> {
  QueryBuilder<FocusIntentDocument, FocusIntentDocument, QDistinct>
  distinctByPayload({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payload', caseSensitive: caseSensitive);
    });
  }
}

extension FocusIntentDocumentQueryProperty
    on QueryBuilder<FocusIntentDocument, FocusIntentDocument, QQueryProperty> {
  QueryBuilder<FocusIntentDocument, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FocusIntentDocument, String, QQueryOperations>
  payloadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payload');
    });
  }
}
