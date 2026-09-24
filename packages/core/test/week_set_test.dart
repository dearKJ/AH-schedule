import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

void main() {
  group('周次集合的表示', () {
    test('去重并升序排列', () {
      final weeks = WeekSet([12, 1, 3, 3, 2, 1]);

      expect(weeks.weeks, [1, 2, 3, 12]);
      expect(weeks.length, 4);
      expect(weeks.min, 1);
      expect(weeks.max, 12);
    });

    test('能表示不连续的周次：第 1 周与第 3-12 周并存', () {
      final weeks = WeekSet([...List.generate(10, (i) => 3 + i), 1]);

      expect(weeks.weeks, [1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
      expect(weeks.contains(1), isTrue);
      expect(weeks.contains(2), isFalse, reason: '第 2 周不在集合里，这正是「断档」的含义');
      expect(weeks.contains(13), isFalse);
    });

    test('单双周只是集合的一种形状，不另立类型', () {
      final oddWeeks = WeekSet([5, 7, 9, 11, 13, 15]);
      final evenWeeks = WeekSet([4, 6, 8, 10, 12]);

      expect(oddWeeks.contains(5), isTrue);
      expect(oddWeeks.contains(6), isFalse);
      expect(evenWeeks.contains(6), isTrue);
      expect(evenWeeks.weeks.first, 4);
    });

    test('集合相等按元素判定，与传入顺序无关', () {
      expect(WeekSet([3, 1]), WeekSet([1, 1, 3]));
      expect(WeekSet([3, 1]), isNot(WeekSet([1, 3, 5])));
      expect(WeekSet([1, 3]).hashCode, WeekSet([3, 1]).hashCode);
    });

    test('周次必须是正整数，且有上限', () {
      expect(() => WeekSet([0]), throwsArgumentError);
      expect(() => WeekSet([-1]), throwsArgumentError);
      expect(() => WeekSet([WeekSet.maxWeek + 1]), throwsArgumentError);
      expect(WeekSet([WeekSet.maxWeek]).max, WeekSet.maxWeek);
    });

    test('空集合是合法的，只是什么周都不含', () {
      final empty = WeekSet(const []);

      expect(empty.isEmpty, isTrue);
      expect(empty.contains(1), isFalse);
      expect(empty.weeks, isEmpty);
      expect(empty.toText(), isEmpty);
    });

    test('传入的集合改不动内部状态', () {
      final source = [1, 2];
      final weeks = WeekSet(source);
      source.add(3);

      expect(weeks.weeks, [1, 2]);
      expect(() => weeks.weeks.add(3), throwsUnsupportedError);
    });
  });

  group('周次集合反向生成人能读的写法', () {
    test('连续段写成区间，断档周之间用空格分隔', () {
      expect(
        WeekSet([1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 13, 14, 15, 16]).toText(),
        '1-8 10 12-16',
      );
    });

    test('单个周次就写一个数字', () {
      expect(WeekSet([12]).toText(), '12');
    });

    test('单双周写回教务系统那套写法', () {
      expect(WeekSet([5, 7, 9, 11, 13, 15]).toText(), '单周第5周-第15周');
      expect(WeekSet([4, 6, 8, 10, 12]).toText(), '双周第4周-第12周');
    });

    test('只有一两周的稀疏集合不硬凑成单双周', () {
      expect(WeekSet([1, 3]).toText(), '1 3');
      expect(WeekSet([5, 7]).toText(), '5 7');
    });

    test('连着的两周写成区间', () {
      expect(WeekSet([4, 5]).toText(), '4-5');
    });
  });

  group('周次集合的解析', () {
    test('普通区间、断档周、特定周', () {
      expect(WeekSet.parse('1-8 10 12-16').weeks, [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        10,
        12,
        13,
        14,
        15,
        16,
      ]);
      expect(WeekSet.parse('第4周-第10周 第12周-第18周').weeks, [
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
      ]);
      expect(WeekSet.parse('第12周').weeks, [12]);
      expect(WeekSet.parse('12').weeks, [12]);
    });

    test('单双周', () {
      expect(WeekSet.parse('单周第5周-第15周').weeks, [5, 7, 9, 11, 13, 15]);
      expect(WeekSet.parse('双周第4周-第12周').weeks, [4, 6, 8, 10, 12]);
      expect(WeekSet.parse('单周第5周').weeks, [5]);
    });

    test('宽容：全角、多余空格、缺少「第」「周」字、顿号分隔', () {
      expect(WeekSet.parse('  1 - 8   10 ').weeks, [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        10,
      ]);
      expect(WeekSet.parse('１-８　１０').weeks, [1, 2, 3, 4, 5, 6, 7, 8, 10]);
      expect(WeekSet.parse('1-8、10').weeks, [1, 2, 3, 4, 5, 6, 7, 8, 10]);
      expect(WeekSet.parse('1-8，10').weeks, [1, 2, 3, 4, 5, 6, 7, 8, 10]);
      expect(WeekSet.parse('1周-8周 10周').weeks, [1, 2, 3, 4, 5, 6, 7, 8, 10]);
      expect(WeekSet.parse('第1-8周 第10周').weeks, [1, 2, 3, 4, 5, 6, 7, 8, 10]);
      expect(WeekSet.parse('单5-9').weeks, [5, 7, 9]);
    });

    test('重复的段被合并', () {
      expect(WeekSet.parse('1-4 3-6').weeks, [1, 2, 3, 4, 5, 6]);
    });

    test('解析不了就明确报错，不静默产出空集合', () {
      expect(() => WeekSet.parse(''), throwsFormatException);
      expect(() => WeekSet.parse('   '), throwsFormatException);
      expect(() => WeekSet.parse('课程表'), throwsFormatException);
      expect(() => WeekSet.parse('1-8 教室'), throwsFormatException);
      expect(() => WeekSet.parse('0'), throwsFormatException);
      expect(() => WeekSet.parse('-3'), throwsFormatException);
      expect(
        () => WeekSet.parse('8-1'),
        throwsFormatException,
        reason: '起止颠倒多半是写错了',
      );
      expect(
        () => WeekSet.parse('${WeekSet.maxWeek + 1}'),
        throwsFormatException,
      );
    });

    test('tryParse 把错误转成 null', () {
      expect(WeekSet.tryParse('1-8'), WeekSet([1, 2, 3, 4, 5, 6, 7, 8]));
      expect(WeekSet.tryParse('课程表'), isNull);
    });

    test('写出去再读回来，还是同一个集合', () {
      final sets = [
        WeekSet([1]),
        WeekSet([12]),
        WeekSet([1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 13, 14, 15, 16]),
        WeekSet([1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]),
        WeekSet([5, 7, 9, 11, 13, 15]),
        WeekSet([4, 6, 8, 10, 12]),
        WeekSet([1, 3]),
        WeekSet([4, 5]),
        WeekSet([1, 4, 5, 6, 9, 11, 12]),
      ];

      for (final set in sets) {
        expect(
          WeekSet.parse(set.toText()),
          set,
          reason: '往返丢信息了：${set.toText()}',
        );
      }
    });
  });
}
