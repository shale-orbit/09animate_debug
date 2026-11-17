import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_errors.dart';
import 'pages/list_page.dart';

void main() {
  // ① 框架同步异常：build / layout / paint 里抛的错（会红屏的那一类）
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details); // 控制台保留完整堆栈
    AppErrors.report(details.exception, details.stack, source: 'FlutterError');
  };

  // ② 未捕获的异步 / 平台异常（移动端 / 桌面端生效）
  // 注意：Web 上根 zone 的未捕获 Promise 异常不会走这里，浏览器仍打 Uncaught，
  // 由下面的 ③ 兜底，这是 Flutter Web 的平台差异。
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppErrors.report(error, stack, source: 'PlatformDispatcher');
    return true; // 已处理，不再向上抛
  };

  // ③ 兜底：runApp 放进自定义 zone，前两层没接住的错误最终从这里走
  runZonedGuarded(() => runApp(const AnimateDebugApp()), (
    Object error,
    StackTrace stack,
  ) {
    AppErrors.report(error, stack, source: 'runZonedGuarded');
  });
}

class AnimateDebugApp extends StatelessWidget {
  const AnimateDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'animate_debug',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const BookListPage(),
    );
  }
}
