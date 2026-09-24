import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

void main() {
  group('学年学期', () {
    test('导出文件与界面的两种写法归一化到同一个学期', () {
      final fromExport = AcademicTerm.parseLabel('2026-2027学年第一学期');
      final fromUi = AcademicTerm.parseLabel('2026-2027学年1学期');

      expect(fromExport.id, '2026-2027-1');
      expect(fromExport, fromUi);
      expect(fromUi.label, '2026-2027学年1学期', reason: '展示名统一成界面上那种写法');
      expect(fromUi.id, '2026-2027-1');
    });

    test('第二学期', () {
      expect(AcademicTerm.parseLabel('2026-2027学年第二学期').id, '2026-2027-2');
      expect(AcademicTerm.parseLabel('2026-2027学年第2学期').id, '2026-2027-2');
    });

    test('容忍多余的空格', () {
      expect(
        AcademicTerm.parseLabel(' 2026-2027 学年 第一学期 '),
        AcademicTerm.parseLabel('2026-2027学年第一学期'),
      );
    });

    test('认不出来的写法明确报错，不猜', () {
      expect(AcademicTerm.tryParseLabel('2026学年第一学期'), isNull);
      expect(AcademicTerm.tryParseLabel('个人课程表'), isNull);
      expect(AcademicTerm.tryParseLabel(''), isNull);
      expect(() => AcademicTerm.parseLabel('个人课程表'), throwsFormatException);
    });

    test('学年学期是数据的隔离单位，按 id 判定同一个', () {
      final a = AcademicTerm(id: '2026-2027-1', label: '2026-2027学年1学期');
      final b = AcademicTerm.parseLabel('2026-2027学年第一学期');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(AcademicTerm.parseLabel('2026-2027学年第二学期')));
    });

    test('id 与展示名都不能是空白', () {
      expect(
        () => AcademicTerm(id: '', label: '2026-2027学年1学期'),
        throwsArgumentError,
      );
      expect(
        () => AcademicTerm(id: '2026-2027-1', label: ' '),
        throwsArgumentError,
      );
    });
  });
}
