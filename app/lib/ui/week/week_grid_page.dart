import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import 'session_detail_sheet.dart';
import 'session_text.dart';
import 'term_sheet.dart';
import 'week_grid_view.dart';

/// 首页：**打开就是整周网格**。
///
/// 这是整个 App 的门面，也是「一眼看全周」这个核心价值所在（规格「看课表」）。
///
/// 它自己不判断任何课表上的事：这一周有什么、哪两格冲突、今天算第几周，全是领域层算好的
/// （`expandWeek`、`WeekRange`、`TermSettings.weekOf`）。这一页只负责摆出来、以及把使用
/// 者的动作（翻周、点格、换学期）转回去。
///
/// 三种「没得看」的状态分开说，不混成一句「空空如也」：
///
/// - **库里一个学年学期都没有**：新装的 App。说「先导入一份课表」，并给出入口。
/// - **这个学期还没导过课表**：说清楚是哪个学期空的，别让人以为课表丢了。
/// - **读库失败**：报错 + 重试，不假装空课表（静默失败是最糟的结果）。
class WeekGridPage extends ConsumerWidget {
  const WeekGridPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final term = ref.watch(selectedTermProvider);

    return Scaffold(
      appBar: AppBar(
        title: TermTitleButton(term: term),
        titleSpacing: 16,
      ),
      body: term == null ? const _NoTerms() : _TermTimetable(term: term),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/import'),
        icon: const Icon(Icons.folder_open),
        label: const Text('导入课表'),
      ),
    );
  }
}

/// 某个学年学期的网格。
class _TermTimetable extends ConsumerWidget {
  const _TermTimetable({required this.term});

  final AcademicTerm term;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetable = ref.watch(termTimetableProvider(term));

    return timetable.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _LoadFailure(
        error: error,
        onRetry: () => ref.invalidate(termTimetableProvider(term)),
      ),
      data: (value) => value == null || value.sessions.isEmpty
          ? _NoSessions(term: term)
          : _WeekBody(timetable: value),
    );
  }
}

/// 网格 + 周次导航。星期栏吸顶是 [WeekGridView] 自己的事，这里只管把周选对。
class _WeekBody extends ConsumerWidget {
  const _WeekBody({required this.timetable});

  final Timetable timetable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(displayedWeekProvider(timetable));
    final range = ref.watch(weekRangeProvider(timetable));
    final grid = ref.watch(weekGridProvider((timetable, week)));
    final currentWeek = ref.watch(currentWeekProvider(timetable));

    return Column(
      children: [
        _WeekNavBar(
          timetable: timetable,
          range: range,
          week: week,
          currentWeek: currentWeek,
          onStep: (delta) =>
              ref.read(displayedWeekProvider(timetable).notifier).step(delta),
          onJumpToToday: () => ref
              .read(displayedWeekProvider(timetable).notifier)
              .jumpToCurrent(),
        ),
        const Divider(height: 1),
        Expanded(
          child: WeekGridView(
            grid: grid,
            // 只有展的正好是本周时，今天那一列才高亮——翻到别的周还标着今天是错的。
            // 算不出今天是第几周（没设「第 1 周的第一天」）时也是 null：不高亮，不猜。
            today: currentWeek == week ? ref.watch(todayProvider) : null,
            dates: weekDates(timetable.settings.firstDayOfWeek1, week),
            onTapCell: (weekday, period) => showSessionDetailSheet(
              context,
              weekday: weekday,
              period: period,
              week: week,
              entries: grid.at(weekday, period).entries,
              bellSchedule: timetable.settings.bellSchedule,
            ),
          ),
        ),
      ],
    );
  }
}

/// 周次导航：前后各一个箭头，中间写第几周与那周的日期，外加「回到本周」。
class _WeekNavBar extends StatelessWidget {
  const _WeekNavBar({
    required this.timetable,
    required this.range,
    required this.week,
    required this.currentWeek,
    required this.onStep,
    required this.onJumpToToday,
  });

  final Timetable timetable;
  final WeekRange range;
  final int week;

  /// 今天算第几教学周。null 表示算不出来（没设「第 1 周的第一天」，或今天不在学期内）。
  final int? currentWeek;

  final void Function(int delta) onStep;
  final VoidCallback onJumpToToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dates = weekDateRangeText(timetable.settings.firstDayOfWeek1, week);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: range.hasPrevious(week) ? () => onStep(-1) : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: '上一周',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '第$week周',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  // 没设「第 1 周的第一天」时说不出日期，但范围还说得出来——
                  // 那个数字来自数据本身，与开学日期无关。
                  dates ?? '共 ${range.length} 周（第${range.from}-${range.to}周）',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: range.hasNext(week) ? () => onStep(1) : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: '下一周',
          ),
          // 算不出「本周」时这个按钮不装样子：点了会**说出来为什么**，而不是把人
          // 送到第 1 周、让人以为那就是本周。
          IconButton(
            onPressed: () => _jump(context),
            icon: const Icon(Icons.today_outlined),
            tooltip: '回到当前教学周',
          ),
        ],
      ),
    );
  }

  void _jump(BuildContext context) {
    final target = currentWeek;
    if (target == null) {
      // 与其把人送到第 1 周、让人以为那就是本周，不如把原因说出来。
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '算不出今天是第几教学周，没法回到本周——'
            '要么这个学期还没设「第 1 周的第一天」，要么今天不在这个学期里。',
          ),
        ),
      );
      return;
    }
    if (target == week) return; // 已经在本周了，什么都不用做。
    onJumpToToday();
  }
}

// ───────────────────────── 没得看的那三种 ─────────────────────────

class _NoTerms extends StatelessWidget {
  const _NoTerms();

  @override
  Widget build(BuildContext context) {
    return const _EmptyView(
      icon: Icons.event_note_outlined,
      title: '还没有课表',
      message: '点右下角「导入课表」，选一份教务系统导出的 .xls —— '
          '导进来之后这里就是一整周的网格。',
    );
  }
}

class _NoSessions extends StatelessWidget {
  const _NoSessions({required this.term});

  final AcademicTerm term;

  @override
  Widget build(BuildContext context) {
    return _EmptyView(
      icon: Icons.grid_off_outlined,
      title: '「${term.label}」里还没有课',
      message: '这个学年学期存着，但一条上课安排都没有（可能是导入时那份文件里没课）。'
          '点右下角重新导入一份。',
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 96),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text('读课表失败：$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
