import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'data/providers.dart';

/// 只在 Android 上跑（ADR-0003）。iOS 的目录是脚手架留下的，冻结着、不碰。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 数据库先打开再 runApp：打开是异步的，界面第一帧就该拿到一个真库，
  // 而不是先画一个「加载中」再换。
  final database = await openAppDatabase();

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const AhScheduleApp(),
    ),
  );
}
