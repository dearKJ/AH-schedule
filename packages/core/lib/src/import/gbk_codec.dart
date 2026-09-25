import 'gbk_table.dart';

/// GBK（CP936）解码。教务处导出的 `.xls` 其实是 **GBK 编码的 HTML**，导入的第一
/// 步就是把字节解成文本，之后才谈得上当 HTML 解析。
///
/// **为什么自带一张表**：`packages/core` 立包时定下「零运行期依赖」，而解码 GBK
/// 要么引 `charset` / `fast_gbk`，要么自带映射表。这里选自带——表是数据，
/// 由 `tools/generate_gbk_table.py` 生成，见 `gbk_table.dart` 抬头。
///
/// **解码失败不抛异常**：解不出来的字节落成 U+FFFD，位置记进 [GbkDecodeResult]
/// 的 `unmappedByteOffsets`，由调用方转成诊断条目。解码是导入的中间步骤，
/// 这里悄悄丢掉东西的话，用户在课表里看到的就是几个问号，而没有任何解释。
abstract final class GbkCodec {
  /// 解不出来的字节替换成它（Unicode 的 replacement character）。
  static const String replacementCharacter = '�';

  /// 覆盖全部 `0x80..0xFF` 的单字节位置：CP936 里**没有**合法的单字节映射落在这
  /// 一段，所以一律按非法处理，不查表。
  static const int _asciiLimit = 0x80;

  static const int _leadMin = 0x81;
  static const int _leadMax = 0xFE;
  static const int _trailMin = 0x40;
  static const int _trailMax = 0xFE;
  static const int _trailSkipped = 0x7F;

  /// 后置字节在行内的下标：跳过 `0x7F` 之后的位置。
  ///
  /// 生成器与这里必须一致——改一处就得改两处，两边的文档注释都写了这条。生成的
  /// 每行**恒为 190 个字符**（后置字节 `0x40..0xFE` 去掉 `0x7F`），所以这条下标
  /// 公式成立；没映射的位置在表里放着 [_unmappedSlot] 这个哨兵。
  static int _trailIndex(int trail) =>
      trail - _trailMin - (trail > _trailSkipped ? 1 : 0);

  /// 表里表示「这个位置 CP936 没映射」的哨兵。
  ///
  /// 取值在 Unicode 的**私用区**：CP936 不映射到私用区，所以它撞不上任何真字符。
  /// 与 `tools/generate_gbk_table.py` 里的 `EMPTY` 是同一个值。
  /// 与 `tools/generate_gbk_table.py` 里的 `EMPTY` 是同一个值——那边生成时写的
  /// 是 `\ue000` 这个转义，这里用 [String.fromCharCode] 拼出来，免得源文件里
  /// 躺一个编辑器显示成豆腐块的裸字符。
  static final String _unmappedSlot = String.fromCharCode(0xE000);

  /// 解码双字节部分。表按需展开一次，之后复用。
  static List<String>? _rows;

  static List<String> get _table => _rows ??= gbkDoubleByteRows;

  /// 把 [bytes] 按 GBK 解成文本，并报告哪些字节没解出来。
  static GbkDecodeResult decode(List<int> bytes) {
    final buffer = StringBuffer();
    final unmapped = <int>[];
    var index = 0;

    while (index < bytes.length) {
      final byte = bytes[index];

      if (byte < _asciiLimit) {
        buffer.writeCharCode(byte);
        index++;
        continue;
      }

      // 这里是双字节序列的起点。前置字节不合法、或后面没有字节了，都只能记一个
      // 替换字符：**不能就此丢掉后半段**，否则后面本来能解的字节会被连着误判。
      if (byte < _leadMin || byte > _leadMax || index + 1 >= bytes.length) {
        unmapped.add(index);
        buffer.write(replacementCharacter);
        index++;
        continue;
      }

      final trail = bytes[index + 1];
      final row = _table[byte - _leadMin];
      final position = _trailIndex(trail);
      final isTrailInRange =
          trail >= _trailMin &&
          trail <= _trailMax &&
          trail != _trailSkipped &&
          position < row.length;

      if (!isTrailInRange) {
        // 后置字节越界。只吃掉前置字节，让后置字节下一轮自己再判一次——
        // 它可能是个合法的单字节 ASCII。
        unmapped.add(index);
        buffer.write(replacementCharacter);
        index++;
        continue;
      }

      final char = row[position];
      if (char == _unmappedSlot) {
        // 两个字节都是合法的 GBK 范围，但这个组合在 CP936 里没有对应字符。
        // 这是**一对**坏字节，两个都要吃掉。
        unmapped.add(index);
        buffer.write(replacementCharacter);
        index += 2;
        continue;
      }

      buffer.write(char);
      index += 2;
    }

    return GbkDecodeResult(text: buffer.toString(), unmappedByteOffsets: unmapped);
  }
}

/// [GbkCodec.decode] 的产物。
class GbkDecodeResult {
  /// 解出来的文本。
  final String text;

  /// 没解出来的字节在**输入里的下标**（升序，可能重复——同一段坏字节的后续字节
  /// 如果也是坏的，会各自记一条）。调用方拿它报位置。
  final List<int> unmappedByteOffsets;

  GbkDecodeResult({
    required this.text,
    required List<int> unmappedByteOffsets,
  }) : unmappedByteOffsets = List.unmodifiable(unmappedByteOffsets);

  /// 有没有字节没解出来。解码器**不抛异常**，所以这一条是调用方唯一的信号。
  bool get hasUnmappedBytes => unmappedByteOffsets.isNotEmpty;

  @override
  String toString() =>
      'GbkDecodeResult(${text.length} 字符, '
      '${unmappedByteOffsets.length} 个字节没解出来)';
}
