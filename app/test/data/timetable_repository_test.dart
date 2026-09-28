import 'package:ah_schedule/data/academic_term_repository.dart';
import 'package:ah_schedule/data/app_database.dart';
import 'package:ah_schedule/data/timetable_repository.dart';
import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// 数据层的接缝：`TimetableRepository.load` / `save`。
///
/// **只从这个接口看进去。** 这里的每条断言都是一句关于「存下来的课表还在不在、
/// 是不是原来那张」的话，没有一条盯着表名、列名或 SQL——那些是这一层的内部实现，
/// 重构它们不该让这里变红。
///
/// 这个领域的形状见 `CONTEXT.md`：学年学期是隔离单位，上课安排是最小单位，例外挂在
/// 安排上（ADR-0001：存规则，不存每周快照）。用例里的词照它用。
void main() {
  late AppDatabase database;
  late TimetableRepository repository;

  setUp(() {
    // 每个用例一个全新的内存库：用例之间不会互相看见对方的行。
    database = AppDatabase.memory();
    repository = TimetableRepository(
      database,
      AcademicTermRepository(database),
    );
  });

  tearDown(() => database.close());

  final term = AcademicTerm.parseLabel('2026-2027学年第一学期');

  test('存进去的一条上课安排，读回来一模一样', () async {
    final timetable = Timetable(
      term: term,
      sessions: [
        ClassSession(
          courseName: '编译原理',
          teacher: '胡冰',
          weekday: 1,
          periods: PeriodSpan(1, 2),
          weeks: WeekSet([1, 2, 3, 4, 5, 6, 7, 8]),
          venue: Venue(room: '4J410', campus: '主校区'),
        ),
      ],
    );

    await repository.save(timetable);

    expect(await repository.load(term), timetable);
  });

  test('学期设置（第 1 周的第一天、总周数、作息时间表）一并回来', () async {
    final timetable = Timetable(
      term: term,
      settings: TermSettings(
        firstDayOfWeek1: DateTime(2026, 9, 7),
        totalWeeks: 18,
        bellSchedule: BellSchedule(
          name: '改过的作息',
          periods: [
            PeriodTime(
              period: 1,
              start: ClockTime(7, 30),
              end: ClockTime(8, 15),
              block: DayBlock.morning,
            ),
            PeriodTime(
              period: 2,
              start: ClockTime(9, 0),
              end: ClockTime(9, 45),
              block: DayBlock.afternoon,
            ),
          ],
        ),
      ),
    );

    await repository.save(timetable);

    expect(await repository.load(term), timetable);
  });

  test('一条安排挂的多个例外都回来，停课与线上教学各是各的', () async {
    final timetable = Timetable(
      term: term,
      sessions: [
        ClassSession(
          courseName: '编译原理',
          teacher: '胡冰',
          weekday: 3,
          periods: PeriodSpan.single(5),
          weeks: WeekSet([4, 5, 6, 7]),
          venue: Venue(room: '4J410', campus: '主校区'),
          // 顺序是刻意的：读回来也得是这个顺序，不是按类型排的。
          exceptions: [
            OnlineTeaching(6, campus: '主校区'),
            Cancellation(4),
          ],
        ),
      ],
    );

    await repository.save(timetable);

    final loaded = await repository.load(term);
    expect(loaded, timetable);
    // 例外是信息、不是删除（ADR-0001）：停课那一周照样在周次集合里。
    expect(loaded!.sessions.single.weeks, WeekSet([4, 5, 6, 7]));
  });

  test('同一门课的多条安排落库后仍是多条，次序也不变', () async {
    final compilers = ClassSession(
      courseName: '编译原理',
      teacher: '胡冰',
      weekday: 1,
      periods: PeriodSpan(1, 2),
      weeks: WeekSet([1, 2, 3]),
      venue: Venue(room: '4J410', campus: '主校区'),
    );
    final mathOnMonday = ClassSession(
      courseName: '高等数学(一)',
      teacher: '张三',
      weekday: 1,
      periods: PeriodSpan(3, 2),
      weeks: WeekSet([1, 2, 3]),
      venue: Venue(room: '5J201'),
    );
    final mathOnWednesday = ClassSession(
      courseName: '高等数学(一)',
      teacher: '李四',
      weekday: 3,
      periods: PeriodSpan(3, 2),
      weeks: WeekSet([1, 2, 3]),
      venue: Venue(room: '5J201'),
    );

    await repository.save(
      Timetable(
        term: term,
        sessions: [compilers, mathOnMonday, mathOnWednesday],
      ),
    );

    final loaded = await repository.load(term);
    expect(loaded!.sessionsOf('高等数学(一)'), [mathOnMonday, mathOnWednesday]);
    expect(loaded.sessions, [compilers, mathOnMonday, mathOnWednesday]);
  });

  test('两个学年学期各存各的，切到哪个读到的就是哪个', () async {
    final lastSpring = AcademicTerm.parseLabel('2025-2026学年第二学期');
    final lastSpringSession = ClassSession(
      courseName: '大学物理',
      weekday: 5,
      periods: PeriodSpan(6, 2),
      weeks: WeekSet([1, 2, 3]),
      venue: Venue(room: '4J101'),
    );
    final thisAutumnSession = ClassSession(
      courseName: '编译原理',
      weekday: 1,
      periods: PeriodSpan(1, 2),
      weeks: WeekSet([1, 2, 3]),
      venue: Venue(room: '5J201'),
    );

    await repository.save(
      Timetable(
        term: term,
        sessions: [thisAutumnSession],
        settings: TermSettings(totalWeeks: 18),
      ),
    );
    await repository.save(
      Timetable(
        term: lastSpring,
        sessions: [lastSpringSession],
        settings: TermSettings(totalWeeks: 20),
      ),
    );

    final autumn = await repository.load(term);
    final spring = await repository.load(lastSpring);

    expect(autumn!.term, term);
    expect(autumn.sessions, [thisAutumnSession]);
    expect(autumn.settings.totalWeeks, 18);
    expect(spring!.term, lastSpring);
    expect(spring.sessions, [lastSpringSession]);
    expect(spring.settings.totalWeeks, 20);
  });

  test('整个学期被重存一遍：旧的安排与例外一并清掉，别的学期一点没动', () async {
    final lastSpring = AcademicTerm.parseLabel('2025-2026学年第二学期');
    final springSession = ClassSession(
      courseName: '大学物理',
      weekday: 5,
      periods: PeriodSpan(6, 2),
      weeks: WeekSet([1, 2, 3]),
      venue: Venue(room: '4J101'),
    );
    final outdated = ClassSession(
      courseName: '编译原理',
      teacher: '胡冰',
      weekday: 1,
      periods: PeriodSpan(1, 2),
      weeks: WeekSet([1, 2, 3]),
      venue: Venue(room: '4J410', campus: '主校区'),
      exceptions: [Cancellation(2)],
    );
    final reimported = ClassSession(
      courseName: '编译原理',
      teacher: '王五',
      weekday: 2,
      periods: PeriodSpan(3, 2),
      weeks: WeekSet([1, 2, 3, 4]),
      venue: Venue(room: '5J202'),
    );

    await repository.save(Timetable(term: term, sessions: [outdated]));
    await repository.save(
      Timetable(term: lastSpring, sessions: [springSession]),
    );

    // 重新导入一次：同一个学年学期整张覆盖。
    await repository.save(Timetable(term: term, sessions: [reimported]));

    final reloaded = await repository.load(term);
    expect(reloaded!.sessions, [reimported]);
    expect((await repository.load(lastSpring))!.sessions, [
      springSession,
    ], reason: '覆盖一个学期，不该碰到别的学期');
  });

  test('重存时学期设置也跟着换掉，不留上一次的', () async {
    await repository.save(
      Timetable(
        term: term,
        settings: TermSettings(
          firstDayOfWeek1: DateTime(2026, 9, 7),
          totalWeeks: 18,
        ),
      ),
    );
    await repository.save(
      Timetable(
        term: term,
        settings: TermSettings(
          firstDayOfWeek1: DateTime(2026, 9, 14),
          totalWeeks: 20,
        ),
      ),
    );

    final loaded = await repository.load(term);
    expect(loaded!.settings.firstDayOfWeek1, DateTime(2026, 9, 14));
    expect(loaded.settings.totalWeeks, 20);
  });

  test('存过一个空的课表，读回来是空的课表，不是 null', () async {
    await repository.save(Timetable(term: term));

    expect(await repository.load(term), Timetable(term: term));
  });

  test('没存过的学年学期读出来是 null', () async {
    await repository.save(Timetable(term: term));

    final neverSaved = AcademicTerm.parseLabel('2024-2025学年第一学期');
    expect(await repository.load(neverSaved), isNull);
  });

  group('库里的归属关系', () {
    /// 这一条**故意看库里的行**，不走仓储的接口。
    ///
    /// 孤儿例外从接口那边看不见——它指着的安排已经没了，`load` 也绝不会读到它；它只会
    /// 在用户的库里越积越多，而「读出来的东西怎么看都对」正是最难发现的那类问题。所以
    /// 这里直接问库里还有没有孤儿的例外行。
    test('安排被清掉时，它挂的例外跟着走，不留在库里', () async {
      final session = ClassSession(
        courseName: '编译原理',
        weekday: 1,
        periods: PeriodSpan(1, 2),
        weeks: WeekSet([1, 2, 3]),
        venue: Venue(room: '4J410'),
        exceptions: [
          Cancellation(2),
          OnlineTeaching(3, campus: '主校区'),
        ],
      );
      await repository.save(Timetable(term: term, sessions: [session]));
      await repository.save(Timetable(term: term));

      final orphans =
          await (database.select(database.sessionExceptions)..where(
                (row) => row.sessionId.isNotInQuery(
                  database.selectOnly(database.classSessions)
                    ..addColumns([database.classSessions.id]),
                ),
              ))
              .get();

      expect(orphans, isEmpty);
    });
  });
}
