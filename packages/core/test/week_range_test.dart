import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

void main() {
  group('周次导航的范围', () {
    ClassSession session(WeekSet weeks) => ClassSession(
      courseName: '高等数学(一)',
      weekday: 1,
      periods: PeriodSpan(1, 2),
      weeks: weeks,
      venue: Venue(room: '4J410', campus: '主校区'),
    );

    test('一条安排都没有的课表给 1..1，不给一个 0 长度的空范围', () {
      expect(WeekRange.of([]), WeekRange(from: 1, to: 1));
    });

    test('范围跟着数据走：数据排到第 18 周就只到第 18 周', () {
      final range = WeekRange.of([
        session(WeekSet([1, 2, 3])),
        session(WeekSet([9, 12, 18])),
      ]);

      expect(range.from, 1);
      expect(range.to, 18, reason: '不摆出一堆永远空着的周');
      expect(range.length, 18);
    });

    test('数据不从第 1 周开始时，起点跟着数据走', () {
      final range = WeekRange.of([session(WeekSet([5, 6, 7]))]);

      expect(range, WeekRange(from: 5, to: 7));
      expect(range.contains(4), isFalse);
      expect(range.contains(8), isFalse);
    });

    test('总周数只把范围往外挪，不会把已经排着的课砍掉', () {
      final sessions = [session(WeekSet([1, 2, 16]))];

      expect(
        WeekRange.of(sessions, settings: TermSettings(totalWeeks: 20)).to,
        20,
        reason: '设了 20 周就是想翻到第 20 周',
      );
      expect(
        WeekRange.of(sessions, settings: TermSettings(totalWeeks: 12)).to,
        16,
        reason: '总周数填小了也不能把第 16 周的课藏起来',
      );
    });

    test('总周数不设就以数据实际范围为准', () {
      expect(WeekRange.of([session(WeekSet([1, 18]))]).to, 18);
    });

    test('前后能不能翻：到边界就停住', () {
      final range = WeekRange(from: 3, to: 18);

      expect(range.hasPrevious(3), isFalse, reason: '已经在第 3 周，不能再往前');
      expect(range.hasPrevious(4), isTrue);
      expect(range.hasNext(18), isFalse, reason: '已经在第 18 周，不能再往后');
      expect(range.hasNext(17), isTrue);
      expect(range.contains(2), isFalse);
      expect(range.contains(3), isTrue);
      expect(range.contains(18), isTrue);
      expect(range.contains(19), isFalse);
    });
  });

  group('打开课表时先落在哪一周', () {
    final range = WeekRange(from: 2, to: 18);

    /// 一份设了「第 1 周的第一天」的学期设置，2026-09-07（周一）开学。
    final settings = TermSettings(firstDayOfWeek1: DateTime(2026, 9, 7));

    test('设了开学日期、今天也落在范围内，就落在当前教学周', () {
      // 2026-09-21 是第 3 周。
      expect(range.weekFor(DateTime(2026, 9, 21), settings.weekOf), 3);
    });

    test('没设「第 1 周的第一天」时不猜，落在范围的第一周', () {
      expect(range.weekFor(DateTime(2026, 9, 21), TermSettings().weekOf), 2);
    });

    test('不知道今天是哪一天时，落在范围的第一周', () {
      expect(range.weekFor(null, settings.weekOf), 2);
    });

    test('算出来的周次在学期范围外时，落在范围的第一周，不丢进空周', () {
      // 2027-01-04 是第 18 周，落在范围内；再往后到第 19 周就该退回去。
      expect(range.weekFor(DateTime(2027, 1, 4), settings.weekOf), 18);
      expect(range.weekFor(DateTime(2027, 1, 11), settings.weekOf), 2);
    });

    test('今天落在范围外过头（越过 53 周）时也不抛错', () {
      expect(range.weekFor(DateTime(2030, 1, 7), settings.weekOf), 2);
    });
  });
}
