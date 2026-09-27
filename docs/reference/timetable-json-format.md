# 课表 JSON（v1）——分享与迁移的契约

**这是课表在设备与设备之间的唯一表示**（ADR-0002：没有服务器，换手机靠它，分享给同学
也靠它）。它由 `packages/core` 的 `TimetableJson` 读写：

```dart
TimetableJson.encode(timetable)        // 课表 → JSON 文本
TimetableJson.decode(text)             // JSON 文本 → 课表
TimetableJson.decodeBytes(fileBytes)   // 文件字节 → 课表
```

**不做 `.ics`**：iCalendar 表达不了单双周、断档周、停课例外，硬塞会丢信息。

## 版本号

顶层必须有 `"version"`，v1 是 `1`。规则只有一条：

- **只增不改**——改了语义就换一个新号。
- 版本号**缺失**或**不是整数** → `missing-version` / `bad-field`；**不认识** →
  `unknown-version`，错误文案里提示升级 App。

今天只有 v1，所以解码器只认 v1，其余一律 `unknown-version`。**「老文件照样读得进」
是在发 v2 的那一天兑现的**：到时候必须同时留着读 v1 的路径，否则这条规则等于没定。

版本号挡在**最前面**：版本不认识就说明后面的字段未必是这套形状，硬解下去只会报出一堆
莫名其妙的「缺字段」。

## 一个例子

真实产物是缩进两格的（给人也能看），下面为省地方省掉了作息时间表中间几节，用 `…` 标出：

```json
{
  "version": 1,
  "term": { "id": "2026-2027-1", "label": "2026-2027学年1学期" },
  "settings": {
    "firstDayOfWeek1": "2026-09-07",
    "totalWeeks": 18,
    "bellSchedule": {
      "name": "安徽工程大学（默认）",
      "periods": [
        { "period": 1, "start": "08:00", "end": "08:45", "block": "morning" },
        …
        { "period": 12, "start": "20:40", "end": "21:25", "block": "evening" }
      ]
    }
  },
  "sessions": [
    {
      "courseName": "编译原理",
      "teacher": "胡冰",
      "weekday": 1,
      "periods": { "start": 1, "length": 2 },
      "weeks": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      "venue": { "room": "4J410", "campus": "主校区" },
      "exceptions": [
        { "type": "cancellation", "week": 2 },
        { "type": "onlineTeaching", "week": 6, "campus": "主校区" }
      ]
    }
  ]
}
```

## 字段

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `version` | 整数 | ✅ | 见上。 |
| `term.id` / `term.label` | 字符串 | ✅ | 学年学期的标识与展示名。数据的隔离靠 `id`。 |
| `settings.firstDayOfWeek1` | `YYYY-MM-DD` | | 第 1 周的第一天，**必须是周一**。留空即未设。 |
| `settings.totalWeeks` | 整数 | | 学期总周数，1..53。留空即以数据实际范围为准。 |
| `settings.bellSchedule.name` | 字符串 | ✅ | 作息时间表的名字。 |
| `settings.bellSchedule.periods[]` | 数组 | ✅ | 每项 `period`（节次）、`start` / `end`（`HH:mm`）、`block`（`morning` / `afternoon` / `evening`）。节次必须唯一且升序。写法与 [`ahpu-bell-schedule.md`](ahpu-bell-schedule.md) 的机器可读形式一致。 |
| `sessions[]` | 数组 | ✅ | 一条上课安排一项，**顺序即课表里的顺序**。 |
| `sessions[].courseName` | 字符串 | ✅ | 课程名。 |
| `sessions[].teacher` | 字符串 | | 没有教师就不写这个键。 |
| `sessions[].weekday` | 整数 | ✅ | 1 = 星期一 … 7 = 星期日（与 `DateTime.weekday` 一致）。 |
| `sessions[].periods.start` / `.length` | 整数 | ✅ | 起始节次 + 节数。连堂就是 `length > 1`。 |
| `sessions[].weeks` | 整数数组 | ✅ | 周次集合，1..53，**不能为空**。写出来一律升序去重；读的时候重复与乱序会被归一成同一个集合（它本来就是个集合，没有「顺序」这回事）。 |
| `sessions[].venue.room` | 字符串 | ✅ | 教室名。线上教学时是「线上教学」。 |
| `sessions[].venue.campus` | 字符串 | | 校区。没有就不写这个键。 |
| `sessions[].exceptions[]` | 数组 | | 没有例外就不写这个键。 |
| `sessions[].exceptions[].type` | 字符串 | ✅ | `cancellation`（停课）或 `onlineTeaching`（线上教学）。**认不出来就报错**，不静默丢——丢掉一条停课等于悄悄多上一节课。 |
| `sessions[].exceptions[].week` | 整数 | ✅ | 例外落在哪一教学周。 |
| `sessions[].exceptions[].campus` | 字符串 | | 线上教学写在校区那一格的校区。 |

几条定下来的形状，理由都在领域层：

- **周次是集合，不是写法。** 教务系统的普通区间 / 单双周 / 断档周 / 特定周在文件里
  **没有区别**——它们是同一组周次的四种写法，解析之后只剩集合（见 `CONTEXT.md` 的
  「周次集合」）。所以文件里就是一张整数数组。`WeekSet.toText()` 那套写法只用于回填
  编辑框，不是契约。
- **例外是信息，不是删除**（ADR-0001）：它挂在既有的上课安排上，**不改变**那条安排的
  周次集合。所以一条「第 2 周停课」的安排，`weeks` 里照样有 `2`。
- **同一门课可以有多条安排**：一周上两次、中途换教师、换教室，各是各的一条，文件里
  就是 `sessions` 里的多项，不会被合并。
- **没有的字段就不写键**：`teacher`、`campus`、`firstDayOfWeek1`、`totalWeeks`、
  `exceptions` 都是。读的时候「键不在」与「写成 `null`」是同一件事。

## 不含学号 / 姓名 / 班级

**这是 ADR-0002 的前置条件，不是可选项**：教务系统导出的原始文件里带着学号、姓名、
班级，而这个 App 要发给同学——一次分享等于公开自己的学号。

在这里它不是靠「记得别写进去」，是靠**没有地方可写**：数据模型里没有装它们的字段，
编码器也只认得上面表里那几个键。两条测试盯着这件事
（`packages/core/test/json/export_privacy_test.dart`）：

1. 拿真实夹具（它的原始字节里**真的**有那三样）导入、导出，正面断言产物里一个都不含；
2. 递归收集导出产物的**全部键**，与白名单比对——今后加字段时这条会红，那时请对着
   ADR-0002 想一遍。

「这两条真的拦得住吗」的核对过程记在 [`packages/core/README.md`](../../packages/core/README.md)。

## 反序列化的错误

**不抛异常。** 版本号缺失 / 不认识、缺字段、坏字段、字节不是 UTF-8，一律落成
`TimetableDecodeResult` 里的一条 `JsonError`：

| 代码 | 什么时候 |
| --- | --- |
| `not-utf8` | 字节不是 UTF-8（选错了文件、传坏了）。 |
| `not-json` | 文本不是 JSON。 |
| `not-object` | 是 JSON，但顶层不是对象。 |
| `missing-version` | 没有版本号（键不在，或写成 `null`）。 |
| `unknown-version` | 版本号认不出来。 |
| `missing-field` | 必填字段不在。 |
| `bad-field` | 字段在，但类型或取值不对。 |
| `unknown-value` | 是个字符串，但那个字符串不认识（例外类型、上午/下午/晚上）。 |

错误**带着它在文件里的位置**（`path`，如 `sessions[3].weeks[0]`）——没有位置，「文件里
有个字段坏了」这句话使用者无从下手。**错误只有一条**：结构一坏就没什么可解的了，
「哪一处最先坏」就是那条拦路的错误。

## 读出来之后

文件里带着学年学期标识（`term`），所以拿到一份别人的课表时，「覆盖还是新增」是读得出
答案的。那条规则属于 issue #13，不在这里抄一份——抄了会漂。
