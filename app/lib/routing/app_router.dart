import 'package:go_router/go_router.dart';

import '../ui/home/home_page.dart';

/// 路由表。
///
/// v0.1 只有一条路由：打开 App 就是课表。后面的票往这里加——导入预览（issue #9）、
/// 安排详情（issue #11）——都从 `/` 派生。
///
/// 路径名用英文、界面文案用中文：路径是代码，文案是给人看的。
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
  ],
);
