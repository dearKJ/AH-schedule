import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// 学年学期表——课表的隔离单位，切换学年学期即切换整张课表。
///
/// `id` 用领域层的 `AcademicTerm.id`（规范化的 `2026-2027-1`），数据层不另造一套标识。
@DataClassName('AcademicTermRow')
class AcademicTerms extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 上课安排表——课表的最小单位。
///
/// 一行 = 领域层的一条 `ClassSession`：某门课 × 某位教师 × 某段教学周 × 某段连续节次
/// × 某个地点。**同一门课一学期可以有多行**（一周上两次、换教师、换教室），落库不会
/// 被合并——这一层不做「同一门课合并成一条」这种判断，那是业务规则，不归它管。
@DataClassName('ClassSessionRow')
class ClassSessions extends Table {
  /// 自增主键。
  ///
  /// 领域层里一条安排没有标识——它是**值**，靠内容区分。需要标识的是**例外**：它得
  /// 指回自己挂在哪条安排上。所以这个 id 是数据层为了挂载关系造出来的，领域层看不见它。
  IntColumn get id => integer().autoIncrement()();

  /// 属于哪个学年学期。课表按它隔离。
  ///
  /// 外键指向学年学期，并且**删学期时级联删掉它的全部安排**——这是行的归属，不是业务
  /// 规则。级联要真的生效，得靠 `PRAGMA foreign_keys`，那个在 [AppDatabase.migration]
  /// 里打开。
  TextColumn get termId =>
      text().references(AcademicTerms, #id, onDelete: KeyAction.cascade)();

  /// 这条安排在它那个学期课表里的次序，从 0 开始。
  ///
  /// 领域层说「保持传入顺序」（导入时是解析顺序，手动录入时是录入顺序），SQL 本身不保证
  /// 任何行序，所以次序得自己存。
  IntColumn get position => integer()();

  TextColumn get courseName => text()();

  /// 没有教师时是 NULL。
  TextColumn get teacher => text().nullable()();

  /// 星期几：1 = 星期一 … 7 = 星期日。
  IntColumn get weekday => integer()();

  /// 起始节次，配 [periodLength] 一起表示连堂。
  IntColumn get periodStart => integer()();

  /// 连着的节数。
  IntColumn get periodLength => integer()();

  /// 周次集合，写成 `1,2,3,5` 这样的升序整数表。
  ///
  /// 领域层说周次**是集合、不是写法**（单双周 / 断档周只是同一组周次的写法），所以这里
  /// 存的是一组升序整数，教务系统那套写法一个字都不进库。编解码在
  /// `timetable_repository.dart`。
  TextColumn get weeks => text()();

  /// 教室名。线上教学时是「线上教学」——领域层把它当作教室名那一格的内容。
  TextColumn get room => text()();

  /// 校区。没有时是 NULL。
  TextColumn get campus => text().nullable()();
}

/// 例外表——挂在某条上课安排上的「哪一教学周 + 哪种变化」。
///
/// 例外是**信息，不是删除**（ADR-0001）：落在这里的停课不改那条安排的周次集合，展开时
/// 由它决定这一周怎么办。
@DataClassName('SessionExceptionRow')
class SessionExceptions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 挂在哪条安排上。安排一没，它的例外就没地方挂了，级联一起走。
  IntColumn get sessionId =>
      integer().references(ClassSessions, #id, onDelete: KeyAction.cascade)();

  /// 哪一种变化：停课 / 线上教学，写成 `cancellation` / `onlineTeaching`。
  ///
  /// 认字符串是这一层唯一几处「不绑 Dart 标识符」的地方——重命名一个类不该让库里已有的
  /// 行读不出来。编解码在 `timetable_repository.dart`。
  TextColumn get kind => text()();

  /// 例外落在哪个教学周。
  IntColumn get week => integer()();

  /// 线上教学写在校区那一格的校区；停课例外没有这一项，是 NULL。
  TextColumn get campus => text().nullable()();

  /// 同一条安排上多个例外的次序（一条安排可以挂多个例外）。
  IntColumn get position => integer()();
}

/// 学期设置表——一个学年学期一行：第 1 周的第一天、学期总周数、作息时间表。
///
/// 三样都是**运行期数据**：教务系统导出的文件里既没有学期起止日期也没有总周数，只能由
/// 使用者自己填；作息时间表由 App 本地维护、用户可改。
///
/// 作息时间表是一整个值对象（名字 + 一串节次），读写都是整体，没有「查某一节」的需求，
/// 所以它落在 [bellScheduleName] / [bellPeriods] 两列里，不为它再开一张表。节次那一列
/// 是一段 JSON 数组，编解码在 `timetable_repository.dart`。
@DataClassName('TermSettingsRow')
class TermSettingsTable extends Table {
  @override
  String get tableName => 'term_settings';

  /// 这份设置属于哪个学年学期。一个学期只有一份设置，所以它本身就是主键。
  TextColumn get termId =>
      text().references(AcademicTerms, #id, onDelete: KeyAction.cascade)();

  /// 第 1 周的第一天（必定是周一）。没设时是 NULL。
  DateTimeColumn get firstDayOfWeek1 => dateTime().nullable()();

  /// 学期总周数。没设时是 NULL——留空即以数据实际范围为准。
  IntColumn get totalWeeks => integer().nullable()();

  TextColumn get bellScheduleName => text()();

  /// 作息时间表的节次，一段 JSON 数组。
  TextColumn get bellPeriods => text()();

  @override
  Set<Column> get primaryKey => {termId};
}

/// 数据类命名为 `AcademicTermRow`（默认会叫 `AcademicTerm`）是有意的：领域层已经有一个
/// `AcademicTerm`，同一个文件里 import 两者的地方若撞名，就会分不清手上这条是**领域对象**
/// 还是**数据库行**——而这一层存在的全部意义就是分清这两者。另外三张表同理。
@DriftDatabase(
  tables: [AcademicTerms, TermSettingsTable, ClassSessions, SessionExceptions],
)
class AppDatabase extends _$AppDatabase {
  /// 打开一个放在文件里的数据库。
  ///
  /// `createInBackground` 把 SQLite 的活儿挪到单独的 isolate，别卡住界面线程。
  AppDatabase.openFile(File file)
    : super(NativeDatabase.createInBackground(file));

  /// 一个**用完就没**的内存库，给测试用。
  ///
  /// 测试要的是「真 SQLite + 空库」：拿假对象去替数据库，级联、主键冲突这些真正会咬人
  /// 的行为就测不到了。
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      // v1 是走路骨架（issue #4）：库里只有学年学期一张表，装过那一版 App 的手机上就是
      // 这个形状。课表的三张表是 v2 加的（issue #8）——**补表，不动行**：原来存着的
      // 学年学期原样留着，不会因为升一次版本就没了。
      //
      // 建表次序不能乱：例外指着安排，安排与学期设置指着学年学期。
      if (from < 2) {
        await migrator.createTable(termSettingsTable);
        await migrator.createTable(classSessions);
        await migrator.createTable(sessionExceptions);
      }
    },
    /// 每次打开数据库时，先打开外键约束。
    ///
    /// **SQLite 默认不认外键**：`references()` 声明了也只等于一句注释——级联不会发生，
    /// 孤儿行照样写得进去。打开这个开关，表结构里写的归属关系才真的成立：删一条安排，
    /// 挂在它上面的例外跟着走。
    ///
    /// 放在这里而不是各个构造函数的 `setup:` 里，是因为它必须**对每一条连接**都生效
    /// （文件库、内存库、以及 `createInBackground` 起的那条后台 isolate）。
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
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
