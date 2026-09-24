import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

void main() {
  group('节次跨度', () {
    test('单节次就是节数为 1 的跨度', () {
      final single = PeriodSpan.single(3);

      expect(single.start, 3);
      expect(single.length, 1);
      expect(single.end, 3);
      expect(single.periods, [3]);
      expect(single.isSingle, isTrue);
    });

    test('连堂：起始节次 + 节数', () {
      final span = PeriodSpan(3, 3);

      expect(span.start, 3);
      expect(span.length, 3, reason: '节数对应导出文件里的 rowspan');
      expect(span.end, 5);
      expect(span.periods, [3, 4, 5]);
      expect(span.isSingle, isFalse);
    });

    test('含哪些节次', () {
      final span = PeriodSpan(8, 2);

      expect(span.contains(8), isTrue);
      expect(span.contains(9), isTrue);
      expect(span.contains(7), isFalse);
      expect(span.contains(10), isFalse);
    });

    test('是否与其他跨度重叠', () {
      final span = PeriodSpan(3, 3); // 第 3-5 节

      expect(span.overlaps(PeriodSpan(3, 3)), isTrue);
      expect(
        span.overlaps(PeriodSpan(2, 2)),
        isTrue,
        reason: '第 2-3 节与它共享第 3 节',
      );
      expect(span.overlaps(PeriodSpan(5, 1)), isTrue);
      expect(span.overlaps(PeriodSpan(6, 4)), isFalse);
      expect(span.overlaps(PeriodSpan(1, 2)), isFalse);
    });

    test('起始节次与节数必须合法', () {
      expect(() => PeriodSpan(0, 1), throwsArgumentError);
      expect(() => PeriodSpan(-1, 1), throwsArgumentError);
      expect(() => PeriodSpan(3, 0), throwsArgumentError);
      expect(() => PeriodSpan(3, -2), throwsArgumentError);
    });

    test('相等按起始节次与节数判定', () {
      expect(PeriodSpan(3, 2), PeriodSpan(3, 2));
      expect(PeriodSpan(3, 2), isNot(PeriodSpan(3, 1)));
      expect(PeriodSpan(3, 2), isNot(PeriodSpan(2, 2)));
      expect(PeriodSpan(3, 2).hashCode, PeriodSpan(3, 2).hashCode);
    });
  });
}
