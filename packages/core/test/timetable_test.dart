import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

void main() {
  final term = AcademicTerm.parseLabel('2026-2027学年第一学期');

  group('课表', () {
    test('同一门课的多条上课安排彼此独立，不会被合并成一条', () {
      // 一周上两次、中途换教师、换教室——同一门课，四条独立的安排。
      final timetable = Timetable(
        term: term,
        sessions: [
          _session(
            weekday: DateTime.monday,
            periods: PeriodSpan(1, 2),
            teacher: '李四',
            room: '4J410',
          ),
          _session(
            weekday: DateTime.thursday,
            periods: PeriodSpan(3, 2),
            teacher: '李四',
            room: '4J410',
          ),
          _session(
            weekday: DateTime.monday,
            periods: PeriodSpan(1, 2),
            teacher: '王五',
            room: '4J410',
          ),
          _session(
            weekday: DateTime.monday,
            periods: PeriodSpan(1, 2),
            teacher: '王五',
            room: '4J209',
          ),
        ],
      );

      expect(timetable.sessions, hasLength(4));
      expect(timetable.courseNames, {'高等数学(一)'});
      expect(timetable.sessionsOf('高等数学(一)'), hasLength(4));
      expect(
        timetable
            .sessionsOf('高等数学(一)')
            .map(
              (s) =>
                  '${s.teacher}/${s.venue.room}/${s.weekday}/'
                  '${s.periods.start}-${s.periods.end}',
            ),
        [
          '李四/4J410/1/1-2',
          '李四/4J410/4/3-4',
          '王五/4J410/1/1-2',
          '王五/4J209/1/1-2',
        ],
        reason: '每条都保留自己的教师、地点、星期、节次，没有被合并或被后来者覆盖',
      );
    });

    test('只有课程名相同才算是同一门课', () {
      final timetable = Timetable(
        term: term,
        sessions: [
          _session(courseName: '高等数学(一)'),
          _session(courseName: '大学英语(二)'),
        ],
      );

      expect(timetable.courseNames, {'高等数学(一)', '大学英语(二)'});
      expect(timetable.sessionsOf('高等数学(一)'), hasLength(1));
      expect(timetable.sessionsOf('没有这门课'), isEmpty);
    });

    test('保持传入的顺序（导入时是解析顺序）', () {
      final first = _session(courseName: 'A');
      final second = _session(courseName: 'B');

      expect(Timetable(term: term, sessions: [first, second]).sessions, [
        first,
        second,
      ]);
    });

    test('空课表是合法的', () {
      final timetable = Timetable(term: term);

      expect(timetable.sessions, isEmpty);
      expect(timetable.courseNames, isEmpty);
      expect(timetable.settings.bellSchedule, BellSchedule.ahpuDefault);
    });

    test('课表带着学年学期与学期设置', () {
      final timetable = Timetable(
        term: term,
        settings: TermSettings(
          firstDayOfWeek1: DateTime(2026, 9, 7),
          totalWeeks: 18,
        ),
      );

      expect(timetable.term.id, '2026-2027-1');
      expect(timetable.settings.firstDayOfWeek1, DateTime(2026, 9, 7));
      expect(timetable.settings.totalWeeks, 18);
    });

    test('内部列表改不动', () {
      final timetable = Timetable(term: term, sessions: [_session()]);

      expect(() => timetable.sessions.add(_session()), throwsUnsupportedError);
    });
  });
}

ClassSession _session({
  String courseName = '高等数学(一)',
  String? teacher = '李四',
  int weekday = DateTime.monday,
  PeriodSpan? periods,
  String room = '4J410',
}) {
  return ClassSession(
    courseName: courseName,
    teacher: teacher,
    weekday: weekday,
    periods: periods ?? PeriodSpan(1, 2),
    weeks: WeekSet([1, 2, 3, 4, 5, 6, 7, 8]),
    venue: Venue(room: room, campus: '主校区'),
  );
}
