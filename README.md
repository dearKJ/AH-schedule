# AH-schedule

安徽工程大学学生的课表 App：导入教务系统导出的课表，**离线查看、一眼看全周、可分享给同学**。

使用者是本人与同校同学（几十到几百人量级），不面向公众发布。

## 状态

**需求阶段已完成。领域层（`packages/core`）已落地，App 脚手架尚未开始。** 结论见下方文档。

## 它解决什么

学校教务系统能看课表，但不能离线、不能一眼看全、不能提醒、不能分享。这个 App 拿走的正是这几件事。

## v0.1 范围

- **周网格课表**：一屏尽收整周，纵向可滚、星期栏吸顶，**高亮今天**；同课同色
- **导入**教务系统导出的 `.xls`（实为 GBK 编码的 HTML 表格），带导入预览确认
- **手动录入**：长按空格子，星期与节次自动带出，课名带历史自动补全
- 点开一条安排看**详情**，可编辑、可删除
- **学期设置**（第 1 周的第一天）与多学期共存
- **导出**课表 JSON，用于换手机与分享（**剥离学号/姓名/班级**）

**明确不做**：iOS（无 Mac）、服务器/账号/云同步、自动登录抓取教务系统、粘贴文本导入、`.ics` 导出、国际化。每条的理由见 `docs/adr/`。

## v0.2 第一顺位

桌面小组件与上课提醒——抬眼看桌面就知道下节课在哪。

## 技术栈

Flutter / Dart · **Riverpod** · **drift** · go_router · 仅 Android 8.0+ · 深色模式跟随系统 · 中文

工程结构分三层：

```
packages/core/   纯 Dart，不依赖 Flutter —— 课表的数据形状，与最容易写错的纯逻辑
app/             Flutter 工程（还没有，见 issue #4）：data/（drift 数据库、仓储）、ui/（界面）
```

`core/` 不许 import Flutter：这段最核心、也最容易写错的逻辑必须能用最快的纯 Dart 单元测试反复砸。这条边界**由包边界强制**——它单独成包、零运行期依赖，还有一条检查盯着它，见 [`packages/core/README.md`](packages/core/README.md)。

## 文档

| 文档 | 内容 |
| --- | --- |
| [`CONTEXT.md`](CONTEXT.md) | 领域词汇表——本项目所有概念的**唯一出处** |
| [`docs/adr/`](docs/adr/) | 已成文的架构决策：数据模型、无服务器、Flutter 仅 Android |
| [`docs/reference/ahpu-jwxt-export-format.md`](docs/reference/ahpu-jwxt-export-format.md) | 教务系统导出文件的解析规格（已在真实样本上验证：15/15） |
| [`docs/reference/ahpu-bell-schedule.md`](docs/reference/ahpu-bell-schedule.md) | 作息时间表默认配置 |
| [`AGENTS.md`](AGENTS.md) | 本仓库的 agent 配置 |

## 完成标准

1. 导入后每一格与教务系统逐格对得上
2. 连续一周，查课不再打开教务系统
3. 手动加一条、改一条、删一条都不崩

## 快速开始

领域层（纯 Dart）已经能跑：

```sh
cd packages/core
dart pub get
dart test
```

App 本身的脚手架还没搭，见 issue #4。

## 许可证

[Apache License 2.0](LICENSE)
