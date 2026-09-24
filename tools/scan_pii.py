#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""扫入库文件里有没有残留的真实个人字段。本仓库是 public，这是最后一道闸。

用法：

    python tools/scan_pii.py test/fixtures/

被禁的真实值从 `.pii-terms`（仓库根目录，**已 gitignore**）按行读取，一行一个。
真实值不写进本文件、也不写进任何入库文件——把要防的东西本身写进仓库就本末倒置了。

扫描按**字节**做，同时试 UTF-8 与 GBK 两种编码——夹具是 GBK 的，
只按 UTF-8 搜会漏。命中任一被禁串即以退出码 1 结束。
"""

import argparse
import os
import sys

ENCODINGS = ("utf-8", "gbk")
TERMS_FILE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".pii-terms")


def scan_bytes(blob, needle):
    """返回 needle 在该字节串里以任一编码出现的次数。"""
    total = 0
    for enc in ENCODINGS:
        try:
            total += blob.count(needle.encode(enc))
        except UnicodeEncodeError:
            continue  # 该编码表示不了这个串，跳过
    return total


def load_terms(path):
    if not os.path.exists(path):
        raise SystemExit(
            f"找不到 {path}。按行写入要禁的真实值（一行一个），该文件已被 gitignore。"
        )
    # utf-8-sig：Windows 记事本存 UTF-8 会带 BOM，不剥掉的话第一行会多一个
    # U+FEFF，那一条被禁串就永远匹配不上——扫描器会在最该拦住的地方静默放行。
    with open(path, encoding="utf-8-sig") as fh:
        terms = [line.strip() for line in fh if line.strip() and not line.startswith("#")]
    if not terms:
        raise SystemExit(f"{path} 里没有任何被禁串，扫了等于没扫，中止。")
    return terms


def iter_files(paths):
    for path in paths:
        if os.path.isdir(path):
            for root, _dirs, files in os.walk(path):
                for name in files:
                    yield os.path.join(root, name)
        else:
            yield path


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("paths", nargs="+", help="要扫的文件或目录")
    parser.add_argument("--terms", default=TERMS_FILE, help=f"被禁串清单，默认 {TERMS_FILE}")
    args = parser.parse_args(argv)

    terms = load_terms(args.terms)

    findings = []
    checked = 0
    for path in iter_files(args.paths):
        with open(path, "rb") as fh:
            blob = fh.read()
        checked += 1
        for needle in terms:
            hits = scan_bytes(blob, needle)
            if hits:
                findings.append((path, needle, hits))

    for path, needle, hits in findings:
        print(f"命中：{path} 含被禁串（{hits} 次）")
    if findings:
        print(f"\n扫了 {checked} 个文件，{len(findings)} 处残留——不许入库。", file=sys.stderr)
        return 1
    print(f"扫了 {checked} 个文件，{len(terms)} 个被禁串，0 处残留。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
