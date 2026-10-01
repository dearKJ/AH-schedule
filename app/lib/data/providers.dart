import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'academic_term_repository.dart';
import 'app_database.dart';
import 'timetable_repository.dart';
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

/// 课表内容（上课安排 / 例外 / 学期设置）的读写入口。
final timetableRepositoryProvider = Provider<TimetableRepository>(
  (ref) => TimetableRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(academicTermRepositoryProvider),
  ),
);

/// 库里现有的学年学期。
///
/// 界面 watch 它，存完之后 invalidate 它——界面上的东西因此总是**从数据库读回来的**，
/// 不会变成界面自己记着的一份副本。
final academicTermsProvider = FutureProvider<List<AcademicTerm>>(
  (ref) => ref.watch(academicTermRepositoryProvider).loadAll(),
);

/// **库里现在**存着的某个学年学期的整张课表。没存过是 null。
///
/// 与 [academicTermsProvider] 同理，它是「读回来的」而不是界面记着的。导入预览要用它
/// 说出两件事：这个学期**现在**有多少条安排与例外（会被整学期覆盖掉），以及它的学期
/// 设置长什么样（导入不动它，得原样带回去）。
final termTimetableProvider = FutureProvider.family<Timetable?, AcademicTerm>(
  (ref, term) => ref.watch(timetableRepositoryProvider).load(term),
);

// ───────────────────────── 周网格要看的那几个 ─────────────────────────

/// 今天是哪一天。
///
/// 单独拎出来是为了让「今天那一列高亮」这件事**有个统一的出处**：界面各处都读它，
/// 以后要冻结时间（截图、测试）也只改这一处。
final todayProvider = Provider<DateTime>((ref) => DateTime.now());

/// 现在看的是哪个学年学期。
///
/// 库里一个学期都没有时是 null——那不是错误，是新装 App 的正常状态，界面该说
/// 「先导入一份课表」而不是报错。
///
/// 选中的学期**不落库**（规格没要求记住上次看的是哪个学期）：App 重启后回到库里第一个。
final selectedTermProvider =
    NotifierProvider<SelectedTermNotifier, AcademicTerm?>(
      SelectedTermNotifier.new,
    );

class SelectedTermNotifier extends Notifier<AcademicTerm?> {
  @override
  AcademicTerm? build() {
    final terms = ref.watch(academicTermsProvider).value;
    final current = state;
    // 库里读回来之后，选中的那个如果已经不存在了（换了库、或者刚被删），回落到第一个。
    if (current != null && (terms?.contains(current) ?? false)) return current;
    return terms == null || terms.isEmpty ? null : terms.first;
  }

  /// 使用者点了一个别的学期。
  void select(AcademicTerm term) => state = term;
}

/// 某个学年学期这份课表能翻到的周次范围。
final weekRangeProvider = Provider.family<WeekRange, Timetable>(
  (ref, timetable) =>
      WeekRange.of(timetable.sessions, settings: timetable.settings),
);

/// 现在展的是第几教学周。
///
/// 键是课表：换学期、或者这张课表刚被整学期覆盖，都该重新落一次——落点见
/// [WeekRange.weekFor]（设了开学日期就落在当前教学周，否则落在数据的第一周）。
final displayedWeekProvider =
    NotifierProvider.family<DisplayedWeekNotifier, int, Timetable>(
      DisplayedWeekNotifier.new,
    );

class DisplayedWeekNotifier extends Notifier<int> {
  DisplayedWeekNotifier(this.timetable);

  /// 这份课表由 family 的参数带进来。Riverpod 3 不公开「取 family 参数」的口子，
  /// 所以在构造时收下。
  final Timetable timetable;

  @override
  int build() {
    // build 会随课表变化重跑，所以「当前教学周」每次都是重新算的，不缓存。
    return _range.weekFor(ref.read(todayProvider), timetable.settings.weekOf);
  }

  WeekRange get _range => ref.read(weekRangeProvider(timetable));

  /// 往前 / 往后翻。**翻到边界就停住**，不回绕——连着点几下「下一周」，停住是对的，
  /// 从最后一周跳回第一周不是。
  void step(int delta) {
    final next = state + delta;
    if (!_range.contains(next)) return;
    state = next;
  }

  /// 跳回当前教学周。没设「第 1 周的第一天」时算不出来，就落在这段范围的第一周。
  void jumpToCurrent() {
    state = _range.weekFor(ref.read(todayProvider), timetable.settings.weekOf);
  }
}

/// 「今天算第几教学周」——算不出来时是 null。
///
/// 网格里今天那一列要不要高亮、周次导航里「回到本周」能不能跳，问的都是它：两处各算
/// 一遍迟早会对不上。算不出来有两种情形（**没设「第 1 周的第一天」**、**今天不在这个
/// 学期里**），对界面来说都是「没有本周」这一件事——[TermSettings.weekOf] 抛的两种异常
/// 在这里一并收成 null。
final currentWeekProvider = Provider.family<int?, Timetable>((ref, timetable) {
  try {
    return timetable.settings.weekOf(ref.watch(todayProvider));
  } on StateError {
    return null;
  } on ArgumentError {
    return null;
  }
});

/// 这张课表的某一周展开成格子——`课表 + 教学周号 → 该周的格子`。
///
/// 领域层算好的东西原样交给界面，界面不自己拼格子：冲突判定（同一格 + 同一周 +
/// 两条安排）在 [WeekGrid] 里，这里只负责把它取出来。
final weekGridProvider = Provider.family<WeekGrid, (Timetable, int)>(
  (ref, arguments) => expandWeek(arguments.$1, arguments.$2),
);
