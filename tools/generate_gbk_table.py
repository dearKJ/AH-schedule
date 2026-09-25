#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""生成 `packages/core/lib/src/import/gbk_table.dart`。

教务系统导出的 `.xls` 是 **GBK 编码的 HTML**，导入解析的第一步就是把字节按 GBK
解码。而 `packages/core` 立包时定下「**零运行期依赖**」（见
`packages/core/test/no_flutter_dependency_test.dart`），所以解码表只能自带，
不能引 `charset` / `fast_gbk` 之类的包。

本脚本把 CP936（= GBK，Python 的 `cp936` 编解码器）整张双字节映射表烘成一份
Dart 常量。**表是数据，不是逻辑**——所以它生成一次、之后只在换解码器时才重跑。

用法：

    python tools/generate_gbk_table.py

表的结构（生成器与解码器必须一致，改一处就得改两处）：

- 每个前置字节 `0x81..0xFE` 一行，行内按后置字节 `0x40..0xFE` 顺序排放，
  **跳过 `0x7F`**（它不是合法的后置字节），每个位置**恰好一个字符**。所以一行的
  下标是 `trail - 0x40 - (trail > 0x7F ? 1 : 0)`。
- CP936 有约 2100 个位置**没有对应字符**，这些位置放 [EMPTY] 这个哨兵字符。
  哨兵必须是**一个位置一个字符**——曾经试过「空洞直接不放」，省下约 10% 体积，
  但那样下标公式就不成立了（解出来的字会整体错位），而且「这个位置没映射」变成
  了「靠数数推出来」的事。宁可多这 2100 个字符。
- 覆盖全部 `0x80..0xFF` 的单字节位置：CP936 里它们**都是**非法的，一律落成
  U+FFFD 并记一条诊断（见 `gbk_codec.dart`），所以不需要表。

Python 的 `cp936` 与「GBK」在双字节上是一致的；`gb18030` 才多出四字节序列，
本脚本刻意不用它——导出文件里没有四字节序列，容忍它只会让坏数据悄悄通过。
"""

from __future__ import annotations

import sys
from pathlib import Path

# 前置字节的范围。0x81 以下与 0xFE 以上都没有双字节序列。
LEAD_MIN = 0x81
LEAD_MAX = 0xFE
# 后置字节的范围。0x7F 被刻意跳过。
TRAIL_MIN = 0x40
TRAIL_MAX = 0xFE
TRAIL_SKIP = 0x7F

# CP936 的空洞在表里放这个哨兵。取值落在 Unicode 的**私用区**：GBK 不可能映射到
# 私用区（CP936 里没有 PUA 目标），所以它不会跟任何真字符撞上。
EMPTY = ""
# 哨兵在生成的 Dart 里写作什么。用转义而不是裸字符：私用区字符在编辑器里多半
# 显示成一个豆腐块，裸着放没法看出这是有意为之。
EMPTY_ESCAPED = chr(92) + "ue000"
# 上面这句刻意用 chr(92) 拼反斜杠，而不是写成字面量：一个反斜杠加 u 开头的
# 转义在编辑链路上会被还原成那个真字符，于是生成的文件里躺进一个编辑器显示成
# 豆腐块的裸字符——那样表里就分不清「没映射」和「解出来正好是它」了。

OUTPUT = (
    Path(__file__).resolve().parent.parent
    / "packages"
    / "core"
    / "lib"
    / "src"
    / "import"
    / "gbk_table.dart"
)

HEADER = """// GENERATED FILE — 请不要手改。
//
// 由 `tools/generate_gbk_table.py` 生成。重跑：
//
//     python tools/generate_gbk_table.py
//
// 表本身是数据，不是逻辑：它是 CP936（= GBK）的双字节 → Unicode 映射，
// 平常不需要动。只有在换解码器（比如改用 GB18030）时才值得重跑一次。
//
// 结构与守法见生成脚本的文档注释，以及 `gbk_codec.dart`。

/// CP936 的双字节映射表。
///
/// `_rows[lead - 0x81]` 是前置字节 `lead` 那一行；行内第 n 个字符对应后置字节
/// `n + 0x40`（跳过 `0x7F`），**未映射的位置不存在**，靠下标公式定位。
const List<String> gbkDoubleByteRows = <String>[
"""


def build_rows() -> tuple[list[str], int, int]:
    """逐前置字节生成一行。返回（行、合法位置数、有映射的位置数）。

    每行**恒为 190 个字符**（= 后置字节 `0x40..0xFE` 去掉 `0x7F`），没映射的位置
    放 [EMPTY]。位置守恒是解码器那条下标公式的前提，所以这里不能省字符。
    """
    rows: list[str] = []
    slots = 0
    mapped = 0
    for lead in range(LEAD_MIN, LEAD_MAX + 1):
        line: list[str] = []
        for trail in range(TRAIL_MIN, TRAIL_MAX + 1):
            if trail == TRAIL_SKIP:
                continue
            slots += 1
            try:
                char = bytes((lead, trail)).decode("cp936")
            except UnicodeDecodeError:
                line.append(EMPTY)
                continue
            if len(char) != 1:
                raise SystemExit(
                    f"意外：{lead:#04x}{trail:#04x} 解出 {len(char)} 个字符（{char!r}），"
                    "表按「一个位置一个字符」假设，遇到多字符映射要重新设计"
                )
            mapped += 1
            line.append(char)
        rows.append("".join(line))
    return rows, slots, mapped


def escape(char: str) -> str:
    """把字符写成 Dart 字符串字面量能吃的写法。

    走**裸字符**而不是 `\\uXXXX`：整张表有 21000 多个位置，全转义成 6 字节一个
    要 130 KiB，裸着放只要 44 KiB。代价是生成的文件是 UTF-8（裸字符）而不是纯
    ASCII——对本仓库无所谓，`.gitattributes` 已经把编码与换行钉死了。

    只转义真会出事的：`"`、`\\`、`$`（Dart 的插值符），以及私用区哨兵与控制字符
    ——裸着放要么生成语法都读不出来的文件，要么在编辑器里显示成一堆豆腐块。
    """
    if char == EMPTY:
        return EMPTY_ESCAPED
    code = ord(char)
    if char == '"':
        return r"\""
    if char == "\\":
        return r"\\"
    if char == "$":
        return r"\$"
    if code < 0x20 or code == 0x7F:
        return f"\\u{code:04x}"
    return char


def main() -> int:
    rows, slots, mapped = build_rows()
    body = "\n".join(
        '  "' + "".join(escape(char) for char in row) + '",' for row in rows
    )
    lines = [HEADER, body, "];", ""]
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    # 刻意用 open + newline=""：让生成的 .dart 恒为 LF，不受 Windows 的 CRLF 影响。
    with open(OUTPUT, "w", encoding="utf-8", newline="") as handle:
        handle.write("\n".join(lines))

    size = OUTPUT.stat().st_size
    print(f"写了 {OUTPUT}")
    print(f"  前置字节 {LEAD_MAX - LEAD_MIN + 1} 行，合法位置 {slots} 个，有映射 {mapped} 个")
    print(f"  {size} 字节（{size / 1024:.1f} KiB）")
    if mapped < 20000:
        print("警告：映射数明显偏少，解码器可能拿错了", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
