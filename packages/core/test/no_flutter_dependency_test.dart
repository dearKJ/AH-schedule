import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// 「领域层不依赖 Flutter」这条边界，必须能被检查，而不是只写在文档里。
///
/// 三条检查叠在一起：
///
/// 1. 领域层自己的源码不 import Flutter（也不 import `dart:ui`）。
/// 2. `pubspec.yaml` 里没有 Flutter 依赖。
/// 3. **解析后的依赖图里没有 `flutter`**——这是最硬的一条，它证明的不是「我没写
///    import」，而是「这个包根本拿不到 Flutter」。
///
/// 另外，这个包用 `dart test` 跑而不是 `flutter test`，全程没有
/// `TestWidgetsFlutterBinding`——跑得起来本身就是边界的证据。
///
/// 术语与理由见 `README.md` 与 issue #3。
void main() {
  final packageRoot = Directory.current;

  test('领域层的源码不 import Flutter', () {
    final forbidden = <RegExp>[
      RegExp(r'''import\s+['"]package:flutter'''),
      RegExp(r'''import\s+['"]dart:ui['"]'''),
      RegExp(r'''export\s+['"]package:flutter'''),
      RegExp(r'''part\s+of\s+['"]package:flutter'''),
    ];
    final offenders = <String>[];
    var scanned = 0;

    for (final directory in ['lib', 'test']) {
      final files = _dartFiles(Directory('${packageRoot.path}/$directory'))
          .toList();
      expect(
        files,
        isNotEmpty,
        reason:
            '一个文件都没扫到，说明路径不对——这条检查不能空转。'
            '请在 packages/core 下跑 `dart test`',
      );
      scanned += files.length;
      for (final file in files) {
        final source = file.readAsStringSync();
        for (final pattern in forbidden) {
          if (pattern.hasMatch(source)) {
            offenders.add('${_relative(file)}: ${pattern.pattern}');
          }
        }
      }
    }

    expect(scanned, greaterThan(0));
    expect(
      offenders,
      isEmpty,
      reason:
          '领域层一旦 import Flutter，它就不再是那条最快的测试接缝了。'
          '业务逻辑要下沉到 core，Flutter 的东西留在 app 里。违规处：$offenders',
    );
  });

  test('pubspec.yaml 里没有 Flutter 依赖', () {
    final pubspec = File('${packageRoot.path}/pubspec.yaml');
    expect(pubspec.existsSync(), isTrue);

    final text = pubspec.readAsStringSync();
    expect(
      RegExp(r'^\s+flutter\s*:', multiLine: true).hasMatch(text),
      isFalse,
      reason: 'pubspec 里出现了 flutter 依赖',
    );
    expect(
      text.contains('sdk: flutter'),
      isFalse,
      reason: 'pubspec 里出现了 sdk: flutter',
    );
    expect(text, isNot(contains('flutter_test')));
  });

  test('解析后的依赖图里没有 flutter——这个包拿不到 Flutter', () {
    final configFile = File(
      '${packageRoot.path}/.dart_tool/package_config.json',
    );
    expect(
      configFile.existsSync(),
      isTrue,
      reason: '先跑 `dart pub get`（在 packages/core 下）',
    );

    final config =
        jsonDecode(configFile.readAsStringSync()) as Map<String, Object?>;
    final packages = (config['packages']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map((package) => package['name']! as String)
        .toSet();

    expect(
      packages,
      contains('ah_schedule_core'),
      reason: '读到的不是 core 的依赖图——请在 packages/core 下跑 `dart test`',
    );
    expect(packages, isNot(contains('flutter')));
    expect(packages, isNot(contains('flutter_test')));
    expect(
      packages,
      isNot(contains('sky_engine')),
      reason: 'sky_engine 是 Flutter 的引擎包',
    );
  });
}

Iterable<File> _dartFiles(Directory directory) sync* {
  if (!directory.existsSync()) return;
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}

String _relative(File file) {
  final root = Directory.current.path;
  if (!file.path.startsWith(root)) return file.path;
  return file.path.substring(root.length).replaceFirst(RegExp(r'^[\\/]+'), '');
}
