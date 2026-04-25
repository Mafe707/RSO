import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rso/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RSOApp());
    
    // Verify that the app starts without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
