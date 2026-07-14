import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project/pages/medicine_list_demo_page.dart';

void main() {
  testWidgets('browse-all medicine details open with cart action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MedicineListDemoPage(onAddToCart: (_) {}, isInCart: (_) => false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Napa Extend Tablet (Extended Release)'), findsOneWidget);

    await tester.tap(find.text('Napa Extend Tablet (Extended Release)').first);
    await tester.pumpAndSettle();

    expect(find.text('Medicine Details'), findsOneWidget);
    expect(find.text('Add to Cart'), findsOneWidget);
  });
}
