import 'clock_time.dart';
import 'day_block.dart';
import 'internal_helpers.dart';
import 'period_time.dart';

/// 作息时间表：节次到具体时刻的映射。
///
/// 教务系统不提供这张表，由 App 本地维护、**用户可改**——它一变，全部提醒时刻
/// 随之改变。内置的默认值见 `docs/reference/ahpu-bell-schedule.md`。
class BellSchedule {
  /// 校验名字不为空、节次唯一且升序。
  factory BellSchedule({
    required String name,
    required List<PeriodTime> periods,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', '作息时间表得有名字');
    }
    if (periods.isEmpty) {
      throw ArgumentError.value(periods, 'periods', '作息时间表不能是空的');
    }
    var previous = 0;
    for (final periodTime in periods) {
      if (periodTime.period <= previous) {
        throw ArgumentError.value(
          periodTime.period,
          'periods',
          '节次必须唯一且升序，第 ${periodTime.period} 节重复或乱序了',
        );
      }
      previous = periodTime.period;
    }
    return BellSchedule._(trimmedName, List.unmodifiable(periods));
  }

  const BellSchedule._(this.name, this.periods);

  /// 本校的默认作息时间表（2026-09-23 经使用者口述确认）。
  ///
  /// 注意文档里记着一处**未经逐格核实**的地方：第四节→第五节的课间与第五节 12:20
  /// 结束是由规律推算的。要精确到分钟的话值得再核一次。
  static final BellSchedule ahpuDefault = BellSchedule(
    name: '安徽工程大学（默认）',
    periods: [
      _period(1, 8, 0, 8, 45, DayBlock.morning),
      _period(2, 8, 50, 9, 35, DayBlock.morning),
      _period(3, 9, 55, 10, 40, DayBlock.morning),
      _period(4, 10, 45, 11, 30, DayBlock.morning),
      _period(5, 11, 35, 12, 20, DayBlock.morning),
      _period(6, 14, 30, 15, 15, DayBlock.afternoon),
      _period(7, 15, 20, 16, 5, DayBlock.afternoon),
      _period(8, 16, 15, 17, 0, DayBlock.afternoon),
      _period(9, 17, 5, 17, 50, DayBlock.afternoon),
      _period(10, 19, 0, 19, 45, DayBlock.evening),
      _period(11, 19, 50, 20, 35, DayBlock.evening),
      _period(12, 20, 40, 21, 25, DayBlock.evening),
    ],
  );

  static PeriodTime _period(
    int period,
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
    DayBlock block,
  ) {
    return PeriodTime(
      period: period,
      start: ClockTime(startHour, startMinute),
      end: ClockTime(endHour, endMinute),
      block: block,
    );
  }

  /// 这张表的名字，如 `安徽工程大学（默认）`。
  final String name;

  /// 按节次升序排列的全部节次。
  final List<PeriodTime> periods;

  /// 一天有多少节。
  int get periodCount => periods.length;

  /// 最后一节的节次编号。空表不可能存在，构造时就挡掉了。
  int get lastPeriod => periods.last.period;

  /// 这个节次的起止时刻；表里没有这个节次时返回 null——不猜。
  PeriodTime? forPeriod(int period) {
    for (final periodTime in periods) {
      if (periodTime.period == period) return periodTime;
    }
    return null;
  }

  /// 这个节次属于上午 / 下午 / 晚上；表里没有这个节次时返回 null。
  DayBlock? blockOf(int period) => forPeriod(period)?.block;

  @override
  String toString() => 'BellSchedule($name, ${periods.length} 节)';

  @override
  bool operator ==(Object other) =>
      other is BellSchedule &&
      other.name == name &&
      listEquals(other.periods, periods);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(periods));
}
