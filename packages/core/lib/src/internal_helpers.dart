/// 领域层的内部小工具。不对外导出。
///
/// 自己写这几行，是为了让 core 保持**零运行期依赖**——为 `listEquals` 或
/// `trimmedOrNull` 引入一个包，不值得。
library;

/// 列表的逐元素相等。值对象的 `==` 都用它。
bool listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// 把空白文本归一成 null。
///
/// 「没有教师」与「教师是空串」在导出文件里是同一个东西（`()`），在手动录入时不填
/// 也是同一个东西，模型里因此只留 null 一种表示——否则相等判断与序列化都要多分一
/// 支支路。
String? trimmedOrNull(String? text) {
  final trimmed = text?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
