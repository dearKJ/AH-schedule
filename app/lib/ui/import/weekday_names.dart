/// 导入这几页里**唯一**一份「星期几怎么写」。
///
/// 网格表头、格子那张单子的标题、编辑器的「位置」都要写星期几——各写一份，迟早会
/// 出现「星期三」与「周三」并存，或者某一份把 `weekday - 1` 写错。领域层里星期是
/// 1=星期一 … 7=星期日（`ClassSession.weekday`），这里只负责把它写成字。
///
/// 刻意不搬进 `core`：`CONTEXT.md` 里还没有「星期」这个词条（README 记了这个缺口，
/// 等 `/domain-modeling` 收），为三个字开一个公开 API 不划算。
library;

/// 写全：`星期一`。
String weekdayName(int weekday) => _fullNames[weekday - 1];

/// 简称，给网格表头那种一格只放得下一个字的地方用。
String weekdayShortName(int weekday) => _shortNames[weekday - 1];

const List<String> _fullNames = [
  '星期一',
  '星期二',
  '星期三',
  '星期四',
  '星期五',
  '星期六',
  '星期日',
];

const List<String> _shortNames = ['一', '二', '三', '四', '五', '六', '日'];
