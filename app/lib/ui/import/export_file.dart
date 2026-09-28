import 'dart:typed_data';

import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:file_picker/file_picker.dart';

/// 从设备上选一个教务系统导出的课表文件，读成字节。
///
/// **这是唯一碰平台的一处**：底下是 `file_picker`（走 Android 自己的文件选择器，
/// 手机浏览器下载的 `.xls`、电脑导出后传过来的都能选）。将来换成别的方式，只动这里。
///
/// 两条出口分得很清：
///
/// - **使用者自己取消** → 返回 null。那不是错误，界面什么都不该弹。
/// - **读不成** → 抛 [ExportFileException]，由调用方转成一句明确说出来的失败。
///   导入过程中的错误不该让 App 崩（规格「出错与冲突」第 37 条）。
Future<PickedExportFile?> pickExportFile() async {
  final PlatformFile? picked;
  try {
    picked = await FilePicker.pickFile(
      dialogTitle: '选教务系统导出的课表文件',
      // 刻意**不按类型过滤**：这份导出文件的扩展名是 `.xls`，内容却是 GBK 编码的
      // HTML（见 `docs/reference/ahpu-jwxt-export-format.md`）。按 `.xls` 过滤，
      // 系统很可能因为它实际的 MIME 不是 Excel 而**把它藏起来**——使用者会觉得
      // 「文件明明在，却选不到」。选错了文件有明确的失败提示兜着（见
      // `ImportPage`），比让人选不到文件强。
      type: FileType.any,
    );
  } catch (error) {
    throw ExportFileException('打不开文件选择器：$error');
  }
  if (picked == null) return null;

  // 先问大小再读。一份课表导出是 38 KB 上下，身上带几百兆的文件不该先进内存再被
  // 拒掉——上限用的就是领域层那一个（`ImportLimits.maxBytes`），不在这里另写一份：
  // 两处一旦漂开，先卡住的就是这里。
  final length = picked.lengthSync();
  if (length != null && length > ImportLimits.maxBytes) {
    throw ExportFileException(
      '这个文件有 ${_mib(length)} MiB，'
      '不像是一份课表导出（上限 ${_mib(ImportLimits.maxBytes)} MiB）',
    );
  }

  final Uint8List bytes;
  try {
    bytes = await picked.readAsBytes();
  } catch (error) {
    throw ExportFileException('读不出「${picked.name}」的内容：$error');
  }
  return PickedExportFile(name: picked.name, bytes: bytes);
}

/// 选中的文件：名字（给诊断与提示用）+ 原始字节。
class PickedExportFile {
  const PickedExportFile({required this.name, required this.bytes});

  final String name;

  /// **原始字节**——领域层的导入要的就是字节：先按 GBK 解码，再当 HTML 解析。
  /// 不让文件在界面层被「顺手」转成字符串或对象。
  final Uint8List bytes;
}

/// 读文件这一步的失败。**消息是给人看的**，调用方直接显示它。
class ExportFileException implements Exception {
  const ExportFileException(this.message);

  final String message;

  @override
  String toString() => message;
}

String _mib(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);
