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

class $TermSettingsTableTable extends TermSettingsTable
    with TableInfo<$TermSettingsTableTable, TermSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TermSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _termIdMeta = const VerificationMeta('termId');
  @override
  late final GeneratedColumn<String> termId = GeneratedColumn<String>(
    'term_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES academic_terms (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _firstDayOfWeek1Meta = const VerificationMeta(
    'firstDayOfWeek1',
  );
  @override
  late final GeneratedColumn<DateTime> firstDayOfWeek1 =
      GeneratedColumn<DateTime>(
        'first_day_of_week1',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _totalWeeksMeta = const VerificationMeta(
    'totalWeeks',
  );
  @override
  late final GeneratedColumn<int> totalWeeks = GeneratedColumn<int>(
    'total_weeks',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bellScheduleNameMeta = const VerificationMeta(
    'bellScheduleName',
  );
  @override
  late final GeneratedColumn<String> bellScheduleName = GeneratedColumn<String>(
    'bell_schedule_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bellPeriodsMeta = const VerificationMeta(
    'bellPeriods',
  );
  @override
  late final GeneratedColumn<String> bellPeriods = GeneratedColumn<String>(
    'bell_periods',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    termId,
    firstDayOfWeek1,
    totalWeeks,
    bellScheduleName,
    bellPeriods,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'term_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<TermSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('term_id')) {
      context.handle(
        _termIdMeta,
        termId.isAcceptableOrUnknown(data['term_id']!, _termIdMeta),
      );
    } else if (isInserting) {
      context.missing(_termIdMeta);
    }
    if (data.containsKey('first_day_of_week1')) {
      context.handle(
        _firstDayOfWeek1Meta,
        firstDayOfWeek1.isAcceptableOrUnknown(
          data['first_day_of_week1']!,
          _firstDayOfWeek1Meta,
        ),
      );
    }
    if (data.containsKey('total_weeks')) {
      context.handle(
        _totalWeeksMeta,
        totalWeeks.isAcceptableOrUnknown(data['total_weeks']!, _totalWeeksMeta),
      );
    }
    if (data.containsKey('bell_schedule_name')) {
      context.handle(
        _bellScheduleNameMeta,
        bellScheduleName.isAcceptableOrUnknown(
          data['bell_schedule_name']!,
          _bellScheduleNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bellScheduleNameMeta);
    }
    if (data.containsKey('bell_periods')) {
      context.handle(
        _bellPeriodsMeta,
        bellPeriods.isAcceptableOrUnknown(
          data['bell_periods']!,
          _bellPeriodsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bellPeriodsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {termId};
  @override
  TermSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TermSettingsRow(
      termId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term_id'],
      )!,
      firstDayOfWeek1: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_day_of_week1'],
      ),
      totalWeeks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_weeks'],
      ),
      bellScheduleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bell_schedule_name'],
      )!,
      bellPeriods: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bell_periods'],
      )!,
    );
  }

  @override
  $TermSettingsTableTable createAlias(String alias) {
    return $TermSettingsTableTable(attachedDatabase, alias);
  }
}

class TermSettingsRow extends DataClass implements Insertable<TermSettingsRow> {
  /// 这份设置属于哪个学年学期。一个学期只有一份设置，所以它本身就是主键。
  final String termId;

  /// 第 1 周的第一天（必定是周一）。没设时是 NULL。
  final DateTime? firstDayOfWeek1;

  /// 学期总周数。没设时是 NULL——留空即以数据实际范围为准。
  final int? totalWeeks;
  final String bellScheduleName;

  /// 作息时间表的节次，一段 JSON 数组。
  final String bellPeriods;
  const TermSettingsRow({
    required this.termId,
    this.firstDayOfWeek1,
    this.totalWeeks,
    required this.bellScheduleName,
    required this.bellPeriods,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['term_id'] = Variable<String>(termId);
    if (!nullToAbsent || firstDayOfWeek1 != null) {
      map['first_day_of_week1'] = Variable<DateTime>(firstDayOfWeek1);
    }
    if (!nullToAbsent || totalWeeks != null) {
      map['total_weeks'] = Variable<int>(totalWeeks);
    }
    map['bell_schedule_name'] = Variable<String>(bellScheduleName);
    map['bell_periods'] = Variable<String>(bellPeriods);
    return map;
  }

  TermSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return TermSettingsTableCompanion(
      termId: Value(termId),
      firstDayOfWeek1: firstDayOfWeek1 == null && nullToAbsent
          ? const Value.absent()
          : Value(firstDayOfWeek1),
      totalWeeks: totalWeeks == null && nullToAbsent
          ? const Value.absent()
          : Value(totalWeeks),
      bellScheduleName: Value(bellScheduleName),
      bellPeriods: Value(bellPeriods),
    );
  }

  factory TermSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TermSettingsRow(
      termId: serializer.fromJson<String>(json['termId']),
      firstDayOfWeek1: serializer.fromJson<DateTime?>(json['firstDayOfWeek1']),
      totalWeeks: serializer.fromJson<int?>(json['totalWeeks']),
      bellScheduleName: serializer.fromJson<String>(json['bellScheduleName']),
      bellPeriods: serializer.fromJson<String>(json['bellPeriods']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'termId': serializer.toJson<String>(termId),
      'firstDayOfWeek1': serializer.toJson<DateTime?>(firstDayOfWeek1),
      'totalWeeks': serializer.toJson<int?>(totalWeeks),
      'bellScheduleName': serializer.toJson<String>(bellScheduleName),
      'bellPeriods': serializer.toJson<String>(bellPeriods),
    };
  }

  TermSettingsRow copyWith({
    String? termId,
    Value<DateTime?> firstDayOfWeek1 = const Value.absent(),
    Value<int?> totalWeeks = const Value.absent(),
    String? bellScheduleName,
    String? bellPeriods,
  }) => TermSettingsRow(
    termId: termId ?? this.termId,
    firstDayOfWeek1: firstDayOfWeek1.present
        ? firstDayOfWeek1.value
        : this.firstDayOfWeek1,
    totalWeeks: totalWeeks.present ? totalWeeks.value : this.totalWeeks,
    bellScheduleName: bellScheduleName ?? this.bellScheduleName,
    bellPeriods: bellPeriods ?? this.bellPeriods,
  );
  TermSettingsRow copyWithCompanion(TermSettingsTableCompanion data) {
    return TermSettingsRow(
      termId: data.termId.present ? data.termId.value : this.termId,
      firstDayOfWeek1: data.firstDayOfWeek1.present
          ? data.firstDayOfWeek1.value
          : this.firstDayOfWeek1,
      totalWeeks: data.totalWeeks.present
          ? data.totalWeeks.value
          : this.totalWeeks,
      bellScheduleName: data.bellScheduleName.present
          ? data.bellScheduleName.value
          : this.bellScheduleName,
      bellPeriods: data.bellPeriods.present
          ? data.bellPeriods.value
          : this.bellPeriods,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TermSettingsRow(')
          ..write('termId: $termId, ')
          ..write('firstDayOfWeek1: $firstDayOfWeek1, ')
          ..write('totalWeeks: $totalWeeks, ')
          ..write('bellScheduleName: $bellScheduleName, ')
          ..write('bellPeriods: $bellPeriods')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    termId,
    firstDayOfWeek1,
    totalWeeks,
    bellScheduleName,
    bellPeriods,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TermSettingsRow &&
          other.termId == this.termId &&
          other.firstDayOfWeek1 == this.firstDayOfWeek1 &&
          other.totalWeeks == this.totalWeeks &&
          other.bellScheduleName == this.bellScheduleName &&
          other.bellPeriods == this.bellPeriods);
}

class TermSettingsTableCompanion extends UpdateCompanion<TermSettingsRow> {
  final Value<String> termId;
  final Value<DateTime?> firstDayOfWeek1;
  final Value<int?> totalWeeks;
  final Value<String> bellScheduleName;
  final Value<String> bellPeriods;
  final Value<int> rowid;
  const TermSettingsTableCompanion({
    this.termId = const Value.absent(),
    this.firstDayOfWeek1 = const Value.absent(),
    this.totalWeeks = const Value.absent(),
    this.bellScheduleName = const Value.absent(),
    this.bellPeriods = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TermSettingsTableCompanion.insert({
    required String termId,
    this.firstDayOfWeek1 = const Value.absent(),
    this.totalWeeks = const Value.absent(),
    required String bellScheduleName,
    required String bellPeriods,
    this.rowid = const Value.absent(),
  }) : termId = Value(termId),
       bellScheduleName = Value(bellScheduleName),
       bellPeriods = Value(bellPeriods);
  static Insertable<TermSettingsRow> custom({
    Expression<String>? termId,
    Expression<DateTime>? firstDayOfWeek1,
    Expression<int>? totalWeeks,
    Expression<String>? bellScheduleName,
    Expression<String>? bellPeriods,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (termId != null) 'term_id': termId,
      if (firstDayOfWeek1 != null) 'first_day_of_week1': firstDayOfWeek1,
      if (totalWeeks != null) 'total_weeks': totalWeeks,
      if (bellScheduleName != null) 'bell_schedule_name': bellScheduleName,
      if (bellPeriods != null) 'bell_periods': bellPeriods,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TermSettingsTableCompanion copyWith({
    Value<String>? termId,
    Value<DateTime?>? firstDayOfWeek1,
    Value<int?>? totalWeeks,
    Value<String>? bellScheduleName,
    Value<String>? bellPeriods,
    Value<int>? rowid,
  }) {
    return TermSettingsTableCompanion(
      termId: termId ?? this.termId,
      firstDayOfWeek1: firstDayOfWeek1 ?? this.firstDayOfWeek1,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      bellScheduleName: bellScheduleName ?? this.bellScheduleName,
      bellPeriods: bellPeriods ?? this.bellPeriods,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (termId.present) {
      map['term_id'] = Variable<String>(termId.value);
    }
    if (firstDayOfWeek1.present) {
      map['first_day_of_week1'] = Variable<DateTime>(firstDayOfWeek1.value);
    }
    if (totalWeeks.present) {
      map['total_weeks'] = Variable<int>(totalWeeks.value);
    }
    if (bellScheduleName.present) {
      map['bell_schedule_name'] = Variable<String>(bellScheduleName.value);
    }
    if (bellPeriods.present) {
      map['bell_periods'] = Variable<String>(bellPeriods.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TermSettingsTableCompanion(')
          ..write('termId: $termId, ')
          ..write('firstDayOfWeek1: $firstDayOfWeek1, ')
          ..write('totalWeeks: $totalWeeks, ')
          ..write('bellScheduleName: $bellScheduleName, ')
          ..write('bellPeriods: $bellPeriods, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClassSessionsTable extends ClassSessions
    with TableInfo<$ClassSessionsTable, ClassSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _termIdMeta = const VerificationMeta('termId');
  @override
  late final GeneratedColumn<String> termId = GeneratedColumn<String>(
    'term_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES academic_terms (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseNameMeta = const VerificationMeta(
    'courseName',
  );
  @override
  late final GeneratedColumn<String> courseName = GeneratedColumn<String>(
    'course_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teacherMeta = const VerificationMeta(
    'teacher',
  );
  @override
  late final GeneratedColumn<String> teacher = GeneratedColumn<String>(
    'teacher',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodStartMeta = const VerificationMeta(
    'periodStart',
  );
  @override
  late final GeneratedColumn<int> periodStart = GeneratedColumn<int>(
    'period_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodLengthMeta = const VerificationMeta(
    'periodLength',
  );
  @override
  late final GeneratedColumn<int> periodLength = GeneratedColumn<int>(
    'period_length',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weeksMeta = const VerificationMeta('weeks');
  @override
  late final GeneratedColumn<String> weeks = GeneratedColumn<String>(
    'weeks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
    'room',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _campusMeta = const VerificationMeta('campus');
  @override
  late final GeneratedColumn<String> campus = GeneratedColumn<String>(
    'campus',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    termId,
    position,
    courseName,
    teacher,
    weekday,
    periodStart,
    periodLength,
    weeks,
    room,
    campus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'class_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('term_id')) {
      context.handle(
        _termIdMeta,
        termId.isAcceptableOrUnknown(data['term_id']!, _termIdMeta),
      );
    } else if (isInserting) {
      context.missing(_termIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('course_name')) {
      context.handle(
        _courseNameMeta,
        courseName.isAcceptableOrUnknown(data['course_name']!, _courseNameMeta),
      );
    } else if (isInserting) {
      context.missing(_courseNameMeta);
    }
    if (data.containsKey('teacher')) {
      context.handle(
        _teacherMeta,
        teacher.isAcceptableOrUnknown(data['teacher']!, _teacherMeta),
      );
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('period_start')) {
      context.handle(
        _periodStartMeta,
        periodStart.isAcceptableOrUnknown(
          data['period_start']!,
          _periodStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('period_length')) {
      context.handle(
        _periodLengthMeta,
        periodLength.isAcceptableOrUnknown(
          data['period_length']!,
          _periodLengthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodLengthMeta);
    }
    if (data.containsKey('weeks')) {
      context.handle(
        _weeksMeta,
        weeks.isAcceptableOrUnknown(data['weeks']!, _weeksMeta),
      );
    } else if (isInserting) {
      context.missing(_weeksMeta);
    }
    if (data.containsKey('room')) {
      context.handle(
        _roomMeta,
        room.isAcceptableOrUnknown(data['room']!, _roomMeta),
      );
    } else if (isInserting) {
      context.missing(_roomMeta);
    }
    if (data.containsKey('campus')) {
      context.handle(
        _campusMeta,
        campus.isAcceptableOrUnknown(data['campus']!, _campusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClassSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      termId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      courseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_name'],
      )!,
      teacher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher'],
      ),
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      periodStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period_start'],
      )!,
      periodLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period_length'],
      )!,
      weeks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weeks'],
      )!,
      room: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room'],
      )!,
      campus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}campus'],
      ),
    );
  }

  @override
  $ClassSessionsTable createAlias(String alias) {
    return $ClassSessionsTable(attachedDatabase, alias);
  }
}

class ClassSessionRow extends DataClass implements Insertable<ClassSessionRow> {
  /// 自增主键。
  ///
  /// 领域层里一条安排没有标识——它是**值**，靠内容区分。需要标识的是**例外**：它得
  /// 指回自己挂在哪条安排上。所以这个 id 是数据层为了挂载关系造出来的，领域层看不见它。
  final int id;

  /// 属于哪个学年学期。课表按它隔离。
  ///
  /// 外键指向学年学期，并且**删学期时级联删掉它的全部安排**——这是行的归属，不是业务
  /// 规则。级联要真的生效，得靠 `PRAGMA foreign_keys`，那个在 [_enableForeignKeys] 里开。
  final String termId;

  /// 这条安排在它那个学期课表里的次序，从 0 开始。
  ///
  /// 领域层说「保持传入顺序」（导入时是解析顺序，手动录入时是录入顺序），SQL 本身不保证
  /// 任何行序，所以次序得自己存。
  final int position;
  final String courseName;

  /// 没有教师时是 NULL。
  final String? teacher;

  /// 星期几：1 = 星期一 … 7 = 星期日。
  final int weekday;

  /// 起始节次，配 [_ClassSessionsTable.periodLength] 一起表示连堂。
  final int periodStart;

  /// 连着的节数。
  final int periodLength;

  /// 周次集合，写成 `1,2,3,5` 这样的升序整数表。
  ///
  /// 领域层说周次**是集合、不是写法**（单双周 / 断档周只是同一组周次的写法），所以这里
  /// 存的是一组升序整数，教务系统那套写法一个字都不进库。编解码在
  /// `timetable_repository.dart`。
  final String weeks;

  /// 教室名。线上教学时是「线上教学」——领域层把它当作教室名那一格的内容。
  final String room;

  /// 校区。没有时是 NULL。
  final String? campus;
  const ClassSessionRow({
    required this.id,
    required this.termId,
    required this.position,
    required this.courseName,
    this.teacher,
    required this.weekday,
    required this.periodStart,
    required this.periodLength,
    required this.weeks,
    required this.room,
    this.campus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['term_id'] = Variable<String>(termId);
    map['position'] = Variable<int>(position);
    map['course_name'] = Variable<String>(courseName);
    if (!nullToAbsent || teacher != null) {
      map['teacher'] = Variable<String>(teacher);
    }
    map['weekday'] = Variable<int>(weekday);
    map['period_start'] = Variable<int>(periodStart);
    map['period_length'] = Variable<int>(periodLength);
    map['weeks'] = Variable<String>(weeks);
    map['room'] = Variable<String>(room);
    if (!nullToAbsent || campus != null) {
      map['campus'] = Variable<String>(campus);
    }
    return map;
  }

  ClassSessionsCompanion toCompanion(bool nullToAbsent) {
    return ClassSessionsCompanion(
      id: Value(id),
      termId: Value(termId),
      position: Value(position),
      courseName: Value(courseName),
      teacher: teacher == null && nullToAbsent
          ? const Value.absent()
          : Value(teacher),
      weekday: Value(weekday),
      periodStart: Value(periodStart),
      periodLength: Value(periodLength),
      weeks: Value(weeks),
      room: Value(room),
      campus: campus == null && nullToAbsent
          ? const Value.absent()
          : Value(campus),
    );
  }

  factory ClassSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassSessionRow(
      id: serializer.fromJson<int>(json['id']),
      termId: serializer.fromJson<String>(json['termId']),
      position: serializer.fromJson<int>(json['position']),
      courseName: serializer.fromJson<String>(json['courseName']),
      teacher: serializer.fromJson<String?>(json['teacher']),
      weekday: serializer.fromJson<int>(json['weekday']),
      periodStart: serializer.fromJson<int>(json['periodStart']),
      periodLength: serializer.fromJson<int>(json['periodLength']),
      weeks: serializer.fromJson<String>(json['weeks']),
      room: serializer.fromJson<String>(json['room']),
      campus: serializer.fromJson<String?>(json['campus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'termId': serializer.toJson<String>(termId),
      'position': serializer.toJson<int>(position),
      'courseName': serializer.toJson<String>(courseName),
      'teacher': serializer.toJson<String?>(teacher),
      'weekday': serializer.toJson<int>(weekday),
      'periodStart': serializer.toJson<int>(periodStart),
      'periodLength': serializer.toJson<int>(periodLength),
      'weeks': serializer.toJson<String>(weeks),
      'room': serializer.toJson<String>(room),
      'campus': serializer.toJson<String?>(campus),
    };
  }

  ClassSessionRow copyWith({
    int? id,
    String? termId,
    int? position,
    String? courseName,
    Value<String?> teacher = const Value.absent(),
    int? weekday,
    int? periodStart,
    int? periodLength,
    String? weeks,
    String? room,
    Value<String?> campus = const Value.absent(),
  }) => ClassSessionRow(
    id: id ?? this.id,
    termId: termId ?? this.termId,
    position: position ?? this.position,
    courseName: courseName ?? this.courseName,
    teacher: teacher.present ? teacher.value : this.teacher,
    weekday: weekday ?? this.weekday,
    periodStart: periodStart ?? this.periodStart,
    periodLength: periodLength ?? this.periodLength,
    weeks: weeks ?? this.weeks,
    room: room ?? this.room,
    campus: campus.present ? campus.value : this.campus,
  );
  ClassSessionRow copyWithCompanion(ClassSessionsCompanion data) {
    return ClassSessionRow(
      id: data.id.present ? data.id.value : this.id,
      termId: data.termId.present ? data.termId.value : this.termId,
      position: data.position.present ? data.position.value : this.position,
      courseName: data.courseName.present
          ? data.courseName.value
          : this.courseName,
      teacher: data.teacher.present ? data.teacher.value : this.teacher,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      periodStart: data.periodStart.present
          ? data.periodStart.value
          : this.periodStart,
      periodLength: data.periodLength.present
          ? data.periodLength.value
          : this.periodLength,
      weeks: data.weeks.present ? data.weeks.value : this.weeks,
      room: data.room.present ? data.room.value : this.room,
      campus: data.campus.present ? data.campus.value : this.campus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassSessionRow(')
          ..write('id: $id, ')
          ..write('termId: $termId, ')
          ..write('position: $position, ')
          ..write('courseName: $courseName, ')
          ..write('teacher: $teacher, ')
          ..write('weekday: $weekday, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodLength: $periodLength, ')
          ..write('weeks: $weeks, ')
          ..write('room: $room, ')
          ..write('campus: $campus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    termId,
    position,
    courseName,
    teacher,
    weekday,
    periodStart,
    periodLength,
    weeks,
    room,
    campus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassSessionRow &&
          other.id == this.id &&
          other.termId == this.termId &&
          other.position == this.position &&
          other.courseName == this.courseName &&
          other.teacher == this.teacher &&
          other.weekday == this.weekday &&
          other.periodStart == this.periodStart &&
          other.periodLength == this.periodLength &&
          other.weeks == this.weeks &&
          other.room == this.room &&
          other.campus == this.campus);
}

class ClassSessionsCompanion extends UpdateCompanion<ClassSessionRow> {
  final Value<int> id;
  final Value<String> termId;
  final Value<int> position;
  final Value<String> courseName;
  final Value<String?> teacher;
  final Value<int> weekday;
  final Value<int> periodStart;
  final Value<int> periodLength;
  final Value<String> weeks;
  final Value<String> room;
  final Value<String?> campus;
  const ClassSessionsCompanion({
    this.id = const Value.absent(),
    this.termId = const Value.absent(),
    this.position = const Value.absent(),
    this.courseName = const Value.absent(),
    this.teacher = const Value.absent(),
    this.weekday = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodLength = const Value.absent(),
    this.weeks = const Value.absent(),
    this.room = const Value.absent(),
    this.campus = const Value.absent(),
  });
  ClassSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String termId,
    required int position,
    required String courseName,
    this.teacher = const Value.absent(),
    required int weekday,
    required int periodStart,
    required int periodLength,
    required String weeks,
    required String room,
    this.campus = const Value.absent(),
  }) : termId = Value(termId),
       position = Value(position),
       courseName = Value(courseName),
       weekday = Value(weekday),
       periodStart = Value(periodStart),
       periodLength = Value(periodLength),
       weeks = Value(weeks),
       room = Value(room);
  static Insertable<ClassSessionRow> custom({
    Expression<int>? id,
    Expression<String>? termId,
    Expression<int>? position,
    Expression<String>? courseName,
    Expression<String>? teacher,
    Expression<int>? weekday,
    Expression<int>? periodStart,
    Expression<int>? periodLength,
    Expression<String>? weeks,
    Expression<String>? room,
    Expression<String>? campus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (termId != null) 'term_id': termId,
      if (position != null) 'position': position,
      if (courseName != null) 'course_name': courseName,
      if (teacher != null) 'teacher': teacher,
      if (weekday != null) 'weekday': weekday,
      if (periodStart != null) 'period_start': periodStart,
      if (periodLength != null) 'period_length': periodLength,
      if (weeks != null) 'weeks': weeks,
      if (room != null) 'room': room,
      if (campus != null) 'campus': campus,
    });
  }

  ClassSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? termId,
    Value<int>? position,
    Value<String>? courseName,
    Value<String?>? teacher,
    Value<int>? weekday,
    Value<int>? periodStart,
    Value<int>? periodLength,
    Value<String>? weeks,
    Value<String>? room,
    Value<String?>? campus,
  }) {
    return ClassSessionsCompanion(
      id: id ?? this.id,
      termId: termId ?? this.termId,
      position: position ?? this.position,
      courseName: courseName ?? this.courseName,
      teacher: teacher ?? this.teacher,
      weekday: weekday ?? this.weekday,
      periodStart: periodStart ?? this.periodStart,
      periodLength: periodLength ?? this.periodLength,
      weeks: weeks ?? this.weeks,
      room: room ?? this.room,
      campus: campus ?? this.campus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (termId.present) {
      map['term_id'] = Variable<String>(termId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (courseName.present) {
      map['course_name'] = Variable<String>(courseName.value);
    }
    if (teacher.present) {
      map['teacher'] = Variable<String>(teacher.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<int>(periodStart.value);
    }
    if (periodLength.present) {
      map['period_length'] = Variable<int>(periodLength.value);
    }
    if (weeks.present) {
      map['weeks'] = Variable<String>(weeks.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (campus.present) {
      map['campus'] = Variable<String>(campus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassSessionsCompanion(')
          ..write('id: $id, ')
          ..write('termId: $termId, ')
          ..write('position: $position, ')
          ..write('courseName: $courseName, ')
          ..write('teacher: $teacher, ')
          ..write('weekday: $weekday, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodLength: $periodLength, ')
          ..write('weeks: $weeks, ')
          ..write('room: $room, ')
          ..write('campus: $campus')
          ..write(')'))
        .toString();
  }
}

class $SessionExceptionsTable extends SessionExceptions
    with TableInfo<$SessionExceptionsTable, SessionExceptionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionExceptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES class_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekMeta = const VerificationMeta('week');
  @override
  late final GeneratedColumn<int> week = GeneratedColumn<int>(
    'week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _campusMeta = const VerificationMeta('campus');
  @override
  late final GeneratedColumn<String> campus = GeneratedColumn<String>(
    'campus',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    kind,
    week,
    campus,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_exceptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionExceptionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('week')) {
      context.handle(
        _weekMeta,
        week.isAcceptableOrUnknown(data['week']!, _weekMeta),
      );
    } else if (isInserting) {
      context.missing(_weekMeta);
    }
    if (data.containsKey('campus')) {
      context.handle(
        _campusMeta,
        campus.isAcceptableOrUnknown(data['campus']!, _campusMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionExceptionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionExceptionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      week: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week'],
      )!,
      campus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}campus'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $SessionExceptionsTable createAlias(String alias) {
    return $SessionExceptionsTable(attachedDatabase, alias);
  }
}

class SessionExceptionRow extends DataClass
    implements Insertable<SessionExceptionRow> {
  final int id;

  /// 挂在哪条安排上。安排一没，它的例外就没地方挂了，级联一起走。
  final int sessionId;

  /// 哪一种变化：停课 / 线上教学，写成 `cancellation` / `onlineTeaching`。
  ///
  /// 认字符串是这一层唯一几处「不绑 Dart 标识符」的地方——重命名一个类不该让库里已有的
  /// 行读不出来。编解码在 `timetable_repository.dart`。
  final String kind;

  /// 例外落在哪个教学周。
  final int week;

  /// 线上教学写在校区那一格的校区；停课例外没有这一项，是 NULL。
  final String? campus;

  /// 同一条安排上多个例外的次序（一条安排可以挂多个例外）。
  final int position;
  const SessionExceptionRow({
    required this.id,
    required this.sessionId,
    required this.kind,
    required this.week,
    this.campus,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['kind'] = Variable<String>(kind);
    map['week'] = Variable<int>(week);
    if (!nullToAbsent || campus != null) {
      map['campus'] = Variable<String>(campus);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  SessionExceptionsCompanion toCompanion(bool nullToAbsent) {
    return SessionExceptionsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      kind: Value(kind),
      week: Value(week),
      campus: campus == null && nullToAbsent
          ? const Value.absent()
          : Value(campus),
      position: Value(position),
    );
  }

  factory SessionExceptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionExceptionRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      kind: serializer.fromJson<String>(json['kind']),
      week: serializer.fromJson<int>(json['week']),
      campus: serializer.fromJson<String?>(json['campus']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'kind': serializer.toJson<String>(kind),
      'week': serializer.toJson<int>(week),
      'campus': serializer.toJson<String?>(campus),
      'position': serializer.toJson<int>(position),
    };
  }

  SessionExceptionRow copyWith({
    int? id,
    int? sessionId,
    String? kind,
    int? week,
    Value<String?> campus = const Value.absent(),
    int? position,
  }) => SessionExceptionRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    kind: kind ?? this.kind,
    week: week ?? this.week,
    campus: campus.present ? campus.value : this.campus,
    position: position ?? this.position,
  );
  SessionExceptionRow copyWithCompanion(SessionExceptionsCompanion data) {
    return SessionExceptionRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      kind: data.kind.present ? data.kind.value : this.kind,
      week: data.week.present ? data.week.value : this.week,
      campus: data.campus.present ? data.campus.value : this.campus,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionExceptionRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('kind: $kind, ')
          ..write('week: $week, ')
          ..write('campus: $campus, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, kind, week, campus, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionExceptionRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.kind == this.kind &&
          other.week == this.week &&
          other.campus == this.campus &&
          other.position == this.position);
}

class SessionExceptionsCompanion extends UpdateCompanion<SessionExceptionRow> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> kind;
  final Value<int> week;
  final Value<String?> campus;
  final Value<int> position;
  const SessionExceptionsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.kind = const Value.absent(),
    this.week = const Value.absent(),
    this.campus = const Value.absent(),
    this.position = const Value.absent(),
  });
  SessionExceptionsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String kind,
    required int week,
    this.campus = const Value.absent(),
    required int position,
  }) : sessionId = Value(sessionId),
       kind = Value(kind),
       week = Value(week),
       position = Value(position);
  static Insertable<SessionExceptionRow> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? kind,
    Expression<int>? week,
    Expression<String>? campus,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (kind != null) 'kind': kind,
      if (week != null) 'week': week,
      if (campus != null) 'campus': campus,
      if (position != null) 'position': position,
    });
  }

  SessionExceptionsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String>? kind,
    Value<int>? week,
    Value<String?>? campus,
    Value<int>? position,
  }) {
    return SessionExceptionsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      kind: kind ?? this.kind,
      week: week ?? this.week,
      campus: campus ?? this.campus,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (week.present) {
      map['week'] = Variable<int>(week.value);
    }
    if (campus.present) {
      map['campus'] = Variable<String>(campus.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionExceptionsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('kind: $kind, ')
          ..write('week: $week, ')
          ..write('campus: $campus, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AcademicTermsTable academicTerms = $AcademicTermsTable(this);
  late final $TermSettingsTableTable termSettingsTable =
      $TermSettingsTableTable(this);
  late final $ClassSessionsTable classSessions = $ClassSessionsTable(this);
  late final $SessionExceptionsTable sessionExceptions =
      $SessionExceptionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    academicTerms,
    termSettingsTable,
    classSessions,
    sessionExceptions,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'academic_terms',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('term_settings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'academic_terms',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('class_sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'class_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_exceptions', kind: UpdateKind.delete)],
    ),
  ]);
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

final class $$AcademicTermsTableReferences
    extends
        BaseReferences<_$AppDatabase, $AcademicTermsTable, AcademicTermRow> {
  $$AcademicTermsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TermSettingsTableTable, List<TermSettingsRow>>
  _termSettingsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.termSettingsTable,
        aliasName: 'academic_terms__id__term_settings__term_id',
      );

  $$TermSettingsTableTableProcessedTableManager get termSettingsTableRefs {
    final manager = $$TermSettingsTableTableTableManager(
      $_db,
      $_db.termSettingsTable,
    ).filter((f) => f.termId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _termSettingsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ClassSessionsTable, List<ClassSessionRow>>
  _classSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.classSessions,
    aliasName: 'academic_terms__id__class_sessions__term_id',
  );

  $$ClassSessionsTableProcessedTableManager get classSessionsRefs {
    final manager = $$ClassSessionsTableTableManager(
      $_db,
      $_db.classSessions,
    ).filter((f) => f.termId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_classSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  Expression<bool> termSettingsTableRefs(
    Expression<bool> Function($$TermSettingsTableTableFilterComposer f) f,
  ) {
    final $$TermSettingsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.termSettingsTable,
      getReferencedColumn: (t) => t.termId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TermSettingsTableTableFilterComposer(
            $db: $db,
            $table: $db.termSettingsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> classSessionsRefs(
    Expression<bool> Function($$ClassSessionsTableFilterComposer f) f,
  ) {
    final $$ClassSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.classSessions,
      getReferencedColumn: (t) => t.termId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassSessionsTableFilterComposer(
            $db: $db,
            $table: $db.classSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  Expression<T> termSettingsTableRefs<T extends Object>(
    Expression<T> Function($$TermSettingsTableTableAnnotationComposer a) f,
  ) {
    final $$TermSettingsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.termSettingsTable,
          getReferencedColumn: (t) => t.termId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TermSettingsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.termSettingsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> classSessionsRefs<T extends Object>(
    Expression<T> Function($$ClassSessionsTableAnnotationComposer a) f,
  ) {
    final $$ClassSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.classSessions,
      getReferencedColumn: (t) => t.termId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.classSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (AcademicTermRow, $$AcademicTermsTableReferences),
          AcademicTermRow,
          PrefetchHooks Function({
            bool termSettingsTableRefs,
            bool classSessionsRefs,
          })
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
                  $$AcademicTermsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({termSettingsTableRefs = false, classSessionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (termSettingsTableRefs) db.termSettingsTable,
                    if (classSessionsRefs) db.classSessions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (termSettingsTableRefs)
                        await $_getPrefetchedData<
                          AcademicTermRow,
                          $AcademicTermsTable,
                          TermSettingsRow
                        >(
                          currentTable: table,
                          referencedTable: $$AcademicTermsTableReferences
                              ._termSettingsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AcademicTermsTableReferences(
                                db,
                                table,
                                p0,
                              ).termSettingsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.termId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (classSessionsRefs)
                        await $_getPrefetchedData<
                          AcademicTermRow,
                          $AcademicTermsTable,
                          ClassSessionRow
                        >(
                          currentTable: table,
                          referencedTable: $$AcademicTermsTableReferences
                              ._classSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AcademicTermsTableReferences(
                                db,
                                table,
                                p0,
                              ).classSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.termId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (AcademicTermRow, $$AcademicTermsTableReferences),
      AcademicTermRow,
      PrefetchHooks Function({
        bool termSettingsTableRefs,
        bool classSessionsRefs,
      })
    >;
typedef $$TermSettingsTableTableCreateCompanionBuilder =
    TermSettingsTableCompanion Function({
      required String termId,
      Value<DateTime?> firstDayOfWeek1,
      Value<int?> totalWeeks,
      required String bellScheduleName,
      required String bellPeriods,
      Value<int> rowid,
    });
typedef $$TermSettingsTableTableUpdateCompanionBuilder =
    TermSettingsTableCompanion Function({
      Value<String> termId,
      Value<DateTime?> firstDayOfWeek1,
      Value<int?> totalWeeks,
      Value<String> bellScheduleName,
      Value<String> bellPeriods,
      Value<int> rowid,
    });

final class $$TermSettingsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TermSettingsTableTable,
          TermSettingsRow
        > {
  $$TermSettingsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AcademicTermsTable _termIdTable(_$AppDatabase db) => db.academicTerms
      .createAlias('term_settings__term_id__academic_terms__id');

  $$AcademicTermsTableProcessedTableManager get termId {
    final $_column = $_itemColumn<String>('term_id')!;

    final manager = $$AcademicTermsTableTableManager(
      $_db,
      $_db.academicTerms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_termIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TermSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TermSettingsTableTable> {
  $$TermSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get firstDayOfWeek1 => $composableBuilder(
    column: $table.firstDayOfWeek1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bellScheduleName => $composableBuilder(
    column: $table.bellScheduleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bellPeriods => $composableBuilder(
    column: $table.bellPeriods,
    builder: (column) => ColumnFilters(column),
  );

  $$AcademicTermsTableFilterComposer get termId {
    final $$AcademicTermsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.termId,
      referencedTable: $db.academicTerms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicTermsTableFilterComposer(
            $db: $db,
            $table: $db.academicTerms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TermSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TermSettingsTableTable> {
  $$TermSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get firstDayOfWeek1 => $composableBuilder(
    column: $table.firstDayOfWeek1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bellScheduleName => $composableBuilder(
    column: $table.bellScheduleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bellPeriods => $composableBuilder(
    column: $table.bellPeriods,
    builder: (column) => ColumnOrderings(column),
  );

  $$AcademicTermsTableOrderingComposer get termId {
    final $$AcademicTermsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.termId,
      referencedTable: $db.academicTerms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicTermsTableOrderingComposer(
            $db: $db,
            $table: $db.academicTerms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TermSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TermSettingsTableTable> {
  $$TermSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get firstDayOfWeek1 => $composableBuilder(
    column: $table.firstDayOfWeek1,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalWeeks => $composableBuilder(
    column: $table.totalWeeks,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bellScheduleName => $composableBuilder(
    column: $table.bellScheduleName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bellPeriods => $composableBuilder(
    column: $table.bellPeriods,
    builder: (column) => column,
  );

  $$AcademicTermsTableAnnotationComposer get termId {
    final $$AcademicTermsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.termId,
      referencedTable: $db.academicTerms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicTermsTableAnnotationComposer(
            $db: $db,
            $table: $db.academicTerms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TermSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TermSettingsTableTable,
          TermSettingsRow,
          $$TermSettingsTableTableFilterComposer,
          $$TermSettingsTableTableOrderingComposer,
          $$TermSettingsTableTableAnnotationComposer,
          $$TermSettingsTableTableCreateCompanionBuilder,
          $$TermSettingsTableTableUpdateCompanionBuilder,
          (TermSettingsRow, $$TermSettingsTableTableReferences),
          TermSettingsRow,
          PrefetchHooks Function({bool termId})
        > {
  $$TermSettingsTableTableTableManager(
    _$AppDatabase db,
    $TermSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TermSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TermSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TermSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> termId = const Value.absent(),
                Value<DateTime?> firstDayOfWeek1 = const Value.absent(),
                Value<int?> totalWeeks = const Value.absent(),
                Value<String> bellScheduleName = const Value.absent(),
                Value<String> bellPeriods = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TermSettingsTableCompanion(
                termId: termId,
                firstDayOfWeek1: firstDayOfWeek1,
                totalWeeks: totalWeeks,
                bellScheduleName: bellScheduleName,
                bellPeriods: bellPeriods,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String termId,
                Value<DateTime?> firstDayOfWeek1 = const Value.absent(),
                Value<int?> totalWeeks = const Value.absent(),
                required String bellScheduleName,
                required String bellPeriods,
                Value<int> rowid = const Value.absent(),
              }) => TermSettingsTableCompanion.insert(
                termId: termId,
                firstDayOfWeek1: firstDayOfWeek1,
                totalWeeks: totalWeeks,
                bellScheduleName: bellScheduleName,
                bellPeriods: bellPeriods,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TermSettingsTableTable, TermSettingsRow>(table),
                  $$TermSettingsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({termId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (termId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.termId,
                        referencedTable: $$TermSettingsTableTableReferences
                            ._termIdTable(db),
                        referencedColumn: $$TermSettingsTableTableReferences
                            ._termIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TermSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TermSettingsTableTable,
      TermSettingsRow,
      $$TermSettingsTableTableFilterComposer,
      $$TermSettingsTableTableOrderingComposer,
      $$TermSettingsTableTableAnnotationComposer,
      $$TermSettingsTableTableCreateCompanionBuilder,
      $$TermSettingsTableTableUpdateCompanionBuilder,
      (TermSettingsRow, $$TermSettingsTableTableReferences),
      TermSettingsRow,
      PrefetchHooks Function({bool termId})
    >;
typedef $$ClassSessionsTableCreateCompanionBuilder =
    ClassSessionsCompanion Function({
      Value<int> id,
      required String termId,
      required int position,
      required String courseName,
      Value<String?> teacher,
      required int weekday,
      required int periodStart,
      required int periodLength,
      required String weeks,
      required String room,
      Value<String?> campus,
    });
typedef $$ClassSessionsTableUpdateCompanionBuilder =
    ClassSessionsCompanion Function({
      Value<int> id,
      Value<String> termId,
      Value<int> position,
      Value<String> courseName,
      Value<String?> teacher,
      Value<int> weekday,
      Value<int> periodStart,
      Value<int> periodLength,
      Value<String> weeks,
      Value<String> room,
      Value<String?> campus,
    });

final class $$ClassSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ClassSessionsTable, ClassSessionRow> {
  $$ClassSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AcademicTermsTable _termIdTable(_$AppDatabase db) => db.academicTerms
      .createAlias('class_sessions__term_id__academic_terms__id');

  $$AcademicTermsTableProcessedTableManager get termId {
    final $_column = $_itemColumn<String>('term_id')!;

    final manager = $$AcademicTermsTableTableManager(
      $_db,
      $_db.academicTerms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_termIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SessionExceptionsTable, List<SessionExceptionRow>>
  _sessionExceptionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.sessionExceptions,
        aliasName: 'class_sessions__id__session_exceptions__session_id',
      );

  $$SessionExceptionsTableProcessedTableManager get sessionExceptionsRefs {
    final manager = $$SessionExceptionsTableTableManager(
      $_db,
      $_db.sessionExceptions,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionExceptionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClassSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ClassSessionsTable> {
  $$ClassSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get periodLength => $composableBuilder(
    column: $table.periodLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weeks => $composableBuilder(
    column: $table.weeks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get campus => $composableBuilder(
    column: $table.campus,
    builder: (column) => ColumnFilters(column),
  );

  $$AcademicTermsTableFilterComposer get termId {
    final $$AcademicTermsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.termId,
      referencedTable: $db.academicTerms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicTermsTableFilterComposer(
            $db: $db,
            $table: $db.academicTerms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sessionExceptionsRefs(
    Expression<bool> Function($$SessionExceptionsTableFilterComposer f) f,
  ) {
    final $$SessionExceptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionExceptions,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExceptionsTableFilterComposer(
            $db: $db,
            $table: $db.sessionExceptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClassSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassSessionsTable> {
  $$ClassSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teacher => $composableBuilder(
    column: $table.teacher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get periodLength => $composableBuilder(
    column: $table.periodLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weeks => $composableBuilder(
    column: $table.weeks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get campus => $composableBuilder(
    column: $table.campus,
    builder: (column) => ColumnOrderings(column),
  );

  $$AcademicTermsTableOrderingComposer get termId {
    final $$AcademicTermsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.termId,
      referencedTable: $db.academicTerms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicTermsTableOrderingComposer(
            $db: $db,
            $table: $db.academicTerms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClassSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassSessionsTable> {
  $$ClassSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get teacher =>
      $composableBuilder(column: $table.teacher, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<int> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get periodLength => $composableBuilder(
    column: $table.periodLength,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weeks =>
      $composableBuilder(column: $table.weeks, builder: (column) => column);

  GeneratedColumn<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => column);

  GeneratedColumn<String> get campus =>
      $composableBuilder(column: $table.campus, builder: (column) => column);

  $$AcademicTermsTableAnnotationComposer get termId {
    final $$AcademicTermsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.termId,
      referencedTable: $db.academicTerms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicTermsTableAnnotationComposer(
            $db: $db,
            $table: $db.academicTerms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sessionExceptionsRefs<T extends Object>(
    Expression<T> Function($$SessionExceptionsTableAnnotationComposer a) f,
  ) {
    final $$SessionExceptionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.sessionExceptions,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SessionExceptionsTableAnnotationComposer(
                $db: $db,
                $table: $db.sessionExceptions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ClassSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClassSessionsTable,
          ClassSessionRow,
          $$ClassSessionsTableFilterComposer,
          $$ClassSessionsTableOrderingComposer,
          $$ClassSessionsTableAnnotationComposer,
          $$ClassSessionsTableCreateCompanionBuilder,
          $$ClassSessionsTableUpdateCompanionBuilder,
          (ClassSessionRow, $$ClassSessionsTableReferences),
          ClassSessionRow,
          PrefetchHooks Function({bool termId, bool sessionExceptionsRefs})
        > {
  $$ClassSessionsTableTableManager(_$AppDatabase db, $ClassSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClassSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> termId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> courseName = const Value.absent(),
                Value<String?> teacher = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<int> periodStart = const Value.absent(),
                Value<int> periodLength = const Value.absent(),
                Value<String> weeks = const Value.absent(),
                Value<String> room = const Value.absent(),
                Value<String?> campus = const Value.absent(),
              }) => ClassSessionsCompanion(
                id: id,
                termId: termId,
                position: position,
                courseName: courseName,
                teacher: teacher,
                weekday: weekday,
                periodStart: periodStart,
                periodLength: periodLength,
                weeks: weeks,
                room: room,
                campus: campus,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String termId,
                required int position,
                required String courseName,
                Value<String?> teacher = const Value.absent(),
                required int weekday,
                required int periodStart,
                required int periodLength,
                required String weeks,
                required String room,
                Value<String?> campus = const Value.absent(),
              }) => ClassSessionsCompanion.insert(
                id: id,
                termId: termId,
                position: position,
                courseName: courseName,
                teacher: teacher,
                weekday: weekday,
                periodStart: periodStart,
                periodLength: periodLength,
                weeks: weeks,
                room: room,
                campus: campus,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClassSessionsTable, ClassSessionRow>(table),
                  $$ClassSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({termId = false, sessionExceptionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionExceptionsRefs) db.sessionExceptions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (termId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.termId,
                            referencedTable: $$ClassSessionsTableReferences
                                ._termIdTable(db),
                            referencedColumn: $$ClassSessionsTableReferences
                                ._termIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sessionExceptionsRefs)
                        await $_getPrefetchedData<
                          ClassSessionRow,
                          $ClassSessionsTable,
                          SessionExceptionRow
                        >(
                          currentTable: table,
                          referencedTable: $$ClassSessionsTableReferences
                              ._sessionExceptionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClassSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionExceptionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ClassSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClassSessionsTable,
      ClassSessionRow,
      $$ClassSessionsTableFilterComposer,
      $$ClassSessionsTableOrderingComposer,
      $$ClassSessionsTableAnnotationComposer,
      $$ClassSessionsTableCreateCompanionBuilder,
      $$ClassSessionsTableUpdateCompanionBuilder,
      (ClassSessionRow, $$ClassSessionsTableReferences),
      ClassSessionRow,
      PrefetchHooks Function({bool termId, bool sessionExceptionsRefs})
    >;
typedef $$SessionExceptionsTableCreateCompanionBuilder =
    SessionExceptionsCompanion Function({
      Value<int> id,
      required int sessionId,
      required String kind,
      required int week,
      Value<String?> campus,
      required int position,
    });
typedef $$SessionExceptionsTableUpdateCompanionBuilder =
    SessionExceptionsCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<String> kind,
      Value<int> week,
      Value<String?> campus,
      Value<int> position,
    });

final class $$SessionExceptionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SessionExceptionsTable,
          SessionExceptionRow
        > {
  $$SessionExceptionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClassSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .classSessions
      .createAlias('session_exceptions__session_id__class_sessions__id');

  $$ClassSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$ClassSessionsTableTableManager(
      $_db,
      $_db.classSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionExceptionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionExceptionsTable> {
  $$SessionExceptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get week => $composableBuilder(
    column: $table.week,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get campus => $composableBuilder(
    column: $table.campus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$ClassSessionsTableFilterComposer get sessionId {
    final $$ClassSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.classSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassSessionsTableFilterComposer(
            $db: $db,
            $table: $db.classSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionExceptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionExceptionsTable> {
  $$SessionExceptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get week => $composableBuilder(
    column: $table.week,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get campus => $composableBuilder(
    column: $table.campus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClassSessionsTableOrderingComposer get sessionId {
    final $$ClassSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.classSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.classSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionExceptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionExceptionsTable> {
  $$SessionExceptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get week =>
      $composableBuilder(column: $table.week, builder: (column) => column);

  GeneratedColumn<String> get campus =>
      $composableBuilder(column: $table.campus, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$ClassSessionsTableAnnotationComposer get sessionId {
    final $$ClassSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.classSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.classSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionExceptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionExceptionsTable,
          SessionExceptionRow,
          $$SessionExceptionsTableFilterComposer,
          $$SessionExceptionsTableOrderingComposer,
          $$SessionExceptionsTableAnnotationComposer,
          $$SessionExceptionsTableCreateCompanionBuilder,
          $$SessionExceptionsTableUpdateCompanionBuilder,
          (SessionExceptionRow, $$SessionExceptionsTableReferences),
          SessionExceptionRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$SessionExceptionsTableTableManager(
    _$AppDatabase db,
    $SessionExceptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionExceptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionExceptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionExceptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> week = const Value.absent(),
                Value<String?> campus = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => SessionExceptionsCompanion(
                id: id,
                sessionId: sessionId,
                kind: kind,
                week: week,
                campus: campus,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required String kind,
                required int week,
                Value<String?> campus = const Value.absent(),
                required int position,
              }) => SessionExceptionsCompanion.insert(
                id: id,
                sessionId: sessionId,
                kind: kind,
                week: week,
                campus: campus,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionExceptionsTable, SessionExceptionRow>(
                    table,
                  ),
                  $$SessionExceptionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$SessionExceptionsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$SessionExceptionsTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SessionExceptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionExceptionsTable,
      SessionExceptionRow,
      $$SessionExceptionsTableFilterComposer,
      $$SessionExceptionsTableOrderingComposer,
      $$SessionExceptionsTableAnnotationComposer,
      $$SessionExceptionsTableCreateCompanionBuilder,
      $$SessionExceptionsTableUpdateCompanionBuilder,
      (SessionExceptionRow, $$SessionExceptionsTableReferences),
      SessionExceptionRow,
      PrefetchHooks Function({bool sessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AcademicTermsTableTableManager get academicTerms =>
      $$AcademicTermsTableTableManager(_db, _db.academicTerms);
  $$TermSettingsTableTableTableManager get termSettingsTable =>
      $$TermSettingsTableTableTableManager(_db, _db.termSettingsTable);
  $$ClassSessionsTableTableManager get classSessions =>
      $$ClassSessionsTableTableManager(_db, _db.classSessions);
  $$SessionExceptionsTableTableManager get sessionExceptions =>
      $$SessionExceptionsTableTableManager(_db, _db.sessionExceptions);
}
