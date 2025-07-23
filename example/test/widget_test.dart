// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quickqr_scanner_plugin_example/main.dart';

void main() {
  testWidgets('Verify QuickQR Scanner app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for the widget to load
    await tester.pumpAndSettle();

    // Verify that the main components are present
    expect(find.text('QuickQR Scanner'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Initialize'), findsOneWidget);
    expect(find.text('Start Scan'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    
    // Verify status message appears
    expect(
      find.byWidgetPredicate(
        (Widget widget) => widget is Text && 
                           (widget.data?.contains('initialize') == true ||
                            widget.data?.contains('compatible') == true ||
                            widget.data?.contains('check') == true),
      ),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('Verify scan results section exists', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Check for scan results section
    expect(
      find.byWidgetPredicate(
        (Widget widget) => widget is Text &&
                           widget.data != null &&
                           widget.data!.contains('Scan Results'),
      ),
      findsOneWidget,
    );
    
    // Check for "Please scan a QR code" placeholder
    expect(find.text('Please scan a QR code'), findsOneWidget);
  });
}
