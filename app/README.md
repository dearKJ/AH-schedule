# AH-schedule 的 App

课表 App 的 Flutter 工程。**只面向 Android**（Android 8.0 / API 26 起）——不写任何
iOS 配置，`ios/` 是 `flutter create` 留下的脚手架，冻结着别碰。理由见
[ADR-0003](../docs/adr/0003-flutter-android-only-v0-1.md)。

领域层不在这个工程里，它在 [`packages/core`](../packages/core)——那条「core 不许
import Flutter」的边界，在 App 这边也有检查盯着（见下）。

## 三层在哪

| 层 | 位置 | 是什么 |
| --- | --- | --- |
| 领域层 | `../packages/core`（path 依赖） | 纯 Dart 的数据形状与纯逻辑。**不依赖 Flutter** |
| 数据层 | `lib/data/` | drift 数据库与仓储，只做「领域对象 ⇄ 数据库行」的映射，不加业务规则 |
| 界面层 | `lib/ui/` | Flutter 界面。只把领域层算好的东西画出来 |

`lib/main.dart`（入口）与 `lib/routing/`（go_router 路由表）是把三层接起来的线。
除此之外 `lib/` 下不该有别的目录——这条是 `test/domain_boundary_test.dart` 检查的。

## 跑起来

```sh
cd app
flutter pub get
dart run build_runner build   # 改了 lib/data/app_database.dart 之后要跑，生成 .g.dart
flutter run -d <设备>
```

数据库是设备上的一个 SQLite 文件（`app_flutter/ah_schedule.sqlite`，在应用私有目录里），
不上云、不需要服务器——ADR-0002。

## 「core 不许 import Flutter」在 App 这边怎么被强制

`flutter test` 会跑 [`test/domain_boundary_test.dart`](test/domain_boundary_test.dart)，
一共六条。`packages/core` 自己那几条只证明了「那个包单独存在时拿不到 Flutter」；App 把
core 接进来之后，边界还有三种被悄悄破坏的方式，对应下面三条：

1. **core 不再是 path 依赖** —— 换成 hosted / git 版本，App 用的就不是本仓库这一份，
   改 core 的源码不再影响 App。
2. **绕过公开入口** —— `import 'package:ah_schedule_core/src/…'` 会把 core 的内部实现
   变成 App 的编译依赖。
3. **App 里长出第二个领域层** —— `lib/core/` 之类的目录一出现，领域逻辑就有了两个出处，
   那条最快的测试接缝也就不再是唯一入口。

余下三条顺带钉住三层目录结构本身，并确认 core 解析后的依赖图里没有 `flutter`。

> **不要把这个仓库改成 Dart pub workspace。** workspace 会把所有包的依赖解到根目录的
> 一份 `package_config.json` 里，core 的 `dart test` 读到的就是含有 Flutter 的那一份，
> 它自己的边界检查会红——那条检查正是边界本身。

## 这一票做到哪

界面还是**走路骨架**（issue #4）：跑得起来，三层真的接上了——界面上的学年学期是从数据库
读出来、也真的写回数据库的。

数据层现在存得下**整张课表**（issue #8）：四张表——学年学期、学期设置、上课安排、例外——
与领域层的形状一一对应；`TimetableRepository` 只做「领域对象 ⇄ 数据库行」的映射，一行业务
规则都不写（判断留给领域层，那里有最快的纯 Dart 测试盯着）。表结构在
[`lib/data/app_database.dart`](lib/data/app_database.dart)，映射在
[`lib/data/timetable_repository.dart`](lib/data/timetable_repository.dart)，往返由
`test/data/` 下那一组盯着（真 SQLite：内存库与文件库各一组，不是假的替身）。

数据库版本因此从 1 升到 2：走路骨架那一版装的库里只有学年学期一张表，升上来时会补上另外
三张（`AppDatabase.migration` 的 `onUpgrade`），原来存着的学年学期原样留着。

**导入走通了**（issue #9）：`lib/ui/import/` 下是「选文件 → 解析 → 预览 → 确认 → 整学期覆盖」
这一条路。选文件在 [`export_file.dart`](lib/ui/import/export_file.dart)（唯一碰平台的一处），
预览那一页在 [`import_preview.dart`](lib/ui/import/import_preview.dart)：说清会替换整学期、
警告手动例外会被清掉、把解不了的格子连位置与原文一起摆出来、格子可改可补，确认之后
整学期覆盖。领域层那边顺带多了一个 `ExportHeader`：从导出文件的页头读那个学年学期，只当
预览页的**默认值**用（归属仍然是使用者确认的那个）。

> **库文件的连接方式动过一次，理由写在代码里**：`AppDatabase.openFile` 用的是主 isolate
> 直连，不是 `NativeDatabase.createInBackground`。后台 isolate 那条连接在验证机上写不进库
> （`attempt to write a readonly database`），导入的东西一条都留不下；换成直连就正常。
> 机制没查清，见 issue #14。

**周网格走通了**（issue #10）：打开 App 就是整周的课表，在
[`lib/ui/week/`](lib/ui/week/) 下。

- [`week_grid_page.dart`](lib/ui/week/week_grid_page.dart)——首页脚手架：周次导航、三种
  「没得看」（没学期 / 这个学期没课 / 读库失败）分开说、AppBar 上的学期名可点开换学期。
- [`week_grid_view.dart`](lib/ui/week/week_grid_view.dart)——网格本体。**星期栏在滚动区
  之外**，这就是「吸顶」；连堂那一整块画在它起始的那一行里、高度是节数 × 一格高，所以占满
  它跨的那几格；冲突的格子上下叠着画、两条都标红。
- [`session_detail_sheet.dart`](lib/ui/week/session_detail_sheet.dart)——点一格看详情：
  课程、教师、节次、**由作息时间表算出的具体时刻**、地点、校区、周次、例外；冲突时顶部
  一条说明 + 双方都列出来，**不替使用者取舍**。
- [`course_colors.dart`](lib/ui/week/course_colors.dart)——课名 → 颜色。**自带一个写死
  常数的散列**，不用 `String.hashCode`（Dart 不保证它跨进程稳定，「重启后颜色不变」会失守）。
  由 `test/ui/course_colors_test.dart` 盯着。
- [`session_text.dart`](lib/ui/week/session_text.dart)——周次的写法、周号 → 那七天的日期、
  节次 → 具体时刻，都只有这一份。

原来的「走路骨架」首页（学年学期列表）并进了 AppBar 上那张 sheet
（[`term_sheet.dart`](lib/ui/week/term_sheet.dart)）：一屏只能有一张课表，课表才是首页。

领域层这一票多了两处**纯逻辑**，都在 `packages/core`、都有测试：

- `TermSettings.weekOf(某一天)` → 第几教学周。没设「第 1 周的第一天」时**抛错不猜**。
- `WeekRange.of(安排们, settings:)` → 周次导航能翻到哪儿。**范围跟着数据走**，总周数只把
  范围往外挪，不会为了迁就它把已经排着的课砍掉。

> **今天高亮与「回到本周」在 #12 之前是「说不出来」的状态**：两者都要靠「第 1 周的第一天」，
> 而填它的界面属于 issue #12。没填时网格照画、只是不高亮今天、点「回到本周」会明说算不出
> 来——**不猜一个开学日期**，那样会在使用者不知情的时候高亮错一列。

手动增删改（#11）、学期设置界面（#12）、导出 / 导入分享文件（#13）还没开始。

## 一个环境坑

`package:sqlite3` 3.x 用 Dart 的 build hook，**第一次构建时会从 GitHub Releases 下载
预编译好的 SQLite 原生库**（校验 sha256）。下不动的话构建会失败在 `build_hooks`。它认
代理环境变量：

```sh
HTTPS_PROXY=http://127.0.0.1:7897 flutter build apk --debug
```

下载下来的东西缓存在 `.dart_tool/hooks_runner/shared/sqlite3/`，之后不再需要网络。
