import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:flutter/material.dart';

/// 解析器说的这一处，摆在界面上就是这一行：**位置 + 说明 + 原文**。
///
/// 位置与原文是硬要求：没有它们，使用者拿到「有一个格子解不出来」也无从下手。
/// 两处用它——预览页的「需要留意的地方」（带「补上」「不管了」）与选错文件时的失败页
/// （只说不做，那里还没有可改的草稿）。
///
/// [onFillIn] 只有在知道位置（星期 + 节次）时才有意义：诊断若只说得出字节位置，就
/// 无从「在这一格补上」。这类诊断仍然要摆出来——它说的是「有几处没解出来」。
class DiagnosticTile extends StatelessWidget {
  const DiagnosticTile({
    required this.diagnostic,
    this.handled = false,
    this.onFillIn,
    this.onToggleHandled,
    super.key,
  });

  final ImportDiagnostic diagnostic;

  /// 处理过了（补上了，或者使用者说了不管）。只是把这一行**画淡**，不从列表里消失。
  final bool handled;

  final void Function(int weekday, int period)? onFillIn;
  final void Function(bool handled)? onToggleHandled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final weekday = diagnostic.weekday;
    final period = diagnostic.period;
    final tint = handled
        ? theme.disabledColor
        : (diagnostic.isError ? colors.error : colors.tertiary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                diagnostic.isError ? Icons.error_outline : Icons.info_outline,
                size: 18,
                color: tint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${diagnostic.positionLabel ?? '整份文件'} · '
                  '${diagnostic.severity.label}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: tint),
                ),
              ),
              if (handled) Text('已处理', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 2),
          Text(diagnostic.message, style: theme.textTheme.bodySmall),
          if (diagnostic.rawText != null) ...[
            const SizedBox(height: 4),
            // **原文**——没有它，使用者拿到「有一个格子解不出来」也无从下手。
            Text(
              '原文：「${diagnostic.rawText}」',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (weekday != null && period != null && onFillIn != null)
            TextButton(
              onPressed: () => onFillIn!(weekday, period),
              child: const Text('补上'),
            ),
          if (onToggleHandled != null)
            TextButton(
              onPressed: () => onToggleHandled!(!handled),
              child: Text(handled ? '撤销' : '不管了'),
            ),
        ],
      ),
    );
  }
}

/// 一张课表上挂着多少条例外（停课 / 线上教学）。
///
/// 预览页与导入后的汇总都要说这个数：**整学期覆盖会连带把它们清掉**。
int totalExceptions(Timetable timetable) => timetable.sessions.fold(
  0,
  (sum, session) => sum + session.exceptions.length,
);
