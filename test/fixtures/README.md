# 测试夹具

## `ahpu-jwxt-export-2026-2027-1.sanitized.xls`

使用者从教务系统（`xjwxt.ahpu.edu.cn` → 课表页 →「导出 Excel」）导出的真实课表，**脱敏后**入库，作为导入解析的测试夹具。

**为什么要用真实文件而不是编造的样本**：教务系统模板自身有一堆坑——多条安排同格时末尾缺 `)`、断档周用空格分隔、停课单列一条、`.xls` 实为 GBK HTML。编造的样本锁不住这些坑（见 [`docs/reference/ahpu-jwxt-export-format.md`](../../docs/reference/ahpu-jwxt-export-format.md) 第五节）。这份夹具是规格里「7×12 = 84 格全部解得出来、0 个无法配对」那条最重要测试的输入。

### 脱敏了什么

只替换学生信息行里三个字段的**值**，字段名、空白、周围一切原样保留：

| 字段 | 替换为 |
| --- | --- |
| 学号 | `3200000001` |
| 学生姓名 | `张三` |
| 所属班级 | `示例241` |

**结构一字未动**：仍是 13 行 × 8 列的 `<table id="manualArrangeCourseTable">`（1 表头行 + 12 节次行），仍是 GBK 编码的 HTML，单元格正文格式、`rowspan`、`TD{n}_{m}` 坐标、JS 块全部与原始文件一致。

### 怎么核对

脱敏的可信度不靠「看着像」，靠两条能跑的检查：

1. **文本 diff 只在那几个字段上不同**

   ```sh
   iconv -f GBK -t UTF-8 "<原始文件>" > /tmp/before.txt
   iconv -f GBK -t UTF-8 test/fixtures/ahpu-jwxt-export-2026-2027-1.sanitized.xls > /tmp/after.txt
   diff /tmp/before.txt /tmp/after.txt
   ```

   预期：只有第 27 行（学生信息行）有差异，且差异只落在三个值上。

2. **逆向替换后逐字节相同**——把假值换回真值，结果与原始文件二进制一致，即结构未动。这比文本 diff 更硬，因为连字节长度都不放过。

### 结构指纹（金标准）

夹具没被改坏的判据。任何一项对不上，就说明夹具被动过了：

| 项 | 值 |
| --- | --- |
| 文件字节数 | **38639**（索引与工作区必须一致） |
| 行数 / 换行 | 686 行，685 个 CRLF，**0 个裸 LF** |
| 表格 | 13 行 × 8 列（1 表头行 + 12 节次行） |
| 带 `id` 的 `TD` 单元格 | 72 |
| `<br>` | 40 |
| `rowspan` | 10 |
| `title` 属性 | 19 |
| 逻辑网格 | 84 格（7 × 12） |
| 有内容的格子 | 8 格 |
| 正文条目（含停课标记） | 16 条 |
| **解出上课安排** | **14 条** |
| **无法配对的单元格** | **0 个** |

最后两行就是规格里那条「最重要的一条测试」的期望值，由
`packages/core/test/import/fixture_import_test.dart` 断言。

**注意一**：目前仓库里**还没有任何东西在自动断言上面那张表里的全部数字**——那些
是「夹具有没有被动过」的核对依据，不是测试期望。导入解析（issue #5）落地时断言了
其中两项：**解出上课安排**与**无法配对的单元格**。

**注意二**：这张表原先写着「解出上课安排 15 条」，那个数字**与夹具本身对不上**。
照着夹具数一遍：84 个逻辑格子里 8 格有内容，这 8 格一共 16 条正文条目，其中 2 条是
`TD38_0` 那一格里的「停课」标记——按格式文档第五条第 4 点，停课与正常那条要合并成
「一次带例外的排课」，所以最终是 **16 − 2 = 14** 条安排。规格正文里那个 15/15 也是
同一个错，以夹具为准。

### 怎么重新生成

```sh
python tools/sanitize_fixture.py \
    --input "<原始文件>" \
    --output test/fixtures/ahpu-jwxt-export-2026-2027-1.sanitized.xls \
    --student-id <真实学号> --name <真实姓名> --class-name <真实班级> \
    --fake-student-id 3200000001 --fake-name 张三 --fake-class-name 示例241
```

脚本对每个字段都要求锚点**恰好命中一次**，命中 0 次或多次直接失败；替换后还会校验真值无残留、假值已到位。

### 入库前扫一遍

```sh
python tools/scan_pii.py test/fixtures/
```

真实值从 `.pii-terms`（仓库根目录，已 gitignore）读，不写进任何入库文件。**本仓库是 public**，这是硬约束不是建议（见 [`docs/spec-v0.1.md`](../../docs/spec-v0.1.md)「夹具与隐私」）。

`.pii-terms` 是**这台机器上的唯一副本，没有备份**。丢了不会静默放行——`scan_pii.py` 找不到该文件会明确报错退出（刻意 fail-closed），但届时没有真值可扫，闸就等于没有。换机器或重装后要重新建一份。

原始样本留在使用者的下载目录，**不提交**。

### 一个容易踩的坑：`*.xls` 必须在 `.gitattributes` 里标成 `binary`

本仓库的 `.gitattributes` 有 `* text=auto eol=lf`。若不把 `*.xls` 排除在外，git 会把夹具当文本处理、在入库时把 685 个 CRLF 全部换成 LF：**加了 `*.xls binary` 之后索引与工作区都是 38639 字节，不加则是 37954 字节**。clone 到别的机器上拿到的就不是同一份文件了，夹具锁住的那些坑随之失效。

所以 `.gitattributes` 里那行 `*.xls binary` 是**承重的**，不要删。核对方法：

```sh
# 索引里的字节数应当等于工作区文件的字节数
git cat-file -s "$(git rev-parse :test/fixtures/ahpu-jwxt-export-2026-2027-1.sanitized.xls)"
stat -c%s test/fixtures/ahpu-jwxt-export-2026-2027-1.sanitized.xls
```

两者都应是 **38639**。

**发现存错了怎么救**：blob 一旦按文本缓存进索引，光 `git add` **不会**重新规范化——索引里仍是 37954。必须先把缓存删掉再加：

```sh
git rm --cached test/fixtures/ahpu-jwxt-export-2026-2027-1.sanitized.xls
git add test/fixtures/ahpu-jwxt-export-2026-2027-1.sanitized.xls
# 或一把梭：git add --renormalize .
```
