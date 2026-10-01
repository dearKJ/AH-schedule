import 'package:ah_schedule/ui/week/course_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 课程颜色那一件事：**同一门课，重启 App 之后还是同一个颜色**。
///
/// 它是规格第 16 条的完成标准，而这条标准最容易悄悄失守——`String.hashCode` 看着就够用，
/// 但 Dart 不保证它跨进程稳定。这个文件盯的就是「颜色的出处与运行环境无关」。
void main() {
  group('课名 → 颜色', () {
    test('同一门课每次都是同一个颜色', () {
      expect(
        CourseColors.of('高等数学(一)', Brightness.light),
        CourseColors.of('高等数学(一)', Brightness.light),
      );
      expect(
        CourseColors.of('编译原理', Brightness.dark),
        CourseColors.of('编译原理', Brightness.dark),
      );
    });

    test('深浅两套主题给的不是同一个颜色', () {
      expect(
        CourseColors.of('离散数学', Brightness.light),
        isNot(CourseColors.of('离散数学', Brightness.dark)),
        reason: '深色主题下要拿更暗的底色，不然夜里一屏浅底格子刺眼',
      );
    });

    test('颜色与课名的实例无关：内容一样就一样', () {
      // 拼出来的同一个字符串，与字面量是不同的对象——颜色只认内容。
      final built = ['高等', '数学(一)'].join();
      expect(
        CourseColors.of(built, Brightness.light),
        CourseColors.of('高等数学(一)', Brightness.light),
      );
    });

    test('多门课铺得开：200 个课名至少给出 20 种颜色', () {
      final colors = {
        for (var i = 0; i < 200; i++)
          CourseColors.of('课程$i', Brightness.light),
      };

      expect(
        colors.length,
        greaterThanOrEqualTo(20),
        reason: '都挤在一两种颜色上的话，「一眼看出这门课排了几次」就不成立了',
      );
    });

    test('底色不透明，格子不会透出下面的网格线', () {
      final color = CourseColors.of('大学英语', Brightness.light);
      expect(color.a, 1.0);
    });
  });

  group('格子上的字', () {
    test('浅底给深字、深底给浅字', () {
      final onLight = CourseColors.textOn(const Color(0xFFEEEEEE));
      final onDark = CourseColors.textOn(const Color(0xFF202020));

      expect(onLight.computeLuminance(), lessThan(0.5));
      expect(onDark.computeLuminance(), greaterThan(0.5));
    });

    test('与自己配色盘上任何一种底色都拉得开', () {
      for (final brightness in Brightness.values) {
        final background = CourseColors.of('线性代数', brightness);
        final text = CourseColors.textOn(background);
        final gap =
            (text.computeLuminance() - background.computeLuminance()).abs();

        expect(
          gap,
          greaterThan(0.2),
          reason: '$brightness 下底色 $background 与字色 $text 太近了',
        );
      }
    });
  });

  group('稳定散列', () {
    test('同一个课名每次都算出同一个值', () {
      expect(CourseColors.stableHash('编译原理'), CourseColors.stableHash('编译原理'));
    });

    test('值写死了：改这条说明散列算法变了，所有人认熟的颜色会跟着变', () {
      // 这两条是**故意钉住的**。散列算法的常数一改，用户已经认熟的颜色就全变了——
      // 那时候要改的是这里，而不是让它悄悄过去。
      expect(CourseColors.stableHash(''), 2166136261);
      expect(CourseColors.stableHash('a'), 1678518572);
      expect(CourseColors.stableHash('高等数学(一)'), 262941083);
    });

    test('不同课名给的值不同', () {
      final names = [
        '高等数学(一)',
        '大学英语',
        '编译原理',
        '人机交互的软件工程方法',
        '线性代数',
      ];
      final hashes = names.map<int>(CourseColors.stableHash).toSet();

      expect(hashes.length, names.length, reason: '这几门课撞在一起了');
    });

    test('长课名不会算出负数或越界', () {
      final long = '一门名字特别长的课程' * 40;
      final hash = CourseColors.stableHash(long);

      expect(hash, greaterThanOrEqualTo(0));
      expect(hash, lessThanOrEqualTo(0x7FFFFFFF));
    });
  });
}
