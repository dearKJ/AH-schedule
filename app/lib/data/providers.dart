import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'academic_term_repository.dart';
import 'app_database.dart';

/// App 的数据库。
///
/// 在这里抛异常是有意的：数据库必须在 `main()` 里打开（打开是异步的，而且要等
/// `WidgetsFlutterBinding` 起来才能问 path_provider 要目录），再在 `ProviderScope`
/// 里覆写进来。忘了覆写就会当场炸，而不是悄悄用上一个空库。
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(
    'appDatabaseProvider 要在 main() 的 ProviderScope(overrides: …) 里覆写。',
  ),
);

final academicTermRepositoryProvider = Provider<AcademicTermRepository>(
  (ref) => AcademicTermRepository(ref.watch(appDatabaseProvider)),
);

/// 库里现有的学年学期。
///
/// 界面 watch 它，存完之后 invalidate 它——界面上的东西因此总是**从数据库读回来的**，
/// 不会变成界面自己记着的一份副本。
final academicTermsProvider = FutureProvider<List<AcademicTerm>>(
  (ref) => ref.watch(academicTermRepositoryProvider).loadAll(),
);
