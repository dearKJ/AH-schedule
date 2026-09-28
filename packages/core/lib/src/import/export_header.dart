import 'dart:typed_data';

import '../academic_term.dart';
import 'cell_arrangements.dart';
import 'gbk_codec.dart';

/// 导出文件的**页头**：`<h1>个人课程表</h1>`、`<h3>2026-2027学年第一学期</h3>`、
/// 学生信息行。规格见 `docs/reference/ahpu-jwxt-export-format.md` 第一节。
///
/// 这里**只读学年学期**，学生信息行一个字都不碰——学号 / 姓名 / 班级是要被剥掉的
/// 东西（ADR-0002），不是要被读出来的东西。
abstract final class ExportHeader {
  /// 从**原始字节**读页头里那个学年学期。先按 GBK 解码，与
  /// [TimetableImporter.importBytes] 走的是同一条路。
  ///
  /// 给界面用：它手上只有原始文件。**让这一层去解码，界面就不必把整篇带学号、姓名、
  /// 班级的文本留在手上**——那正是 [TimetableImportResult] 刻意不挂文本的原因。
  /// 解不出来（空文件、空字节、认不出）时返回 null。
  static AcademicTerm? academicTermOfBytes(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    return academicTerm(GbkCodec.decode(bytes).text);
  }

  /// 页头里写的**学年学期**，认不出来时是 null。
  ///
  /// **只当参考。** 文件里写作 `2026-2027学年第一学期`，与界面上的
  /// `2026-2027学年1学期` 写法不同（归一化由 [AcademicTerm.parseLabel] 做）；而真正
  /// 定归属的是调用方传给 [TimetableImporter] 的那个学年学期——学期常常是使用者自己
  /// 在教务系统里选的，而认错学期等于把课表挂到别的学期上。所以这一条的价值只有一个：
  /// 给界面一个**默认值**，省掉使用者手打一遍。
  ///
  /// 按文档，学期名在 `<h3>` 里；这里顺带把 `<h1>` / `<h2>` 也扫一遍——标题写在第几级
  /// 是模板的自由，认出学年学期就行。取**第一个认得出的**标题，认不出返回 null：
  /// 与其从一个像学期又不是学期的标题里凑一个出来，不如让界面去问使用者。
  static AcademicTerm? academicTerm(String html) {
    for (final match in _headingPattern.allMatches(html)) {
      final term = AcademicTerm.tryParseLabel(_plainText(match.group(2)!));
      if (term != null) return term;
    }
    return null;
  }

  /// 一级到三级标题。`</h1>` 用反向引用对应 `<h1>`，免得把 `<h3>…</h1>` 这种残标签
  /// 配成一对。
  static final RegExp _headingPattern = RegExp(
    r'<h([123])\b[^>]*>(.*?)</h\1\s*>',
    caseSensitive: false,
    dotAll: true,
  );

  /// 标题那一小段 HTML → 纯文本。
  ///
  /// 去标签用 [CellArrangements.stripTags]（同一份导出文件的同一套写法，不另造一个），
  /// 再把 `&nbsp;` 还原成空格——它是 HTML 里最常见的那个实体，留成字面量会让
  /// 「`2026-2027学年第一学期&nbsp;`」这样的标题认不出来。
  static String _plainText(String headingHtml) => CellArrangements.stripTags(
    headingHtml.replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' '),
  );
}
