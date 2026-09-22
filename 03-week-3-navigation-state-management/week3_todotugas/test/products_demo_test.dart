import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/widgets/products_demo.dart';

void main() {
  testWidgets('Test full flow: loading -> data display', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ProductPage()),
      ),
    );

    // 1. Loading State
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 2. Wait for async build()
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // 3. Success State
    expect(find.text('Keyboard'), findsOneWidget);
    expect(find.text('Mouse'), findsOneWidget);
    expect(find.text('Monitor'), findsOneWidget);
  });
}
