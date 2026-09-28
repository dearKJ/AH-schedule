import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../academic_term_dialog.dart';
import 'diagnostic_tile.dart';
import 'export_file.dart';
import 'import_draft.dart';
import 'import_preview.dart';

/// 导入一票走到底：**选文件 → 解析 → 预览 → 确认 → 整学期覆盖**。
///
/// 一页两态。选文件那一态里也放失败提示——选错文件（选了个跟课表无关的文件）必须有
/// **明确的失败**，不是对着空白界面发呆（规格「出错与冲突」第 37 条）。
///
/// 解析与入库都在领域层与数据层：这一页只做三件事——把文件拿进来、把结果摆出来、
/// 让使用者在摆出来的那份上直接改，然后把改完的交给数据层。
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  /// 正在选文件 / 解析。
  var _busy = false;

  /// 正在入库。
  var _saving = false;

  /// 明确的失败。**不是「空白界面」**——它带着说法，可能还带着诊断原文。
  _ImportFailure? _failure;

  /// 预览页手上那份还没入库的课表。为 null 就是还在选文件那一态。
  ImportDraft? _draft;

  /// 文件页头里写的学年学期，只当参考。
  AcademicTerm? _fileTermHint;

  bool get _isPreviewing => _draft != null;

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    return PopScope(
      // 预览里改动过东西时，返回要问一句——丢掉的是使用者刚补的那些格子。
      canPop: !_isPreviewing,
      onPopInvokedWithResult: (didPop, _) => _handlePop(didPop),
      child: Scaffold(
        appBar: AppBar(title: Text(_isPreviewing ? '导入预览' : '导入课表')),
        body: draft == null
            ? (_failure == null ? _buildPicker() : _buildFailure(_failure!))
            : ImportPreview(draft: draft, fileTermHint: _fileTermHint),
        bottomNavigationBar: draft == null
            ? null
            // `minimum` 是承重的：按钮是这一页唯一的出口，不能指望系统给的下边距。
            // 实测（Android 16 模拟器、手势导航）只写 SafeArea 时它贴到了屏幕最下沿、
            // 大半个在屏幕外，点不着。多留这 24 说是给手势条的，实际是给自己兜底。
            : SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: FilledButton(
                  onPressed: _saving ? null : _confirm,
                  child: Text(_saving ? '正在写进数据库……' : '确认导入（替换整学期）'),
                ),
              ),
      ),
    );
  }

  // ───────────────────────── 选文件 ─────────────────────────

  Widget _buildPicker() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('把教务系统导出的课表导进来', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          '在教务系统的课表页点「导出 Excel」，把那个 .xls 存到手机上（或者电脑导出后'
          '传到手机），再回到这里选它。',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('别用 Excel / WPS 另存为', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  '那个文件的扩展名是 .xls，内容其实是网页。用表格软件打开再另存，'
                  '结构会被改掉，课表就解不出来了。原样存下的那个文件才是对的。',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _pick,
          icon: const Icon(Icons.folder_open),
          label: Text(_busy ? '正在读文件……' : '选文件'),
        ),
        if (_busy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Widget _buildFailure(_ImportFailure failure) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: colors.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: colors.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        failure.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  failure.message,
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ],
            ),
          ),
        ),
        if (failure.diagnostics.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('解析器说的话', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          for (final diagnostic in failure.diagnostics)
            DiagnosticTile(diagnostic: diagnostic),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _pick,
          icon: const Icon(Icons.folder_open),
          label: const Text('重新选一个文件'),
        ),
      ],
    );
  }

  /// 选文件 → 解析 → 进预览。
  ///
  /// **分得清「他取消了」与「出错了」**：取消什么都不弹，出错一定要说出来。整段包在
  /// try 里——读文件与解析都可能出意外，导入过程中的错误不该让 App 崩。
  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final file = await pickExportFile();
      if (!mounted) return;
      if (file == null) {
        // 使用者自己取消的，不是错误。
        setState(() => _busy = false);
        return;
      }

      // 文件页头里那一行只当**默认值**：认不出来就问使用者。
      final hint = ExportHeader.academicTermOfBytes(file.bytes);
      var term = hint;
      if (term == null) {
        if (!mounted) return;
        term = await showAcademicTermDialog(
          context,
          title: '这份文件里没写学年学期',
          description: '课表要挂在一个学年学期上。填一个，导入之后就归它管。',
          confirmLabel: '用这个',
        );
        if (!mounted) return;
        if (term == null) {
          // 没填学年学期就没法解析（课表得挂在某个学期上）。说一声，别静悄悄地什么
          // 都不发生——使用者刚选完文件，正等着看到点什么。
          setState(() => _busy = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('没填学年学期，这次导入没成。再选一次文件吧。')),
          );
          return;
        }
      }

      final result = TimetableImporter.importBytes(file.bytes, term: term);
      if (!mounted) return;

      if (result.timetable.sessions.isEmpty && result.hasUnparsableContent) {
        // 一条都没解出来、还有出错诊断：这不是「一份空的课表」，是文件不对。
        // 把它当成预览摆出来等于让使用者对着一张空表点确认——静默失败。
        setState(() {
          _busy = false;
          _failure = _ImportFailure(
            title: '这个文件里没能解出课表',
            message:
                '「${file.name}」解不出一条上课安排。它可能不是教务系统导出的课表'
                '文件，或者文件已经损坏。换一个再试。',
            diagnostics: result.diagnostics,
          );
        });
        return;
      }

      setState(() {
        _busy = false;
        _fileTermHint = hint;
        _draft = ImportDraft(
          term: term!,
          sessions: result.timetable.sessions,
          diagnostics: result.diagnostics,
        );
      });
    } on ExportFileException catch (error) {
      _fail(error.message);
    } catch (error) {
      // 解析器里的意外（理论上不该有，但「不该崩」是要求，不是愿望）。
      _fail('解析这个文件时出错了：$error');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failure = _ImportFailure(
        title: '这个文件没能导进来',
        message: message,
        diagnostics: const [],
      );
    });
  }

  // ───────────────────────── 确认 ─────────────────────────

  /// 确认：**整学期覆盖**，然后给出汇总。
  ///
  /// 存的是 [ImportDraft.sessions]——使用者改完的那一份，没有第二条路径。学期设置
  /// 从库里读回来原样带过去：导入换的是安排与例外，不是使用者的作息时间表。
  Future<void> _confirm() async {
    final draft = _draft!;
    setState(() => _saving = true);
    try {
      final repository = ref.read(timetableRepositoryProvider);
      final previous = await repository.load(draft.term);
      await repository.save(
        Timetable(
          term: draft.term,
          sessions: draft.sessions,
          settings: previous?.settings,
        ),
      );
      if (!mounted) return;

      ref.invalidate(academicTermsProvider);
      ref.invalidate(termTimetableProvider(draft.term));
      setState(() => _saving = false);

      await _showSummary(draft, previous);
      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('没能写进数据库：$error')));
    }
  }

  /// 导入后的汇总：解出多少条、有多少处需要留意、换掉了旧的多少条。
  Future<void> _showSummary(ImportDraft draft, Timetable? previous) {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('已导入「${draft.term.label}」'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('解出 ${draft.parsedCount} 条上课安排'),
            Text(
              draft.diagnostics.isEmpty
                  ? '没有需要留意的地方'
                  : '需要留意 ${draft.diagnostics.length} 处'
                        '（还有 ${draft.pendingCount} 处没处理）',
            ),
            if (draft.touchedCount > 0)
              Text('你补了 ${draft.addedCount} 条、改了 ${draft.replacedCount} 条'),
            Text('这份课表存了 ${draft.length} 条'),
            if (previous != null) ...[
              const SizedBox(height: 8),
              Text(
                '替换掉的是旧的 ${previous.sessions.length} 条安排、'
                '${totalExceptions(previous)} 条例外',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  /// 系统返回键（或返回手势）在预览态被挡下来一次：问过之后再决定退不退。
  ///
  /// 它是个方法而不是 `build` 里的闭包，是为了让 `context` 与 `mounted` 指的是同一个
  /// 东西——闭包里那个 `context` 是 `build` 的参数，与 `State.mounted` 不是一回事。
  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;
    if (!await _confirmDiscard()) return;
    if (!mounted) return;
    context.pop();
  }

  Future<bool> _confirmDiscard() async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃这次导入？'),
        content: const Text('你在预览里改的东西会丢掉。课表还是原来那张，没动过。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('接着改'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );
    return answer ?? false;
  }
}

/// 一次明确的导入失败：一句说法 + 解析器说的话。
class _ImportFailure {
  const _ImportFailure({
    required this.title,
    required this.message,
    required this.diagnostics,
  });

  final String title;
  final String message;
  final List<ImportDiagnostic> diagnostics;
}
