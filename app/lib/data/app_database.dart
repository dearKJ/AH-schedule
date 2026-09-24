import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// 学年学期表——课表的隔离单位，切换学年学期即切换整张课表。
///
/// **这一票（issue #4）只放这一张表。** 走路骨架要证明的是「数据层存下一个学年学期、
/// 界面把它读出来显示」，所以只需要一处能真正落盘的东西。上课安排 / 例外 / 学期设置
/// 三张表属于 issue #8，等它来加。
///
/// `id` 用领域层的 `AcademicTerm.id`（规范化的 `2026-2027-1`），数据层不另造一套标识。
@DataClassName('AcademicTermRow')
class AcademicTerms extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 数据类命名为 `AcademicTermRow`（默认会叫 `AcademicTerm`）是有意的：领域层已经有一个
/// `AcademicTerm`，同一个文件里 import 两者的地方若撞名，就会分不清手上这条是**领域对象**
/// 还是**数据库行**——而这一层存在的全部意义就是分清这两者。
@DriftDatabase(tables: [AcademicTerms])
class AppDatabase extends _$AppDatabase {
  /// 打开一个放在文件里的数据库。
  ///
  /// `createInBackground` 把 SQLite 的活儿挪到单独的 isolate，别卡住界面线程。
  AppDatabase.openFile(File file)
    : super(NativeDatabase.createInBackground(file));

  @override
  int get schemaVersion => 1;
}

/// 数据库文件落在应用文档目录下——「存在手机本地、没有服务器」的落点（ADR-0002）。
///
/// 文件名不用 App 名，用 `ah_schedule`：它在设备上是这个 App 的私有目录，写清楚是给
/// 以后要拿 `adb` 翻它的人看的。
Future<AppDatabase> openAppDatabase() async {
  final directory = await getApplicationDocumentsDirectory();
  return AppDatabase.openFile(
    File(p.join(directory.path, 'ah_schedule.sqlite')),
  );
}
