import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

/// 从「逻辑网格 + 一块格子正文」到领域层 `ClassSession` 的那一步。
///
/// 这里盯两件事：
///
/// 1. **四种未经样本验证的写法**（单双周 / 断档周标准写法 / 特定周 / 线上教学）。
///    格式文档第六节说得很清楚：它们**必须有用例，但不得声称已验证**。这一组
///    用例就是那句话的落地——用例在，措辞上不写「已实测」。
/// 2. **停课那条与正常那条合并成一条**，不是两次上课。
void main() {
  group('四种未经样本验证的写法', () {
    test('单双周：单周第5周-第15周', () {
      final sessions = _import('(单周第5周-第15周,4J410(主校区))');
      expect(sessions, hasLength(1));
      expect(sessions.single.weeks.weeks, [5, 7, 9, 11, 13, 15]);
    });

    test('单双周：双周第4周-第12周', () {
      final sessions = _import('(双周第4周-第12周,4J410(主校区))');
      expect(sessions.single.weeks.weeks, [4, 6, 8, 10, 12]);
    });

    test('断档周的标准写法：第4周-第10周 第12周-第18周', () {
      final sessions = _import('(第4周-第10周 第12周-第18周,4J410(主校区))');
      expect(sessions.single.weeks.weeks, [
        4, 5, 6, 7, 8, 9, 10, //
        12, 13, 14, 15, 16, 17, 18,
      ]);
      expect(sessions.single.weeks.contains(11), isFalse);
    });

    test('特定周：第12周', () {
      final sessions = _import('(第12周,4J410(主校区))');
      expect(sessions.single.weeks.weeks, [12]);
    });

    test('线上教学：第14周，地点那一格写「线上教学」', () {
      final sessions = _import('(第14周,线上教学(主校区))');
      expect(sessions, hasLength(1));
      final session = sessions.single;
      expect(session.venue.isOnline, isTrue);
      expect(session.venue.room, Venue.onlineRoomLabel);
      expect(session.venue.campus, '主校区');
      expect(session.weeks.weeks, [14]);
      // 线上教学改的是**地点**，不影响这次课出不出现。
      expect(
        session.exceptions,
        [OnlineTeaching(14, campus: '主校区')],
        reason: '例外是信息，挂在安排上，不是删除',
      );
    });

    test('线上教学那一格不写校区也能解出来', () {
      final sessions = _import('(第14周,线上教学)');
      expect(sessions.single.venue.isOnline, isTrue);
      expect(sessions.single.venue.campus, isNull);
    });
  });

  group('停课与正常那条合并成一条', () {
    test('样本里那一格：停课一条 + 正常一条 → 一条安排，周次有断档', () {
      // 这就是 `TD38_0` 那一格的形状。
      final sessions = _import(
        '(2,停课(主校区)<br/>'
        '编译原理(073170140.01) (胡冰)<br/>'
        '(1 3-12,4J410(主校区)',
      );

      expect(
        sessions,
        hasLength(1),
        reason: '不能当成两次上课——那是「一次带例外的排课」',
      );
      final session = sessions.single;
      expect(session.weeks.contains(2), isFalse, reason: '第 2 周停课');
      expect(session.weeks.weeks.first, 1);
      expect(session.venue.toText(), '4J410(主校区)');
      expect(
        session.exceptions,
        isEmpty,
        reason: '正常那条的周次本来就排除了第 2 周，再挂一遍例外是把话说两回',
      );
    });

    test('正常那条**包含**停课那一周时，例外才挂上去', () {
      // 正常那条的周次里有第 3 周，停课那条也点名第 3 周——这时它是一条真例外。
      final sessions = _import(
        '(3,停课(主校区)<br/>'
        '编译原理(073170140.01) (胡冰)<br/>'
        '(1-8,4J410(主校区)',
      );

      expect(sessions, hasLength(1));
      final session = sessions.single;
      expect(session.weeks.contains(3), isTrue, reason: '周次集合原样不动');
      expect(session.exceptions, [Cancellation(3)]);
      expect(
        session.coversWeek(3),
        isTrue,
        reason: 'coversWeek 不看例外——要不要出现由展开时按例外决定',
      );
    });
  });

  group('例外挂不上去时**报诊断**，不静默吞掉', () {
    test('一格正文里只有停课那一行', () {
      final issues = ImportIssues();
      final sessions = _importWithIssues('(2,停课(主校区))', issues);
      expect(sessions, isEmpty);
      final diagnostic = issues.diagnostics.single;
      expect(diagnostic.code, ImportIssue.unparsableCell);
      expect(diagnostic.severity, ImportSeverity.error);
      expect(diagnostic.message, contains('停课挂不上去'));
    });
  });

  group('周次超出范围时**报诊断**，不让异常穿出去', () {
    test('周次超过上限（教务系统是 53 位，超出的只可能是坏数据）', () {
      // `WeekSet.parse` 对超范围的周次抛的是 FormatException（不是
      // ArgumentError），所以这一层接得住。接不住的话整次导入会炸在异常上，
      // 而不是给出一份「哪一格解不出来」的清单。
      final issues = ImportIssues();
      final sessions = _importWithIssues('(1-60,4J410(主校区))', issues);

      expect(sessions, isEmpty);
      expect(issues.diagnostics, hasLength(1));
      final diagnostic = issues.diagnostics.single;
      expect(diagnostic.code, ImportIssue.unparsableCell);
      expect(diagnostic.severity, ImportSeverity.error);
      expect(diagnostic.message, contains('1-60'));
      expect(diagnostic.rawText, contains('1-60'));
    });

    test('周次写成 0 也一样接住', () {
      final issues = ImportIssues();
      expect(_importWithIssues('(0-5,4J410(主校区))', issues), isEmpty);
      expect(issues.diagnostics.single.code, ImportIssue.unparsableCell);
    });

    test('一格炸了不影响别的格子', () {
      // 一格里周次坏了，另一格照常解出来——这是「诊断是返回值的一部分」的用处：
      // 用户还是拿到了那份课表，只是同时看到一条「这里没解出来」。
      final issues = ImportIssues();
      final grid = GridTable(
        periodCount: 12,
        cells: [
          GridCell(
            period: 1,
            column: 1,
            rowSpan: 1,
            id: 'TD0_0',
            rawText: '坏课(1.01) (师)<br/>(1-60,4J410(主校区))',
          ),
          GridCell(
            period: 2,
            column: 2,
            rowSpan: 1,
            id: 'TD13_0',
            rawText: '好课(2.01) (师)<br/>(1-8,4J209(主校区))',
          ),
        ],
      );
      final sessions = ClassSessionBuilder.build(table: grid, issues: issues);
      expect(sessions, hasLength(1));
      expect(sessions.single.courseName, '好课');
      expect(issues.diagnostics, hasLength(1));
    });
  });

  group('星期与节次来自格子的位置', () {
    test('第 3 天、第 3 节起、rowspan=3 → 星期三第3-5节', () {
      final grid = _grid(
        weekday: 3,
        period: 3,
        rowSpan: 3,
        body: '课(1.01) (师)<br/>(1-8,4J410(主校区))',
      );
      final issues = ImportIssues();
      final sessions = ClassSessionBuilder.build(table: grid, issues: issues);
      expect(sessions.single.weekday, 3);
      expect(sessions.single.periods, PeriodSpan(3, 3));
      expect(issues.diagnostics, isEmpty);
    });

    test('rowspan 超出节次总数时这一格不导入，并报诊断', () {
      // 三个节次行，最后一行的格子却要连 3 节。
      final grid = _grid(
        weekday: 1,
        period: 3,
        rowSpan: 3,
        body: '课(1.01) (师)<br/>(1-8,4J410(主校区))',
        periods: 3,
      );
      final issues = ImportIssues();
      final sessions = ClassSessionBuilder.build(table: grid, issues: issues);
      expect(sessions, isEmpty);
      final diagnostic = issues.diagnostics.single;
      expect(diagnostic.code, ImportIssue.malformedTable);
      expect(diagnostic.message, contains('越过'));
      // 位置与原文都带着。
      expect(diagnostic.weekday, 1);
      expect(diagnostic.period, 3);
      expect(diagnostic.rawText, contains('课(1.01)'));
    });

    test('解不出来的格子：诊断里带星期、节次与原文', () {
      final grid = _grid(
        weekday: 4,
        period: 6,
        rowSpan: 1,
        body: '这一格的正文不是排课格式',
      );
      final issues = ImportIssues();
      final sessions = ClassSessionBuilder.build(table: grid, issues: issues);

      expect(sessions, isEmpty);
      final diagnostic = issues.diagnostics.single;
      expect(diagnostic.code, ImportIssue.unparsableCell);
      expect(diagnostic.severity, ImportSeverity.error);
      expect(diagnostic.positionLabel, '星期四第6节');
      expect(diagnostic.rawText, contains('这一格的正文不是排课格式'));
      expect(diagnostic.isError, isTrue);
    });

    test('空格子不报诊断', () {
      final grid = _grid(weekday: 2, period: 2, rowSpan: 1, body: '');
      final issues = ImportIssues();
      expect(ClassSessionBuilder.build(table: grid, issues: issues), isEmpty);
      expect(issues.diagnostics, isEmpty);
    });
  });
}

/// 周次那一行 → 课表里的安排。
///
/// 用例只写**周次行**，课程行由这里补上：这一组要测的是周次写法，课程行是固定的
/// 陪衬，写十几遍只会让「真正在变的是什么」看不清。
List<ClassSession> _import(String weeksLine) =>
    _importWithIssues(weeksLine, ImportIssues());

List<ClassSession> _importWithIssues(String weeksLine, ImportIssues issues) {
  final grid = _grid(
    weekday: 1,
    period: 1,
    rowSpan: 1,
    body: '课(1.01) (师)<br/>$weeksLine',
  );
  return ClassSessionBuilder.build(table: grid, issues: issues);
}

/// 造一张只有一个格子的网格。
///
/// 刻意绕开 `HtmlCourseTableParser`：这些用例要测的是「正文 → 安排」，直接构造
/// 网格能让失败指向那一层，而不是让人先怀疑是 HTML 没抠对。
GridTable _grid({
  required int weekday,
  required int period,
  required int rowSpan,
  required String body,
  int periods = 12,
}) {
  return GridTable(
    periodCount: periods,
    cells: [
      GridCell(
        period: period,
        column: weekday,
        rowSpan: rowSpan,
        id: 'TD${(weekday - 1) * periods + period - 1}_0',
        rawText: body,
      ),
    ],
  );
}
