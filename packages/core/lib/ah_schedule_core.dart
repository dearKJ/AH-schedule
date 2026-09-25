/// AH-schedule 的领域层：纯 Dart，**不依赖 Flutter**。
///
/// 这里放的是课表的数据形状与最容易写错的纯逻辑（周次集合、节次跨度、作息时间表、
/// 教务系统导出文件的导入解析）。
/// 「不依赖 Flutter」不是自觉，是包边界强制的——这个包的 pubspec 里没有任何运行期
/// 依赖，测试用 `dart test` 跑（不是 `flutter test`），并且有一条检查在盯着它，
/// 见 `test/no_flutter_dependency_test.dart`。
library;

export 'src/academic_term.dart';
export 'src/bell_schedule.dart';
export 'src/class_session.dart';
export 'src/clock_time.dart';
export 'src/day_block.dart';
export 'src/import/cell_arrangements.dart';
export 'src/import/class_session_builder.dart';
export 'src/import/gbk_codec.dart';
export 'src/import/html_course_table.dart';
export 'src/import/import_diagnostics.dart';
export 'src/import/timetable_importer.dart';
export 'src/period_span.dart';
export 'src/period_time.dart';
export 'src/session_exception.dart';
export 'src/term_settings.dart';
export 'src/timetable.dart';
export 'src/venue.dart';
export 'src/week_set.dart';
