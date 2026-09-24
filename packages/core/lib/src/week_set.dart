import 'internal_helpers.dart';

/// 周次集合——周次**唯一**的内部表示。
///
/// 教务系统的四种写法（普通区间 / 单双周 / 断档周 / 特定周）都只是同一组周次的不同
/// **写法**，解析后一律落成这个集合；模型里不存在「这是单双周」这种类型。
/// 位图是教务系统的内部实现，这里不引入——集合就是去重升序的整数集合。
///
/// 术语见 `CONTEXT.md` 的「周次集合」。
class WeekSet {
  /// 从任意整数序列构造：自动去重、升序。校验周次落在 `1..maxWeek` 内。
  ///
  /// 传入空集合合法（表示什么周都不含），是否允许由使用方决定——
  /// [ClassSession] 就不接受空集合，因为一条永不出现的上课安排只会是静默失败。
  WeekSet(Iterable<int> weeks) : weeks = _normalize(weeks);

  /// 周次的上限。教务系统里周次是一个 53 位位图，超出的值只可能是解析出了错。
  static const int maxWeek = 53;

  /// 去重升序的周次。不可修改。
  final List<int> weeks;

  static List<int> _normalize(Iterable<int> weeks) {
    final sorted = weeks.toSet().toList()..sort();
    for (final week in sorted) {
      if (week < 1 || week > maxWeek) {
        throw ArgumentError.value(week, 'weeks', '周次必须在 1..$maxWeek 之间');
      }
    }
    return List.unmodifiable(sorted);
  }

  /// 集合里的周次个数。
  int get length => weeks.length;

  bool get isEmpty => weeks.isEmpty;

  bool get isNotEmpty => weeks.isNotEmpty;

  /// 最小的周次。空集合上调用会抛错。
  int get min => weeks.first;

  /// 最大的周次。空集合上调用会抛错。
  int get max => weeks.last;

  bool contains(int week) => weeks.contains(week);

  /// 反向生成人能读的写法，用于回填编辑框。
  ///
  /// 连续段写成 `1-8`，多段之间用空格分隔（与教务系统的断档周写法一致）；
  /// 若整个集合正好是间隔为 2 的等差数列（且至少三个），写成
  /// `单周第5周-第15周` / `双周第4周-第12周`——这样编辑一条导入的安排时，
  /// 它原来在教务系统里的写法不会被抹掉。空集合写成空串。
  String toText() {
    if (weeks.isEmpty) return '';
    if (_isEveryOtherWeek) {
      final prefix = weeks.first.isOdd ? '单周' : '双周';
      return '$prefix第${weeks.first}周-第${weeks.last}周';
    }

    final parts = <String>[];
    var runStart = weeks.first;
    var previous = weeks.first;
    for (final week in weeks.skip(1)) {
      if (week == previous + 1) {
        previous = week;
        continue;
      }
      parts.add(_renderRun(runStart, previous));
      runStart = previous = week;
    }
    parts.add(_renderRun(runStart, previous));
    return parts.join(' ');
  }

  bool get _isEveryOtherWeek {
    if (weeks.length < 3) return false;
    final parity = weeks.first.isOdd;
    for (var i = 0; i < weeks.length; i++) {
      final week = weeks[i];
      if (week != weeks.first + i * 2 || week.isOdd != parity) return false;
    }
    return true;
  }

  static String _renderRun(int start, int end) =>
      start == end ? '$start' : '$start-$end';

  /// 解析教务系统那套周次写法：`1-8 10 12-16`、`第4周-第10周 第12周-第18周`、
  /// `单周第5周-第15周`、`双周第4周-第12周`、`第12周`。
  ///
  /// 宽容：容忍全角数字与全角标点、多余空格、缺「第」「周」字。单双周取区间内
  /// 的奇数周 / 偶数周（`单周第4周-第10周` 因此得到第 5、7、9 周）。
  ///
  /// 认不出来、起止颠倒、超出 [maxWeek]、以及某一段一个周次都取不到时抛
  /// [FormatException]——**不静默产出空集合**。调用方（导入解析）负责把异常
  /// 转成诊断条目；解析器的错误是返回值的一部分，而这里只是领域层的一层校验。
  static WeekSet parse(String text) {
    final normalized = _normalizeText(text);
    if (normalized.isEmpty) {
      throw FormatException('周次写法是空的', text);
    }

    final weeks = <int>{};
    for (final token in normalized.split(RegExp(r'[\s,]+'))) {
      if (token.isEmpty) continue;
      weeks.addAll(_parseSegment(token, text));
    }
    if (weeks.isEmpty) {
      throw FormatException('周次写法认不出来：「$text」', text);
    }
    return WeekSet(weeks);
  }

  /// [parse] 的宽容版：认不出来时返回 null。
  static WeekSet? tryParse(String text) {
    try {
      return parse(text);
    } on FormatException {
      return null;
    }
  }

  /// 把全角数字、全角空格、全角逗号、顿号与各种破折号拉平成 ASCII 写法。
  static String _normalizeText(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune >= 0xFF10 && rune <= 0xFF19) {
        buffer.writeCharCode(rune - 0xFF10 + 0x30); // 全角数字 ０-９
        continue;
      }
      final replacement = switch (rune) {
        0x3000 => ' ', // 全角空格
        0xFF0C || 0x3001 => ',', // 全角逗号、顿号
        0x2013 || 0x2014 || 0xFF5E || 0x301C => '-', // – — ～ 〜
        _ => null,
      };
      if (replacement != null) {
        buffer.write(replacement);
        continue;
      }
      buffer.writeCharCode(rune);
    }
    return buffer.toString().replaceAll(RegExp(r'\s*-\s*'), '-').trim();
  }

  static List<int> _parseSegment(String token, String original) {
    var body = token;
    bool? oddOnly;
    if (body.startsWith('单') || body.startsWith('双')) {
      oddOnly = body.startsWith('单');
      body = body.substring(1);
      if (body.startsWith('周')) body = body.substring(1);
    }
    body = body.replaceAll('第', '').replaceAll('周', '');

    final match = RegExp(r'^(\d+)(?:-(\d+))?$').firstMatch(body);
    if (match == null) {
      throw FormatException('周次写法认不出来：「$token」', original);
    }
    final start = int.tryParse(match.group(1)!);
    final end = match.group(2) == null ? start : int.tryParse(match.group(2)!);
    if (start == null || end == null || start < 1 || end > maxWeek) {
      throw FormatException('周次超出 1..$maxWeek：「$token」', original);
    }
    if (end < start) {
      throw FormatException('周次的起止颠倒了：「$token」', original);
    }

    final weeks = <int>[];
    for (var week = start; week <= end; week++) {
      if (oddOnly == null || week.isOdd == oddOnly) weeks.add(week);
    }
    if (weeks.isEmpty) {
      throw FormatException('这一周次段里一个周次都没有：「$token」', original);
    }
    return weeks;
  }

  /// [toText] 的产物，方便调试。
  @override
  String toString() => 'WeekSet(${weeks.join(',')})';

  @override
  bool operator ==(Object other) =>
      other is WeekSet && listEquals(other.weeks, weeks);

  @override
  int get hashCode => Object.hashAll(weeks);
}
