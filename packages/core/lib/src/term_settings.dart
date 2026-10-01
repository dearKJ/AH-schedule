import 'bell_schedule.dart';
import 'week_set.dart';

/// 学期设置：第 1 周的第一天、学期总周数、作息时间表。
///
/// 这三样都是**运行期数据**——教务系统导出的文件里既没有学期起止日期，也没有
/// 学期总周数，只能由使用者自己填。前两项都允许留空。
class TermSettings {
  /// 校验总周数与「第 1 周的第一天」；日期只留到天。
  factory TermSettings({
    DateTime? firstDayOfWeek1,
    int? totalWeeks,
    BellSchedule? bellSchedule,
  }) {
    if (totalWeeks != null &&
        (totalWeeks < 1 || totalWeeks > WeekSet.maxWeek)) {
      throw ArgumentError.value(
        totalWeeks,
        'totalWeeks',
        '学期总周数必须在 1..${WeekSet.maxWeek} 之间',
      );
    }
    final firstDay = firstDayOfWeek1 == null ? null : dateOnly(firstDayOfWeek1);
    if (firstDay != null && firstDay.weekday != DateTime.monday) {
      throw ArgumentError.value(
        firstDayOfWeek1,
        'firstDayOfWeek1',
        '第 1 周的第一天必须是周一——一周从周一算起',
      );
    }
    return TermSettings._(
      firstDay,
      totalWeeks,
      bellSchedule ?? BellSchedule.ahpuDefault,
    );
  }

  const TermSettings._(
    this.firstDayOfWeek1,
    this.totalWeeks,
    this.bellSchedule,
  );

  /// 第 1 周的第一天。一周从**周一**算起，所以它必定是周一；没有时是 null。
  final DateTime? firstDayOfWeek1;

  /// 学期总周数。不写死：留空即以数据实际范围为准。
  final int? totalWeeks;

  /// 作息时间表。默认是内建的那张，可改。
  final BellSchedule bellSchedule;

  /// 抹掉时分秒，只留日期。
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// 把任意一天归到它所在那一周的周一。
  static DateTime mondayOf(DateTime date) {
    final day = dateOnly(date);
    return DateTime(day.year, day.month, day.day - (day.weekday - 1));
  }

  /// 某一天落在第几教学周。
  ///
  /// 一周从**周一**算起，第 N 周就是从「第 1 周的第一天」那个周一算起的连续 7 天——
  /// 星期栏里今天那一列高亮、以及「跳回当前教学周」都靠它（规格「时间规则」）。
  ///
  /// 一天里的时分秒不参与计算，只按日期算。
  ///
  /// **没设「第 1 周的第一天」时抛 [StateError]**——「没设」与「第 0 周」是两件事，
  /// 混成同一个返回值就等于替使用者猜了一个开学日期。开学之前、以及算出来超出
  /// `1..53` 的那些天抛 [ArgumentError]：和 [WeekGrid] 收周号时一样，周次认错比报错
  /// 糟得多。
  int weekOf(DateTime date) {
    final firstDay = firstDayOfWeek1;
    if (firstDay == null) {
      throw StateError('还没设「第 1 周的第一天」，算不出 $date 是第几教学周');
    }
    final days = dateOnly(date).difference(firstDay).inDays;
    // 用 floorDiv 而不是 `~/`：开学之前那些天算出来是负数，`~/` 向零取整会把
    // 「开学前一周」和「开学后一周」算成同一周。
    final week = _floorDiv(days, 7) + 1;
    if (week < 1 || week > WeekSet.maxWeek) {
      throw ArgumentError.value(
        date,
        'date',
        '这一天落在第 $week 教学周，超出 1..${WeekSet.maxWeek} 的范围',
      );
    }
    return week;
  }

  /// 向下取整的整除：`_floorDiv(-1, 7) == -1`，而 `-1 ~/ 7 == 0`。
  static int _floorDiv(int numerator, int denominator) =>
      (numerator - (numerator % denominator + denominator) % denominator) ~/
      denominator;

  @override
  String toString() =>
      'TermSettings(${firstDayOfWeek1 ?? '未设第 1 周'}, '
      '${totalWeeks ?? '未设总周数'} 周, ${bellSchedule.name})';

  @override
  bool operator ==(Object other) =>
      other is TermSettings &&
      other.firstDayOfWeek1 == firstDayOfWeek1 &&
      other.totalWeeks == totalWeeks &&
      other.bellSchedule == bellSchedule;

  @override
  int get hashCode => Object.hash(firstDayOfWeek1, totalWeeks, bellSchedule);
}
