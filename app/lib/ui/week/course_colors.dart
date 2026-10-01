import 'package:flutter/material.dart';

/// 课程颜色：**同一门课在同一台设备上，重启 App 之后还是同一个颜色**。
///
/// 规格把这件事定成「按课程稳定分配、不入库、不上云」——颜色不进数据库、也不跟着导出的
/// JSON 走，所以「稳定」只能靠**算得出来**：同名的课永远算出同一个颜色。
///
/// 这里**不能用 `String.hashCode`**。Dart 只保证它在一次进程里自洽，不保证跨进程稳定
/// （实现可以变，也可能带随机种子），拿它配色就等于「今天绿的明天可能变蓝」——正是规格
/// 第 16 条要防的事。所以自己算一个**写死常数的多项式散列**：结果只取决于课名。
///
/// 色相由散列定、明度与彩度按主题明暗取两套固定值，格子的底色因此与主题无关地稳定。
class CourseColors {
  const CourseColors._();

  /// 浅色主题下格子底色的明度与彩度。格子小、字多，取「淡底深字」这一组。
  static const double _lightness = 0.86;
  static const double _saturation = 0.42;

  /// 深色主题下换成一组更暗的底色，不然一屏浅底格子在夜里刺眼。
  static const double _darkLightness = 0.30;
  static const double _darkSaturation = 0.40;

  /// 色相在整圈上的步长。相邻色差够看得出来，又不至于把整圈挤成几种颜色。
  static const double _hueStep = 0.42;

  /// 配色盘上能取到的颜色个数——散列先取模到它，再乘步长铺到 360° 上。
  static const int paletteSize = 360;

  /// 这门课的颜色。[brightness] 是当前主题的明暗。
  static Color of(String courseName, Brightness brightness) =>
      ofSeed(stableHash(courseName), brightness);

  /// 从散列值取色。与 [of] 分开写，是为了让「同一个散列 → 同一个颜色」能被直接断言。
  static Color ofSeed(int seed, Brightness brightness) {
    final hue = (seed % paletteSize) * _hueStep % 360;
    return HSLColor.fromAHSL(
      1,
      hue,
      brightness == Brightness.dark ? _darkSaturation : _saturation,
      brightness == Brightness.dark ? _darkLightness : _lightness,
    ).toColor();
  }

  /// 格子上的字色：底色浅就用深字，底色深就用浅字。
  ///
  /// 不取主题的 `onSurface`——同一门课的底色在两套主题下不同，字色得跟着**底色**走，
  /// 跟着主题走会在某一种明暗下糊成一片。
  static Color textOn(Color background) => background.computeLuminance() > 0.5
      ? const Color(0xFF1B1B1B)
      : const Color(0xFFF5F5F5);

  /// 课名 → 稳定散列。同名同值，且与运行环境、进程、App 版本无关。
  ///
  /// 一条多项式滚动散列（FNV 那一类的思路）：每位异或进来再乘一个质数。**这些常数是
  /// 写死的**——它们一变，所有人已经认熟的颜色就全变了。
  static int stableHash(String text) {
    var hash = 2166136261;
    for (final unit in text.codeUnits) {
      hash = (hash ^ unit) * 16777619;
      // 收进 31 位：长课名下不让它越滚越大。JS 与原生 VM 的整数宽度不一样，不收会在
      // 不同平台上算出不同的值——那正是这一步要防的。
      hash &= 0x7FFFFFFF;
    }
    return hash;
  }
}
