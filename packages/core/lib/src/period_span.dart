/// 一条上课安排占哪些节次：起始节次 + 节数。
///
/// 单节次就是节数为 1 的跨度（用 [PeriodSpan.single]）。节数对应导出文件里的
/// `rowspan`——一趟连堂占多个格子，占的正是这个跨度。
///
/// 这里**不写死一天 12 节**：那是作息时间表与导出文件的事，跨度只知道从第几节
/// 起、连着几节。
class PeriodSpan {
  /// 校验起始节次与节数。
  factory PeriodSpan(int start, int length) {
    if (start < 1) {
      throw ArgumentError.value(start, 'start', '起始节次从第 1 节开始');
    }
    if (length < 1) {
      throw ArgumentError.value(length, 'length', '节数至少是 1');
    }
    return PeriodSpan._(start, length);
  }

  /// 单节次的跨度。
  factory PeriodSpan.single(int period) => PeriodSpan(period, 1);

  const PeriodSpan._(this.start, this.length);

  /// 起始节次。
  final int start;

  /// 连着几节。
  final int length;

  /// 最后一节的节次。
  int get end => start + length - 1;

  /// 占用的节次，升序。
  Iterable<int> get periods sync* {
    for (var period = start; period <= end; period++) {
      yield period;
    }
  }

  bool get isSingle => length == 1;

  bool contains(int period) => period >= start && period <= end;

  /// 两段节次是否有重叠。同一格里两条安排冲突与否，先看这个。
  bool overlaps(PeriodSpan other) => start <= other.end && other.start <= end;

  @override
  String toString() => isSingle ? '第$start节' : '第$start-$end节';

  @override
  bool operator ==(Object other) =>
      other is PeriodSpan && other.start == start && other.length == length;

  @override
  int get hashCode => Object.hash(start, length);
}
