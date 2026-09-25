import 'dart:convert';
import 'dart:typed_data';

import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

/// 把文本摊成码位，好让断言不受终端编码影响。
///
/// 「解出来的字对不对」这件事在某些终端上没法用字面量直说（U+FFFD 在 Windows 的
/// 控制台里会被显示成一个汉字），`expect(text, '安�')` 会变成靠渲染结果猜。摊成
/// 码位就只有一个说法了：序列相等。
List<String> units(String text) => text.codeUnits
    .map((unit) => 'U+${unit.toRadixString(16).toUpperCase().padLeft(4, '0')}')
    .toList();

/// GBK 解码。
///
/// 「解码」听着像个库调用，但 `packages/core` 零运行期依赖，所以这里自带一张
/// CP936 表（`tools/generate_gbk_table.py` 生成）。表要是生成错了，后面整条导入
/// 链都会跟着错，而且错得很像「文件有问题」——所以这层得单独砸实。
void main() {
  group('常见字符', () {
    test('ASCII 原样通过', () {
      final decoded = GbkCodec.decode(
        Uint8List.fromList(utf8.encode('Software Testing 3 ()')),
      );
      expect(decoded.text, 'Software Testing 3 ()');
      expect(decoded.hasUnmappedBytes, isFalse);
    });

    test('双字节汉字', () {
      // 「安徽工程大学」的 GBK 编码。
      final bytes = Uint8List.fromList([
        0xB0, 0xB2, // 安
        0xBB, 0xD5, // 徽
        0xB9, 0xA4, // 工
        0xB3, 0xCC, // 程
        0xB4, 0xF3, // 大
        0xD1, 0xA7, // 学
      ]);
      final decoded = GbkCodec.decode(bytes);
      expect(decoded.text, '安徽工程大学');
      expect(decoded.hasUnmappedBytes, isFalse);
    });

    test('全角标点', () {
      // 导出文件里课程名带全角括号，教室名带半角括号——两种都得对。
      final bytes = Uint8List.fromList([
        0xA3, 0xA8, // （
        0xB0, 0xB2, // 安
        0xA3, 0xA9, // ）
        0x41, // A
      ]);
      expect(GbkCodec.decode(bytes).text, '（安）A');
    });
  });

  group('解不出来时不抛异常，而是记位置', () {
    test('孤立的单字节 0x80..0xFF', () {
      // CP936 里没有合法的单字节落在这一段。`0x80` 落单，前后两个 ASCII 原样留着。
      final decoded = GbkCodec.decode(Uint8List.fromList([0x41, 0x80, 0x42]));
      expect(units(decoded.text), ['U+0041', 'U+FFFD', 'U+0042']);
      expect(decoded.unmappedByteOffsets, [1]);
    });

    test('0x80..0xFF 那一字节之后紧跟的合法双字节照解', () {
      // `0x81 0x42` 是**合法的双字节**（「丅」），不该被当成坏数据。
      final decoded = GbkCodec.decode(
        Uint8List.fromList([0x81, 0x42, 0x80, 0x81, 0x42]),
      );
      expect(decoded.text, '丅�丅');
      expect(decoded.unmappedByteOffsets, [2]);
    });

    test('孤立的前置字节：后面没有字节了', () {
      final decoded = GbkCodec.decode(Uint8List.fromList([0x41, 0x81]));
      expect(units(decoded.text), ['U+0041', 'U+FFFD']);
      expect(decoded.unmappedByteOffsets, [1]);
    });

    test('后置字节越界：只吃掉前置字节，后面那个自己再判一次', () {
      // 0x81 0x20：0x20 是空格，不在后置字节的范围里。**不能连它一起丢掉**，
      // 否则它后面那个合法的「安」会被连着误判。
      final decoded = GbkCodec.decode(
        Uint8List.fromList([0x81, 0x20, 0xB0, 0xB2]),
      );
      expect(decoded.text, '� 安');
      expect(decoded.unmappedByteOffsets, [0]);
    });

    test('后置字节 0x7F 不合法，但它本身是个可见的 ASCII 字符', () {
      // 越界的是**后置字节**，所以只吃掉前置字节；0x7F 留在文本里。
      final decoded = GbkCodec.decode(
        Uint8List.fromList([0xB0, 0x7F, 0xB0, 0xB2]),
      );
      expect(units(decoded.text), ['U+FFFD', 'U+007F', 'U+5B89']);
      expect(decoded.unmappedByteOffsets, [0]);
    });

    test('两个字节都在合法范围、但 CP936 里没有这个组合', () {
      // CP936 有约 2100 个这样的空洞，`0xA1 0x40` 是其中第一个。这是**一对**坏
      // 字节，两个都要吃掉——不能只吃前置字节，那样后面的字节会被连着解错位。
      final decoded = GbkCodec.decode(
        Uint8List.fromList([0xB0, 0xB2, 0xA1, 0x40, 0xB0, 0xB2]),
      );
      expect(units(decoded.text), ['U+5B89', 'U+FFFD', 'U+5B89']);
      expect(decoded.unmappedByteOffsets, [2]);
    });

    test('几个坏字节各记一条，位置是输入里的下标', () {
      // `0xA1 0x40` 与 `0xA1 0x41` 都是空洞；`0x80` 是落单的单字节。
      final decoded = GbkCodec.decode(
        Uint8List.fromList([0xB0, 0xB2, 0xA1, 0x40, 0xA1, 0x41, 0x80]),
      );
      expect(units(decoded.text), [
        'U+5B89',
        'U+FFFD',
        'U+FFFD',
        'U+FFFD',
      ]);
      expect(decoded.unmappedByteOffsets, [2, 4, 6]);
    });
  });

  group('对照物：整张表跟 Python 的 cp936 编解码器对一遍', () {
    test('抽样位置逐个相符', () {
      // 期望值是拿 Python 的 `bytes(...).decode('cp936')` 取出来的（不是从本实现
      // 里抄的）——否则这条测试只是在证明「表跟它自己一致」。
      // 样本刻意落在 CP936 的四段上：符号区、一级汉字区、二级汉字区、GBK 扩展区。
      const samples = <List<int>, int>{
        [0xA1, 0xAD]: 0x2026, // …
        [0xA1, 0xA4]: 0x00B7, // ·
        [0xA3, 0xAC]: 0xFF0C, // ，
        [0xD2, 0xBB]: 0x4E00, // 一
        [0xC1, 0xFA]: 0x9F99, // 龙（二级汉字区）
        [0xFD, 0x9B]: 0x9FA5, // 龥（二级汉字区靠后）
        [0x81, 0x40]: 0x4E02, // 扩展区第一个双字节位置
        [0x82, 0x40]: 0x4FA4,
      };
      for (final entry in samples.entries) {
        final bytes = Uint8List.fromList(entry.key);
        expect(
          GbkCodec.decode(bytes).text.codeUnitAt(0),
          entry.value,
          reason:
              '${entry.key.map((b) => b.toRadixString(16)).join('/')} '
              '应当解成 U+${entry.value.toRadixString(16).toUpperCase()}',
        );
      }
    });

    test('夹具全文解出来之后一个坏字节都没有', () {
      // 真实导出是全中文的，解出替换字符就说明表缺了一块。
      final decoded = GbkCodec.decode(fixtureBytes());
      expect(
        decoded.unmappedByteOffsets,
        isEmpty,
        reason: '真实导出文件里不该有解不出来的字节',
      );
      expect(decoded.text, isNot(contains(GbkCodec.replacementCharacter)));
    });

    test('解出来的正文里有已知的字样', () {
      // 上面的「没有坏字节」还不够——整张表要是**整体错位**了，一样能解出「没有
      // 坏字节」。这里钉几个只有真解对了才会出现的字样。
      final text = fixtureText();
      expect(text, contains('个人课程表'));
      expect(text, contains('2026-2027学年第一学期'));
      expect(text, contains('星期一'));
      expect(text, contains('第一节'));
      expect(text, contains('编译原理'));
      expect(text, contains('停课'));
      expect(text, contains('授课计划'));
    });
  });
}
