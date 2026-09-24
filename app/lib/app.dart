import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'routing/app_router.dart';

/// App 的外壳：主题、语言、路由。
///
/// 深色模式**跟随系统**（规格里定的），只做中文。
class AhScheduleApp extends StatelessWidget {
  const AhScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AH-schedule',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A6FA5)),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A6FA5),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      // 只做中文，不做国际化：这里定的是 Material 自带控件的语言（长按菜单、
      // 文本选择菜单这些），不是把界面文案做成可翻译的。
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
