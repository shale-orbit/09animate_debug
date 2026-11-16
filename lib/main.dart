import 'package:flutter/material.dart';

import 'pages/list_page.dart';

void main() {
  runApp(const AnimateDebugApp());
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
