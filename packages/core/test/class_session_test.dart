import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

void main() {
  group('上课安排', () {
    test('一条安排承载课程 / 教师 / 周次集合 / 节次跨度 / 地点', () {
      final session = ClassSession(
        courseName: '高等数学(一)',
        teacher: '李四',
        weekday: DateTime.tuesday,
        periods: PeriodSpan(3, 3),
        weeks: WeekSet([1, 2, 3, 4, 5, 6, 7, 8]),
        venue: Venue(room: '4J410', campus: '主校区'),
      );

      expect(session.courseName, '高等数学(一)');
      expect(session.teacher, '李四');
      expect(session.weekday, 2);
      expect(session.periods.periods, [3, 4, 5]);
      expect(session.weeks.length, 8);
      expect(session.venue.room, '4J410');
      expect(session.exceptions, isEmpty);
    });

    test('教师可以没有（导出文件里的空括号、手动录入时不填）', () {
      expect(_session(teacher: '').teacher, isNull);
      expect(_session(teacher: '  ').teacher, isNull);
      expect(_session(teacher: ' 李四 ').teacher, '李四');
      expect(_session(teacher: null).teacher, isNull);
    });

    test('课程名不能是空白', () {
      expect(() => _session(courseName: '   '), throwsArgumentError);
    });

    test('星期必须是 1..7', () {
      expect(_session(weekday: 1).weekday, 1);
      expect(_session(weekday: 7).weekday, 7);
      expect(() => _session(weekday: 0), throwsArgumentError);
      expect(() => _session(weekday: 8), throwsArgumentError);
    });

    test('周次集合不能是空的——那会是一条永远不出现的安排', () {
      expect(() => _session(weeks: WeekSet(const [])), throwsArgumentError);
    });

    test('相等按全部字段判定', () {
      expect(_session(), _session());
      expect(_session().hashCode, _session().hashCode);
      expect(_session(), isNot(_session(teacher: '王五')));
      expect(_session(), isNot(_session(periods: PeriodSpan(4, 1))));
    });
  });

  group('例外', () {
    test('停课挂在既有的上课安排之上，是信息而不是删除', () {
      final session = _session(
        weeks: WeekSet([1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]),
        exceptions: [Cancellation(2)],
      );

      expect(session.exceptions, hasLength(1));
      expect(session.exceptions.single, isA<Cancellation>());
      expect(session.exceptions.single.week, 2);
      expect(session.weeks.weeks, [
        1,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
      ], reason: '导出文件里停课那条单列，正常那条的周次集合已经排除了第 2 周');
    });

    test('同一条安排能挂多个例外', () {
      final session = _session(
        exceptions: [
          Cancellation(2),
          OnlineTeaching(14, campus: '主校区'),
        ],
      );

      expect(session.exceptions, hasLength(2));
      expect(session.exceptions[1], isA<OnlineTeaching>());
      expect((session.exceptions[1] as OnlineTeaching).campus, '主校区');
    });

    test('线上教学的例外改的是地点那一项，不含停课那种「不上」的语义', () {
      final online = OnlineTeaching(14, campus: '主校区');

      expect(online.week, 14);
      expect(online.campus, '主校区');
      expect(online, isNot(Cancellation(14)));
    });

    test('例外所在的教学周必须合法', () {
      expect(() => Cancellation(0), throwsArgumentError);
      expect(() => Cancellation(WeekSet.maxWeek + 1), throwsArgumentError);
      expect(() => OnlineTeaching(0), throwsArgumentError);
    });

    test('例外不改变安排本身', () {
      final session = _session(exceptions: [Cancellation(2)]);
      final sameWithoutExceptions = _session();

      expect(session.courseName, sameWithoutExceptions.courseName);
      expect(session.coversWeek(2), isTrue, reason: '停课例外不改周次集合');
      expect(sameWithoutExceptions.exceptions, isEmpty);
    });
  });
}

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
