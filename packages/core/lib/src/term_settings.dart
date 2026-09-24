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
