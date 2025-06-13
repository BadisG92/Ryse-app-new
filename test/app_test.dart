import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ryze_app/main.dart';

void main() {
  group('Ryze App Tests', () {
    testWidgets('App starts without crashing', (WidgetTester tester) async {
      // Build the app and trigger a frame
      await tester.pumpWidget(const MyApp());

      // Verify that the app starts without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // The app should load without throwing exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('App has correct title', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      // Verify that the MaterialApp has the correct title
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, 'Ryze App');
    });
  });
} 