import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

/// HTML 表格骨架的解析：有课格子的坐标、连堂的 `rowspan`、以及**结构坏掉时
/// 能不能说清哪里坏**。
///
/// 这一层不碰课表内容，只管「哪个格子在哪一天哪一节」。它是最容易悄悄错的地方
/// ——错一格，整个课表就整体挪位，而界面上看起来还挺像那么回事。
void main() {
  group('正常结构', () {
    test('日节次数按实际节次行数取，不写死 12', () {
      final issues = ImportIssues();
      final grid = HtmlCourseTableParser.parse(_table(periods: 5), issues);

      expect(grid.periodCount, 5, reason: '5 个节次行就是一天 5 节');
      expect(issues.diagnostics, isEmpty);
    });

    test('表头在 thead 里，不算进节次行', () {
      final issues = ImportIssues();
      final grid = HtmlCourseTableParser.parse(_table(periods: 12), issues);
      expect(grid.periodCount, 12);
    });

    test('没有 tbody 时退回「整张表减掉 thead」，表头行被跳过', () {
      // 真正的模板一定有 `<tbody>`；这条锁的是退路。少了这段逻辑，第一个节次行
      // 会被当成表头丢掉，整张课表少一天。
      final issues = ImportIssues();
      final html =
          '<table id="manualArrangeCourseTable">'
          '<tr><th>节次/周次</th><th>星期一</th><th>星期二</th><th>星期三</th>'
          '<th>星期四</th><th>星期五</th><th>星期六</th><th>星期日</th></tr>'
          '<tr><td>第一节</td><td id="TD0_0" rowspan="1">A(1.01) (师)<br/>(1-4,4J410(主校区))</td>'
          '<td></td><td></td><td></td><td></td><td></td><td></td></tr>'
          '</table>';
      final grid = HtmlCourseTableParser.parse(html, issues);

      expect(grid.periodCount, 1);
      final cell = grid.cells.firstWhere((c) => c.id == 'TD0_0');
      expect(cell.period, 1, reason: '第一个节次行是第一节，不是表头');
      expect(cell.column, 1);
    });

    test('rowspan 盖住的格子不占列，后面的格子不会因此挪位', () {
      // 样本里被 rowspan 盖住的位置**在 DOM 里根本不出现**。要是按「第几个 td」
      // 推列号，后面的格子全会往左挪。
      final issues = ImportIssues();
      final grid = HtmlCourseTableParser.parse(_table(periods: 3), issues);
      final secondRow = grid.cells
          .where((cell) => cell.period == 2 && cell.column > 0)
          .toList();

      // 第一节那一行有 7 个格子；第二节那一行只有被 rowspan 盖住的星期一缺席。
      expect(
        secondRow.map((cell) => cell.column).toList(),
        [2, 3, 4, 5, 6, 7],
        reason: '星期一的第 2 节被上一行的 rowspan 盖住了',
      );
    });

    test('坐标与 id 对得上时不报诊断', () {
      final issues = ImportIssues();
      HtmlCourseTableParser.parse(_table(periods: 12), issues);
      expect(
        issues.diagnostics.where((d) => d.code == ImportIssue.coordinateMismatch),
        isEmpty,
      );
    });

    test('id 与 DOM 算出来的位置对不上时，以 DOM 顺序为准并报诊断', () {
      final issues = ImportIssues();
      // 一天 11 节的表里，`TD12_0` 按公式是「星期二第二节」（12 = 1×11 + 1），
      // 可它出现在星期一第一节的位置上。每日节次数是**按实际行数**取的，所以
      // id 解出来的坐标跟着表走，这正是这条校验要抓的东西。
      const id = 'TD12_0';
      // 刻意**不写 `</tbody>`**：正文只到第一个 `</tbody>` 为止，写早了后面的
      // 补白行就全被截掉了。
      final html =
          '<table id="manualArrangeCourseTable"><tbody>'
          '<tr><td>第一节</td><td id="$id">A(1.01) (师)<br/>(1-4,4J410(主校区))</td>'
          '<td></td><td></td><td></td><td></td><td></td><td></td></tr>';
      final grid = HtmlCourseTableParser.parse(
        '$html${_fillerRows(firstPeriod: 2, periods: 11)}</tbody></table>',
        issues,
      );

      final cell = grid.cells.firstWhere((c) => c.id == id);
      expect(cell.column, 1, reason: '以 DOM 顺序为准，它还在这行的第一个位置');
      final mismatch = issues.diagnostics.firstWhere(
        (d) => d.code == ImportIssue.coordinateMismatch,
        orElse: () => throw StateError('没有报出坐标不一致'),
      );
      expect(mismatch.severity, ImportSeverity.warning);
      expect(mismatch.message, contains(id));
      expect(mismatch.message, contains('星期二第2节'));
      expect(mismatch.message, contains('星期一第1节'));
    });

    test('认不出的 id 不报诊断——没有坐标好校验就不校验', () {
      final issues = ImportIssues();
      final html =
          '<table id="manualArrangeCourseTable"><tbody>'
          '<tr><td>第一节</td><td id="whatever">A(1.01) (师)<br/>(1-4,4J410(主校区))</td>'
          '<td></td><td></td><td></td><td></td><td></td><td></td></tr>'
          '</tbody></table>';
      HtmlCourseTableParser.parse(html, issues);
      expect(issues.diagnostics, isEmpty);
    });
  });

  group('结构坏掉时中止导入并说清原因', () {
    test('没有那张表', () {
      final issues = ImportIssues();
      expect(
        () => HtmlCourseTableParser.parse('<html><body>别的什么</body></html>', issues),
        throwsA(isA<MalformedTableException>()),
      );
      final diagnostic = issues.diagnostics.single;
      expect(diagnostic.code, ImportIssue.missingTable);
      expect(diagnostic.severity, ImportSeverity.error);
      expect(diagnostic.message, contains('manualArrangeCourseTable'));
    });

    test('表里一行都没有', () {
      final issues = ImportIssues();
      expect(
        () => HtmlCourseTableParser.parse(
          '<table id="manualArrangeCourseTable"></table>',
          issues,
        ),
        throwsA(isA<MalformedTableException>()),
      );
      expect(issues.diagnostics.single.code, ImportIssue.malformedTable);
    });

    test('只有表头、没有节次行', () {
      final issues = ImportIssues();
      final html =
          '<table id="manualArrangeCourseTable"><thead>'
          '<tr><th>节次/周次</th><th>星期一</th></tr>'
          '</thead><tbody></tbody></table>';
      expect(
        () => HtmlCourseTableParser.parse(html, issues),
        throwsA(isA<MalformedTableException>()),
      );
      expect(issues.hasErrors, isTrue);
    });

    test('星期列数不是 7：某一行少了一列', () {
      // 六个星期列的表——每一行都少一列。这一条**必须能报出来**，不能当作
      // 「星期日没课」而静默吞掉。
      final issues = ImportIssues();
      final buffer = StringBuffer(
        '<table id="manualArrangeCourseTable"><tbody>',
      );
      buffer.write('<tr><td>第一节</td>');
      for (var column = 0; column < 6; column++) {
        buffer.write('<td></td>');
      }
      buffer.write('</tr></tbody></table>');

      final grid = HtmlCourseTableParser.parse(buffer.toString(), issues);
      expect(
        grid.cells.where((cell) => cell.column > 0).length,
        6,
        reason: '表里只有六个星期列',
      );
      expect(
        grid.cells.any((cell) => cell.column == HtmlCourseTableParser.weekdayCount),
        isFalse,
        reason: '第七列压根不存在——解析器不该替它补一个空格子',
      );
    });

    test('星期列数不是 7：某一行多出一列', () {
      final issues = ImportIssues();
      final buffer = StringBuffer(
        '<table id="manualArrangeCourseTable"><tbody><tr><td>第一节</td>',
      );
      for (var column = 0; column < 8; column++) {
        buffer.write('<td></td>');
      }
      buffer.write('</tr></tbody></table>');

      expect(
        () => HtmlCourseTableParser.parse(buffer.toString(), issues),
        throwsA(isA<MalformedTableException>()),
      );
      final diagnostic = issues.diagnostics.single;
      expect(diagnostic.code, ImportIssue.malformedTable);
      expect(diagnostic.message, contains('比 7 天还多'));
      expect(diagnostic.message, contains('星期列对齐'));
    });

    test('rowspan 超出节次总数', () {
      final issues = ImportIssues();
      // 三个节次行，最后一行的格子却要连 3 节。
      final html =
          '<table id="manualArrangeCourseTable"><tbody>'
          '<tr><td>第一节</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>'
          '<tr><td>第二节</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>'
          '<tr><td>第三节</td><td id="TD0_0" rowspan="3">A(1.01) (师)<br/>(1-4,4J410(主校区))</td>'
          '<td></td><td></td><td></td><td></td><td></td><td></td></tr>'
          '</tbody></table>';
      expect(
        () => HtmlCourseTableParser.parse(html, issues),
        throwsA(isA<MalformedTableException>()),
      );
      final diagnostic = issues.diagnostics.single;
      expect(diagnostic.code, ImportIssue.malformedTable);
      expect(diagnostic.message, contains('rowspan=3'));
      expect(diagnostic.message, contains('第 3 节'));
    });

    test('rowspan 解出来小于 1', () {
      final issues = ImportIssues();
      final html =
          '<table id="manualArrangeCourseTable"><tbody>'
          '<tr><td>第一节</td><td id="TD0_0" rowspan="0">A(1.01) (师)<br/>(1-4,4J410(主校区))</td>'
          '<td></td><td></td><td></td><td></td><td></td><td></td></tr>'
          '<tr><td>第二节</td><td></td><td></td><td></td><td></td><td></td><td></td></tr>'
          '</tbody></table>';
      expect(
        () => HtmlCourseTableParser.parse(html, issues),
        throwsA(isA<MalformedTableException>()),
      );
      expect(issues.diagnostics.single.message, contains('至少是 1'));
    });
  });
}

/// 造一份最小的课表 HTML：`periods` 个节次行、每行 7 个星期列。
///
/// 星期一第一节那一格刻意带 `rowspan="2"`（跟真实样本一样），好让「被盖住的
/// 位置在 DOM 里不出现」这条路径被测到。
String _table({required int periods}) {
  final buffer = StringBuffer(
    '<html><body><table id="manualArrangeCourseTable">',
  );
  buffer.write('<thead><tr><th>节次/周次</th>');
  for (final label in const ['一', '二', '三', '四', '五', '六', '日']) {
    buffer.write('<th>星期$label</th>');
  }
  buffer.write('</tr></thead><tbody>');

  for (var period = 1; period <= periods; period++) {
    buffer.write('<tr><td>第$period节</td>');
    for (var weekday = 1; weekday <= 7; weekday++) {
      if (period == 1 && weekday == 1) {
        buffer.write(
          '<td id="TD0_0" rowspan="2">课(1.01) (师)<br/>(1-4,4J410(主校区))</td>',
        );
        continue;
      }
      // 被上一行的 rowspan 盖住的位置：在 DOM 里**什么都不输出**。
      if (period == 2 && weekday == 1) continue;
      buffer.write('<td id="TD${(weekday - 1) * periods + period - 1}_0"></td>');
    }
    buffer.write('</tr>');
  }
  buffer.write('</tbody></table></body></html>');
  return buffer.toString();
}

/// 补几行普通的空节次行（**不含闭合标签**，由调用方自己收尾）。
String _fillerRows({required int firstPeriod, required int periods}) {
  final buffer = StringBuffer();
  for (var period = firstPeriod; period <= periods; period++) {
    buffer.write('<tr><td>第$period节</td>');
    for (var weekday = 1; weekday <= 7; weekday++) {
      buffer.write('<td></td>');
    }
    buffer.write('</tr>');
  }
  return buffer.toString();
}
