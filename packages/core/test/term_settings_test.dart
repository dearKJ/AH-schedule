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

  group('某一天落在第几教学周', () {
    // 2026-09-07 是周一，拿它当「第 1 周的第一天」。
    final settings = TermSettings(firstDayOfWeek1: DateTime(2026, 9, 7));

    test('第 1 周那七天都算第 1 周', () {
      expect(settings.weekOf(DateTime(2026, 9, 7)), 1, reason: '周一');
      expect(settings.weekOf(DateTime(2026, 9, 13)), 1, reason: '周日，仍是第 1 周');
    });

    test('第 N 周 = 从开学那周的周一算起的连续 7 天', () {
      expect(settings.weekOf(DateTime(2026, 9, 14)), 2);
      expect(settings.weekOf(DateTime(2026, 9, 20)), 2, reason: '第 2 周的周日');
      expect(settings.weekOf(DateTime(2026, 9, 21)), 3);
    });

    test('一天里的时分秒不影响归到哪一周', () {
      expect(
        settings.weekOf(DateTime(2026, 9, 14, 23, 59, 59)),
        2,
        reason: '按日期算，不按时刻算',
      );
      expect(settings.weekOf(DateTime(2026, 9, 20, 0, 0, 1)), 2);
    });

    test('跨月、跨年照算', () {
      // 2027-01-01 与 2026-09-07 差 116 天，116 = 16 × 7 + 4，所以落在第 17 周。
      expect(settings.weekOf(DateTime(2027, 1, 1)), 17);
      expect(settings.weekOf(DateTime(2026, 10, 1)), 4);
    });

    test('范围的两个端点：第 1 周与第 53 周都算得出来，第 54 周越界', () {
      expect(
        settings.weekOf(DateTime(2027, 9, 12)),
        WeekSet.maxWeek,
        reason: '第 53 周的周日',
      );
      expect(() => settings.weekOf(DateTime(2027, 9, 13)), throwsArgumentError);
    });

    test('开学之前明确报错，不返回 0 或负数', () {
      expect(() => settings.weekOf(DateTime(2026, 9, 6)), throwsArgumentError);
      expect(() => settings.weekOf(DateTime(2026, 1, 1)), throwsArgumentError);
    });

    test('没设「第 1 周的第一天」时不猜，明确报错', () {
      expect(
        () => TermSettings().weekOf(DateTime(2026, 9, 7)),
        throwsStateError,
        reason: '「没设」与「第 0 周」是两件事，不能混成一个返回值',
      );
    });
  });
}
