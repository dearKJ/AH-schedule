import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

void main() {
  group('地点', () {
    test('教室由「教室编号 + 校区」共同确定', () {
      final one = Venue(room: '4J410', campus: '主校区');
      final another = Venue(room: '4J410', campus: '国际工程师学院');

      expect(one, isNot(another), reason: '同一间教室编号在不同校区可能重复');
    });

    test('没有校区时校区是空的，而不是空串', () {
      expect(Venue(room: '4J209').campus, isNull);
      expect(Venue(room: '4J209', campus: '  ').campus, isNull);
      expect(Venue(room: '4J209', campus: ' 主校区 ').campus, '主校区');
    });

    test('线上教学占着原本放教室名的位置', () {
      final online = Venue.online(campus: '主校区');

      expect(online.room, Venue.onlineRoomLabel);
      expect(online.isOnline, isTrue);
      expect(online.campus, '主校区');
      expect(Venue(room: '4J209', campus: '主校区').isOnline, isFalse);
    });

    test('教室名不能是空白', () {
      expect(() => Venue(room: '   '), throwsArgumentError);
    });

    test('相等按教室名与校区判定', () {
      expect(
        Venue(room: '4J410', campus: '主校区'),
        Venue(room: '4J410', campus: '主校区'),
      );
      expect(
        Venue(room: '4J410', campus: '主校区').hashCode,
        Venue(room: '4J410', campus: '主校区').hashCode,
      );
    });
  });
}
