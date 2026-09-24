import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/academic_term_repository.dart';
import '../../data/providers.dart';

/// 走路骨架的门面（issue #4）。
///
/// 它要证明的不是「有个界面」，而是**三层真的接上了**：这里的每一个字都来自数据库，
/// 写入也真的落库。下一票（周网格）会把它换成真课表。
///
/// 领域层的词照 `CONTEXT.md` 用——界面上的「学年学期」就是 `AcademicTerm`。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terms = ref.watch(academicTermsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AH-schedule')),
      body: terms.when(
        data: (value) => _TermList(terms: value),
        error: (error, _) => _LoadFailure(
          error: error,
          onRetry: () => ref.invalidate(academicTermsProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _AddAcademicTermDialog(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('存一个学年学期'),
      ),
    );
  }
}

class _TermList extends StatelessWidget {
  const _TermList({required this.terms});

  final List<AcademicTerm> terms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // 这一票的核心：这个数字是刚才那次数据库查询的结果，不是写在界面上的常量。
        Text('库里存了 ${terms.length} 个学年学期', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          '数据来自设备上的 SQLite 数据库，重启 App 还在。',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (terms.isEmpty)
          const _EmptyHint()
        else
          for (final term in terms)
            Card(
              child: ListTile(title: Text(term.label), subtitle: Text(term.id)),
            ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Text(
        '库里还没有学年学期。\n点右下角存一个，它会从数据库里被读回来。',
        textAlign: TextAlign.center,
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
            Text('读数据库失败：$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

class _AddAcademicTermDialog extends ConsumerStatefulWidget {
  const _AddAcademicTermDialog();

  @override
  ConsumerState<_AddAcademicTermDialog> createState() =>
      _AddAcademicTermDialogState();
}

class _AddAcademicTermDialogState
    extends ConsumerState<_AddAcademicTermDialog> {
  final _controller = TextEditingController();
  String? _errorText;
  var _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final AcademicTerm term;
    try {
      // 学年学期怎么写归领域层认——数据层不碰规则，界面更不碰。
      term = AcademicTerm.parseLabel(_controller.text);
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
      return;
    }

    setState(() => _saving = true);
    final AcademicTermRepository repository = ref.read(
      academicTermRepositoryProvider,
    );
    await repository.save(term);
    if (!mounted) return;

    // 重新问数据库要一遍，而不是把刚存进去的东西塞进界面。
    ref.invalidate(academicTermsProvider);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('存一个学年学期'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        enabled: !_saving,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          labelText: '学年学期',
          // 用的就是教务系统那种写法，照着抄就行。
          hintText: '2026-2027学年第一学期',
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('算了'),
        ),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('存')),
      ],
    );
  }
}
