import 'import_diagnostics.dart';

/// 教务系统导出的课表里那张表的 id。**定位整张课表靠它**——一份导出里不止一张表
/// （后面还有授课计划表、课程小结表），按「第几张表」找会找错。
const String courseTableId = 'manualArrangeCourseTable';

/// 把 HTML 里那张课表解成**逻辑网格**。
///
/// 导出文件的表格不是规整的：`rowspan` 覆盖到的那些格子**在 DOM 里根本不出现**
/// （被盖住的位置既不输出 `<td>` 也不输出占位符），所以「第几个 `<td>`」推不出
/// 列号。做法是：
///
/// 1. 按 DOM 顺序走每个行，维护一张「被上面的 `rowspan` 占住的位置」的表；
/// 2. 每遇到一个 `<td>`，落到本行**第一个没被占住**的位置；
/// 3. 再拿 `id="TD{n}_{m}"` 反推出来的坐标**交叉校验**——正文里那套坐标是教务系统
///    自己给的，两条独立的路对上了才算稳。对不上就记一条
///    [ImportIssue.coordinateMismatch]，但**以 DOM 顺序为准**：`id` 只是个提示。
///
/// 结构对不上（行数不足、某行列数不是 7、`rowspan` 越界）时抛
/// [MalformedTableException]——这一层中止导入，由 [TimetableImporter] 转成诊断。
abstract final class HtmlCourseTableParser {
  /// 一天有几天。教务系统的表恒为 7 列（星期一…星期日）。
  static const int weekdayCount = 7;

  /// 从 [html] 里解出逻辑网格。
  ///
  /// [issues] 收下这层的全部诊断，**包括中止导入时的结构问题**。
  static GridTable parse(String html, ImportIssues issues) {
    final body = _extractTableBody(html);
    if (body == null) {
      issues.add(
        ImportDiagnostic(
          code: ImportIssue.missingTable,
          severity: ImportSeverity.error,
          message:
              '这份文件里没有找到 id="$courseTableId" 的表格，'
              '不像教务系统的课表导出',
        ),
      );
      throw const MalformedTableException('找不到课表那张表');
    }

    return _buildGrid(body, issues);
  }

  /// 抠出课表里**节次行**那一段，以及里面**有没有表头行**。
  ///
  /// 「有没有表头行」是要紧的：真正的模板把表头放在 `<thead>` 里，抠出来的
  /// `<tbody>` **整段都是节次行**；退路那种写法（没有 `<tbody>`）则第一个 `<tr>`
  /// 就是表头。两种情况差一行，把日节次数算错一格，坐标校验会全错位。
  ///
  /// 没有这张表时返回 null。
  static _TableBody? _extractTableBody(String html) {
    final openTag = RegExp(
      "<table\\b[^>]*\\bid\\s*=\\s*[\"']?$courseTableId[\"']?[^>]*>",
      caseSensitive: false,
    ).firstMatch(html);
    if (openTag == null) return null;

    final rest = html.substring(openTag.end);
    final closeTag = rest.indexOf('</table>');
    final tableHtml = closeTag < 0 ? rest : rest.substring(0, closeTag);

    // **必须只取这个 `<tbody>`**：一份导出里后面还有授课计划表、课程小结表，它们
    // 也有 `<tr>`。曾经写成「`<tbody>` 之后的全部内容」，结果后面那张表的行也被算
    // 进课表，日节次数整个错位。
    final tbody = _contentOfTag(tableHtml, 'tbody');
    if (tbody != null) return _TableBody(tbody, hasHeaderRow: false);

    return _TableBody(_withoutTag(tableHtml, 'thead'), hasHeaderRow: true);
  }

  /// `<tagName>…</tagName>` 之间的内容；没有这一对标签时返回 null。
  static String? _contentOfTag(String html, String tagName) {
    final open = RegExp(
      '<$tagName\\b[^>]*>',
      caseSensitive: false,
    ).firstMatch(html);
    if (open == null) return null;
    final close = RegExp(
      '</$tagName\\s*>',
      caseSensitive: false,
    ).firstMatch(html.substring(open.end));
    if (close == null) return null;
    return html.substring(open.end, open.end + close.start);
  }

  /// 去掉 `<tagName>…</tagName>` 这一整段。
  static String _withoutTag(String html, String tagName) {
    final block = RegExp(
      '<$tagName\\b[^>]*>.*?</$tagName\\s*>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    if (block == null) return html;
    return html.substring(0, block.start) + html.substring(block.end);
  }

  /// 按 DOM 顺序铺出逻辑网格。
  static GridTable _buildGrid(_TableBody body, ImportIssues issues) {
    final rows = RegExp(
      r'<tr\b[^>]*>(.*?)</tr>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(body.html).toList();
    if (rows.isEmpty) {
      issues.add(
        ImportDiagnostic(
          code: ImportIssue.malformedTable,
          severity: ImportSeverity.error,
          message: '课表那张表里一行都没有',
        ),
      );
      throw const MalformedTableException('表格里没有行');
    }

    // 表头那一行不在网格里——它在 `<thead>` 里，而 [body] 只给了节次那一段。
    // 退路那种写法（没有 `<tbody>`）才需要跳过第一个 `<tr>`。
    final firstRow = body.hasHeaderRow ? 1 : 0;
    final bodyRows = rows.length - firstRow;
    if (bodyRows < 1) {
      issues.add(
        ImportDiagnostic(
          code: ImportIssue.malformedTable,
          severity: ImportSeverity.error,
          message: '课表那张表只有表头、没有节次行',
        ),
      );
      throw const MalformedTableException('表格只有表头');
    }

    final cells = <GridCell>[];
    // 被上面 rowspan 占住的位置：carried[row] 是这一行里「不用再放 <td>」的列号集合。
    // 下标按 [rows] 来，好跟后面的循环对上。
    final carried = <Set<int>>[
      for (var row = 0; row < rows.length; row++) <int>{},
    ];

    for (var row = firstRow; row < rows.length; row++) {
      // 节次是**从 1 开始**的：第一节的 `row` 是 `firstRow`，所以减掉它再加一。
      final period = row - firstRow + 1;
      final rowHtml = rows[row].group(1)!;
      final tdTags = RegExp(
        r'<td\b([^>]*)>(.*?)</td>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(rowHtml).toList();

      var column = 0;
      for (final td in tdTags) {
        final attributes = td.group(1)!;
        while (column < weekdayCount + 1 && carried[row].contains(column)) {
          column++;
        }
        if (column >= weekdayCount + 1) {
          // 一行里格子比 7 天还多。这不是「某一列多了个空格子」那么轻——列对齐
          // 从这里起就不可信了，接着解会把后面所有格子都挪位。
          issues.add(
            ImportDiagnostic(
              code: ImportIssue.malformedTable,
              severity: ImportSeverity.error,
              message:
                  '第 $period 节这一行里格子比 $weekdayCount 天还多，'
                  '星期列对齐不可信',
              period: period,
            ),
          );
          throw const MalformedTableException('一行里的格子超过 7 天');
        }

        final rowSpan = _intAttribute(attributes, 'rowspan') ?? 1;
        if (rowSpan < 1) {
          issues.add(
            ImportDiagnostic(
              code: ImportIssue.malformedTable,
              severity: ImportSeverity.error,
              message: 'rowspan 解出来是 $rowSpan，至少是 1',
              period: period,
            ),
          );
          throw const MalformedTableException('rowspan 小于 1');
        }
        if (row + rowSpan > rows.length) {
          issues.add(
            ImportDiagnostic(
              code: ImportIssue.malformedTable,
              severity: ImportSeverity.error,
              message:
                  '第 $period 节的 rowspan=$rowSpan 跨过了最后一行'
                  '（连堂最多到第 $bodyRows 节）',
              period: period,
            ),
          );
          throw const MalformedTableException('rowspan 越过了最后一行');
        }

        final id = _stringAttribute(attributes, 'id');
        final expected = _coordinateFromId(id, bodyRows);
        if (expected != null &&
            (expected.period != period || expected.column != column)) {
          issues.add(
            ImportDiagnostic(
              code: ImportIssue.coordinateMismatch,
              severity: ImportSeverity.warning,
              message:
                  'id="$id" 说这个格子在'
                  '${_describe(expected.period, expected.column)}，'
                  '但 DOM 顺序算出它在'
                  '${_describe(period, column)}——以 DOM 顺序为准',
              period: period,
            ),
          );
        }

        cells.add(
          GridCell(
            period: period,
            column: column,
            rowSpan: rowSpan,
            id: id,
            rawText: td.group(2)!,
          ),
        );

        for (var offset = 1; offset < rowSpan; offset++) {
          carried[row + offset].add(column);
        }
        column++;
      }
    }

    if (cells.isEmpty) {
      // 文件里找到了那张表，但表里一个格子都没有——这不是「课表是空的」，
      // 是这份文件不像导出。
      issues.add(
        ImportDiagnostic(
          code: ImportIssue.missingTable,
          severity: ImportSeverity.error,
          message: 'id="$courseTableId" 那张表里一个格子都没有',
        ),
      );
      throw const MalformedTableException('表格里没有格子');
    }

    return GridTable(periodCount: bodyRows, cells: cells);
  }

  /// 从 `TD{n}_{m}` 里反推坐标。**用带名字的记录返回**，好让调用处没法把列与行
  /// 写反——写反的后果不是报错，是交叉校验**永远通过**，看起来一切正常。
  ///
  /// `n = 星期序号 × 每日节次数 + 节次序号`：**商是星期、余数是节次**。样本里实测
  /// `TD0_0` = 星期一第一节、`TD12_0` = 星期二第一节（12 = 1×12 + 0）、`TD2_0` =
  /// 星期一第三节。`m` 在样本里恒为 0、含义未知，**不参与**。每日节次数由**实际
  /// 节次行数**给出（[GridTable.periodCount]），不写死 12。
  ///
  /// 解不出来（没 id、格式不是这样、m 不是 0、算出来的星期超出 7 天）时返回 null
  /// ——**没有坐标好校验就不校验**，不能因为一个认不出的 id 就报布局错误。
  static ({int column, int period})? _coordinateFromId(
    String? id,
    int periodCount,
  ) {
    if (id == null || periodCount < 1) return null;
    final match = RegExp(r'^TD(\d+)_(\d+)$').firstMatch(id.trim());
    if (match == null) return null;
    final n = int.tryParse(match.group(1)!);
    final m = int.tryParse(match.group(2)!);
    if (n == null || m == null || m != 0) return null;

    final weekdayIndex = n ~/ periodCount;
    if (weekdayIndex >= weekdayCount) return null;
    return (column: weekdayIndex + 1, period: n % periodCount + 1);
  }

  static String _describe(int period, int column) {
    if (column < 1 || column > weekdayCount) return '第 $period 节第 $column 列';
    return '${_weekdayColumnLabels[column - 1]}第$period节';
  }

  /// 从标签属性里解出整数；没有或解不出时返回 null。
  static int? _intAttribute(String attributes, String name) {
    final raw = _stringAttribute(attributes, name);
    return raw == null ? null : int.tryParse(raw.trim());
  }

  /// 从标签属性里解出字符串；没有时返回 null。
  static String? _stringAttribute(String attributes, String name) {
    final match = RegExp(
      '\\b$name\\s*=\\s*(?:"([^"]*)"|\'([^\']*)\'|([^\\s>]+))',
      caseSensitive: false,
    ).firstMatch(attributes);
    if (match == null) return null;
    return match.group(1) ?? match.group(2) ?? match.group(3);
  }
}

/// 列下标（1..7）到星期几的写法，只为把诊断写清楚。
const List<String> _weekdayColumnLabels = [
  '星期一',
  '星期二',
  '星期三',
  '星期四',
  '星期五',
  '星期六',
  '星期日',
];

/// 表结构对不上——导入在**这一层**中止，由调用方转成诊断。
class MalformedTableException implements Exception {
  const MalformedTableException(this.message);

  final String message;

  @override
  String toString() => 'MalformedTableException($message)';
}

/// 课表的**逻辑网格**：把 `rowspan` 折进去之后的「哪一行哪一列是哪个格子」。
class GridTable {
  GridTable({required this.periodCount, required List<GridCell> cells})
    : cells = List.unmodifiable(cells);

  /// 每日节次数——**按实际节次行数取，不写死 12**。
  final int periodCount;

  /// 全部格子，按 DOM 顺序。
  final List<GridCell> cells;
}

/// 从 HTML 里抠出来的「节次行那一段」，外加它里面有没有表头行。
class _TableBody {
  const _TableBody(this.html, {required this.hasHeaderRow});

  final String html;

  /// 这段 HTML 的第一个 `<tr>` 是不是表头。见 `_extractTableBody` 的说明。
  final bool hasHeaderRow;
}

/// 逻辑网格里的一个格子。
class GridCell {
  const GridCell({
    required this.period,
    required this.column,
    required this.rowSpan,
    required this.id,
    required this.rawText,
  });

  /// **起始节次**，从 1 开始。表头那一行不在网格里，所以第一节就是 1。
  final int period;

  /// 列下标：0 是节次列，1 是星期一 … 7 是星期日。
  final int column;

  /// 跨几行（连堂几节）。
  final int rowSpan;

  /// `id` 属性。没有时是 null。
  final String? id;

  /// 格子的原始 HTML 正文（还没去标签、还没解）。诊断里的「原文」用它。
  final String rawText;

  /// 这个格子在哪一天：1 = 星期一 … 7 = 星期日。节次列（column 0）上是 null。
  int? get weekday => column == 0 ? null : column;

  @override
  String toString() =>
      'GridCell(第$period节, 列$column, rowspan=$rowSpan'
      '${id == null ? '' : ', id=$id'})';
}

/// 一路收集诊断，按**产生顺序**存着——顺序本身有意义（解码在最前、结构问题在后），
/// 丢掉顺序就没法解释「为什么先报了这条」。
class ImportIssues {
  final List<ImportDiagnostic> _diagnostics = [];

  /// 收下一条诊断。
  void add(ImportDiagnostic diagnostic) => _diagnostics.add(diagnostic);

  /// 到目前已收下的全部诊断。不返回内部列表本身。
  List<ImportDiagnostic> get diagnostics =>
      List<ImportDiagnostic>.unmodifiable(_diagnostics);

  /// 有没有出错级别的诊断。
  bool get hasErrors =>
      _diagnostics.any((d) => d.severity == ImportSeverity.error);

  bool get isEmpty => _diagnostics.isEmpty;

  int get length => _diagnostics.length;
}
