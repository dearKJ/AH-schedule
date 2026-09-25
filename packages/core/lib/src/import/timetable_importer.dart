import 'dart:typed_data';

import '../academic_term.dart';
import '../class_session.dart';
import '../term_settings.dart';
import '../timetable.dart';
import 'class_session_builder.dart';
import 'gbk_codec.dart';
import 'html_course_table.dart';
import 'import_diagnostics.dart';

/// 导入的入口：把导出文件的**原始字节**变成一张课表加一份诊断清单。
///
/// 这是整个 App 最确定的一段——那份 `.xls` 其实是一份 **GBK 编码的 HTML**，
/// 所以先按 GBK 解码、再当 HTML 解析，**不需要任何 Excel 解析库**。解析规格的
/// 权威出处是 `docs/reference/ahpu-jwxt-export-format.md`。
///
/// **诊断是返回值的一部分，不是异常。** 除了「文件根本不是这份东西」（空、太大、
/// 没有那张表）算调用失败，其余一律返回「能解出来的课表 + 一份说清哪里没解出来的
/// 清单」。静默失败是最糟的结果——它比「解析成功」还重要。
abstract final class TimetableImporter {
  /// 从 [bytes] 导入。**不抛异常**（除了领域模型自己的参数校验）：
  /// 输入不像导出文件时也返回一个结果，只是它的诊断里躺着一条出错条目。
  ///
  /// [term] 是这份课表挂在哪个学年学期上。**导出文件里的学期名只当参考**——
  /// 它写作 `2026-2027学年第一学期`，而且学期本身常常是用户自己选的。真正定
  /// 归属的是这个参数：认错学期等于把课表挂到别的学期上，比报错糟得多。
  ///
  /// [settings] 是学期设置（第 1 周的第一天、总周数、作息时间表）。导出文件里
  /// 既没有学期起止日期也没有总周数，只能由使用者自己填，所以留了默认值。
  static TimetableImportResult importBytes(
    Uint8List bytes, {
    required AcademicTerm term,
    TermSettings? settings,
  }) {
    final issues = ImportIssues();

    if (bytes.isEmpty) {
      issues.add(
        ImportDiagnostic(
          code: ImportIssue.emptyFile,
          severity: ImportSeverity.error,
          message: '文件是空的（0 字节）',
        ),
      );
      return TimetableImportResult(
        timetable: Timetable(term: term, settings: settings),
        diagnostics: issues.diagnostics,
      );
    }

    if (bytes.length > ImportLimits.maxBytes) {
      issues.add(
        ImportDiagnostic(
          code: ImportIssue.fileTooLarge,
          severity: ImportSeverity.error,
          message:
              '文件有 ${bytes.length} 字节，超过导入上限 '
              '${ImportLimits.maxBytes} 字节——这不像是一份课表导出',
        ),
      );
      return TimetableImportResult(
        timetable: Timetable(term: term, settings: settings),
        diagnostics: issues.diagnostics,
      );
    }

    final decoded = GbkCodec.decode(bytes);
    _reportUnmappedBytes(decoded, issues);

    return importText(
      decoded.text,
      term: term,
      settings: settings,
      issues: issues,
    );
  }

  /// 从**已解码**的 HTML 文本导入。给测试与「文本是从别处来的」这类情形用。
  static TimetableImportResult importText(
    String html, {
    required AcademicTerm term,
    TermSettings? settings,
    ImportIssues? issues,
  }) {
    final collected = issues ?? ImportIssues();
    final sessions = <ClassSession>[];

    try {
      final table = HtmlCourseTableParser.parse(html, collected);
      sessions.addAll(
        ClassSessionBuilder.build(table: table, issues: collected),
      );
    } on MalformedTableException {
      // 结构对不上时解析器已经把诊断记下了（`HtmlCourseTableParser.parse` 在抛
      // 之前先写诊断），这里只负责把导入停在这一层——产一张空课表出去就是静默
      // 失败。
    }

    if (sessions.isEmpty && !collected.hasErrors) {
      // 结构没问题、也没有解不出来的格子，就是一条安排都没有。空课表**是合法
      // 结果**（学期还没选课），但值得说一声——用户选了文件却没看到东西时，
      // 这一条就是那句「文件是空的课表，不是没导进来」。
      collected.add(
        ImportDiagnostic(
          code: ImportIssue.emptyTimetable,
          severity: ImportSeverity.warning,
          message: '这份课表里一条上课安排都没有',
        ),
      );
    }

    return TimetableImportResult(
      timetable: Timetable(
        term: term,
        sessions: sessions,
        settings: settings,
      ),
      diagnostics: collected.diagnostics,
    );
  }

  /// 解码阶段没解出来的字节 → 一条诊断（**只报一次**，不是一格报一条）。
  static void _reportUnmappedBytes(GbkDecodeResult decoded, ImportIssues issues) {
    if (!decoded.hasUnmappedBytes) return;
    final offsets = decoded.unmappedByteOffsets;
    final preview = offsets.take(10).join(', ');
    issues.add(
      ImportDiagnostic(
        code: ImportIssue.unmappedByte,
        severity: ImportSeverity.warning,
        message:
            '有 ${offsets.length} 个字节按 GBK 解不出来（字节位置 $preview'
            '${offsets.length > 10 ? ' …' : ''}），这些位置在课表里显示成 '
            '「${GbkCodec.replacementCharacter}」',
        byteOffset: offsets.first,
      ),
    );
  }
}

/// 导入的结果：**课表与诊断一起**。
///
/// 没有「只看成功那一半」的用法——[hasUnparsableContent] 为真时，界面该让用户
/// 先确认再应用，而不是当作成功。
class TimetableImportResult {
  TimetableImportResult({
    required this.timetable,
    required List<ImportDiagnostic> diagnostics,
  }) : diagnostics = List.unmodifiable(diagnostics);

  /// 解出来的课表。没解出来的部分**不在里面**——它们在 [diagnostics] 里。
  final Timetable timetable;

  /// 全部诊断，按产生顺序。
  ///
  /// **原文不在这里**——它在每条诊断自己的 [ImportDiagnostic.rawText] 上。刻意不把
  /// 整篇解码后的文件挂在结果上：那里面带着学号 / 姓名 / 班级，而这份结果要长期留
  /// 在 App 里、还可能被分享出去（ADR-0002）。诊断只要带上**出问题那一格**的原文，
  /// 就够了。
  final List<ImportDiagnostic> diagnostics;

  /// 有没有内容没解出来。为真时**不要**静默应用这份课表。
  bool get hasUnparsableContent => diagnostics.any((d) => d.isError);

  /// 出错级别的诊断。
  List<ImportDiagnostic> get errors =>
      diagnostics.where((d) => d.isError).toList();

  /// 提示级别的诊断。
  List<ImportDiagnostic> get warnings =>
      diagnostics.where((d) => !d.isError).toList();

  /// 某一种代码的诊断。
  List<ImportDiagnostic> withCode(String code) =>
      diagnostics.where((d) => d.code == code).toList();

  @override
  String toString() =>
      'TimetableImportResult(${timetable.sessions.length} 条安排, '
      '${diagnostics.length} 条诊断)';
}
