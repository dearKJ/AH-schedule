# 测试夹具

## `ahpu-jwxt-export-2026-2027-1.sanitized.xls`

使用者从教务系统（`xjwxt.ahpu.edu.cn` → 课表页 →「导出 Excel」）导出的真实课表，**脱敏后**入库，作为导入解析的测试夹具。

**为什么要用真实文件而不是编造的样本**：教务系统模板自身有一堆坑——多条安排同格时末尾缺 `)`、断档周用空格分隔、停课单列一条、`.xls` 实为 GBK HTML。编造的样本锁不住这些坑（见 [`docs/reference/ahpu-jwxt-export-format.md`](../../docs/reference/ahpu-jwxt-export-format.md) 第五节）。这份夹具是规格里「7×12 = 84 格解出 15 条上课安排、0 个无法配对」那条最重要测试的输入。

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
