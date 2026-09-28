import 'package:go_router/go_router.dart';

import '../ui/home/home_page.dart';
import '../ui/import/import_page.dart';

/// 路由表。
///
/// v0.1 只有两条路由：打开 App 就是课表，导入是它派生出去的一页。后面的票往这里加——
/// 安排详情（issue #11）、学期设置（issue #12）——都从 `/` 派生。
///
/// 路径名用英文、界面文案用中文：路径是代码，文案是给人看的。
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/import',
      name: 'import',
      builder: (context, state) => const ImportPage(),
    ),
  ],
);
