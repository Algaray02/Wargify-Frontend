import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wargify/main.dart';

void main() {
  testWidgets('App renders configured initial page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(initialPage: Placeholder()));

    expect(find.byType(Placeholder), findsOneWidget);
  });
}
