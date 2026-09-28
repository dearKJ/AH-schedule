import 'dart:convert';

import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:drift/drift.dart';

import 'academic_term_repository.dart';
import 'app_database.dart';

/// 课表在「领域对象」与「数据库行」之间的映射。
///
/// 接口只有两个：读一个学年学期的整张课表，存一个学年学期的整张课表。
///
/// 这一层**刻意薄**：只做存与取，不引入新的业务规则。星期几必须是 1..7、周次不能是空
/// 集合、同一门课不做合并……这些判断一条都不在这里——它们要么属于领域层（有最快的纯
/// Dart 测试盯着），要么根本不该存在。这里多一条 `if`，领域层就少一处被保护的形状。
class TimetableRepository {
  TimetableRepository(this._database, this._terms);

  final AppDatabase _database;

  /// 学年学期那一张表由它写。课表挂在学年学期底下，`save` 得先把学年学期本身落下来，
  /// 上课安排才有地方挂——「怎么存一个学年学期」因此只有一处。
  final AcademicTermRepository _terms;

  /// 读出某个学年学期的整张课表。**库里没有这个学年学期时返回 null**——「没存过」与
  /// 「存过但一条安排都没有」是两件事，前者不该被伪装成后者。
  ///
  /// 读出来的每一行都只属于这个学年学期：别的学期的安排、例外、设置一概看不见。
  Future<Timetable?> load(AcademicTerm term) async {
    final termRow = await (_database.select(
      _database.academicTerms,
    )..where((row) => row.id.equals(term.id))).getSingleOrNull();
    if (termRow == null) return null;

    final settingsRow = await (_database.select(
      _database.termSettingsTable,
    )..where((row) => row.termId.equals(term.id))).getSingleOrNull();

    final sessionRows =
        await (_database.select(_database.classSessions)
              ..where((row) => row.termId.equals(term.id))
              ..orderBy([(row) => OrderingTerm.asc(row.position)]))
            .get();

    final exceptions = await _exceptionsOf([
      for (final row in sessionRows) row.id,
    ]);

    return Timetable(
      term: term,
      // 学期设置那一行不在（比如这个学年学期是在界面上单存的，还没配过课表）就用领域层
      // 的默认值：那是领域层的默认，不在这里另造一份。
      settings: settingsRow == null
          ? TermSettings()
          : _settingsFrom(settingsRow),
      sessions: [
        for (final row in sessionRows)
          _sessionFrom(row, exceptions[row.id] ?? const []),
      ],
    );
  }

  /// 存下一整张课表，**整学期覆盖**。
  ///
  /// 这个学年学期原来存着的安排与例外先清掉，再写这一份——所以「重新导入一次」不会留下
  /// 上一版课表的残骸。清的范围**只限这个学期**：别的学期一行都不动。
  ///
  /// 全程在一个事务里：中途出错不会有半张课表留在库里。
  Future<void> save(Timetable timetable) async {
    final termId = timetable.term.id;
    await _database.transaction(() async {
      // 学年学期先落下来。
      await _terms.save(timetable.term);

      // 旧安排清掉。挂在这些安排上的例外由外键级联一并带走——归属关系写在表结构里
      // （见 `app_database.dart` 的 `AppDatabase.migration`），不在这里手工删两遍。
      await (_database.delete(
        _database.classSessions,
      )..where((row) => row.termId.equals(termId))).go();

      // 一个学期一份设置，termId 本身就是主键，重复写就是改写，不用先删。
      await _database
          .into(_database.termSettingsTable)
          .insertOnConflictUpdate(
            _settingsCompanion(timetable.settings, termId),
          );

      var position = 0;
      for (final session in timetable.sessions) {
        final sessionId = await _database
            .into(_database.classSessions)
            .insert(_sessionCompanion(session, termId, position));
        position++;

        var exceptionPosition = 0;
        for (final exception in session.exceptions) {
          await _database
              .into(_database.sessionExceptions)
              .insert(
                _exceptionCompanion(exception, sessionId, exceptionPosition),
              );
          exceptionPosition++;
        }
      }
    });
  }

  /// 这些安排挂着的全部例外，按安排分组。
  ///
  /// 传进来的安排要是一串空 id（这个学期一条安排都没有），就不查：`IN ()` 在 SQL 里是个
  /// 语法错误，与其为它捏一个恒假条件，不如根本不发这条查询。
  Future<Map<int, List<SessionException>>> _exceptionsOf(
    List<int> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return const {};

    final rows =
        await (_database.select(_database.sessionExceptions)
              ..where((row) => row.sessionId.isIn(sessionIds))
              // 一条安排可以挂多个例外，例外的先后也是领域层的一部分（它有次序），
              // 所以按存下来的次序取。
              ..orderBy([(row) => OrderingTerm.asc(row.position)]))
            .get();

    final grouped = <int, List<SessionException>>{};
    for (final row in rows) {
      (grouped[row.sessionId] ??= []).add(_exceptionFrom(row));
    }
    return grouped;
  }
}

// ───────────────────────── 行 ⇄ 领域对象 ─────────────────────────
//
// 往下都是纯映射：左边是数据库行，右边是领域对象，中间**没有判断**——除了「这个字符串
// 认不认识」，那不是判断，是取证。

ClassSessionsCompanion _sessionCompanion(
  ClassSession session,
  String termId,
  int position,
) => ClassSessionsCompanion.insert(
  termId: termId,
  position: position,
  courseName: session.courseName,
  teacher: Value(session.teacher),
  weekday: session.weekday,
  periodStart: session.periods.start,
  periodLength: session.periods.length,
  weeks: _weeksToColumn(session.weeks),
  room: session.venue.room,
  campus: Value(session.venue.campus),
);

ClassSession _sessionFrom(
  ClassSessionRow row,
  List<SessionException> exceptions,
) => ClassSession(
  courseName: row.courseName,
  teacher: row.teacher,
  weekday: row.weekday,
  periods: PeriodSpan(row.periodStart, row.periodLength),
  weeks: _weeksFromColumn(row.weeks),
  venue: Venue(room: row.room, campus: row.campus),
  exceptions: exceptions,
);

SessionExceptionsCompanion _exceptionCompanion(
  SessionException exception,
  int sessionId,
  int position,
) => switch (exception) {
  Cancellation() => SessionExceptionsCompanion.insert(
    sessionId: sessionId,
    kind: _cancellationKind,
    week: exception.week,
    position: position,
  ),
  OnlineTeaching() => SessionExceptionsCompanion.insert(
    sessionId: sessionId,
    kind: _onlineTeachingKind,
    week: exception.week,
    campus: Value(exception.campus),
    position: position,
  ),
};

SessionException _exceptionFrom(SessionExceptionRow row) => switch (row.kind) {
  _cancellationKind => Cancellation(row.week),
  _onlineTeachingKind => OnlineTeaching(row.week, campus: row.campus),
  _ => _unreadable('例外类型「${row.kind}」'),
};

TermSettingsTableCompanion _settingsCompanion(
  TermSettings settings,
  String termId,
) => TermSettingsTableCompanion.insert(
  termId: termId,
  firstDayOfWeek1: Value(settings.firstDayOfWeek1),
  totalWeeks: Value(settings.totalWeeks),
  bellScheduleName: settings.bellSchedule.name,
  bellPeriods: _bellPeriodsToColumn(settings.bellSchedule),
);

TermSettings _settingsFrom(TermSettingsRow row) => TermSettings(
  firstDayOfWeek1: row.firstDayOfWeek1,
  totalWeeks: row.totalWeeks,
  bellSchedule: BellSchedule(
    name: row.bellScheduleName,
    periods: _bellPeriodsFromColumn(row.bellPeriods),
  ),
);

// ─────────────────────────── 三个列的写法 ───────────────────────────

/// 周次集合落成一列整数：`1,2,3,5`。
///
/// 写成整数表，不写教务系统那套「单周第1周-第15周」：**那是写法，这是集合**。把一种
/// 表达当成数据存下来，以后多一种写法就要动存储。
String _weeksToColumn(WeekSet weeks) => weeks.weeks.join(',');

WeekSet _weeksFromColumn(String column) =>
    WeekSet(column.split(',').map(int.parse));

/// 作息时间表的节次落成一列 JSON，如
/// `[{"period":1,"start":"08:00","end":"08:45","block":"morning"}, …]`。
///
/// 一整个作息时间表是一个值对象（名字 + 一串节次），读写都是整体，从来没有「查某一节」
/// 的需求，所以它落在 `term_settings` 的两列里，不另开一张表：摊成一行一节要多一张表、
/// 多一次连接，换来的查询能力这里一处都用不上。
String _bellPeriodsToColumn(BellSchedule schedule) => jsonEncode([
  for (final period in schedule.periods)
    {
      'period': period.period,
      'start': period.start.toText(),
      'end': period.end.toText(),
      'block': _blockNames[period.block],
    },
]);

List<PeriodTime> _bellPeriodsFromColumn(String column) => [
  for (final entry in jsonDecode(column) as List<Object?>)
    _periodTimeFrom((entry as Map<String, Object?>).cast<String, Object?>()),
];

PeriodTime _periodTimeFrom(Map<String, Object?> entry) => PeriodTime(
  period: entry['period']! as int,
  start: ClockTime.parse(entry['start']! as String),
  end: ClockTime.parse(entry['end']! as String),
  block: _dayBlockOf(entry['block']! as String),
);

/// 时段落在库里的写法。
///
/// 与本文件里例外类型那两处同理：**认字符串，不认 Dart 枚举名**——库里的行不该因为源码
/// 里重命名一个枚举成员就读不出来。同一张表编码解码都走它，不会两边对不上。
const Map<DayBlock, String> _blockNames = {
  DayBlock.morning: 'morning',
  DayBlock.afternoon: 'afternoon',
  DayBlock.evening: 'evening',
};

final Map<String, DayBlock> _blocksByName = {
  for (final entry in _blockNames.entries) entry.value: entry.key,
};

DayBlock _dayBlockOf(String name) {
  final block = _blocksByName[name];
  if (block == null) _unreadable('时段「$name」');
  return block;
}

/// 例外类型落在库里的两个字符串。这里不是课表 JSON 的契约，是**这个库自己的**约定。
const String _cancellationKind = 'cancellation';
const String _onlineTeachingKind = 'onlineTeaching';

/// 库里有一行读不出来——被别的版本的 App 写过，或者被人拿 `adb` 手工改过。
///
/// **不静默跳过。** 跳过一条例外等于悄悄多上一节课，跳过一节作息时间表等于整张课表的
/// 时刻全错：这两种错都比当场报错糟得多。
Never _unreadable(String what) => throw StateError('数据库里有一行读不回来：$what');
