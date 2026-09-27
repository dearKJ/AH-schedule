/// 课表 JSON 反序列化的错误代码。[JsonError.code] 用它，测试也用它——比去匹配消息
/// 文本稳。
///
/// 与导入诊断（`import_diagnostics.dart`）刻意不同：导入的诊断是**一批**（一个格子
/// 解不出来不影响别的格子），而这里的错误是**一条**——课表 JSON 是一份整体契约，
/// 结构一坏就没什么可解的了，「哪一处最先坏」就是那条拦路的错误。
///
/// 刻意都是 `String` 而不是 enum：未知的代码不应该让解析器崩掉——它是数据，不是
/// 控制流。
abstract final class JsonIssue {
  /// 字节不是 UTF-8，解不出文本。
  static const String notUtf8 = 'not-utf8';

  /// 文本不是 JSON。
  static const String notJson = 'not-json';

  /// 是 JSON，但顶层不是一个对象。
  static const String notObject = 'not-object';

  /// 没有版本号——这不像是一份课表文件。
  static const String missingVersion = 'missing-version';

  /// 版本号认不出来（比本机认得的新，或者根本不是这份格式的版本号）。
  static const String unknownVersion = 'unknown-version';

  /// 缺字段。**必填字段**不在就是它；可选字段（教师、校区、第 1 周第一天、总周数）
  /// 不在是正常的。
  static const String missingField = 'missing-field';

  /// 字段在，但类型或取值不对。
  static const String badField = 'bad-field';

  /// 字段是个字符串，但那个字符串不认识（例外类型 `cancellation` /
  /// `onlineTeaching`、时段 `morning` / `afternoon` / `evening`）。
  static const String unknownValue = 'unknown-value';
}

/// 一条反序列化错误：**什么代码 + 给谁看的话 + 坏在哪一处**。
///
/// [path] 是坏掉那一处在文件里的位置（如 `sessions[3].weeks[0]`），是这份东西的
/// `rawText`——没有它，「文件里有个字段坏了」这句话使用者无从下手。
class JsonError {
  /// 校验代码与说明不为空白。
  factory JsonError({
    required String code,
    required String message,
    String? path,
  }) {
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      throw ArgumentError.value(code, 'code', '错误代码不能是空白');
    }
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw ArgumentError.value(message, 'message', '错误说明不能是空白');
    }
    return JsonError._(trimmedCode, trimmedMessage, path);
  }

  const JsonError._(this.code, this.message, this.path);

  /// 见 [JsonIssue]。
  final String code;

  /// 给人看的说明。
  final String message;

  /// 坏掉那一处在文件里的位置，如 `sessions[3].weeks[0]`；整份文件级别的问题
  /// （不是 UTF-8、不是 JSON、顶层不是对象）上是 null。**版本号不算整份文件级别**：
  /// 它就是 `version` 这一处，路径也就是 `version`。
  final String? path;

  @override
  String toString() => '[$code]${path == null ? '' : ' @$path'} $message';
}
