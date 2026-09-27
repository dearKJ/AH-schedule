# ah_schedule_core

AH-schedule 的**领域层**：纯 Dart，不依赖 Flutter。

课表的数据形状与最容易写错的那部分纯逻辑都在这里。它单独成包不是为了整齐，是为了让
「不依赖 Flutter」这条边界**由包边界强制**，而不是靠自觉——没有 Flutter，它就能被最快的
纯 Dart 单元测试反复砸，这是整个规格里唯一的重测试接缝。

术语一律用 [`CONTEXT.md`](../../CONTEXT.md) 里的词：代码、测试名、注释都照它写。

## 跑测试

```sh
cd packages/core
dart pub get
dart test
```

`dart test`，不是 `flutter test`——没有 `TestWidgetsFlutterBinding`，跑得起来本身就是
边界的证据。

## 这里的文件对应哪个领域概念

| 文件 | 领域概念 |
| --- | --- |
| `lib/src/academic_term.dart` | 学年学期（数据的隔离单位） |
| `lib/src/class_session.dart` | 上课安排（课表的最小单位） |
| `lib/src/week_set.dart` | 周次集合（周次唯一的内部表示） |
| `lib/src/period_span.dart` | 节次跨度（起始节次 + 节数，对应 `rowspan`） |
| `lib/src/session_exception.dart` | 例外：停课 / 线上教学 |
| `lib/src/venue.dart` | 地点：教室名 + 校区 |
| `lib/src/bell_schedule.dart` | 作息时间表（含内建默认值） |
| `lib/src/period_time.dart` | 一个节次的起止时刻与时段 |
| `lib/src/clock_time.dart` | 一天之内的时刻 |
| `lib/src/day_block.dart` | 上午 / 下午 / 晚上 |
| `lib/src/term_settings.dart` | 学期设置（第 1 周的第一天、总周数、作息时间表） |
| `lib/src/timetable.dart` | 课表：一个学年学期的全部安排 |
| `lib/src/week_grid.dart` | 按周展开（`expandWeek`：课表 + 教学周号 → 该周的格子） |
| `lib/src/json/timetable_json.dart` | 课表 ⇄ 带版本号的 JSON（分享 / 迁移的契约） |
| `lib/src/json/json_diagnostics.dart` | 反序列化的错误代码（`JsonIssue`）与 `JsonError` |

导入解析（字节 → 课表 + 诊断）在这一层，但单独归拢在 `lib/src/import/`：

| 文件 | 干什么 |
| --- | --- |
| `lib/src/import/timetable_importer.dart` | 入口：`importBytes` / `importText`，与结果类型 `TimetableImportResult` |
| `lib/src/import/gbk_codec.dart` | GBK 解码（自带映射表，见下） |
| `lib/src/import/gbk_table.dart` | **生成的文件**，CP936 映射表，由 `tools/generate_gbk_table.py` 烘出来 |
| `lib/src/import/html_course_table.dart` | 抠出课表那张表、按 `rowspan` 铺成逻辑网格 |
| `lib/src/import/cell_arrangements.dart` | 一格正文 → 叶子安排（课程名 + 教师 / 周次集合 + 地点） |
| `lib/src/import/class_session_builder.dart` | 叶子安排 → `ClassSession`，合并停课例外 |
| `lib/src/import/import_diagnostics.dart` | 诊断类型与代码（`ImportIssue` / `ImportDiagnostic` / `ImportSeverity`） |

`lib/src/internal_helpers.dart` 是内部小工具（列表逐元素相等、空白文本归一成 null），不对外
导出——自己写这几行是为了让这个包保持**零运行期依赖**。

## 定下来的几条形状

- **周次集合是周次唯一的内部表示。** 普通区间 / 单双周 / 断档周 / 特定周只是它不同的
  **写法**，解析后全落成同一个整数集合；模型里没有「这是单双周」这种类型。集合能反向
  生成人能读的写法（`toText()`），且整集合正好是隔周数列时写回
  `单周第5周-第15周`——编辑一条导入的安排，不该把它原来在教务系统里的写法抹掉。
- **同一门课一学期可以有多条上课安排**，一周上两次、中途换教师、换教室，各是各的一条，
  不会被合并（`Timetable.sessionsOf` 一次拿回全部）。
- **例外是信息，不是删除。** 停课 / 线上教学挂在既有的上课安排上，不改变它的周次集合
  （`ClassSession.coversWeek` 因此不看例外）；「这一周它出不出现」是展开时的事。
- **一周从周一算起**，第 N 周就是从开学那周的周一算起的连续 7 天。`ClassSession.weekday`
  用 1=星期一 … 7=星期日，与 `DateTime.weekday` 一致。
- **作息时间表有内建默认值且可改**：它一变，全部时刻随之改变。
- 数值一律在构造时校验，越界就抛 `ArgumentError`；**认不出来的写法抛 `FormatException`
  而不是静默给一个空集合**——静默失败是这套东西最怕的结果。

## 导入解析（issue #5）

把导出文件的**原始字节**变成课表加一份诊断清单。那份 `.xls` 其实是 **GBK 编码的
HTML**，所以先按 GBK 解码、再当 HTML 解析，**不需要任何 Excel 解析库**。解析规格的
权威出处是 [`docs/reference/ahpu-jwxt-export-format.md`](../../docs/reference/ahpu-jwxt-export-format.md)。

- **诊断是返回值的一部分，不是异常。** `importBytes` 只在「输入根本不是课表」（空、
  太大、没有那张表）时返回一条错误级诊断；其余情况一律返回「解出来的那部分课表 +
  一份说清哪里没解出来的清单」。`TimetableImportResult.hasUnparsableContent` 为真时
  界面该让用户确认再应用——静默失败比解析出错糟得多。
- **测试对着真实夹具跑。** `test/fixtures/` 里那份是使用者从教务系统导出的文件脱敏后
  的副本，它锁着一批编造样本锁不住的坑（模板少写 `)`、断档周用空格分隔、停课单列
  一条……）。夹具位置在**仓库根**，测试从 `packages/core` 往上找两格。
- **GBK 表是烘进来的。** `lib/src/import/gbk_table.dart` 有 7 万多字节，是生成的文件，
  不要手改；重跑用 `python tools/generate_gbk_table.py`。之所以自带一张表而不是引
  `charset` / `fast_gbk`，是因为这个包要守住**零运行期依赖**——那是上面那条边界检查
  赖以成立的前提。

## 「不依赖 Flutter」是怎么被强制的

三条检查都在 `test/no_flutter_dependency_test.dart` 里，`dart test` 时就跑：

1. 这个包的源码（`lib/` 与 `test/`）不 import `package:flutter` / `dart:ui`；
2. `pubspec.yaml` 里没有 Flutter 依赖；
3. **解析后的依赖图里没有 `flutter`**——这条最硬，它证明的不是「我没写 import」，
   而是「这个包根本拿不到 Flutter」。

第 1 条做过反向验证：临时往 `lib/` 里塞一个 `import 'package:flutter/…'`，
这条检查会红。

## 按周展开（issue #6）

`课表 + 教学周号 → 该周的格子`，规格里 `core` 三个纯函数入口的第二个。这是 ADR-0001
点名过的那段逻辑，也是整个 App 最容易写错的一段——消费它的是周网格、「今日课程」与桌面
小组件，**不是存储本身**（展开发生在读取时，不存每周快照）。

```dart
final grid = expandWeek(timetable, 7);          // 第 7 教学周
final cell = grid.at(DateTime.monday, 3);       // 星期一第三节
cell.entries;      // 这一周这一格要画的全部安排（冲突时两条都在）
cell.hasConflict;  // 同一格 + 同一周 + 两条安排
```

- **7 天 × 每一天的节次数**。节次数来自作息时间表（默认 12），不写死；节次号也不当
  下标用——表里节次号不连续（如只有第 1、3、5、7 节）时照样按**节次号**定位。
  `WeekGrid.at` 的星期或节次越界**抛 `ArgumentError` 而不是返回空格子**——画错了不
  报错会一路画到底。
- **连堂占满它的节次跨度**：一条 `PeriodSpan(3, 3)` 的安排在星期一第 3、4、5 节各出现
  一格，每格带的是同一条安排（不是被切碎的某一节）。跨度越过当天最后一节时只铺得进的
  那几格，**不溢出到相邻那天**。
- **例外在展开时生效**，安排本身原样不动（ADR-0001）：停课那一周这条不出现、其余周照常；
  线上教学只改**地点那一项**（`GridEntry.venue` 变成 `Venue.online`，教室名仍留在
  `entry.session.venue.room` 里）；两者挂在同一条上时**停课说了算**。
- **「教室那条」与「线上那条」并成一条**。导入解析把线上教学那一行单独解成一条安排，
  所以一门课改线上时格子里会同时收到两条。周次互斥时它们落在不同周、本来就不会碰面；
  周次一旦重叠，并成**线上那一条**（出现照教室那条，地点照线上那条），否则画出来是
  「同一门课并排两条还标红」的假冲突。判不准的一律不并——两条都留着让人眼看。
  ⚠️ 线上教学的写法在真实样本里**一次都没出现过**（`docs/reference/ahpu-jwxt-export-format.md`
  第六节），这一条的语义是按 `CONTEXT.md` 的定义推的，**没有样本验证过**。
- **冲突在这一层判定，UI 只负责画**：`hasConflict` 为真 = 同一格 + 同一周 + 两条安排，
  两条都留着，**不自动取舍**。同一格里**周次错开**的多门课不是冲突——在展开了的某一周里
  它们本来就不会同时出现。停课被挡在前面，所以不会有「其中一条这周其实不上」的假冲突。
- **地点逐周可能不同**，所以它在 `GridEntry` 上而不只在 `ClassSession` 上。
- **表外的节次铺不进网格，也不出声**。导入解析已经把「越过最后一节」挡在门外并报了
  错误级诊断（`ClassSessionBuilder`），所以正常数据到不了这一步；只有使用者把作息时间
  表改短之后才会出现，那是学期设置（issue #12）该提示的事。这里宁可不铺，也不折回第 1
  节或铺到第二天去。

## 课表 JSON（issue #7）

`课表 ⇄ 带版本号的 JSON`，规格里 `core` 三个纯函数入口的第三个。它是**往来于设备与
同学之间的唯一契约**（ADR-0002：没有服务器，换手机靠它，分享给同学也靠它）。文件
格式的权威出处是 [`docs/reference/timetable-json-format.md`](../../docs/reference/timetable-json-format.md)。

```dart
final text = TimetableJson.encode(timetable);       // 课表 → JSON 文本
final result = TimetableJson.decode(text);          // JSON 文本 → 课表
final fromFile = TimetableJson.decodeBytes(bytes);  // 文件字节 → 课表

result.isSuccess;          // 解出来了吗
result.timetable;          // 成功时是课表，失败时是 null
result.error;              // 失败时是一条 JsonError：code + 说明 + 坏在哪一处
result.error?.path;        // 'sessions[3].weeks[0]'
```

- **导出里没有学号 / 姓名 / 班级，因为它们没有位置可写**：`Timetable` 里没有装它们的
  字段，编码器也只认得那几个键。这条不是靠「记得别写进去」，是靠两条测试盯着
  （`test/json/export_privacy_test.dart`）：一条拿真实夹具（它的原始字节里**真的**有
  这三样）导出后正面断言不含，一条递归收集导出产物的**全部键**跟白名单比对——加了新
  字段就会红。两条都做过反向验证：往编码器里塞一个 `studentId`，两条一起红。
- **反序列化不抛异常。** 版本号缺失 / 不认识、缺字段、坏字段、字节不是 UTF-8，一律落成
  `TimetableDecodeResult.error` 里的一条 `JsonError`，**带着它在文件里的位置**
  （`sessions[3].weeks[0]`）——没有位置那句话使用者无从下手。这条测试里有一组坏输入
  轮着过一遍，断言没有一种会抛。
- **路径不靠调用方拼对。** 取值走一个「JSON 对象 + 它在文件里的位置」的小类型，子路径
  自己从父节点长出来；领域模型的 `ArgumentError.value(x, '字段名', …)` 带着字段名，用它
  把路径补到**具体那一项**上（`settings` → `settings.firstDayOfWeek1`）。于是「报错说清
  是哪一处」是结构保证的，不是靠每处调用都记得把字符串拼对。
- **错误只有一条，不是一列**：这份东西是一份整体契约，结构一坏就没什么可解的了，
  「哪一处最先坏」就是那条拦路的错误。与导入诊断刻意不同——导入是逐格解，一格坏不
  影响别格，所以那边是一列。
- **可选字段与必填字段分得清**：教师、校区、第 1 周的第一天、总周数不在（或写成
  `null`）都算「没有」；课程名、星期、节次、周次、地点、作息时间表不在就是「缺字段」。
- **取值校验不在这里抄一份**，交给领域模型自己的构造校验（星期 1..7、周次 1..53、
  第 1 周第一天必须是周一……），`ArgumentError` 翻成一条坏字段错误，消息原样带着。
- **例外的类型名认不出来就报错**，不静默丢掉——丢掉一条「这周停课」等于悄悄多上一节课。
  时段名与例外类型名**写死在对照表里，不跟着 Dart 枚举名走**：文件格式是契约，重命名
  一个枚举成员不该让所有 v1 文件读不进来。

## 不在这里的东西

数据形状（issue #3）、导入解析（issue #5）、按周展开（issue #6）、课表 JSON 序列化
（issue #7）都已经落进来了。剩下这个有票，但落在别处：

- drift schema 与仓储：issue #8（在 `data/`，不在这里）

课程配色**不在 `core`**：规格只说「按课程稳定分配、不入库、不上云」，那是周网格视图
（issue #10）自己的事——展开结果里的 `GridEntry.courseName` 就是它的着色键。

## 一个词汇缺口

`CONTEXT.md` 里没有单列「星期」这个词条，但上课安排必须知道自己是星期几——规格里
「星期栏吸顶」「星期与节次自动带出」这些说法都默认它有。代码里叫 `ClassSession.weekday`
（1=星期一）。这是术语表的一个缺口，记在这里，等 `/domain-modeling` 收。
