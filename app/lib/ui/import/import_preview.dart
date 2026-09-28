import 'dart:math' as math;

import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../academic_term_dialog.dart';
import 'diagnostic_tile.dart';
import 'import_draft.dart';
import 'session_editor.dart';
import 'weekday_names.dart';

/// 导入预览：**确认之前把话说清楚，把解不了的地方摆出来，并且当场能改**。
///
/// 预览页是必需品而非锦上添花——教务系统的模板自己有 bug，解析器迟早会碰到没见过的
/// 写法，**静默失败是最糟的结果**。所以这一页要说三件事：
///
/// 1. 导入会**替换整学期**，并且**手动标记的例外会被清掉**（v0.1 不做例外保留）。
/// 2. 解出了多少条、有几处需要留意。
/// 3. 哪一格里有什么没解出来（位置 + 原文），并且**就在那儿补上**。
///
/// 改的是 [draft]——它就是入库时唯一的那份来源，没有「原件」与「改过的」两份并存。
class ImportPreview extends ConsumerStatefulWidget {
  const ImportPreview({
    required this.draft,
    required this.fileTermHint,
    super.key,
  });

  final ImportDraft draft;

  /// 文件页头里写的学年学期，认不出来时是 null。只用来把学期那一行说清楚
  /// （「按文件里写的填的」还是「你填的」），**不是归属的依据**。
  final AcademicTerm? fileTermHint;

  @override
  ConsumerState<ImportPreview> createState() => _ImportPreviewState();
}

class _ImportPreviewState extends ConsumerState<ImportPreview> {
  ImportDraft get _draft => widget.draft;

  /// 网格要画几节：作息时间表里有的节次 ∪ 这份草稿里出现过的节次。
  ///
  /// 取并集是为了**不漏**：一份把课排到第 13 节的文件，在 12 节的表里不该有一格是
  /// 「看不见的」——那正是这一页最不能出的错。
  List<int> get _periods {
    final periods = <int>{
      for (final period in _bellSchedule().periods) period.period,
      for (final entry in _draft.entries) ...entry.session.periods.periods,
    }.toList()..sort();
    return periods;
  }

  BellSchedule _bellSchedule() =>
      _existing()?.settings.bellSchedule ?? TermSettings().bellSchedule;

  Timetable? _existing() => ref.watch(termTimetableProvider(_draft.term)).value;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _OverwriteWarning(
          term: _draft.term,
          existing: ref.watch(termTimetableProvider(_draft.term)),
        ),
        const SizedBox(height: 12),
        _Summary(draft: _draft),
        const SizedBox(height: 12),
        _TermRow(
          draft: _draft,
          fileTermHint: widget.fileTermHint,
          onChange: _changeTerm,
        ),
        if (_draft.diagnostics.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Diagnostics(draft: _draft, onFillIn: _fillIn, onToggle: _toggle),
        ],
        const SizedBox(height: 12),
        _Grid(draft: _draft, periods: _periods, onTapCell: _openCell),
      ],
    );
  }

  Future<void> _changeTerm() async {
    final term = await showAcademicTermDialog(
      context,
      title: '导入到哪个学年学期',
      description: '导入会替换这个学期的整张课表。文件页头里写的只是参考，改这里才算数。',
      initialLabel: _draft.term.label,
      confirmLabel: '就这个',
    );
    if (term == null || !mounted) return;
    setState(() => _draft.term = term);
  }

  void _toggle(int index, {required bool handled}) =>
      setState(() => _draft.setHandled(index, handled: handled));

  /// 一条诊断「补上」：在这一格上开编辑器，存了就把它标成已处理。
  ///
  /// **只标这一条**——同一格上还挂着别的诊断，那是别的没解出来的内容，各自处理。
  Future<void> _fillIn(int index, int weekday, int period) async {
    final session = await _editAt(weekday, period);
    if (session == null || !mounted) return;
    setState(() => _draft.setHandled(index, handled: true));
  }

  /// 点一格：有安排就把那一格的安排列出来（可改可删），空着就直接开编辑器补一条。
  Future<void> _openCell(int weekday, int period) async {
    final entries = _draft.at(weekday, period);
    if (entries.isEmpty) {
      await _editAt(weekday, period);
      return;
    }
    if (!mounted) return;

    final action = await showModalBottomSheet<_CellAction>(
      context: context,
      builder: (_) => _CellSheet(
        weekday: weekday,
        period: period,
        entries: entries,
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _EditEntry(:final id):
        final entry = entries.firstWhere((entry) => entry.id == id);
        final session = await _editAt(weekday, period, existing: entry);
        if (session == null || !mounted) return;
        if (session == entry.session) return; // 没改就不动它
        setState(() => _draft.replace(id, session));
      case _DeleteEntry(:final id):
        setState(() => _draft.remove(id));
      case _AddEntry():
        await _editAt(weekday, period);
    }
  }

  /// 开编辑器。存了就返回那条安排，算了返回 null。
  ///
  /// [existing] 给的是「改这一条」，不给就是「在这一格补一条」——**补的那条这里就落进
  /// 草稿**，改的那条由调用方拿返回值去 `replace`。两种意图靠一个参数说清，免得出现
  /// 「补一条、但又带着一条已有的」这种自相矛盾的调用。
  Future<ClassSession?> _editAt(
    int weekday,
    int period, {
    DraftEntry? existing,
  }) async {
    final session = await showSessionEditor(
      context,
      weekday: weekday,
      period: period,
      maxLength: math.max(1, _periods.last - period + 1),
      session: existing?.session,
    );
    if (session == null || !mounted) return null;
    if (existing == null) setState(() => _draft.add(session));
    return session;
  }
}

/// 预览页上点一个格子要做什么。
sealed class _CellAction {
  const _CellAction();
}

class _EditEntry extends _CellAction {
  const _EditEntry(this.id);
  final int id;
}

class _DeleteEntry extends _CellAction {
  const _DeleteEntry(this.id);
  final int id;
}

class _AddEntry extends _CellAction {
  const _AddEntry();
}

// ───────────────────────── 会替换整学期 ─────────────────────────

/// 导入前必须说清楚的两件事：**整学期覆盖**，以及**手动标记的例外会被清除**。
///
/// 说得出具体数字就不含糊：这个学期现在存着多少条安排、多少条例外，一并报出来——
/// 「会替换」这句话配上数字，才不至于被读成「会合并」。
class _OverwriteWarning extends StatelessWidget {
  const _OverwriteWarning({required this.term, required this.existing});

  final AcademicTerm term;
  final AsyncValue<Timetable?> existing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: colors.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '会替换「${term.label}」的整学期课表',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              switch (existing) {
                AsyncData(value: final timetable?) =>
                  '这个学期现在有 ${timetable.sessions.length} 条上课安排、'
                      '${totalExceptions(timetable)} 条例外（停课 / 线上教学）。'
                      '这次导入会把它们整批换掉——'
                      '手动标记的例外不会保留，重导之后要重新标。',
                AsyncData() => '这个学期库里还没有课表，导入会新建它。',
                AsyncError(error: final error) => '读不出这个学期现在存着什么：$error',
                _ => '正在看这个学期现在存着什么……',
              },
              style: TextStyle(color: colors.onErrorContainer),
            ),
            const SizedBox(height: 8),
            Text(
              '学期设置（第 1 周的第一天、作息时间表）不受影响，导入不动它。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 汇总 ─────────────────────────

/// 这次解析的质量：解出多少条、有几处需要留意、现在这份有多少条。
class _Summary extends StatelessWidget {
  const _Summary({required this.draft});

  final ImportDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('这次解析', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('解出 ${draft.parsedCount} 条上课安排'),
            Text(
              _pendingLabel(draft),
              style: draft.pendingCount > 0
                  ? TextStyle(color: theme.colorScheme.error)
                  : null,
            ),
            Text('这份课表现在有 ${draft.length} 条，确认后按它入库'),
            if (draft.parsedCount == 0)
              Text(
                '这份文件里一条上课安排都没解出来——确认之后，这个学期的课表就是空的。'
                '先看清楚是不是选错了文件。',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            if (draft.touchedCount > 0)
              Text(
                '其中你补了 ${draft.addedCount} 条、改了 ${draft.replacedCount} 条',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

String _pendingLabel(ImportDraft draft) {
  final total = draft.diagnostics.length;
  if (total == 0) return '没有需要留意的地方';
  if (draft.pendingCount == 0) return '$total 处需要留意，都已经处理过了';
  return '${draft.pendingCount} 处需要留意（一共 $total 处）';
}

// ───────────────────────── 学年学期 ─────────────────────────

/// 这份课表挂到哪个学年学期，以及它凭什么。
class _TermRow extends StatelessWidget {
  const _TermRow({
    required this.draft,
    required this.fileTermHint,
    required this.onChange,
  });

  final ImportDraft draft;
  final AcademicTerm? fileTermHint;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = fileTermHint;
    return Card(
      // 不用 ListTile：它把 trailing 的宽度从副标题里扣掉的方式，在副标题偏长时会
      // 让文字从按钮底下穿过去。这一行自己排：左边一列字，右边一个按钮。
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '导入到：${draft.term.label}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint == null
                        ? '文件页头里没写学年学期，这个是你填的'
                        : hint.id == draft.term.id
                        ? '文件页头里写的就是这个'
                        : '文件页头里写的是「${hint.label}」，你改成了别的学期',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onChange, child: const Text('改')),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 解析不了的地方 ─────────────────────────

/// 每一处没解出来的东西：**位置 + 原文**，外加就地补上。
///
/// 这一块是这一页存在的理由。没有它，「有内容没解出来」就只剩一个数字，使用者拿着
/// 数字无从下手；有了它，每一处都能当场改掉，不必先存一份错的再回来修。
class _Diagnostics extends StatelessWidget {
  const _Diagnostics({
    required this.draft,
    required this.onFillIn,
    required this.onToggle,
  });

  final ImportDraft draft;
  final void Function(int index, int weekday, int period) onFillIn;
  final void Function(int index, {required bool handled}) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('需要留意的地方', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (var index = 0; index < draft.diagnostics.length; index++)
              DiagnosticTile(
                diagnostic: draft.diagnostics[index],
                handled: draft.isHandled(index),
                onFillIn: (weekday, period) => onFillIn(index, weekday, period),
                onToggleHandled: (handled) =>
                    onToggle(index, handled: handled),
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 网格 ─────────────────────────

/// 预览用的网格：7 天 × 几节，格子上是这门课的名字与周次。
///
/// 它刻意比真课表（issue #10 的周网格）素：没有配色、没有今天高亮、没有周次切换。
/// 这一页要的是**每一格都对得上**，不是好看。
///
/// **不走 `core` 的 `expandWeek`**：那个是「某一教学周里有什么」，而这里要的是
/// 「这份文件里的每一条安排都在、都还没错」——周次错开的两条安排（`1-8周` 与 `9-18周`）
/// 在任何一周里都不会同时出现，可这一页必须让它们都看得见，否则「这一格解错了」就没人
/// 发现。所以这里按安排自己的星期与节次跨度摆，不按某一周展开。
class _Grid extends StatelessWidget {
  const _Grid({
    required this.draft,
    required this.periods,
    required this.onTapCell,
  });

  final ImportDraft draft;
  final List<int> periods;
  final void Function(int weekday, int period) onTapCell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('预览', style: theme.textTheme.titleSmall),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              const periodWidth = 30.0;
              final dayWidth = math.max(
                46.0,
                (constraints.maxWidth - periodWidth) / 7,
              );
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: periodWidth + dayWidth * 7,
                  child: Table(
                    border: TableBorder.all(
                      color: theme.dividerColor,
                      width: 0.5,
                    ),
                    columnWidths: {
                      0: const FixedColumnWidth(periodWidth),
                      for (var day = 1; day <= 7; day++)
                        day: FixedColumnWidth(dayWidth),
                    },
                    defaultVerticalAlignment:
                        TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        children: [
                          const _GridHeader(''),
                          for (var day = 1; day <= 7; day++)
                            _GridHeader(weekdayShortName(day)),
                        ],
                      ),
                      for (final period in periods)
                        TableRow(
                          children: [
                            _GridHeader('$period'),
                            for (var weekday = 1; weekday <= 7; weekday++)
                              _GridCell(
                                draft: draft,
                                weekday: weekday,
                                period: period,
                                onTap: () => onTapCell(weekday, period),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              '点一格可以改或删里面的安排；空格子直接补一条。'
              '标红的格子是有一处没解出来的内容。',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridHeader extends StatelessWidget {
  const _GridHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.center,
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.draft,
    required this.weekday,
    required this.period,
    required this.onTap,
  });

  final ImportDraft draft;
  final int weekday;
  final int period;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final entries = draft.at(weekday, period);
    final open = draft.hasOpenErrorAt(weekday, period);

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: open
              ? colors.errorContainer
              : entries.isEmpty
              ? null
              : colors.surfaceContainerHighest,
          border: open
              ? Border.all(color: colors.error, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.session.courseName,
                      style: theme.textTheme.labelSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      // 周次摆出来，同一格上「一门课上半个学期、另一门接下半个学期」
                      // 才看得出来——那正是这一页要使用者确认的事。
                      _weeksText(entry.session.weeks),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: theme.textTheme.labelSmall?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 点一格之后那张单子：这一格上有什么，以及能拿它怎么办。
class _CellSheet extends StatelessWidget {
  const _CellSheet({
    required this.weekday,
    required this.period,
    required this.entries,
  });

  final int weekday;
  final int period;
  final List<DraftEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '${weekdayName(weekday)} 第$period节',
              style: theme.textTheme.titleMedium,
            ),
          ),
          for (final entry in entries)
            ListTile(
              title: Text(entry.session.courseName),
              subtitle: Text(_describe(entry.session)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: '删掉这条',
                onPressed: () =>
                    Navigator.of(context).pop(_DeleteEntry(entry.id)),
              ),
              onTap: () => Navigator.of(context).pop(_EditEntry(entry.id)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('在这一格再补一条'),
              onPressed: () => Navigator.of(context).pop(const _AddEntry()),
            ),
          ),
        ],
      ),
    );
  }
}

/// 周次的展示写法。
///
/// **不能一律在后头接一个「周」字**：[WeekSet.toText] 有两种形态，普通区间那种不带
/// 后缀（`1-8 10`），单双周那种本身就以「周」结尾（`单周第5周-第15周`）——一律接就会
/// 写出「单周第5周-第15周周」。这个字是给使用者看的，写错了就是一眼可见的错。
String _weeksText(WeekSet weeks) {
  final text = weeks.toText();
  return text.endsWith('周') ? text : '$text周';
}

/// 一条安排写成一行：课程、教师、周次、地点、节次。
String _describe(ClassSession session) {
  final parts = <String>[
    if (session.teacher != null) session.teacher!,
    '${session.periods}',
    _weeksText(session.weeks),
    session.venue.toText(),
    for (final exception in session.exceptions) _describeException(exception),
  ];
  return parts.join(' · ');
}

String _describeException(SessionException exception) => switch (exception) {
  Cancellation(:final week) => '第$week周停课',
  OnlineTeaching(:final week) => '第$week周线上教学',
};
