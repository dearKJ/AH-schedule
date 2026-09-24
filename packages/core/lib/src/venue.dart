import 'internal_helpers.dart';

/// 上课地点：教室名 + 校区。
///
/// 教室由「教室编号 + 校区」共同确定——同一间教室编号在不同校区可能重复，
/// 所以只比教室名是不够的。线上教学时，教室名那一格放 [`onlineRoomLabel`]。
class Venue {
  /// 校验教室名不为空白；校区为空白时归一成「没有校区」。
  factory Venue({required String room, String? campus}) {
    final trimmedRoom = room.trim();
    if (trimmedRoom.isEmpty) {
      throw ArgumentError.value(room, 'room', '教室名不能是空白');
    }
    return Venue._(trimmedRoom, trimmedOrNull(campus));
  }

  /// 线上教学：它占着原本放教室名的位置，只带一个校区。
  factory Venue.online({String? campus}) =>
      Venue(room: onlineRoomLabel, campus: campus);

  const Venue._(this.room, this.campus);

  /// 教务系统在教室名那一格写的就是这四个字。
  static const String onlineRoomLabel = '线上教学';

  /// 教室名（教室编号），如 `4J410`。
  final String room;

  /// 校区，如 `主校区`。没有时是 null。
  final String? campus;

  bool get isOnline => room == onlineRoomLabel;

  /// 展示写法，如 `4J410(主校区)`——与导出文件的写法一致。
  String toText() => campus == null ? room : '$room($campus)';

  @override
  String toString() => toText();

  @override
  bool operator ==(Object other) =>
      other is Venue && other.room == room && other.campus == campus;

  @override
  int get hashCode => Object.hash(room, campus);
}
