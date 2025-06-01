// This is a basic Flutter widget test for the Kenya Pool Billiards app.
//
// These tests verify that the app renders properly and key components
// like the splash screen are displayed correctly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pool_billiard_app/app.dart';
import 'package:pool_billiard_app/main_screen/splash_screen.dart';

void main() {
  testWidgets('Kenya Pool Billiards app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const App());

    // Verify that the app renders without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
  
  testWidgets('Splash screen displays app name', (WidgetTester tester) async {
    // Build the splash screen directly
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen())
    );
    
    // Verify the splash screen shows the app name
    expect(find.text('Kenya Pool Billiards'), findsOneWidget);
    
    // Verify the splash screen has a progress indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
