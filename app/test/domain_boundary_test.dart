import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 「领域层不依赖 Flutter」这条边界，在 App 这边也必须成立，而且**可被检查**。
///
/// 这条边界在 `packages/core` 里由它自己的三重检查盯着（见
/// `packages/core/test/no_flutter_dependency_test.dart`）。但那只证明了「那个包单独
/// 存在时拿不到 Flutter」。App 把 core 接进来之后，边界还有三种被悄悄破坏的方式，
/// 这里逐条盯着：
///
/// 1. **不再是 path 依赖** —— core 若被换成 hosted / git 版本，App 用的就不是本仓库
///    的这一份，改 core 的源码不再影响 App，边界成了摆设。
/// 2. **绕过公开入口** —— App 直接 import `package:ah_schedule_core/src/…`，等于把
///    领域层的内部实现拉进 App，从此 App 编译依赖 core 的内部结构。
/// 3. **App 里长出第二个领域层** —— `lib/core/` 之类的目录一旦出现，领域逻辑就有了
///    两个出处，那条「最快的测试接缝」也就不再是唯一入口。
///
/// 第 3 条顺带把「三层目录结构」也钉住了：App 只有 `data/`（drift、仓储）与
/// `ui/`（界面），领域层在 `packages/core`。
///
/// 术语与理由见 `README.md`、`docs/adr/0003-flutter-android-only-v0-1.md`、issue #4。
void main() {
  final appRoot = Directory.current;
  final repoRoot = appRoot.parent;
  final coreRoot = Directory('${repoRoot.path}/packages/core');

  /// `app/lib` 下允许出现的顶层条目。领域层不在这张表里——它不在 App 里。
  const allowedLibEntries = <String>{
    'main.dart',
    'app.dart',
    'routing',
    'data',
    'ui',
  };

  group('领域层以 path 依赖接入', () {
    test('pubspec 里 ah_schedule_core 是 path 依赖，指向本仓库的 packages/core', () {
      final pubspec = File('${appRoot.path}/pubspec.yaml');
      expect(
        pubspec.existsSync(),
        isTrue,
        reason: '请在 app 目录下跑 `flutter test`',
      );

      final lines = pubspec.readAsLinesSync();
      final coreIndex = lines.indexWhere(
        (line) => RegExp(r'^\s+ah_schedule_core\s*:').hasMatch(line),
      );
      expect(
        coreIndex,
        isNot(-1),
        reason: 'pubspec 的 dependencies 里没有 ah_schedule_core，App 根本没接上领域层',
      );

      // 只取 ah_schedule_core 这一项自己的那几行：YAML 里它下面的缩进行都算它的，
      // 缩进回到同级或更浅（也就是下一个依赖 / 下一节）就结束。取太宽会把后面别的
      // 依赖的 `path:` 也吃进来，那样这条检查就假通过了。
      final indent = _indentOf(lines[coreIndex]);
      final bodyLines = <String>[];
      for (final line in lines.sublist(coreIndex + 1)) {
        if (line.trim().isEmpty || _indentOf(line) > indent) {
          bodyLines.add(line);
          continue;
        }
        break;
      }
      final body = bodyLines.join('\n');

      expect(
        body,
        contains('path:'),
        reason:
            'core 必须是 path 依赖。换成 hosted / git 版本就等于用的不是本仓库这一份，'
            '改 core 的源码不再影响 App。实际写的是：\n$body',
      );
      expect(body, contains('../packages/core'));
    });

    test('解析出来的 ah_schedule_core 确实落在本仓库的 packages/core', () {
      expect(
        coreRoot.existsSync(),
        isTrue,
        reason: '${coreRoot.path} 不存在——App 的 path 依赖指向了一个不存在的目录',
      );

      final configFile = File('${appRoot.path}/.dart_tool/package_config.json');
      expect(
        configFile.existsSync(),
        isTrue,
        reason: '先跑 `flutter pub get`（在 app 目录下）',
      );

      final config =
          jsonDecode(configFile.readAsStringSync()) as Map<String, Object?>;
      final packages = (config['packages']! as List<Object?>)
          .cast<Map<String, Object?>>();

      final core = packages.where(
        (package) => package['name'] == 'ah_schedule_core',
      );
      expect(core, hasLength(1), reason: '依赖图里没有 ah_schedule_core');

      // package_config.json 里的 rootUri 相对它自己所在目录（app/.dart_tool/）解析。
      final resolved = configFile.parent.uri
          .resolve(core.single['rootUri']! as String)
          .toFilePath(windows: Platform.isWindows);
      final expected = coreRoot.resolveSymbolicLinksSync();

      expect(
        Directory(resolved).resolveSymbolicLinksSync(),
        expected,
        reason:
            '依赖图里解出来的 core 不是本仓库的 packages/core。'
            'App 用的领域层与仓库里的那一份不是同一份，边界就是假的。',
      );
    });
  });

  group('App 不绕过领域层的公开入口', () {
    test('app/lib 里没有 import package:ah_schedule_core/src/…', () {
      final offenders = <String>[];
      final libraryFiles = _dartFiles(Directory('${appRoot.path}/lib'))
          .toList();

      expect(libraryFiles, isNotEmpty, reason: '一个文件都没扫到，说明路径不对——这条检查不能空转');

      for (final file in libraryFiles) {
        for (final line in file.readAsLinesSync()) {
          if (RegExp(
            r'''^\s*(import|export)\s+['"]package:ah_schedule_core/src/''',
          ).hasMatch(line)) {
            offenders.add('${_relative(file, appRoot)}: ${line.trim()}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            '领域层只能从它的公开入口 package:ah_schedule_core/ah_schedule_core.dart '
            '接入。伸进 src/ 会把 core 的内部实现变成 App 的编译依赖，'
            '以后 core 内部一改 App 就跟着碎。违规处：$offenders',
      );
    });
  });

  group('三层目录结构', () {
    test('app/lib 下没有第二个领域层', () {
      expect(
        Directory('${appRoot.path}/lib/core').existsSync(),
        isFalse,
        reason:
            '领域层在 packages/core，App 里不该再有 lib/core/。'
            '领域逻辑一旦有两处出处，就没法保证 App 用的是被测试盯着的那一份。',
      );
    });

    test('app/lib 下的文件只落在 data/ 与 ui/（加入口与路由）', () {
      final strays = <String>[];
      var dataFiles = 0;
      var uiFiles = 0;

      for (final entry in Directory('${appRoot.path}/lib').listSync()) {
        final name = entry.uri.pathSegments
            .where((segment) => segment.isNotEmpty)
            .last;
        if (entry is Directory && allowedLibEntries.contains(name)) {
          final count = _dartFiles(entry).length;
          if (name == 'data') dataFiles += count;
          if (name == 'ui') uiFiles += count;
          continue;
        }
        if (entry is File && allowedLibEntries.contains(name)) continue;
        strays.add(name);
      }

      expect(
        strays,
        isEmpty,
        reason:
            'app/lib 下只允许 ${allowedLibEntries.join('、')}。'
            '多出来的条目说明分层开始糊了。实际多出：$strays',
      );
      expect(dataFiles, greaterThan(0), reason: 'data/ 是空的——数据层没成形，这条检查不能空转');
      expect(uiFiles, greaterThan(0), reason: 'ui/ 是空的——界面层没成形，这条检查不能空转');
    });
  });

  group('领域层拿不到 Flutter', () {
    test('core 解析后的依赖图里没有 flutter / sky_engine', () {
      final configFile = File(
        '${coreRoot.path}/.dart_tool/package_config.json',
      );
      expect(
        configFile.existsSync(),
        isTrue,
        reason:
            '读不到 core 的依赖图。先跑 `flutter pub get`（在 app 目录下会一并生成）'
            '，或在 packages/core 下跑 `dart pub get`',
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
        reason: '读到的不是 core 的依赖图——路径不对',
      );
      expect(
        packages,
        isNot(contains('flutter')),
        reason: 'core 拿得到 Flutter，App 这边这条边界就不成立了',
      );
      expect(packages, isNot(contains('sky_engine')));
    });
  });
}

Iterable<File> _dartFiles(Directory directory) sync* {
  if (!directory.existsSync()) return;
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}

int _indentOf(String line) => line.length - line.trimLeft().length;

String _relative(File file, Directory root) {
  if (!file.path.startsWith(root.path)) return file.path;
  return file.path
      .substring(root.path.length)
      .replaceFirst(RegExp(r'^[\\/]+'), '');
}
