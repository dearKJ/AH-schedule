// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AcademicTermsTable extends AcademicTerms
    with TableInfo<$AcademicTermsTable, AcademicTermRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AcademicTermsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, label];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'academic_terms';
  @override
  VerificationContext validateIntegrity(
    Insertable<AcademicTermRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AcademicTermRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AcademicTermRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
    );
  }

  @override
  $AcademicTermsTable createAlias(String alias) {
    return $AcademicTermsTable(attachedDatabase, alias);
  }
}

class AcademicTermRow extends DataClass implements Insertable<AcademicTermRow> {
  final String id;
  final String label;
  const AcademicTermRow({required this.id, required this.label});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    return map;
  }

  AcademicTermsCompanion toCompanion(bool nullToAbsent) {
    return AcademicTermsCompanion(id: Value(id), label: Value(label));
  }

  factory AcademicTermRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AcademicTermRow(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
    };
  }

  AcademicTermRow copyWith({String? id, String? label}) =>
      AcademicTermRow(id: id ?? this.id, label: label ?? this.label);
  AcademicTermRow copyWithCompanion(AcademicTermsCompanion data) {
    return AcademicTermRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AcademicTermRow(')
          ..write('id: $id, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcademicTermRow &&
          other.id == this.id &&
          other.label == this.label);
}

class AcademicTermsCompanion extends UpdateCompanion<AcademicTermRow> {
  final Value<String> id;
  final Value<String> label;
  final Value<int> rowid;
  const AcademicTermsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AcademicTermsCompanion.insert({
    required String id,
    required String label,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label);
  static Insertable<AcademicTermRow> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AcademicTermsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<int>? rowid,
  }) {
    return AcademicTermsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AcademicTermsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AcademicTermsTable academicTerms = $AcademicTermsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [academicTerms];
}

typedef $$AcademicTermsTableCreateCompanionBuilder =
    AcademicTermsCompanion Function({
      required String id,
      required String label,
      Value<int> rowid,
    });
typedef $$AcademicTermsTableUpdateCompanionBuilder =
    AcademicTermsCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<int> rowid,
    });

class $$AcademicTermsTableFilterComposer
    extends Composer<_$AppDatabase, $AcademicTermsTable> {
  $$AcademicTermsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AcademicTermsTableOrderingComposer
    extends Composer<_$AppDatabase, $AcademicTermsTable> {
  $$AcademicTermsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AcademicTermsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AcademicTermsTable> {
  $$AcademicTermsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);
}

class $$AcademicTermsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AcademicTermsTable,
          AcademicTermRow,
          $$AcademicTermsTableFilterComposer,
          $$AcademicTermsTableOrderingComposer,
          $$AcademicTermsTableAnnotationComposer,
          $$AcademicTermsTableCreateCompanionBuilder,
          $$AcademicTermsTableUpdateCompanionBuilder,
          (
            AcademicTermRow,
            BaseReferences<_$AppDatabase, $AcademicTermsTable, AcademicTermRow>,
          ),
          AcademicTermRow,
          PrefetchHooks Function()
        > {
  $$AcademicTermsTableTableManager(_$AppDatabase db, $AcademicTermsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AcademicTermsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AcademicTermsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AcademicTermsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AcademicTermsCompanion(id: id, label: label, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                Value<int> rowid = const Value.absent(),
              }) => AcademicTermsCompanion.insert(
                id: id,
                label: label,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AcademicTermsTable, AcademicTermRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AcademicTermsTable,
                    AcademicTermRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AcademicTermsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AcademicTermsTable,
      AcademicTermRow,
      $$AcademicTermsTableFilterComposer,
      $$AcademicTermsTableOrderingComposer,
      $$AcademicTermsTableAnnotationComposer,
      $$AcademicTermsTableCreateCompanionBuilder,
      $$AcademicTermsTableUpdateCompanionBuilder,
      (
        AcademicTermRow,
        BaseReferences<_$AppDatabase, $AcademicTermsTable, AcademicTermRow>,
      ),
      AcademicTermRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AcademicTermsTableTableManager get academicTerms =>
      $$AcademicTermsTableTableManager(_db, _db.academicTerms);
}
