import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:doctoroncall/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E Test: Pass Onboarding, Signup, Login', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Pass Onboarding (3 pages)
    final nextOrGetStartedFinder = find.byType(ElevatedButton);
    expect(nextOrGetStartedFinder, findsOneWidget);
    
    // Tap Next 3 times
    await tester.tap(nextOrGetStartedFinder);
    await tester.pumpAndSettle();
    await tester.tap(nextOrGetStartedFinder);
    await tester.pumpAndSettle();
    await tester.tap(nextOrGetStartedFinder);
    await tester.pumpAndSettle();

    // 2. Select Role 'Patient'
    expect(find.text('Patient'), findsOneWidget);
    await tester.tap(find.text('Patient'));
    await tester.pumpAndSettle();

    // 3. Login Screen -> Go to Signup
    expect(find.text('Signup'), findsOneWidget);
    await tester.tap(find.text('Signup'));
    await tester.pumpAndSettle();

    // 4. Fill Signup Form
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(3)); // Name, Email, Password

    await tester.enterText(textFields.at(0), 'Test User');
    await tester.enterText(textFields.at(1), 'testuser@example.com');
    await tester.enterText(textFields.at(2), 'password123');
    await tester.pumpAndSettle();

    // Tap Signup Button
    await tester.tap(find.text('Sign Up'));
    // Wait for API request
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify Snackbar or Navigation back to Login
    expect(find.text('User registered & logged in!'), findsOneWidget);

    // Give it a second
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
