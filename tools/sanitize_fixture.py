#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把教务系统导出的真实课表脱敏成可入库的测试夹具。

用法：

    python tools/sanitize_fixture.py \\
        --input "/path/to/课表.xls" \\
        --output test/fixtures/ahpu-jwxt-export-2026-2027-1.sanitized.xls \\
        --student-id <真实学号> --name <真实姓名> --class-name <真实班级> \\
        --fake-student-id 3200000001 --fake-name 张三 --fake-class-name 示例241

真实值只从命令行传入，**不要写进本文件**——本仓库是 public，
把要防的东西本身写进仓库就本末倒置了。见 docs/spec-v0.1.md「夹具与隐私」。

约束：

- 只替换学号 / 学生姓名 / 所属班级三个字段的**值**，不碰任何结构。
- 每个字段都带原文锚点（`学号:` 等）匹配，且必须**恰好命中一次**——
  命中 0 次说明文件格式变了，命中多次说明锚点不够特异，两种情况都直接失败。
- 替换后校验：原文三个值一个都不许残留，假值必须都在。
- 解码 / 编码走 GBK，逐字节回写，其余部分与原始文件完全一致。
"""

import argparse
import sys

# 学生信息行的字段名。锚点连同字段名一起替换，保证只在信息行里命中。
# (锚点模板, 字段名)
FIELDS = [
    ("学号:{value}", "student_id"),
    ("学生姓名:{value}", "name"),
    ("所属班级: {value}", "class_name"),
]

ENCODING = "GBK"


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--input", required=True, help="原始导出文件（GBK HTML）")
    parser.add_argument("--output", required=True, help="脱敏副本的落盘路径")
    parser.add_argument("--student-id", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--class-name", required=True)
    parser.add_argument("--fake-student-id", required=True)
    parser.add_argument("--fake-name", required=True)
    parser.add_argument("--fake-class-name", required=True)
    args = parser.parse_args(argv)

    real = {
        "student_id": args.student_id,
        "name": args.name,
        "class_name": args.class_name,
    }
    fake = {
        "student_id": args.fake_student_id,
        "name": args.fake_name,
        "class_name": args.fake_class_name,
    }

    with open(args.input, "rb") as fh:
        raw = fh.read()
    text = raw.decode(ENCODING)

    for anchor_template, key in FIELDS:
        anchor = anchor_template.format(value=real[key])
        count = text.count(anchor)
        if count != 1:
            raise SystemExit(
                f"锚点 {anchor!r} 命中 {count} 次（应为 1 次）——文件格式可能已变，中止"
            )
        text = text.replace(anchor, anchor_template.format(value=fake[key]))

    # 校验：真值一个不留，假值全部到位。
    for key, value in real.items():
        if value in text:
            raise SystemExit(f"脱敏失败：原文 {key}={value!r} 仍然出现在结果里")
    for key, value in fake.items():
        if value not in text:
            raise SystemExit(f"脱敏失败：假值 {key}={value!r} 没有写进结果")

    out = text.encode(ENCODING)
    with open(args.output, "wb") as fh:
        fh.write(out)

    print(f"原始 {len(raw)} 字节 → 脱敏 {len(out)} 字节")
    for key in real:
        print(f"  {key}: {real[key]} → {fake[key]}")


if __name__ == "__main__":
    sys.exit(main())
