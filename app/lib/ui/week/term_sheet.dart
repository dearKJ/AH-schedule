import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/academic_term_repository.dart';
import '../../data/providers.dart';
import '../academic_term_dialog.dart';

/// AppBar 上那个学期名：点开可以**换一个学年学期**，也可以新存一个。
///
/// 学年学期是课表的隔离单位——换它就是换整张课表——所以它摆在标题这个位置：使用者一眼
/// 看得见自己在看哪个学期的课。
///
/// 一个学期都没有时不显示文字，改说「还没有课表」：这句话比一个空的标题有用。
class TermTitleButton extends StatelessWidget {
  const TermTitleButton({required this.term, super.key});

  final AcademicTerm? term;

  @override
  Widget build(BuildContext context) {
    final label = term?.label ?? '还没有课表';
    return InkWell(
      onTap: () => showTermSheet(context),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

/// 学期那一张单子：库里存着的全列出来，当前那个打钩；底下是「新存一个」。
Future<void> showTermSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _TermSheet(),
  );
}

class _TermSheet extends ConsumerWidget {
  const _TermSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final terms = ref.watch(academicTermsProvider);
    final selected = ref.watch(selectedTermProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('学年学期', style: theme.textTheme.titleMedium),
          ),
          Flexible(
            child: terms.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('读不出库里存着的学年学期：$error'),
              ),
              data: (value) => value.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text('库里还没有学年学期。导入一份课表，它会连学年学期一起存进来。'),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final term in value)
                          ListTile(
                            title: Text(term.label),
                            subtitle: Text(term.id),
                            trailing: term == selected
                                ? Icon(
                                    Icons.check,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              ref
                                  .read(selectedTermProvider.notifier)
                                  .select(term);
                              Navigator.of(context).pop();
                            },
                          ),
                      ],
                    ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('新存一个学年学期'),
            subtitle: const Text('课表要挂在一个学年学期上；导入时没有的话会问你'),
            onTap: () => _addTerm(context, ref),
          ),
        ],
      ),
    );
  }

  /// 新存一个学年学期。**只存学期本身**，不建课表——课表由导入或手动录入填。
  ///
  /// 与原来首页那个按钮同一件事，只是换了个地方摆：学年学期的写法归领域层认
  /// （[AcademicTerm.parseLabel]），这里只负责问与存。
  Future<void> _addTerm(BuildContext context, WidgetRef ref) async {
    final term = await showAcademicTermDialog(context);
    if (term == null) return;

    final AcademicTermRepository repository = ref.read(
      academicTermRepositoryProvider,
    );
    await repository.save(term);
    // 重新问数据库要一遍，而不是把刚存进去的东西塞进界面。
    ref.invalidate(academicTermsProvider);
    ref.read(selectedTermProvider.notifier).select(term);
    if (context.mounted) Navigator.of(context).pop();
  }
}
