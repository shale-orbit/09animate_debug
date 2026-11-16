import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animate_debug/main.dart';

void main() {
  testWidgets('列表页能渲染收藏条目', (WidgetTester tester) async {
    await tester.pumpWidget(const AnimateDebugApp());
    // 列表里有循环动画，不能用 pumpAndSettle，手动推一帧即可。
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('我的收藏'), findsOneWidget);
    expect(find.text('Flutter 实战'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsWidgets);
  });
}
