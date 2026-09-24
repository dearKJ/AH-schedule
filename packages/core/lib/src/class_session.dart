import 'internal_helpers.dart';
import 'period_span.dart';
import 'session_exception.dart';
import 'venue.dart';
import 'week_set.dart';

/// 上课安排——课表的最小单位。
///
/// 一条「某门课 × 某位教师 × 某段教学周 × 某段连续节次 × 某个地点」的记录。
/// **同一门课一学期可以有多条**：一周上两次、中途换教师、换教室，各自都是一条
/// 独立的安排，不会被合并。用「课程」当单位会把整个数据模型做错。
///
/// 它是导入的产物，也是例外（停课 / 线上教学）挂载的对象。
class ClassSession {
  /// 校验课程名、星期与周次集合；教师与校区的空白归一成 null。
  factory ClassSession({
    required String courseName,
    required int weekday,
    required PeriodSpan periods,
    required WeekSet weeks,
    required Venue venue,
    String? teacher,
    List<SessionException> exceptions = const [],
  }) {
    final trimmedName = courseName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(courseName, 'courseName', '课程名称不能是空白');
    }
    if (weekday < 1 || weekday > 7) {
      throw ArgumentError.value(weekday, 'weekday', '星期必须在 1..7 之间（1 = 星期一）');
    }
    if (weeks.isEmpty) {
      throw ArgumentError.value(weeks, 'weeks', '周次集合不能是空的——那会是一条永远不出现的安排');
    }
    return ClassSession._(
      courseName: trimmedName,
      teacher: trimmedOrNull(teacher),
      weekday: weekday,
      periods: periods,
      weeks: weeks,
      venue: venue,
      exceptions: List.unmodifiable(exceptions),
    );
  }

  const ClassSession._({
    required this.courseName,
    required this.teacher,
    required this.weekday,
    required this.periods,
    required this.weeks,
    required this.venue,
    required this.exceptions,
  });

  /// 课程名称（教学内容本身），如 `高等数学(一)`。
  final String courseName;

  /// 教师。没有时是 null。
  final String? teacher;

  /// 星期几：1 = 星期一 … 7 = 星期日（与 `DateTime.weekday` 一致）。
  final int weekday;

  /// 这条安排占哪些节次。连堂就是节数大于 1 的跨度。
  final PeriodSpan periods;

  /// 这条安排实际生效的那组教学周。
  final WeekSet weeks;

  /// 上课地点：教室名 + 校区。
  final Venue venue;

  /// 挂在这条安排上的例外（停课 / 线上教学）。
  final List<SessionException> exceptions;

  /// 这条安排的**周次集合**是否覆盖这一教学周（**不看例外**：停课例外不改周次集合，
  /// 是否出现由展开时按例外决定）。
  bool coversWeek(int week) => weeks.contains(week);

  @override
  String toString() =>
      '$courseName${teacher == null ? '' : ' ($teacher)'} '
      '${_weekdayLabel(weekday)} ${periods.toString()} ${weeks.toText()}周 @${venue.toText()}';

  @override
  bool operator ==(Object other) =>
      other is ClassSession &&
      other.courseName == courseName &&
      other.teacher == teacher &&
      other.weekday == weekday &&
      other.periods == periods &&
      other.weeks == weeks &&
      other.venue == venue &&
      listEquals(other.exceptions, exceptions);

  @override
  int get hashCode => Object.hash(
    courseName,
    teacher,
    weekday,
    periods,
    weeks,
    venue,
    Object.hashAll(exceptions),
  );
}

const List<String> _weekdayLabels = [
  '星期一',
  '星期二',
  '星期三',
  '星期四',
  '星期五',
  '星期六',
  '星期日',
];

String _weekdayLabel(int weekday) => _weekdayLabels[weekday - 1];
