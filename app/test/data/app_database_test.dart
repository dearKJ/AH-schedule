import 'dart:io';

import 'package:ah_schedule/data/academic_term_repository.dart';
import 'package:ah_schedule/data/app_database.dart';
import 'package:ah_schedule/data/timetable_repository.dart';
import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 真机上那个数据库是**文件库**，而且 drift 把它开在另一条 isolate 上
/// （`createInBackground`）；仓储的那一组测试跑的是内存库。这一条盯的就是那条路：
/// 文件库上存取也真的成立——包括外键级联，那条规则是在打开数据库时开的。
void main() {
  late Directory directory;
  AppDatabase? database;

  /// 开一个文件库并记下来：用例结束时关的是这一个。测试体里自己关过的那次会把它置空，
  /// 所以不会重复关。
  AppDatabase open() => database = AppDatabase.openFile(
    File('${directory.path}/ah_schedule.sqlite'),
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ah_schedule_test');
    database = null;
  });

  tearDown(() async {
    await database?.close();
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  final term = AcademicTerm.parseLabel('2026-2027学年第一学期');
  final session = ClassSession(
    courseName: '编译原理',
    teacher: '胡冰',
    weekday: 1,
    periods: PeriodSpan(1, 2),
    weeks: WeekSet([1, 2, 3, 4, 5, 6, 7, 8]),
    venue: Venue(room: '4J410', campus: '主校区'),
    exceptions: [Cancellation(2)],
  );

  test('文件库上存进去，关掉再打开还在', () async {
    final timetable = Timetable(term: term, sessions: [session]);

    final first = open();
    await TimetableRepository(
      first,
      AcademicTermRepository(first),
    ).save(timetable);
    await first.close();
    database = null;

    // 重新打开同一个文件——「App 重启之后数据还在」就是这一件事。
    final second = open();
    final loaded = await TimetableRepository(
      second,
      AcademicTermRepository(second),
    ).load(term);

    expect(loaded, timetable);
  });

  test('文件库上重存一个学期，它旧的例外也一并清掉', () async {
    final db = open();
    final repository = TimetableRepository(db, AcademicTermRepository(db));

    await repository.save(Timetable(term: term, sessions: [session]));
    await repository.save(Timetable(term: term));
    await db.close();
    database = null;

    final reopened = open();
    final orphans =
        await (reopened.select(reopened.sessionExceptions)..where(
              (row) => row.sessionId.isNotInQuery(
                reopened.selectOnly(reopened.classSessions)
                  ..addColumns([reopened.classSessions.id]),
              ),
            ))
            .get();

    expect(orphans, isEmpty);
  });

  test('走路骨架那一版装的库（v1，只有学年学期表）能升上来，存着的学年学期还在', () async {
    // 先按老样子造一个库出来：只有学年学期一张表、版本号 1——装过走路骨架那一版
    // （issue #4）的手机上就是这个形状。
    final file = File('${directory.path}/ah_schedule.sqlite');
    final legacy = NativeDatabase(file);
    await legacy.ensureOpen(_WalkingSkeletonDatabase());
    await legacy.runInsert('''
      CREATE TABLE academic_terms (
        id TEXT NOT NULL,
        label TEXT NOT NULL,
        PRIMARY KEY (id)
      )
    ''', const []);
    await legacy.runInsert(
      'INSERT INTO academic_terms (id, label) VALUES (?, ?)',
      const ['2025-2026-2', '2025-2026学年2学期'],
    );
    await legacy.close();

    // 用今天的 App 打开它：版本从 1 升到 2，三张新表得补上。
    final upgraded = open();
    final repository = TimetableRepository(
      upgraded,
      AcademicTermRepository(upgraded),
    );
    final legacyTerm = AcademicTerm(id: '2025-2026-2', label: '2025-2026学年2学期');

    final upgradedTerm = await repository.load(legacyTerm);
    expect(upgradedTerm, isNotNull, reason: '升级不该把原来存着的学年学期弄丢');
    expect(upgradedTerm!.sessions, isEmpty, reason: '它还没有课表内容');

    // 补上来的三张表是能用的：往这个升过级的库里存一张课表，读得回来。
    final timetable = Timetable(term: term, sessions: [session]);
    await repository.save(timetable);

    expect(await repository.load(term), timetable);
  });
}

/// 走路骨架那一版的库：版本号是 1。表由用例自己建（见上），这里只负责把版本号交代清楚。
///
/// 手写一遍老形状，是为了让「升级」这件事真的被跑到——drift 的 schema 快照工具能生成更
/// 完整的迁移测试，但为这一张表、一次升级装那套工具不划算。
class _WalkingSkeletonDatabase implements drift.QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    drift.QueryExecutor executor,
    drift.OpeningDetails details,
  ) async {}
}
