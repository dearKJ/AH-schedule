/// 学年学期——课表的隔离单位。切换学年学期即切换整张课表。
///
/// 同一个学期有两种写法：导出文件里写 `2026-2027学年第一学期`，界面上写
/// `2026-2027学年1学期`。[parseLabel] 把两者归一化到同一个学期，[label] 统一用
/// 界面上那种写法。
class AcademicTerm {
  /// 校验 id 与展示名不为空白。
  factory AcademicTerm({required String id, required String label}) {
    final trimmedId = id.trim();
    final trimmedLabel = label.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError.value(id, 'id', '学年学期的标识不能是空白');
    }
    if (trimmedLabel.isEmpty) {
      throw ArgumentError.value(label, 'label', '学年学期的展示名不能是空白');
    }
    return AcademicTerm._(trimmedId, trimmedLabel);
  }

  const AcademicTerm._(this.id, this.label);

  /// 从教务系统那种写法解析，容忍多余空格、可选的「第」字与中文数字。
  ///
  /// 认不出来时抛 [FormatException]——**不猜**。学年学期认错等于把课表挂到别的
  /// 学期上，比报错糟得多。
  static AcademicTerm parseLabel(String label) {
    final match = _labelPattern.firstMatch(label);
    if (match == null) {
      throw FormatException('学年学期写法认不出来：「$label」', label);
    }
    final year = match.group(1)!.replaceAll(' ', '');
    final term = _termDigits[match.group(2)!]!;
    return AcademicTerm(id: '$year-$term', label: '$year学年$term学期');
  }

  /// [parseLabel] 的宽容版：认不出来时返回 null。
  static AcademicTerm? tryParseLabel(String label) {
    try {
      return parseLabel(label);
    } on FormatException {
      return null;
    }
  }

  static final RegExp _labelPattern = RegExp(
    r'^\s*(\d{4}\s*-\s*\d{4})\s*学年\s*第?\s*([一二三四1234])\s*学期\s*$',
  );

  static const Map<String, String> _termDigits = {
    '一': '1',
    '二': '2',
    '三': '3',
    '四': '4',
    '1': '1',
    '2': '2',
    '3': '3',
    '4': '4',
  };

  /// 规范化的学期标识，如 `2026-2027-1`。数据的隔离靠它。
  final String id;

  /// 展示名，如 `2026-2027学年1学期`。
  final String label;

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) => other is AcademicTerm && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
