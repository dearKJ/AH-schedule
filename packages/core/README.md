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

## 不在这里的东西

这一票（issue #3）只定**数据形状**；导入解析（issue #5）已经落进来了。下面这些各自
有票，也都落在 `core`：

- 按周展开（课表 + 教学周号 → 格子）：issue #6
- 课表 JSON 序列化（带版本号）：issue #7
- drift schema 与仓储：issue #8（在 `data/`，不在这里）

## 一个词汇缺口

`CONTEXT.md` 里没有单列「星期」这个词条，但上课安排必须知道自己是星期几——规格里
「星期栏吸顶」「星期与节次自动带出」这些说法都默认它有。代码里叫 `ClassSession.weekday`
（1=星期一）。这是术语表的一个缺口，记在这里，等 `/domain-modeling` 收。
