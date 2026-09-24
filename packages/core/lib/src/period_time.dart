import 'clock_time.dart';
import 'day_block.dart';

/// 一个节次在一天里的位置：第几节 + 起止时刻 + 属于哪个时段。
class PeriodTime {
  /// 校验节次为正、下课不早于上课。
  factory PeriodTime({
    required int period,
    required ClockTime start,
    required ClockTime end,
    required DayBlock block,
  }) {
    if (period < 1) {
      throw ArgumentError.value(period, 'period', '节次从第 1 节开始');
    }
    if (end.compareTo(start) < 0) {
      throw ArgumentError('下课时刻不能早于上课时刻：${start.toText()}-${end.toText()}');
    }
    return PeriodTime._(period: period, start: start, end: end, block: block);
  }

  const PeriodTime._({
    required this.period,
    required this.start,
    required this.end,
    required this.block,
  });

  /// 节次，从 1 开始。
  final int period;

  final ClockTime start;
  final ClockTime end;

  /// 上午 / 下午 / 晚上。
  final DayBlock block;

  /// 时刻的展示写法，如 `08:00-08:45`。
  String get label => '${start.toText()}-${end.toText()}';

  @override
  String toString() => '第$period节 $label';

  @override
  bool operator ==(Object other) =>
      other is PeriodTime &&
      other.period == period &&
      other.start == start &&
      other.end == end &&
      other.block == block;

  @override
  int get hashCode => Object.hash(period, start, end, block);
}
