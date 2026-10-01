import 'package:go_router/go_router.dart';

import '../ui/import/import_page.dart';
import '../ui/week/week_grid_page.dart';

/// 路由表。
///
/// 打开 App 就是课表——「一眼看全周」是这个 App 的核心价值，它不该藏在二级页里
/// （issue #10）。导入是它派生出去的一页，后面的票也往这里加：安排详情（issue #11）、
/// 学期设置（issue #12）都从 `/` 派生。
///
/// 路径名用英文、界面文案用中文：路径是代码，文案是给人看的。
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const WeekGridPage(),
    ),
    GoRoute(
      path: '/import',
      name: 'import',
      builder: (context, state) => const ImportPage(),
    ),
  ],
);
