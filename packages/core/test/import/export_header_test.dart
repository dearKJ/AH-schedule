import 'dart:convert';
import 'dart:typed_data';

import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

/// 导出文件**页头**里那个学年学期（`<h3>`）。
///
/// 它只当**参考**：真正定归属的是调用方传进 [TimetableImporter] 的那个学年学期
/// （见 `timetable_importer.dart` 的说明）。这一组测试盯的是「读得准 / 读不出来
/// 就说读不出来」，不是「它说了算」。
///
/// 规格见 `docs/reference/ahpu-jwxt-export-format.md` 第一节：`<h3>` 写作
/// `2026-2027学年第一学期`，与界面上的 `2026-2027学年1学期` 写法不同，要归一化。
void main() {
  group('夹具页头里的学年学期', () {
    test('解出 2026-2027学年1学期', () {
      expect(
        ExportHeader.academicTerm(fixtureText()),
        AcademicTerm.parseLabel('2026-2027学年第一学期'),
      );
    });

    test('解出来的 id 是规范化的 2026-2027-1', () {
      expect(ExportHeader.academicTerm(fixtureText())!.id, '2026-2027-1');
    });

    test('从原始字节读也一样——界面手上只有字节', () {
      expect(
        ExportHeader.academicTermOfBytes(fixtureBytes())?.id,
        '2026-2027-1',
        reason: 'GBK 解码这一步在这一层做，界面不必自己解',
      );
    });
  });

  group('从字节读时的坏输入', () {
    test('空字节 → null，不炸', () {
      expect(ExportHeader.academicTermOfBytes(Uint8List(0)), isNull);
    });

    test('解不出学年学期的文件 → null', () {
      expect(
        ExportHeader.academicTermOfBytes(
          Uint8List.fromList(utf8.encode('<html><body>随便什么</body></html>')),
        ),
        isNull,
      );
    });
  });

  group('读不出学年学期时返回 null，不猜', () {
    test('文件里一个标题都没有', () {
      expect(ExportHeader.academicTerm('<html><body>随便什么</body></html>'), isNull);
    });

    test('标题不是学年学期（`个人课程表` 那种）', () {
      expect(
        ExportHeader.academicTerm('<h3>个人课程表</h3>'),
        isNull,
        reason: '认不出来就说认不出来——认错学期等于把课表挂到别的学期上',
      );
    });

    test('标题像学年学期但写法认不出来', () {
      expect(ExportHeader.academicTerm('<h3>2026学年 第一学期</h3>'), isNull);
    });
  });

  group('写法上的容错', () {
    test('标题带属性、内部还套着标签', () {
      expect(
        ExportHeader.academicTerm(
          '<h3 align="center"><b>2026-2027学年第一学期</b></h3>',
        )?.id,
        '2026-2027-1',
      );
    });

    test('标题里有 &nbsp; 与多余空白', () {
      expect(
        ExportHeader.academicTerm('<h3> 2026 - 2027 学年&nbsp;第一学期 </h3>')?.id,
        '2026-2027-1',
      );
    });

    test('学期写在 <h1> 里（模板换了个标题级）也认', () {
      expect(
        ExportHeader.academicTerm('<h1>2026-2027学年第二学期</h1>')?.label,
        '2026-2027学年2学期',
      );
    });

    test('前面几个标题都不是，用后面那个是的那一个', () {
      expect(
        ExportHeader.academicTerm(
          '<h1>个人课程表</h1><h2>2026-2027学年第一学期</h2><h3>课表</h3>',
        )?.id,
        '2026-2027-1',
      );
    });
  });
}
