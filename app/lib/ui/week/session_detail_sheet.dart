import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:flutter/material.dart';

import '../import/weekday_names.dart';
import 'course_colors.dart';
import 'session_text.dart';

/// 点一格之后那张单子：**这条安排的全部信息**。
///
/// 规格「看课表」第 17 条列全了：课程、教师、地点、校区、节次、周次，以及**由作息时间表
/// 给出的具体时刻**。最后那一项是这张单子存在的理由——网格上只写得下课名，几点上课只有
/// 这里说得清。
///
/// 冲突时在这里**把双方都列出来**，并且不替使用者取舍（规格第 35、36 条）：教务系统本不
/// 该产生这种数据，一旦出现就是要人眼介入的信号。
Future<void> showSessionDetailSheet(
  BuildContext context, {
  required int weekday,
  required int period,
  required int week,
  required List<GridEntry> entries,
  required BellSchedule bellSchedule,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SessionDetailSheet(
      weekday: weekday,
      period: period,
      week: week,
      entries: entries,
      bellSchedule: bellSchedule,
    ),
  );
}

class _SessionDetailSheet extends StatelessWidget {
  const _SessionDetailSheet({
    required this.weekday,
    required this.period,
    required this.week,
    required this.entries,
    required this.bellSchedule,
  });

  final int weekday;
  final int period;
  final int week;
  final List<GridEntry> entries;
  final BellSchedule bellSchedule;

  /// 同一格同一周两条以上 = 冲突。判定在领域层（`WeekCell.hasConflict`），这里只照着画。
  bool get _hasConflict => entries.length > 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              '${weekdayName(weekday)} 第$period节',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 2),
            Text(
              '第$week教学周',
              style: theme.textTheme.bodySmall,
            ),
            if (_hasConflict) ...[
              const SizedBox(height: 12),
              _ConflictNotice(count: entries.length),
            ],
            const SizedBox(height: 12),
            for (final entry in entries) ...[
              _EntryCard(
                entry: entry,
                bellSchedule: bellSchedule,
                // 冲突时两条都标红——只标一条会变成「另一条看着没事」。
                highlight: _hasConflict,
              ),
              const SizedBox(height: 12),
            ],
            if (!_hasConflict)
              Text(
                '这一格这一周就这一条。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 冲突的说明。**把「我不替你取舍」这句话说出来**——不然使用者看到两条并排，会以为
/// App 漏了什么。
class _ConflictNotice extends StatelessWidget {
  const _ConflictNotice({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '这一格这一周有 $count 条安排',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '两条都在，App 不替你取舍。多半是课表改了、或者导入时解错了——'
                  '自己判断该按哪条走。',
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 一条安排的详情。
class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.bellSchedule,
    required this.highlight,
  });

  final GridEntry entry;
  final BellSchedule bellSchedule;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final session = entry.session;
    final color = CourseColors.of(session.courseName, theme.brightness);
    final onColor = CourseColors.textOn(color);
    final time = timeRangeText(session, bellSchedule);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: highlight ? colors.error : colors.outlineVariant,
          width: highlight ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 课程名用它在网格上的那个颜色：一眼把这张单子和格子里那一块对上。
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
            ),
            child: Text(
              session.courseName,
              style: theme.textTheme.titleMedium?.copyWith(
                color: onColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(label: '教师', value: session.teacher ?? '没写'),
                _Row(label: '节次', value: '${session.periods}'),
                _Row(
                  label: '时间',
                  value: time ?? '作息时间表里没有第${session.periods.start}节的时刻',
                  emphasise: true,
                ),
                _Row(
                  label: '地点',
                  value: session.venue.room,
                ),
                _Row(
                  label: '校区',
                  value: session.venue.campus ?? '没写',
                ),
                _Row(label: '周次', value: weeksText(session.weeks)),
                if (session.exceptions.isNotEmpty)
                  _Row(
                    label: '例外',
                    value: [
                      for (final exception in session.exceptions)
                        exceptionText(exception),
                    ].join('、'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 详情里的一行：左边标签、右边值。标签宽度固定，几行才对得齐。
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final String value;

  /// 具体时刻那一行加重一点——它是这张单子最要紧的一项。
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: emphasise
                  ? theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )
                  : theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
