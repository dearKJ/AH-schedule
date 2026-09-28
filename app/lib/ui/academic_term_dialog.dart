import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:flutter/material.dart';

/// 让使用者写一个**学年学期**，认出来了就把它交回去；「算了」返回 null。
///
/// 写法归领域层认（[AcademicTerm.parseLabel]），界面只负责把认不出来的原文摆在输入框
/// 底下——**不替使用者猜**：学年学期认错等于把课表挂到别的学期上。
///
/// 这里**不落库**，也不管谁来落。要存进库的地方（首页那个按钮）自己存；只是想知道
/// 使用者写的是哪个学期的（导入预览里改学期）拿它的返回值就行。
Future<AcademicTerm?> showAcademicTermDialog(
  BuildContext context, {
  String title = '学年学期',
  String? initialLabel,
  String? description,
  String confirmLabel = '确定',
}) {
  return showDialog<AcademicTerm>(
    context: context,
    builder: (_) => _AcademicTermDialog(
      title: title,
      initialLabel: initialLabel,
      description: description,
      confirmLabel: confirmLabel,
    ),
  );
}

class _AcademicTermDialog extends StatefulWidget {
  const _AcademicTermDialog({
    required this.title,
    required this.initialLabel,
    required this.description,
    required this.confirmLabel,
  });

  final String title;
  final String? initialLabel;
  final String? description;
  final String confirmLabel;

  @override
  State<_AcademicTermDialog> createState() => _AcademicTermDialogState();
}

class _AcademicTermDialogState extends State<_AcademicTermDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialLabel ?? '',
  );
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final AcademicTerm term;
    try {
      term = AcademicTerm.parseLabel(_controller.text);
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
      return;
    }
    Navigator.of(context).pop(term);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.description != null) ...[
            Text(widget.description!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: '学年学期',
              // 用的就是教务系统那种写法，照着抄就行。
              hintText: '2026-2027学年第一学期',
              errorText: _errorText,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('算了'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
