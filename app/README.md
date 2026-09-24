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

`app/` 现在是**走路骨架**（issue #4）：跑得起来，三层真的接上了——界面上的学年学期是从
数据库读出来、也真的写回数据库的。周网格（#10）、导入（#5/#9）、手动增删改（#11）、
学期设置（#12）都还没开始。

## 一个环境坑

`package:sqlite3` 3.x 用 Dart 的 build hook，**第一次构建时会从 GitHub Releases 下载
预编译好的 SQLite 原生库**（校验 sha256）。下不动的话构建会失败在 `build_hooks`。它认
代理环境变量：

```sh
HTTPS_PROXY=http://127.0.0.1:7897 flutter build apk --debug
```

下载下来的东西缓存在 `.dart_tool/hooks_runner/shared/sqlite3/`，之后不再需要网络。
