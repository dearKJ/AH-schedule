import 'class_session.dart';
import 'term_settings.dart';
import 'week_set.dart';

/// 周次导航的范围：**以数据实际范围为准**，外加一个可配的总周数。
///
/// 规格「时间规则」把这件事说死了——学期总周数**不写死**，周次导航的范围跟着数据走，
/// 不为一个想象的 20 周学期摆出一堆永远空着的周。所以范围是这样定出来的：
///
/// - 起点是**数据里出现的最小周次**。
/// - 终点是**数据里出现的最大周次**；设了学期总周数的学期，终点取两者里更大的那个
///   （设了 20 周就是想翻到第 20 周，哪怕课只排到第 16 周）。
/// - 一条安排都没有的课表给 `1..1`，而不是一个 0 长度的空范围——界面上总得有个能落下
///   的地方。
///
/// 它**不会为了迁就总周数把数据砍掉**：一份排到第 18 周的课表，即使总周数填了 16，
/// 第 17、18 周也不会从导航里消失——那会把真上着的课藏起来。
///
/// [WeekSet.maxWeek] 是两头的硬上限（教务系统里周次就是一个 53 位位图）。
class WeekRange {
  /// 校验起止与上下界。
  WeekRange({required this.from, required this.to})
    : assert(from >= 1, '第一周至少是第 1 周'),
      assert(to <= WeekSet.maxWeek, '最后一周不能超过 ${WeekSet.maxWeek}'),
      assert(from <= to, '第一周不能晚于最后一周');

  /// 从这份课表算出它能翻到哪几周。
  factory WeekRange.of(List<ClassSession> sessions, {TermSettings? settings}) {
    final weeks = <int>[
      for (final session in sessions) ...session.weeks.weeks,
    ];
    if (weeks.isEmpty) return WeekRange(from: 1, to: 1);
    weeks.sort();

    final dataTo = weeks.last;
    final total = settings?.totalWeeks;
    return WeekRange(
      from: weeks.first,
      // 总周数只可能把范围**往外**挪，不会把已经排着的课砍掉。
      to: total == null || total < dataTo ? dataTo : total,
    );
  }

  /// 第一周，也是往前翻的边界。
  final int from;

  /// 最后一周，也是往后翻的边界。
  final int to;

  /// 一共几周。
  int get length => to - from + 1;

  /// [week] 在不在这段范围里。
  bool contains(int week) => week >= from && week <= to;

  /// 还能不能往前翻。[week] 已经在起点时就不能了——前后各一个箭头靠它们禁用。
  bool hasPrevious(int week) => week > from;

  /// 还能不能往后翻。[week] 已经在终点时就不能了。
  bool hasNext(int week) => week < to;

  /// 打开课表时先落在哪一周。
  ///
  /// 设了「第 1 周的第一天」、且算出来的当前教学周落在这段范围里，就落在当前教学周；
  /// 其余情况一律落在 [from]——没设开学日期时不猜，算出来的周次在学期范围外时（学期
  /// 早结束了、或者还没开学）也不把使用者丢在一片空周里。
  ///
  /// [today] 为 null 表示「不知道今天是哪天」，同样落在 [from]。[weekOf] 是「某一天是
  /// 第几教学周」那个换算（见 `TermSettings.weekOf`），由调用方传进来，好让这里不依赖
  /// `DateTime.now()`——那样这个换算就没法测了。
  int weekFor(DateTime? today, int Function(DateTime date) weekOf) {
    if (today == null) return from;
    final int current;
    try {
      current = weekOf(today);
    } on StateError {
      return from; // 没设「第 1 周的第一天」。
    } on ArgumentError {
      return from; // 今天落在这个学期之外。
    }
    return contains(current) ? current : from;
  }

  @override
  String toString() => 'WeekRange(第$from周-第$to周)';

  @override
  bool operator ==(Object other) =>
      other is WeekRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}
