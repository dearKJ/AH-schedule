import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

void main() {
  group('学期设置', () {
    test('默认什么都不填时，作息时间表用内建默认值', () {
      final settings = TermSettings();

      expect(settings.firstDayOfWeek1, isNull);
      expect(settings.totalWeeks, isNull, reason: '学期总周数不写死，留空即以数据实际范围为准');
      expect(settings.bellSchedule, BellSchedule.ahpuDefault);
    });

    test('「第 1 周的第一天」只留日期，丢掉时分秒', () {
      final settings = TermSettings(
        firstDayOfWeek1: DateTime(2026, 9, 7, 13, 45, 30),
      );

      expect(settings.firstDayOfWeek1, DateTime(2026, 9, 7));
    });

    test('一周从周一算起，因此第 1 周的第一天必须是周一', () {
      expect(DateTime(2026, 9, 7).weekday, DateTime.monday);
      expect(
        TermSettings(firstDayOfWeek1: DateTime(2026, 9, 7)).firstDayOfWeek1,
        DateTime(2026, 9, 7),
      );
      expect(
        () => TermSettings(firstDayOfWeek1: DateTime(2026, 9, 9)),
        throwsArgumentError,
        reason: '2026-09-09 是周三',
      );
    });

    test('能把任意一天归到它所在那一周的周一', () {
      expect(TermSettings.mondayOf(DateTime(2026, 9, 9)), DateTime(2026, 9, 7));
      expect(TermSettings.mondayOf(DateTime(2026, 9, 7)), DateTime(2026, 9, 7));
      expect(
        TermSettings.mondayOf(DateTime(2026, 9, 13)),
        DateTime(2026, 9, 7),
        reason: '周日归到本周周一',
      );
    });

    test('学期总周数要么不填，要么是个正数', () {
      expect(TermSettings(totalWeeks: 18).totalWeeks, 18);
      expect(
        TermSettings(totalWeeks: WeekSet.maxWeek).totalWeeks,
        WeekSet.maxWeek,
      );
      expect(() => TermSettings(totalWeeks: 0), throwsArgumentError);
      expect(() => TermSettings(totalWeeks: -1), throwsArgumentError);
      expect(
        () => TermSettings(totalWeeks: WeekSet.maxWeek + 1),
        throwsArgumentError,
      );
    });

    test('换作息时间表就是换掉整张表', () {
      final custom = BellSchedule(
        name: '调休作息',
        periods: [
          PeriodTime(
            period: 1,
            start: ClockTime(10, 0),
            end: ClockTime(10, 45),
            block: DayBlock.morning,
          ),
        ],
      );

      expect(
        TermSettings(bellSchedule: custom).bellSchedule
            .forPeriod(1)!
            .start
            .toText(),
        '10:00',
      );
    });
  });
}
