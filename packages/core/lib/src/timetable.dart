import 'academic_term.dart';
import 'class_session.dart';
import 'internal_helpers.dart';
import 'term_settings.dart';

/// 课表：一个学年学期的全部上课安排 + 这份课表的学期设置。
///
/// 一个学年学期一张课表，切换学年学期即切换整张课表。
///
/// 存储以**规则**为单位（[ClassSession] 就是规则），不存每周快照——ADR-0001。
/// 把课表展开成「某个教学周里每一天每一节上有什么」是读取时的事，不属于这里。
class Timetable {
  factory Timetable({
    required AcademicTerm term,
    List<ClassSession> sessions = const [],
    TermSettings? settings,
  }) {
    return Timetable._(
      term: term,
      sessions: List.unmodifiable(sessions),
      settings: settings ?? TermSettings(),
    );
  }

  const Timetable._({
    required this.term,
    required this.sessions,
    required this.settings,
  });

  /// 这份课表属于哪个学年学期。
  final AcademicTerm term;

  /// 全部上课安排，保持传入顺序（导入时是解析顺序，手动录入时是录入顺序）。
  ///
  /// **同一门课的多条安排都在这里，各是各的一条**，不会被合并。
  final List<ClassSession> sessions;

  /// 学期设置：第 1 周的第一天、学期总周数、作息时间表。
  final TermSettings settings;

  /// 课表里出现过的课程名。一门课对应一个颜色，用它来收集。
  Set<String> get courseNames =>
      sessions.map((session) => session.courseName).toSet();

  /// 某个课程名下的全部上课安排。一门课一周上两次，这里就有两条。
  List<ClassSession> sessionsOf(String courseName) =>
      sessions.where((session) => session.courseName == courseName).toList();

  @override
  String toString() => 'Timetable(${term.label}, ${sessions.length} 条安排)';

  @override
  bool operator ==(Object other) =>
      other is Timetable &&
      other.term == term &&
      other.settings == settings &&
      listEquals(other.sessions, sessions);

  @override
  int get hashCode => Object.hash(term, settings, Object.hashAll(sessions));
}
