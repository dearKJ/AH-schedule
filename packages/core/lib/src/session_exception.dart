import 'internal_helpers.dart';
import 'week_set.dart';

/// 挂在一条上课安排上的单周例外：**哪一教学周 + 哪种变化**。
///
/// 例外是**信息，不是删除**——它不改变安排本身（周次集合原样不动），展开时由它
/// 决定这一周怎么办。这样「这周停课」不会把规则拆成一堆快照（ADR-0001）。
sealed class SessionException {
  const SessionException._(this.week);

  /// 例外落在哪个教学周。
  final int week;

  static int _checkedWeek(int week) {
    if (week < 1 || week > WeekSet.maxWeek) {
      throw ArgumentError.value(
        week,
        'week',
        '教学周必须在 1..${WeekSet.maxWeek} 之间',
      );
    }
    return week;
  }

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is SessionException &&
      other.week == week;

  @override
  int get hashCode => Object.hash(runtimeType, week);

  @override
  String toString() => '$runtimeType(第$week周)';
}

/// 停课：这一教学周的这次课不上。教务系统写作 `(2,停课(主校区))`。
final class Cancellation extends SessionException {
  Cancellation(int week) : super._(SessionException._checkedWeek(week));
}

/// 线上教学：这一教学周的这次课改在线上。教务系统写作 `(第14周,线上教学(校区))`。
///
/// 它改的是**地点那一项**，不影响这次课出不出现——与 [Cancellation] 的区别正在这里。
final class OnlineTeaching extends SessionException {
  OnlineTeaching(int week, {String? campus})
    : campus = trimmedOrNull(campus),
      super._(SessionException._checkedWeek(week));

  /// 线上教学写在校区那一格的校区。没有时是 null。
  final String? campus;

  @override
  bool operator ==(Object other) =>
      super == other && other is OnlineTeaching && other.campus == campus;

  @override
  int get hashCode => Object.hash(runtimeType, week, campus);

  @override
  String toString() =>
      'OnlineTeaching(第$week周${campus == null ? '' : '($campus)'})';
}
