/// 一天之内的时刻，精确到分。
///
/// 作息时间表里「节次 → 时刻」的映射用它表示。对外写作 `HH:mm`（如 `08:00`），
/// 解析时宽容地接受 `8:00`、全角冒号、以及带秒的 `08:00:00`。
class ClockTime implements Comparable<ClockTime> {
  /// 校验时刻落在一天之内。
  factory ClockTime(int hour, int minute) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', '小时必须在 0..23 之间');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute', '分钟必须在 0..59 之间');
    }
    return ClockTime._(hour, minute);
  }

  const ClockTime._(this.hour, this.minute);

  /// 解析 `HH:mm`。宽容地容忍缺前导零、全角冒号、多余空格与尾随的秒。
  ///
  /// 认不出来或超出一天的范围时抛 [FormatException]。
  static ClockTime parse(String text) {
    var body = text.trim().replaceAll('：', ':');
    if (body.contains(':')) body = body.split(':').take(2).join(':');
    final match = RegExp(r'^(\d{1,2}):(\d{1,2})$').firstMatch(body);
    if (match == null) {
      throw FormatException('时刻写法认不出来：「$text」', text);
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) {
      throw FormatException('时刻超出一天的范围：「$text」', text);
    }
    return ClockTime(hour, minute);
  }

  /// [parse] 的宽容版：认不出来时返回 null。
  static ClockTime? tryParse(String text) {
    try {
      return parse(text);
    } on FormatException {
      return null;
    }
  }

  final int hour;
  final int minute;

  /// 自 00:00 起的分钟数。
  int get minutesSinceMidnight => hour * 60 + minute;

  /// 写成 `HH:mm`。
  String toText() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(ClockTime other) =>
      minutesSinceMidnight - other.minutesSinceMidnight;

  @override
  String toString() => toText();

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}
