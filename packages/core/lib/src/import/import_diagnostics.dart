/// 导入的诊断代码。[ImportDiagnostic.code] 用它，测试也用它——比去匹配消息文本稳。
///
/// 刻意都是 `String` 而不是 enum：诊断将来会长（线上教学、单双周、学期起止……），
/// 而**未知的代码不应该让解析器崩掉**——它是数据，不是控制流。
abstract final class ImportIssue {
  /// 文件是空的（0 字节）。
  static const String emptyFile = 'empty-file';

  /// 文件大得不像一份课表导出。上限见 [TimetableImporter.maxBytes]。
  static const String fileTooLarge = 'file-too-large';

  /// 有字节没解出来，落成了 U+FFFD。
  static const String unmappedByte = 'unmapped-byte';

  /// 文本里没有 `id="manualArrangeCourseTable"` 的那张表——不像教务系统的导出。
  static const String missingTable = 'missing-table';

  /// 表结构对不上：行数不足、某行列数不是 7、`rowspan` 越界……导入中止。
  static const String malformedTable = 'malformed-table';

  /// 单元格正文解不出安排（少了周次行、少了课程行、正文全是垃圾……）。
  static const String unparsableCell = 'unparsable-cell';

  /// 周次那一行解不出来（写法认不出、周次越界、起止颠倒……）。
  static const String badWeeks = 'bad-weeks';

  /// 地点那一格空了。
  static const String missingVenue = 'missing-venue';

  /// 单元格 `id` 与它在 DOM 里的坐标对不上。
  static const String coordinateMismatch = 'coordinate-mismatch';

  /// 结构没问题，但一条上课安排都没解出来。
  static const String emptyTimetable = 'empty-timetable';
}

/// 诊断的严重程度。
///
/// 只有两级，而且**两级都要给用户看**——差别只在「要不要确认」：出错条目的意思是
/// 「有内容没进来」，静默应用等于悄悄改小用户的课表。语义见
/// [ImportOutcome.hasUnparsableContent]。
enum ImportSeverity {
  /// 有内容没解出来。（严重）
  error('有内容没解出来'),

  /// 解出来了，但有值得说一声的地方。（提示）
  warning('值得说一声');

  const ImportSeverity(this.label);

  /// 界面上的写法。
  final String label;
}

/// 一条导入诊断。
///
/// **诊断是返回值的一部分，不是异常**——静默失败是最糟的结果，比「解析成功」还
/// 要紧。所以解不出来的格子一律产出诊断条目，条目**带着原文**，而且不许被丢掉。
class ImportDiagnostic {
  /// 校验消息不为空白。
  factory ImportDiagnostic({
    required String code,
    required ImportSeverity severity,
    required String message,
    int? weekday,
    int? period,
    String? rawText,
    int? byteOffset,
  }) {
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      throw ArgumentError.value(code, 'code', '诊断代码不能是空白');
    }
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw ArgumentError.value(message, 'message', '诊断消息不能是空白');
    }
    return ImportDiagnostic._(
      code: trimmedCode,
      severity: severity,
      message: trimmedMessage,
      weekday: weekday,
      period: period,
      rawText: rawText,
      byteOffset: byteOffset,
    );
  }

  const ImportDiagnostic._({
    required this.code,
    required this.severity,
    required this.message,
    required this.weekday,
    required this.period,
    required this.rawText,
    required this.byteOffset,
  });

  /// 见 [ImportIssue]。用字符串而不是 enum——未知代码不该让解析器崩掉。
  final String code;

  final ImportSeverity severity;

  /// 给人看的说明。
  final String message;

  /// 出问题的格子在星期几：1 = 星期一 … 7 = 星期日。不是格子上的问题就是 null。
  final int? weekday;

  /// 出问题的格子的节次（起始节）。不是格子上的问题就是 null。
  final int? period;

  /// **原文**——不解出来的那段文本原样带着。这一条是硬要求：没有原文，用户拿到
  /// 「有一个格子解不出来」也无从下手。
  final String? rawText;

  /// 字节位置。解码阶段的诊断才用得上。
  final int? byteOffset;

  /// 位置的展示写法，如 `星期三第3节`。没位置信息时是 null。
  ///
  /// [_weekdayLabels] 里存的本来就是「星期一」这样的全文，所以**不要再加一次
  /// 「星期」前缀**——那样会拼出「星期星期四第6节」。
  String? get positionLabel {
    if (weekday == null && period == null) return null;
    final weekdayPart = weekday == null
        ? '?'
        : _weekdayLabels[weekday! - 1];
    final periodPart = period == null ? '?' : '第$period节';
    return '$weekdayPart$periodPart';
  }

  /// 是出错还是提示。
  bool get isError => severity == ImportSeverity.error;

  @override
  String toString() {
    final position = positionLabel;
    final where = position == null
        ? (byteOffset == null ? '' : ' @字节$byteOffset')
        : ' @$position';
    final raw = rawText == null ? '' : ' 原文：「$rawText」';
    return '[${severity.label}/$code]$where $message$raw';
  }
}

/// 导入的结果：课表 + 诊断。
///
/// [TimetableImportResult.timetable] 与它的诊断一起返回，**没有「只看成功那一半」的
/// 用法**——调用方拿到 [TimetableImportResult.hasUnparsableContent] 为真时该让用户
/// 确认，而不是当作成功。术语见 [ImportIssue]。
abstract final class ImportLimits {
  /// 文件大小的上限：8 MiB。
  ///
  /// 真实导出是 38 KB 上下；一份课表导出不该有大几百倍于此的体积。挡住超大文件
  /// 是为了不把内存与解析时间交给一个明显不像是课表的输入（比如误选了别的 xls）。
  static const int maxBytes = 8 * 1024 * 1024;
}

const List<String> _weekdayLabels = [
  '星期一',
  '星期二',
  '星期三',
  '星期四',
  '星期五',
  '星期六',
  '星期日',
];
