import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

import 'import/fixture.dart';

void main() {
  final term = AcademicTerm.parseLabel('2026-2027学年第一学期');

  group('按周展开', () {
    test('一周 7 天 × 12 节，每格都能取到', () {
      final grid = expandWeek(Timetable(term: term), 1);

      expect(grid.week, 1);
      expect(grid.days, hasLength(7));
      for (final day in grid.days) {
        expect(day.periods, hasLength(12));
      }
      expect(
        grid.days.expand((day) => day.cells).every((cell) => cell.isEmpty),
        isTrue,
        reason: '没有课的格子是空的，不摆占位文字',
      );
    });

    test('教学周号必须落在 1..53 之间', () {
      final timetable = Timetable(term: term);

      expect(() => expandWeek(timetable, 0), throwsArgumentError);
      expect(() => expandWeek(timetable, -1), throwsArgumentError);
      expect(
        () => expandWeek(timetable, WeekSet.maxWeek + 1),
        throwsArgumentError,
      );
      expect(expandWeek(timetable, WeekSet.maxWeek).week, WeekSet.maxWeek);
    });

    test('落在本格的安排占住它的格子，别的格子不受影响', () {
      final grid = expandWeek(_timetable(term, [_session()]), 1);

      expect(_courses(grid.at(DateTime.monday, 3)), ['高等数学(一)']);
      expect(grid.at(DateTime.monday, 2).isEmpty, isTrue);
      expect(grid.at(DateTime.tuesday, 3).isEmpty, isTrue);
      expect(
        grid.at(DateTime.monday, 3).entries.single.session,
        _session(),
        reason: '格子带的是它来源的那条安排',
      );
    });

    test('连堂跨 3 节就占满那 3 格，位置正确', () {
      // 第三～五节连堂：占第 3、4、5 节，不碰第 2、6 节。
      final grid = expandWeek(
        _timetable(term, [_session(periods: PeriodSpan(3, 3))]),
        1,
      );

      expect(_courses(grid.at(DateTime.monday, 2)), isEmpty);
      expect(_courses(grid.at(DateTime.monday, 3)), ['高等数学(一)']);
      expect(_courses(grid.at(DateTime.monday, 4)), ['高等数学(一)']);
      expect(_courses(grid.at(DateTime.monday, 5)), ['高等数学(一)']);
      expect(_courses(grid.at(DateTime.monday, 6)), isEmpty);
      expect(
        grid.at(DateTime.monday, 4).entries.single.session.periods,
        PeriodSpan(3, 3),
        reason: '格子带的是整条安排，不是被切碎的某一节',
      );
    });

    test('连堂不会溢出到相邻那天的同一节', () {
      final grid = expandWeek(
        _timetable(term, [_session(periods: PeriodSpan(11, 2))]),
        1,
      );

      expect(_courses(grid.at(DateTime.monday, 11)), ['高等数学(一)']);
      expect(_courses(grid.at(DateTime.monday, 12)), ['高等数学(一)']);
      expect(_courses(grid.at(DateTime.tuesday, 11)), isEmpty);
      expect(_courses(grid.at(DateTime.tuesday, 12)), isEmpty);
    });

    test('一周都装不下的跨度只铺得进的那几格，不溢出网格', () {
      final grid = expandWeek(
        _timetable(term, [_session(periods: PeriodSpan(11, 3))]),
        1,
      );

      expect(_courses(grid.at(DateTime.monday, 11)), ['高等数学(一)']);
      expect(_courses(grid.at(DateTime.monday, 12)), ['高等数学(一)']);
      expect(grid.days[0].cells, hasLength(12));
      expect(grid.days[1].cells, hasLength(12));
    });

    test('起始节次就已经在表外时整条都不铺，不抛错也不溢出', () {
      // 表外是 12 节时，第 13 节起是一条数据坏了才会有的跨度。网格宁可空着这一格，
      // 也不该把它折回第 1 节，或者把它铺到第二天去。
      final grid = expandWeek(
        _timetable(term, [_session(periods: PeriodSpan(13, 2))]),
        1,
      );

      expect(grid.at(DateTime.monday, 12).isEmpty, isTrue);
      expect(grid.at(DateTime.tuesday, 1).isEmpty, isTrue);
      expect(grid.at(DateTime.tuesday, 12).isEmpty, isTrue);
    });

    test('周次集合不含本周 → 一条都不出现', () {
      final session = _session(weeks: WeekSet([1, 2]));
      final timetable = _timetable(term, [session]);

      expect(_courses(gridAt(timetable, 2, DateTime.monday, 3)), [
        '高等数学(一)',
      ]);
      expect(_courses(gridAt(timetable, 3, DateTime.monday, 3)), isEmpty);
      expect(_courses(gridAt(timetable, 18, DateTime.monday, 3)), isEmpty);
    });

    test('周次错开的安排各自只在含它的那一周出现', () {
      final timetable = _timetable(term, [
        _session(courseName: '单周课', weeks: WeekSet([1, 3, 5, 7])),
        _session(courseName: '双周课', weeks: WeekSet([2, 4, 6, 8])),
      ]);

      expect(_courses(gridAt(timetable, 3, DateTime.monday, 3)), ['单周课']);
      expect(_courses(gridAt(timetable, 4, DateTime.monday, 3)), ['双周课']);
    });

    test('学期设置里没填总周数也不影响展开', () {
      final timetable = Timetable(
        term: term,
        sessions: [_session(weeks: WeekSet([20]))],
        settings: TermSettings(),
      );

      expect(_courses(gridAt(timetable, 20, DateTime.monday, 3)), ['高等数学(一)']);
    });

    test('网格内部改不动', () {
      final grid = expandWeek(_timetable(term, [_session()]), 1);
      final cell = grid.at(DateTime.monday, 3);

      expect(() => grid.days.add(grid.days.first), throwsUnsupportedError);
      expect(() => grid.days.first.cells.add(cell), throwsUnsupportedError);
      expect(
        () => cell.entries.add(cell.entries.single),
        throwsUnsupportedError,
      );
    });
  });

  group('例外', () {
    test('停课那一周不出现，其余周照常出现', () {
      final session = _session(
        weeks: WeekSet([1, 3, 4, 5, 6]),
        exceptions: [Cancellation(3)],
      );
      final timetable = _timetable(term, [session]);

      expect(_courses(gridAt(timetable, 2, DateTime.monday, 3)), isEmpty);
      expect(_courses(gridAt(timetable, 3, DateTime.monday, 3)), isEmpty);
      expect(_courses(gridAt(timetable, 4, DateTime.monday, 3)), ['高等数学(一)']);
      expect(
        session.weeks.weeks,
        contains(3),
        reason: '停课是例外不是删除——周次集合原样不动',
      );
    });

    test('停课例外不影响同格里的另一条安排', () {
      final timetable = _timetable(term, [
        _session(courseName: '停课那门', exceptions: [Cancellation(2)]),
        _session(courseName: '照常那门', weeks: WeekSet([2])),
      ]);

      expect(_courses(gridAt(timetable, 2, DateTime.monday, 3)), ['照常那门']);
    });

    test('线上教学的例外只改地点，不改变它出不出现', () {
      final session = _session(
        weeks: WeekSet([1, 2, 3]),
        exceptions: [OnlineTeaching(2, campus: '主校区')],
      );
      final timetable = _timetable(term, [session]);

      final offline = gridAt(timetable, 1, DateTime.monday, 3).entries.single;
      expect(offline.venue, Venue(room: '4J410', campus: '主校区'));
      expect(offline.venue.isOnline, isFalse);

      final online = gridAt(timetable, 2, DateTime.monday, 3).entries.single;
      expect(online.venue.isOnline, isTrue);
      expect(online.venue.campus, '主校区');
      expect(online.session, session, reason: '改的是这周的展开结果，安排本身原样不动');
      expect(
        online.session.venue.room,
        '4J410',
        reason: '教室名还在原安排里，被线上盖掉的只是这一周的展开结果',
      );
    });

    test('线上教学没写校区时，沿用安排本身的校区', () {
      final timetable = _timetable(term, [
        _session(weeks: WeekSet([1, 2]), exceptions: [OnlineTeaching(1)]),
      ]);

      expect(
        gridAt(timetable, 1, DateTime.monday, 3).entries.single.venue,
        Venue.online(campus: '主校区'),
      );
    });

    test('线上教学与停课挂在同一条上时，停课说了算', () {
      final timetable = _timetable(term, [
        _session(
          weeks: WeekSet([1, 2, 3]),
          exceptions: [OnlineTeaching(1), Cancellation(2)],
        ),
      ]);

      expect(gridAt(timetable, 1, DateTime.monday, 3).entries, hasLength(1));
      expect(gridAt(timetable, 2, DateTime.monday, 3).isEmpty, isTrue);
      expect(gridAt(timetable, 3, DateTime.monday, 3).entries, hasLength(1));
    });

    test('别的周次的例外不生效', () {
      final timetable = _timetable(term, [
        _session(
          weeks: WeekSet([1, 2, 3, 4]),
          exceptions: [Cancellation(4), OnlineTeaching(5)],
        ),
      ]);

      expect(gridAt(timetable, 1, DateTime.monday, 3).entries, hasLength(1));
      expect(gridAt(timetable, 2, DateTime.monday, 3).entries, hasLength(1));
      expect(
        gridAt(timetable, 3, DateTime.monday, 3).entries.single.venue.isOnline,
        isFalse,
      );
    });

    test('同一格的「教室那条」与「线上那条」并成一条线上，不是冲突', () {
      // 导入解析把线上教学那一行单独解成一条安排，所以一门课改线上会同时有
      // 两条：教室那条、线上那条。这一格该画的是**一条线上教学**，不是并排两条。
      final timetable = _timetable(term, [
        _session(courseName: '甲课', weeks: WeekSet([1, 2, 3])),
        _session(
          courseName: '甲课',
          weeks: WeekSet([2]),
          venue: Venue.online(campus: '主校区'),
        ),
      ]);

      final week1 = gridAt(timetable, 1, DateTime.monday, 3);
      expect(week1.entries, hasLength(1));
      expect(week1.entries.single.venue.isOnline, isFalse);

      final week2 = gridAt(timetable, 2, DateTime.monday, 3);
      expect(week2.entries, hasLength(1), reason: '不是两条并排的假冲突');
      expect(week2.entries.single.venue, Venue.online(campus: '主校区'));
      expect(week2.hasConflict, isFalse);

      final week3 = gridAt(timetable, 3, DateTime.monday, 3);
      expect(week3.entries, hasLength(1));
      expect(week3.entries.single.venue.isOnline, isFalse);
    });

    test('只并「同一门课同一节次」那一对，别的照旧是冲突', () {
      final online = Venue.online(campus: '主校区');
      final timetable = _timetable(term, [
        _session(courseName: '甲课', weeks: WeekSet([2]), venue: online),
        _session(courseName: '甲课', weeks: WeekSet([2])),
        _session(courseName: '乙课', weeks: WeekSet([2])),
      ]);

      final cell = gridAt(timetable, 2, DateTime.monday, 3);

      expect(
        cell.entries.map((entry) => entry.courseName),
        ['甲课', '乙课'],
        reason: '线上那条把教室那条并掉了，乙课没人并',
      );
      expect(cell.entries.first.venue.isOnline, isTrue);
      expect(cell.hasConflict, isTrue);
    });

    test('两条在线上、或教师对不上时，一条都不并，宁可不取舍', () {
      final online = Venue.online(campus: '主校区');
      final twoOnline = _timetable(term, [
        _session(courseName: '甲课', weeks: WeekSet([2]), venue: online),
        _session(courseName: '甲课', weeks: WeekSet([2]), venue: online),
      ]);
      final teachersDiffer = _timetable(term, [
        _session(courseName: '甲课', weeks: WeekSet([2]), teacher: '李四', venue: online),
        _session(courseName: '甲课', weeks: WeekSet([2]), teacher: '王五'),
      ]);

      expect(gridAt(twoOnline, 2, DateTime.monday, 3).entries, hasLength(2));
      expect(
        gridAt(teachersDiffer, 2, DateTime.monday, 3).entries,
        hasLength(2),
      );
    });
  });

  group('冲突', () {
    test('同一格同一周两条安排 → 两条都在，且被标出来', () {
      final timetable = _timetable(term, [
        _session(courseName: '高等数学(一)', weeks: WeekSet([2, 3])),
        _session(courseName: '大学英语(二)', weeks: WeekSet([3, 4])),
      ]);

      final cell = gridAt(timetable, 3, DateTime.monday, 3);

      expect(cell.entries, hasLength(2));
      expect(cell.hasConflict, isTrue);
      expect(
        cell.entries.map((entry) => entry.courseName),
        ['高等数学(一)', '大学英语(二)'],
        reason: '不自动取舍，两条都留着，顺序照课表里的先后',
      );
    });

    test('同一格里周次错开的安排是常态，不是冲突', () {
      final timetable = _timetable(term, [
        _session(courseName: '单周课', weeks: WeekSet([1, 3])),
        _session(courseName: '双周课', weeks: WeekSet([2, 4])),
      ]);

      for (final week in [1, 2, 3, 4]) {
        final cell = gridAt(timetable, week, DateTime.monday, 3);
        expect(cell.entries, hasLength(1), reason: '第 $week 周只有一门');
        expect(cell.hasConflict, isFalse);
      }
    });

    test('连堂的部分重叠也算冲突（第三～四节 vs 第四节）', () {
      final timetable = _timetable(term, [
        _session(courseName: '连堂那门', periods: PeriodSpan(3, 2)),
        _session(courseName: '单节那门', periods: PeriodSpan(4, 1)),
      ]);

      final grid = expandWeek(timetable, 1);

      expect(grid.at(DateTime.monday, 3).hasConflict, isFalse);
      expect(grid.at(DateTime.monday, 4).entries, hasLength(2));
      expect(grid.at(DateTime.monday, 4).hasConflict, isTrue);
      expect(grid.at(DateTime.monday, 5).isEmpty, isTrue);
    });

    test('同一门的同一节课一周上两次也算冲突', () {
      final timetable = _timetable(term, [
        _session(courseName: '高等数学(一)', teacher: '李四'),
        _session(courseName: '高等数学(一)', teacher: '王五'),
      ]);

      final cell = gridAt(timetable, 1, DateTime.monday, 3);

      expect(cell.entries, hasLength(2));
      expect(cell.hasConflict, isTrue);
      expect(
        cell.entries.map((entry) => entry.courseName),
        ['高等数学(一)', '高等数学(一)'],
        reason: '颜色取课程名，两条同色——但它们确实是两条安排',
      );
    });

    test('停课让冲突在那一周消失，别的周照旧', () {
      final timetable = _timetable(term, [
        _session(courseName: '甲', weeks: WeekSet([1, 2, 3])),
        _session(
          courseName: '乙',
          weeks: WeekSet([1, 2, 3]),
          exceptions: [Cancellation(2)],
        ),
      ]);

      expect(gridAt(timetable, 1, DateTime.monday, 3).hasConflict, isTrue);
      expect(gridAt(timetable, 2, DateTime.monday, 3).entries, hasLength(1));
      expect(gridAt(timetable, 2, DateTime.monday, 3).hasConflict, isFalse);
      expect(gridAt(timetable, 3, DateTime.monday, 3).hasConflict, isTrue);
    });

    test('格子带得出它这一周要画的那几条', () {
      final timetable = _timetable(term, [
        _session(courseName: '甲', periods: PeriodSpan(3, 2)),
        _session(courseName: '乙', periods: PeriodSpan(3, 2)),
      ]);

      final cell = gridAt(timetable, 1, DateTime.monday, 4);

      expect(cell.weekday, DateTime.monday);
      expect(cell.period, 4);
      expect(cell.entries.map((entry) => entry.courseName), ['甲', '乙']);
      expect(
        gridCourses(expandWeek(timetable, 1)),
        ['甲', '乙'],
        reason: '一屏要用的课程名，从格子里收集',
      );
    });
  });

  group('取格子外的坐标', () {
    test('星期或节次越界就明确报错，不返回空', () {
      final grid = expandWeek(_timetable(term, [_session()]), 1);

      expect(() => grid.at(0, 3), throwsArgumentError);
      expect(() => grid.at(8, 3), throwsArgumentError);
      expect(() => grid.at(DateTime.monday, 0), throwsArgumentError);
      expect(() => grid.at(DateTime.monday, 13), throwsArgumentError);
    });
  });

  group('节次表不是 12 节那一种', () {
    // 作息时间表允许改（「它一变，全部提醒时刻随之改变」），所以展开不能假设
    // 节次号就是下标、也不能假设一天正好 12 节。
    final fourPeriods = BellSchedule(
      name: '四节课的小表',
      periods: [
        PeriodTime(
          period: 1,
          start: ClockTime(8, 0),
          end: ClockTime(9, 30),
          block: DayBlock.morning,
        ),
        PeriodTime(
          period: 3,
          start: ClockTime(10, 0),
          end: ClockTime(11, 30),
          block: DayBlock.morning,
        ),
        PeriodTime(
          period: 5,
          start: ClockTime(14, 0),
          end: ClockTime(15, 30),
          block: DayBlock.afternoon,
        ),
        PeriodTime(
          period: 7,
          start: ClockTime(16, 0),
          end: ClockTime(17, 30),
          block: DayBlock.afternoon,
        ),
      ],
    );

    test('节次号不连续时按节次号定位，不拿它当下标', () {
      final timetable = Timetable(
        term: term,
        sessions: [_session(periods: PeriodSpan(5, 1))],
        settings: TermSettings(bellSchedule: fourPeriods),
      );
      final grid = expandWeek(timetable, 1);

      expect(grid.periodCount, 4);
      expect(
        _courses(grid.at(DateTime.monday, 5)),
        ['高等数学(一)'],
        reason: '第 5 节是这一天的第 3 格，不是第 5 格',
      );
      expect(grid.days[0].cells.map((cell) => cell.period), [1, 3, 5, 7]);
    });

    test('表里没有的节次取不到，明确报错', () {
      final grid = expandWeek(
        Timetable(
          term: term,
          sessions: [_session(periods: PeriodSpan(5, 1))],
          settings: TermSettings(bellSchedule: fourPeriods),
        ),
        1,
      );

      expect(() => grid.at(DateTime.monday, 2), throwsArgumentError);
      expect(() => grid.at(DateTime.monday, 12), throwsArgumentError);
    });

    test('一条安排跨到表外的节次时，只铺得进表里的那几格', () {
      final grid = expandWeek(
        Timetable(
          term: term,
          sessions: [_session(periods: PeriodSpan(5, 3))],
          settings: TermSettings(bellSchedule: fourPeriods),
        ),
        1,
      );

      expect(_courses(grid.at(DateTime.monday, 5)), ['高等数学(一)']);
      expect(
        _courses(grid.at(DateTime.monday, 7)),
        ['高等数学(一)'],
        reason: '第 6 节不在表里，第 7 节在——中间跳掉的那节不该把第 7 节顶掉',
      );
      expect(grid.days[0].cells, hasLength(4));
    });
  });

  group('拿真实导出文件的脱敏夹具展开', () {
    // 期望值是对着夹具逐周数出来的，见 `test/fixtures/README.md`。这份夹具里
    // **没有例外**，也**没有冲突**——它是「常态课表展开应该长什么样」的凭据。
    final timetable = importFixture().timetable;

    /// 每一周有几个格子有课。夹具里的安排在 18 周上互相错开，所以这个数列是
    /// 一头一尾都对得上的指纹：哪一周多了一格或少了一格，一眼就能看出是第几周。
    const occupiedCellsPerWeek = [
      18, 20, 22, 22, 22, 22, 22, 22, 22, 22, // 第 1-10 周
      20, 20, 16, 16, 11, 11, 4, 4, // 第 11-18 周
    ];

    // 「解出 14 条安排、0 个解不出来」由 `test/import/fixture_import_test.dart`
    // 断言（那是它那一票的验收凭据），这里只断言**展开**这一步。

    test('18 周逐周展开，每一周的格子数都对得上', () {
      expect(occupiedCellsPerWeek, hasLength(18));

      for (var week = 1; week <= occupiedCellsPerWeek.length; week++) {
        final grid = expandWeek(timetable, week);
        final occupied = grid.days
            .expand((day) => day.cells)
            .where((cell) => cell.isNotEmpty)
            .length;

        expect(
          occupied,
          occupiedCellsPerWeek[week - 1],
          reason: '第 $week 周的格子数对不上',
        );
      }
      expect(
        occupiedCellsPerWeek.reduce((a, b) => a + b),
        316,
        reason: '逐周格子数加起来；格子数逐周不同是因为安排在 18 周上互相错开',
      );
      expect(
        expandWeek(timetable, 1).days.last.cells.every((cell) => cell.isEmpty),
        isTrue,
        reason: '这份课表里星期日一格都没有',
      );
    });

    test('展开整学期，格子从来不冲突', () {
      final conflicts = <String>[];
      for (var week = 1; week <= 18; week++) {
        for (final day in expandWeek(timetable, week).days) {
          for (final cell in day.cells) {
            if (cell.hasConflict) {
              conflicts.add('第$week周 星期${cell.weekday} 第${cell.period}节');
            }
          }
        }
      }

      expect(conflicts, isEmpty, reason: '教务系统导出的课表本不该有重叠');
    });

    test('连堂占满它的跨度：星期一第三～五节都是「人机交互的软件工程方法」', () {
      final grid = expandWeek(timetable, 1);

      for (final period in [3, 4, 5]) {
        final entries = grid.at(DateTime.monday, period).entries;

        expect(entries, hasLength(1), reason: '第 $period 节只有这一条');
        expect(entries.single.courseName, '人机交互的软件工程方法');
        expect(entries.single.session.periods.periods, [3, 4, 5]);
        expect(entries.single.venue.room, '4J410');
      }
      expect(grid.at(DateTime.monday, 2).entries.single.courseName, '编译原理');
      expect(
        grid.at(DateTime.monday, 6).entries.single.courseName,
        'Software Testing（软件测试技术）',
        reason: '连堂到第五节为止，第六节起是另一条安排',
      );
      expect(
        grid.at(DateTime.monday, 8).isEmpty,
        isTrue,
        reason: '星期一第 7 节是最后有课的一节，连堂没有溢出到第 8 节',
      );
    });

    test('周次集合不含本周就完全不出现：第 13 周星期一没有「编译原理」', () {
      final week13 = expandWeek(timetable, 13);

      expect(
        week13.at(DateTime.monday, 1).isEmpty,
        isTrue,
        reason: '编译原理星期一第 1-2 节是第 1 周与第 3-12 周，第 13 周不在其中',
      );
      expect(week13.at(DateTime.monday, 2).isEmpty, isTrue);
      // 同一门课的另一条（星期四第 3-4 节）也不在第 13 周，但星期四本来就只占这一天。
      expect(week13.at(DateTime.thursday, 3).isEmpty, isTrue);

      final week12 = expandWeek(timetable, 12);
      expect(week12.at(DateTime.monday, 1).entries.single.courseName, '编译原理');
      expect(week12.at(DateTime.thursday, 3).entries.single.courseName, '编译原理');
    });

    test('断档周只跳掉第 2 周：星期四第 3-4 节的「编译原理」', () {
      for (final week in [1, 3, 4, 12]) {
        expect(
          expandWeek(timetable, week).at(DateTime.thursday, 3).entries,
          hasLength(1),
          reason: '第 $week 周它该出现',
        );
      }
      expect(expandWeek(timetable, 2).at(DateTime.thursday, 3).isEmpty, isTrue);
      expect(expandWeek(timetable, 13).at(DateTime.thursday, 3).isEmpty, isTrue);
    });

    test('一门课换教师是两条独立的安排，展开到各自那几周', () {
      final firstHalf = expandWeek(timetable, 1).at(DateTime.monday, 3).entries;
      final secondHalf = expandWeek(timetable, 12).at(DateTime.monday, 3).entries;

      expect(firstHalf.single.session.teacher, '李超波');
      expect(secondHalf.single.session.teacher, '戴家树');
      expect(
        firstHalf.single.session.courseName,
        secondHalf.single.session.courseName,
        reason: '同一门课，颜色该是一样的——换教师不该换色',
      );
    });

    test('一门课换教室：星期二第 1-2 节第 9 周起改到 4J203', () {
      expect(
        expandWeek(timetable, 8).at(DateTime.tuesday, 1).entries.single.venue,
        Venue(room: '4J209', campus: '主校区'),
      );
      expect(
        expandWeek(timetable, 9).at(DateTime.tuesday, 1).entries.single.venue,
        Venue(room: '4J203', campus: '主校区'),
      );
      expect(
        expandWeek(timetable, 9).at(DateTime.tuesday, 1).entries.single
            .courseName,
        '嵌入式开发',
        reason: '第 9 周起这条安排本身就是另一门课了',
      );
    });

    test('整张网格是 7 天 × 12 节，第 13 节这种坐标直接报错', () {
      final grid = expandWeek(timetable, 1);

      expect(grid.days, hasLength(7));
      expect(grid.periodCount, 12);
      expect(() => grid.at(DateTime.sunday, 1), returnsNormally);
      expect(() => grid.at(DateTime.sunday, 12), returnsNormally);
      expect(() => grid.at(DateTime.sunday, 13), throwsArgumentError);
    });
  });
}

/// 展开第 [week] 周的课表，取星期一那一列的第 [period] 节。
///
/// 断言里最常写的就是这一步，抽出来省得每处都写 `expandWeek(...).at(...)`。
WeekCell gridAt(Timetable timetable, int week, int weekday, int period) =>
    expandWeek(timetable, week).at(weekday, period);

/// 一格里的课程名，按格子里的先后。
List<String> _courses(WeekCell cell) =>
    cell.entries.map((entry) => entry.courseName).toList();

/// 整张网格里出现过的课程名，按扫到的先后。
List<String> gridCourses(WeekGrid grid) {
  final names = <String>[];
  for (final day in grid.days) {
    for (final cell in day.cells) {
      for (final entry in cell.entries) {
        if (!names.contains(entry.courseName)) names.add(entry.courseName);
      }
    }
  }
  return names;
}

Timetable _timetable(AcademicTerm term, List<ClassSession> sessions) =>
    Timetable(term: term, sessions: sessions);

ClassSession _session({
  String courseName = '高等数学(一)',
  String? teacher = '李四',
  int weekday = DateTime.monday,
  PeriodSpan? periods,
  WeekSet? weeks,
  Venue? venue,
  List<SessionException> exceptions = const [],
}) {
  return ClassSession(
    courseName: courseName,
    teacher: teacher,
    weekday: weekday,
    periods: periods ?? PeriodSpan(3, 3),
    weeks: weeks ?? WeekSet([1, 2, 3, 4, 5, 6, 7, 8]),
    venue: venue ?? Venue(room: '4J410', campus: '主校区'),
    exceptions: exceptions,
  );
}
