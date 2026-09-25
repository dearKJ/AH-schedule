import 'dart:io';
import 'dart:typed_data';

import 'package:ah_schedule_core/ah_schedule_core.dart';
// 只为 `fail()`——夹具读不到时**直接失败**，不能悄悄跳过而变绿。
import 'package:test/test.dart';

/// 真实导出文件的**脱敏夹具**（issue #2 的产物）。
///
/// 位置刻意放在**仓库根**的 `test/fixtures/`：它不归任何一个包所有，而且脱敏
/// 脚本、PII 扫描脚本都在根上。从 `packages/core` 往上找两格是稳的——`dart test`
/// 在包根跑，CWD 就是 `packages/core`。
///
/// 夹具的结构指纹（字节数、行数、格子数、解出多少条安排）记在它自己的
/// `README.md` 里；这里的测试断言那些数字，改坏夹具就会红。
final File fixtureFile = File(
  [
    Directory.current.path,
    '..',
    '..',
    'test',
    'fixtures',
    'ahpu-jwxt-export-2026-2027-1.sanitized.xls',
  ].join(Platform.pathSeparator),
);

/// 夹具的字节。读不到时**直接失败**——测试不能因为找不到夹具而「跳过」而变绿。
Uint8List fixtureBytes() {
  if (!fixtureFile.existsSync()) {
    fail(
      '找不到测试夹具：${fixtureFile.path}\n'
      '（`dart test` 要在 packages/core 下跑；夹具在仓库根的 test/fixtures/）',
    );
  }
  return fixtureFile.readAsBytesSync();
}

/// 夹具按 GBK 解码后的文本。
String fixtureText() => GbkCodec.decode(fixtureBytes()).text;

/// 从夹具的字节导入，全用默认值。
TimetableImportResult importFixture() => TimetableImporter.importBytes(
  fixtureBytes(),
  term: AcademicTerm(id: '2026-2027-1', label: '2026-2027学年1学期'),
);
