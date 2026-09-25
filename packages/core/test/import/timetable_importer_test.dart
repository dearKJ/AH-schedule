import 'dart:convert';
import 'dart:typed_data';

import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

/// 导入的入口：**错误也要有明确出口**。
///
/// 这一组测试盯的是规格里那条最要紧的话——「**静默失败是最糟的结果**」。所以每个
/// 坏输入都问同一件事：它有没有明确说出来？还是悄悄给了用户一张空课表？
void main() {
  final term = AcademicTerm(id: '2026-2027-1', label: '2026-2027学年1学期');

  TimetableImportResult run(String text) =>
      TimetableImporter.importText(text, term: term);

  group('输入根本不像课表时，返回明确错误', () {
    test('空文件（0 字节）', () {
      final result = TimetableImporter.importBytes(
        Uint8List(0),
        term: term,
      );
      final diagnostic = result.diagnostics.single;
      expect(diagnostic.code, ImportIssue.emptyFile);
      expect(diagnostic.severity, ImportSeverity.error);
      expect(result.hasUnparsableContent, isTrue);
      expect(result.timetable.sessions, isEmpty);
    });

    test('超过大小上限的文件', () {
      final result = TimetableImporter.importBytes(
        Uint8List(ImportLimits.maxBytes + 1),
        term: term,
      );
      final diagnostic = result.diagnostics.single;
      expect(diagnostic.code, ImportIssue.fileTooLarge);
      expect(diagnostic.severity, ImportSeverity.error);
      expect(result.timetable.sessions, isEmpty);
    });

    test('不是 HTML：纯文本', () {
      final result = run('这是一份随便的文本，不是 HTML');
      final diagnostic = result.diagnostics.single;
      expect(diagnostic.code, ImportIssue.missingTable);
      expect(diagnostic.severity, ImportSeverity.error);
    });

    test('是 HTML，但没有课表那张表', () {
      final result = run(
        '<html><body><h1>个人课程表</h1>'
        '<table id="someOtherTable"><tr><td>别的表</td></tr></table>'
        '</body></html>',
      );
      final diagnostic = result.diagnostics.single;
      expect(diagnostic.code, ImportIssue.missingTable);
      expect(diagnostic.severity, ImportSeverity.error);
      expect(diagnostic.message, contains('manualArrangeCourseTable'));
    });

    test('有那张表，但没有表头/节次行', () {
      final result = run(
        '<table id="manualArrangeCourseTable"><thead>'
        '<tr><th>节次/周次</th></tr></thead><tbody></tbody></table>',
      );
      expect(result.hasUnparsableContent, isTrue);
      expect(result.timetable.sessions, isEmpty);
      expect(result.withCode(ImportIssue.malformedTable), isNotEmpty);
    });

    test('**以上任何一条都不许静默产出一张空课表**', () {
      // 这一条是把上面几条的意思说穿：空课表 + 没有出错诊断 = 静默失败。
      for (final bad in [
        '',
        '随便的文本',
        '<html><body>没有表</body></html>',
        '<table id="manualArrangeCourseTable"></table>',
      ]) {
        final result = run(bad);
        expect(
          result.hasUnparsableContent,
          isTrue,
          reason: '输入「$bad」应当报错，而不是给一张安静的空课表',
        );
      }
    });
  });

  group('合法但空的课表是合法结果，只是值得说一声', () {
    test('13 行 × 8 列的表，一格有内容的都没有', () {
      final buffer = StringBuffer(
        '<table id="manualArrangeCourseTable">'
        '<thead><tr><th>节次/周次</th>',
      );
      for (final label in const ['一', '二', '三', '四', '五', '六', '日']) {
        buffer.write('<th>星期$label</th>');
      }
      buffer.write('</tr></thead><tbody>');
      for (var period = 1; period <= 12; period++) {
        buffer.write('<tr><td>第$period节</td>');
        for (var weekday = 1; weekday <= 7; weekday++) {
          buffer.write('<td id="TD${(weekday - 1) * 12 + period - 1}_0"></td>');
        }
        buffer.write('</tr>');
      }
      buffer.write('</tbody></table>');

      final result = run(buffer.toString());
      expect(result.timetable.sessions, isEmpty);
      expect(
        result.hasUnparsableContent,
        isFalse,
        reason: '空课表不是错误',
      );
      final diagnostic = result.diagnostics.single;
      expect(diagnostic.code, ImportIssue.emptyTimetable);
      expect(diagnostic.severity, ImportSeverity.warning);
    });
  });

  group('诊断是返回值的一部分', () {
    test('解不出来的格子：诊断**不会被丢掉**，且带着位置与原文', () {
      final result = run(
        '<table id="manualArrangeCourseTable"><tbody>'
        '<tr><td>第一节</td>'
        '<td id="TD0_0">这一格的正文不是排课格式</td>'
        '<td></td><td></td><td></td><td></td><td></td><td></td></tr>'
        '<tr><td>第二节</td>'
        '<td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>'
        '</tbody></table>',
      );

      expect(result.hasUnparsableContent, isTrue);
      expect(result.timetable.sessions, isEmpty);
      final diagnostic = result.errors.single;
      expect(diagnostic.code, ImportIssue.unparsableCell);
      expect(diagnostic.positionLabel, '星期一第1节');
      expect(diagnostic.rawText, contains('这一格的正文不是排课格式'));
      expect(diagnostic.weekday, 1);
      expect(diagnostic.period, 1);
    });

    test('解出来的那部分照常返回，与诊断并存', () {
      final result = run(
        '<table id="manualArrangeCourseTable"><tbody>'
        '<tr><td>第一节</td>'
        '<td id="TD0_0">好课(1.01) (师)<br/>(1-8,4J410(主校区))</td>'
        '<td id="TD12_0">这一格解不出来</td>'
        '<td></td><td></td><td></td><td></td><td></td></tr>'
        '<tr><td>第二节</td>'
        '<td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>'
        '</tbody></table>',
      );

      expect(result.timetable.sessions, hasLength(1));
      expect(result.timetable.sessions.single.courseName, '好课');
      expect(result.hasUnparsableContent, isTrue);
      expect(result.errors, hasLength(1));
      expect(result.errors.single.positionLabel, '星期二第1节');
    });

    test('errors 与 warnings 分开取', () {
      final result = run(
        '<table id="manualArrangeCourseTable"><tbody>'
        '<tr><td>第一节</td>'
        '<td id="TD0_0">这一格解不出来</td>'
        '<td></td><td></td><td></td><td></td><td></td><td></td></tr>'
        '<tr><td>第二节</td>'
        '<td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>'
        '</tbody></table>',
      );
      expect(result.errors, hasLength(1));
      expect(result.warnings, isEmpty);
      expect(result.errors.single.isError, isTrue);
    });
  });

  group('解码', () {
    test('坏字节 → 一条诊断（只报一次，不是一格一条）', () {
      // 这份 HTML 全是 ASCII（CP936 与 ASCII 一致），只在格子正文里塞一个
      // `0x80`——它在 CP936 里没有合法的单字节含义。
      final bytes = <int>[
        ...utf8.encode(
          '<table id="manualArrangeCourseTable"><tbody>'
          '<tr><td>p1</td><td id="TD0_0">Math',
        ),
        0x80,
        ...utf8.encode(
          '(1.01) (T)<br/>(1-8,4J410(Main))</td>'
          '<td></td><td></td><td></td><td></td><td></td><td></td></tr>'
          '<tr><td>p2</td>'
          '<td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>'
          '</tbody></table>',
        ),
      ];

      final result = TimetableImporter.importBytes(
        Uint8List.fromList(bytes),
        term: term,
      );
      final unmapped = result.withCode(ImportIssue.unmappedByte);
      expect(unmapped, hasLength(1));
      expect(unmapped.single.severity, ImportSeverity.warning);
      expect(unmapped.single.byteOffset, isNotNull);
      expect(unmapped.single.message, contains('1 个字节'));
      // 坏字节只影响那一个格子，别的照常导入。
      expect(result.timetable.sessions, hasLength(1));
      expect(
        result.hasUnparsableContent,
        isFalse,
        reason: '坏字节是提示级的——课表还是导进来了',
      );
    });

    test('ASCII 输入照样能导入', () {
      final result = TimetableImporter.importBytes(
        Uint8List.fromList(
          utf8.encode(
            '<table id="manualArrangeCourseTable"><tbody>'
            '<tr><td>p1</td>'
            '<td id="TD0_0">Math(1.01) (T)<br/>(1-8,4J410(Main))</td>'
            '<td></td><td></td><td></td><td></td><td></td><td></td></tr>'
            '<tr><td>p2</td>'
            '<td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>'
            '</tbody></table>',
          ),
        ),
        term: term,
      );
      expect(result.hasUnparsableContent, isFalse);
      expect(result.timetable.sessions.single.courseName, 'Math');
      expect(result.timetable.sessions.single.venue.room, '4J410');
    });
  });

  group('课表挂到哪个学年学期，是调用方给的', () {
    test('term 原样落到 Timetable 上', () {
      final result = run('<table id="manualArrangeCourseTable"></table>');
      expect(result.timetable.term, term);
    });

    test('settings 传进去就落上去，不传就是默认的', () {
      final settings = TermSettings(totalWeeks: 18);
      final withSettings = TimetableImporter.importText(
        '<table id="manualArrangeCourseTable"></table>',
        term: term,
        settings: settings,
      );
      expect(withSettings.timetable.settings.totalWeeks, 18);

      final withoutSettings = run('<table id="manualArrangeCourseTable"></table>');
      expect(withoutSettings.timetable.settings.totalWeeks, isNull);
    });
  });
}
