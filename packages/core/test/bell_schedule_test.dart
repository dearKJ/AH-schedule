import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

void main() {
  group('内建默认作息时间表', () {
    test('默认值可用，一共 12 节', () {
      final schedule = BellSchedule.ahpuDefault;

      expect(schedule.periods, hasLength(12), reason: '本校一天 12 节');
      expect(schedule.name, isNotEmpty);
      expect(
        schedule.periods.map((p) => p.period),
        List.generate(12, (i) => i + 1),
      );
    });

    test('节次 → 时刻的映射逐条正确', () {
      const expected = {
        1: ('08:00', '08:45', DayBlock.morning),
        2: ('08:50', '09:35', DayBlock.morning),
        3: ('09:55', '10:40', DayBlock.morning),
        4: ('10:45', '11:30', DayBlock.morning),
        5: ('11:35', '12:20', DayBlock.morning),
        6: ('14:30', '15:15', DayBlock.afternoon),
        7: ('15:20', '16:05', DayBlock.afternoon),
        8: ('16:15', '17:00', DayBlock.afternoon),
        9: ('17:05', '17:50', DayBlock.afternoon),
        10: ('19:00', '19:45', DayBlock.evening),
        11: ('19:50', '20:35', DayBlock.evening),
        12: ('20:40', '21:25', DayBlock.evening),
      };

      for (final entry in expected.entries) {
        final time = BellSchedule.ahpuDefault.forPeriod(entry.key);
        expect(time, isNotNull, reason: '第 ${entry.key} 节没有时刻');
        expect(
          time!.start.toText(),
          entry.value.$1,
          reason: '第 ${entry.key} 节的开始时刻',
        );
        expect(
          time.end.toText(),
          entry.value.$2,
          reason: '第 ${entry.key} 节的结束时刻',
        );
        expect(time.block, entry.value.$3, reason: '第 ${entry.key} 节属于哪个时段');
      }
    });

    test('上午 / 下午 / 晚上的分界与教务系统一致', () {
      expect(DayBlock.morning.label, '上午');
      expect(DayBlock.afternoon.label, '下午');
      expect(DayBlock.evening.label, '晚上');
      expect(BellSchedule.ahpuDefault.blockOf(1), DayBlock.morning);
      expect(BellSchedule.ahpuDefault.blockOf(5), DayBlock.morning);
      expect(BellSchedule.ahpuDefault.blockOf(6), DayBlock.afternoon);
      expect(BellSchedule.ahpuDefault.blockOf(9), DayBlock.afternoon);
      expect(BellSchedule.ahpuDefault.blockOf(10), DayBlock.evening);
      expect(BellSchedule.ahpuDefault.blockOf(12), DayBlock.evening);
    });

    test('查不到的节次返回 null，不猜一个默认值', () {
      expect(BellSchedule.ahpuDefault.forPeriod(0), isNull);
      expect(BellSchedule.ahpuDefault.forPeriod(13), isNull);
      expect(BellSchedule.ahpuDefault.blockOf(13), isNull);
    });

    test('默认值每次拿到的都是同一份，改动它不会串味', () {
      final a = BellSchedule.ahpuDefault;
      final b = BellSchedule.ahpuDefault;

      expect(identical(a, b), isTrue);
      expect(() => a.periods.add(a.periods.first), throwsUnsupportedError);
    });
  });

  group('作息时间表可改', () {
    test('换一张表，节次对应的时刻跟着变', () {
      final custom = BellSchedule(
        name: '暑假作息',
        periods: [
          PeriodTime(
            period: 1,
            start: ClockTime(9, 30),
            end: ClockTime(10, 15),
            block: DayBlock.morning,
          ),
        ],
      );

      expect(custom.forPeriod(1)!.start.toText(), '09:30');
      expect(custom.forPeriod(2), isNull);
      expect(
        BellSchedule.ahpuDefault.forPeriod(1)!.start.toText(),
        '08:00',
        reason: '改一张表不该动到默认那张',
      );
    });

    test('一张表里的节次必须唯一且升序', () {
      PeriodTime at(int period) => PeriodTime(
        period: period,
        start: ClockTime(8, 0),
        end: ClockTime(8, 45),
        block: DayBlock.morning,
      );

      expect(
        () => BellSchedule(name: '空表', periods: const []),
        throwsArgumentError,
      );
      expect(
        () => BellSchedule(name: '乱序', periods: [at(2), at(1)]),
        throwsArgumentError,
      );
      expect(
        () => BellSchedule(name: '重复', periods: [at(1), at(1)]),
        throwsArgumentError,
      );
      expect(
        () => BellSchedule(name: '  ', periods: [at(1)]),
        throwsArgumentError,
      );
    });

    test('一节课的结束时刻不能早于开始时刻', () {
      expect(
        () => PeriodTime(
          period: 1,
          start: ClockTime(10, 0),
          end: ClockTime(9, 0),
          block: DayBlock.morning,
        ),
        throwsArgumentError,
      );
    });
  });

  group('时刻', () {
    test('写成 HH:mm', () {
      expect(ClockTime(8, 0).toText(), '08:00');
      expect(ClockTime(13, 5).toText(), '13:05');
      expect(ClockTime(23, 59).toText(), '23:59');
    });

    test('解析时宽容：`8:00`、`08：00` 都认', () {
      expect(ClockTime.parse('08:00'), ClockTime(8, 0));
      expect(ClockTime.parse('8:00'), ClockTime(8, 0));
      expect(ClockTime.parse(' 08：00 '), ClockTime(8, 0));
      expect(ClockTime.parse('08:00:00'), ClockTime(8, 0));
    });

    test('不是时刻就明确报错', () {
      expect(() => ClockTime.parse(''), throwsFormatException);
      expect(() => ClockTime.parse('八点'), throwsFormatException);
      expect(() => ClockTime.parse('24:00'), throwsFormatException);
      expect(() => ClockTime.parse('08:60'), throwsFormatException);
      expect(ClockTime.tryParse('八点'), isNull);
    });

    test('时刻有先后之分', () {
      expect(ClockTime(8, 0).compareTo(ClockTime(9, 0)), lessThan(0));
      expect(ClockTime(8, 0).compareTo(ClockTime(8, 0)), 0);
      expect(ClockTime(9, 0).compareTo(ClockTime(8, 30)), greaterThan(0));
      expect(ClockTime(9, 5).minutesSinceMidnight, 545);
    });

    test('时刻必须在一天之内', () {
      expect(() => ClockTime(24, 0), throwsArgumentError);
      expect(() => ClockTime(-1, 0), throwsArgumentError);
      expect(() => ClockTime(8, 60), throwsArgumentError);
    });
  });
}
