import 'dart:math' as math;

import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:flutter/material.dart';

import '../import/weekday_names.dart';
import 'course_colors.dart';

/// 周网格：**一屏尽收整周**。
///
/// 画什么全由领域层算好了——[WeekGrid] 是 `课表 + 教学周号 → 该周的格子` 的产物，这一层
/// 只把它摆出来。所以这里没有一处判断「这周到底上不上」：周次不含本周、这周停课，那些安排
/// 根本不在格子里；同一格两条＝冲突，也是 [WeekCell.hasConflict] 说了算。
///
/// 摆法上有三件事是这一页的承诺：
///
/// 1. **星期栏吸顶**：纵向滚动时星期那一行不动（它不在滚动区里，见 [build]）。
/// 2. **空格留白**：没课的格子什么都不摆，不写「没课」也不铺底色。
/// 3. **今天那一列高亮**：[today] 给出今天是哪一天，它的星期那一列打底、并且在星期栏上
///    标出来。不知道今天是哪天（[today] 为 null，或没设「第 1 周的第一天」）就都不高亮
///    ——不猜。
class WeekGridView extends StatelessWidget {
  const WeekGridView({
    required this.grid,
    required this.today,
    required this.onTapCell,
    this.dates,
    super.key,
  });

  final WeekGrid grid;

  /// 今天。null 表示「不知道今天是哪天」，那一列就不高亮。
  final DateTime? today;

  /// 这一周七天的日期（周一 … 周日）。
  ///
  /// 设了「第 1 周的第一天」才有。没设开学日期时日期栏空着，但网格照画——**不猜一个日期
  /// 出来**。
  final List<DateTime>? dates;

  /// 点了一格。空着也会回调——点空格子看看这儿本来有没有课，是常见动作。
  final void Function(int weekday, int period) onTapCell;

  /// 节次那一列的宽度。放得下「第12节 / 20:40」两行小字。
  static const double _periodColumnWidth = 38;

  /// 一格的最小高度。
  static const double _blockHeight = 52;

  /// 网格外框的左右内边距。
  static const double _padding = 4;

  /// 今天是星期几（1 = 星期一 … 7 = 星期日）；不知道就是 null。
  int? get _todayWeekday => today?.weekday;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dayWidth = math.max(
          30.0,
          (constraints.maxWidth - _periodColumnWidth - _padding * 2) / 7,
        );
        final tableWidth = _periodColumnWidth + dayWidth * 7;

        return Column(
          children: [
            // 星期栏在滚动区**之外**——这就是「吸顶」这件事本身，不靠 sliver 去粘。
            Padding(
              padding: const EdgeInsets.fromLTRB(_padding, 0, _padding, 0),
              child: SizedBox(
                width: tableWidth,
                child: Row(
                  children: [
                    const SizedBox(width: _periodColumnWidth),
                    for (var weekday = 1; weekday <= 7; weekday++)
                      SizedBox(
                        width: dayWidth,
                        child: _DayHeader(
                          weekday: weekday,
                          today: today,
                          date: dates == null ? null : dates![weekday - 1],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(_padding, 0, _padding, 24),
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      for (var index = 0; index < grid.periods.length; index++)
                        _Row(
                          grid: grid,
                          periods: grid.periods,
                          rowIndex: index,
                          dayWidth: dayWidth,
                          todayWeekday: _todayWeekday,
                          onTapCell: onTapCell,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 星期栏上的一格：星期几 + 那天的日期（设了「第 1 周的第一天」才有）。
class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.weekday,
    required this.today,
    required this.date,
  });

  final int weekday;
  final DateTime? today;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // 今天那一列：打底 + 加粗。一周里只有这一列是这样。
    final isToday = today != null && weekday == today!.weekday;
    final day = date;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isToday ? colors.primaryContainer : null,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            // 一列只有 40 来像素宽，写全称放不下——简称 + 底下的日期够认。
            weekdayShortName(weekday),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isToday ? FontWeight.bold : null,
              color: isToday ? colors.onPrimaryContainer : null,
            ),
          ),
          if (day != null)
            Text(
              '${day.month}/${day.day}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: isToday
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// 一行：节次栏 + 7 个格子。
///
/// 行高**由这一行里从本节起画的那些课撑出来**，不写死：一节高，冲突时两节高。连堂那一整块
/// （`节数 × 一格高`）画在它起始的那一行里，于是纵向看是一条连着的色块，横向仍然是 7 天。
class _Row extends StatelessWidget {
  const _Row({
    required this.grid,
    required this.periods,
    required this.rowIndex,
    required this.dayWidth,
    required this.todayWeekday,
    required this.onTapCell,
  });

  final WeekGrid grid;
  final List<PeriodTime> periods;
  final int rowIndex;
  final double dayWidth;
  final int? todayWeekday;
  final void Function(int weekday, int period) onTapCell;

  PeriodTime get _periodTime => periods[rowIndex];

  WeekCell _cellAt(int weekday) => grid.days[weekday - 1].cells[rowIndex];

  /// 这一行要占几节高：本行每一格里，从本节起画的那几条**一共要多少地方**，取最大的那个。
  ///
  /// 两件事都得算进去：
  ///
  /// - 单条占的那一块是 `节数 × 一格高` 的一整块（连堂画在它起始的这一行里），所以至少
  ///   要有它那几节高。
  /// - 冲突的一格是几条上下叠着画的，每条各占自己那一块，所以是它们的**和**——只看条数
  ///   或只看最长的那条，都会把其中一条截掉半截。
  int get _rowBlocks {
    var blocks = 1;
    for (var weekday = 1; weekday <= 7; weekday++) {
      var needed = 0;
      for (final entry in _cellAt(weekday).entries) {
        if (entry.session.periods.start != _periodTime.period) continue;
        needed += entry.session.periods.length;
      }
      if (needed > blocks) blocks = needed;
    }
    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final minHeight = _rowBlocks * WeekGridView._blockHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: WeekGridView._periodColumnWidth,
          child: _PeriodLabel(periodTime: _periodTime, height: minHeight),
        ),
        for (var weekday = 1; weekday <= 7; weekday++)
          SizedBox(
            width: dayWidth,
            child: _Cell(
              weekday: weekday,
              period: _periodTime.period,
              cell: _cellAt(weekday),
              isToday: weekday == todayWeekday,
              minHeight: minHeight,
              borderColor: colors.outlineVariant,
              onTap: () => onTapCell(weekday, _periodTime.period),
            ),
          ),
      ],
    );
  }
}

/// 节次栏的一格：第几节 + 起止时刻。上午 / 下午 / 晚上用左边一道细线分开。
class _PeriodLabel extends StatelessWidget {
  const _PeriodLabel({required this.periodTime, required this.height});

  final PeriodTime periodTime;

  /// 这一行的最小高度：一节的高度。连堂那几行比它高，这一栏跟着拉伸。
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: BoxConstraints(minHeight: height),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 0.5),
          left: BorderSide(color: _blockColor(theme, periodTime.block), width: 3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${periodTime.period}',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            periodTime.start.toText(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 上午 / 下午 / 晚上各一道颜色不同的边——一屏里三段的分界一眼可辨。
  ///
  /// 用固定的三种颜色，不取主题色：它标的是「上午 / 下午 / 晚上」这件事本身，不是当前
  /// 配色的一部分。按明暗主题各调一档，深色下不至于糊在背景里。
  Color _blockColor(ThemeData theme, DayBlock block) {
    final dark = theme.brightness == Brightness.dark;
    return switch (block) {
      DayBlock.morning =>
        dark ? const Color(0xFF8A6D1F) : const Color(0xFFE0A800),
      DayBlock.afternoon =>
        dark ? const Color(0xFF2E6B45) : const Color(0xFF4CAF50),
      DayBlock.evening =>
        dark ? const Color(0xFF7A3F5E) : const Color(0xFFD08190),
    };
  }
}

/// 一个格子：有课画课、没课留白、冲突并排标红。
///
/// 连堂那一块**只画在它起始的那一行**，高度是它的节数 × 一格高——所以它把跨的那几格
/// 占满，而下几行在这个格子里是空的（那几行的高度本来就被它撑起来了）。
class _Cell extends StatelessWidget {
  const _Cell({
    required this.weekday,
    required this.period,
    required this.cell,
    required this.isToday,
    required this.minHeight,
    required this.borderColor,
    required this.onTap,
  });

  final int weekday;
  final int period;
  final WeekCell cell;
  final bool isToday;

  /// 这一行的高度（见 `_Row._maxStarts`）。空格子靠它撑出网格的形状。
  final double minHeight;

  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final entries = cell.entries;
    final isConflict = cell.hasConflict;

    // 从这一节起画的那些安排。跨过本节的连堂不在这儿重复画。
    final starts = [
      for (final entry in entries)
        if (entry.session.periods.start == period) entry,
    ];

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        decoration: BoxDecoration(
          // 今天那一列：空着的格子打一层很淡的底，让人一眼看得到今天这一竖条。
          color: isToday && entries.isEmpty
              ? colors.primaryContainer.withValues(alpha: 0.18)
              : null,
          border: Border(
            top: BorderSide(color: borderColor, width: 0.5),
            left: BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(1),
        child: starts.isEmpty
            ? const SizedBox(
                height: WeekGridView._blockHeight,
              )
            // 冲突时上下叠着画：两条都画，谁也不盖谁。只有一条时让它自己撑满这一行——
            // 连堂占满它跨的那几格，靠的就是这个。
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in starts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: starts.length > 1
                          ? SizedBox(
                              height:
                                  entry.session.periods.length *
                                      WeekGridView._blockHeight -
                                  2,
                              child: _EntryTile(entry: entry, conflict: true),
                            )
                          : _EntryTile(entry: entry, conflict: isConflict),
                    ),
                ],
              ),
      ),
    );
  }
}

/// 格子里那一块课。
///
/// 高度**由外面给**（`SizedBox` 包着它，见 [_Cell]），这样只有一条时它能撑满整行——连堂
/// 占满它跨的那几格靠的就是这一下；冲突时外面会给它自己那一块的高度，几条上下叠着。
class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.conflict});

  final GridEntry entry;
  final bool conflict;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final session = entry.session;
    // 同课同色：颜色只由课名算出来，同一个名字在哪儿都是这一个色。
    final color = CourseColors.of(session.courseName, theme.brightness);
    final onColor = CourseColors.textOn(color);

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        // 冲突标红：红框 + 加粗，几条叠着时一眼看得出这是要人管的。
        border: conflict ? Border.all(color: colors.error, width: 1.5) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Text(
        session.courseName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: onColor,
          fontSize: 10,
          height: 1.15,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
