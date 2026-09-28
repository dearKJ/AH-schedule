import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:flutter/material.dart';

import 'weekday_names.dart';

/// 编辑（或补上）一格上的一条上课安排。存了就返回那条安排，「算了」返回 null。
///
/// **星期与起始节次不在这里改**：它们由使用者在网格里点的那一格给出——预览页上要改的
/// 是「这一格解错了」，不是「把它挪到别处」。真要挪，删了在另一格补一条。
/// 节数（连堂）可以改，那是这一格上的一处事实。
///
/// 校验归领域层：周次走 [WeekSet.parse]（教务系统那套写法），课程名与教室由
/// [ClassSession] 与 [Venue] 自己把关。认不出来就把原因照原样摆出来，**不猜**。
Future<ClassSession?> showSessionEditor(
  BuildContext context, {
  required int weekday,
  required int period,
  required int maxLength,
  ClassSession? session,
}) {
  return showDialog<ClassSession>(
    context: context,
    builder: (_) => _SessionEditorDialog(
      weekday: weekday,
      period: period,
      maxLength: maxLength,
      session: session,
    ),
  );
}

class _SessionEditorDialog extends StatefulWidget {
  const _SessionEditorDialog({
    required this.weekday,
    required this.period,
    required this.maxLength,
    required this.session,
  });

  final int weekday;
  final int period;

  /// 这一格起最多能连几节（到作息时间表最后一节为止）。
  final int maxLength;

  /// 改的那条；补的话是 null。
  final ClassSession? session;

  @override
  State<_SessionEditorDialog> createState() => _SessionEditorDialogState();
}

class _SessionEditorDialogState extends State<_SessionEditorDialog> {
  late final TextEditingController _courseName = TextEditingController(
    text: widget.session?.courseName ?? '',
  );
  late final TextEditingController _teacher = TextEditingController(
    text: widget.session?.teacher ?? '',
  );
  late final TextEditingController _weeks = TextEditingController(
    text: widget.session?.weeks.toText() ?? '',
  );
  late final TextEditingController _room = TextEditingController(
    text: widget.session?.venue.room ?? '',
  );
  late final TextEditingController _campus = TextEditingController(
    text: widget.session?.venue.campus ?? '',
  );
  late int _length = widget.session?.periods.length ?? 1;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_courseName, _teacher, _weeks, _room, _campus]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final ClassSession session;
    try {
      session = ClassSession(
        courseName: _courseName.text,
        teacher: _teacher.text,
        weekday: widget.weekday,
        periods: PeriodSpan(widget.period, _length),
        weeks: WeekSet.parse(_weeks.text),
        venue: Venue(room: _room.text, campus: _campus.text),
      );
    } on FormatException catch (error) {
      setState(() => _error = '周次：${error.message}');
      return;
    } on ArgumentError catch (error) {
      // 领域层写的消息本来就是给人看的，原样摆出来。
      setState(() => _error = error.message?.toString() ?? error.toString());
      return;
    }
    Navigator.of(context).pop(session);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.session == null ? '在这里补一条' : '改这一条'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '位置：${weekdayName(widget.weekday)} 第${widget.period}节起',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _courseName,
              autofocus: true,
              decoration: const InputDecoration(labelText: '课程名称'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _teacher,
              decoration: const InputDecoration(labelText: '教师（可以空着）'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _weeks,
              decoration: const InputDecoration(
                labelText: '周次',
                // 照教务系统那套写法抄：多段之间用空格，单双周写「单周第5周-第15周」。
                hintText: '1-8 10 12-16　或　单周第5周-第15周',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _room,
                    decoration: const InputDecoration(
                      labelText: '教室',
                      hintText: '4J410',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _campus,
                    decoration: const InputDecoration(
                      labelText: '校区（可以空着）',
                      hintText: '主校区',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('连堂节数', style: theme.textTheme.bodyMedium),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _length,
                  onChanged: (value) =>
                      setState(() => _length = value ?? _length),
                  items: [
                    for (var length = 1; length <= widget.maxLength; length++)
                      DropdownMenuItem(
                        value: length,
                        child: Text(length == 1 ? '1 节' : '$length 节'),
                      ),
                  ],
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('算了'),
        ),
        FilledButton(onPressed: _submit, child: const Text('存')),
      ],
    );
  }
}

