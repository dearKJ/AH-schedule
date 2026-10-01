/// 周网格与详情里那几行字、以及「第 N 周是哪七天」，**只有这一份写法**。
///
/// 同一句话在网格里、在详情单里、在周次导航里各写一遍，迟早会两处对不上（详情里写
/// 「08:00」、网格里写「8:00」）。这里只管把领域层的东西写成字、把周号换算成日期，
/// 不做判断。
library;

import 'package:ah_schedule_core/ah_schedule_core.dart';

/// 周次的展示写法。
///
/// **不能一律在后头接一个「周」字**：[WeekSet.toText] 有两种形态——普通区间那种不带
/// 后缀（`1-8 10`），单双周那种本身就以「周」结尾（`单周第5周-第15周`）。一律接就会写
/// 出「单周第5周-第15周周」。
String weeksText(WeekSet weeks) {
  final text = weeks.toText();
  return text.endsWith('周') ? text : '$text周';
}

/// 第 [week] 周是哪七天，周一到周日。
///
/// 「第 N 周 = 从第 1 周的第一天算起的连续 7 天」——与 `TermSettings.weekOf` 是同一个
/// 换算，只是反着来。没设「第 1 周的第一天」[firstDayOfWeek1] 为 null 时返回 null：
/// **不猜一个日期出来**，那天柱子上就空着。
List<DateTime>? weekDates(DateTime? firstDayOfWeek1, int week) {
  if (firstDayOfWeek1 == null) return null;
  final monday = firstDayOfWeek1.add(Duration(days: (week - 1) * 7));
  return [for (var day = 0; day < 7; day++) monday.add(Duration(days: day))];
}

/// 一周的日期范围，如 `9月7日-9月13日`。没有日期时返回 null。
String? weekDateRangeText(DateTime? firstDayOfWeek1, int week) {
  final dates = weekDates(firstDayOfWeek1, week);
  if (dates == null) return null;
  final monday = dates.first;
  final sunday = dates.last;
  return '${_monthDay(monday)}-${_monthDay(sunday)}';
}

String _monthDay(DateTime date) => '${date.month}月${date.day}日';

/// 这条安排这几节在一天里的具体时刻：第一节的上课时刻 → 最后一节的下课时刻。
///
/// 连堂写成一段（第三节 09:55 → 第五节 12:20 就是 `09:55-12:20`），不逐节列——规格要的
/// 是「它对应的具体时刻」，一段区间正是这个意思。
///
/// 作息时间表里查不到某一节时返回 null（**不猜**）：那说明课表里有一节的时刻是空的，
/// 与其编一个，不如让界面把「作息时间表里没有这一节」说出来。
String? timeRangeText(ClassSession session, BellSchedule schedule) {
  final times = [
    for (final period in session.periods.periods) schedule.forPeriod(period),
  ];
  if (times.any((time) => time == null)) return null;
  return '${times.first!.start.toText()}-${times.last!.end.toText()}';
}

/// 例外的展示写法。
String exceptionText(SessionException exception) => switch (exception) {
  Cancellation(:final week) => '第$week周停课',
  OnlineTeaching(:final week) => '第$week周线上教学',
};
