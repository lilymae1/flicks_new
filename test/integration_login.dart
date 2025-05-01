import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flicks_new/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can log in with correct credentials', (WidgetTester tester) async {
    app.main(); // Start your app
    await tester.pumpAndSettle(); // Wait for UI to load

    // Enter username and password
    await tester.enterText(find.byKey(const Key('usernameField')), 'testuser');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password123');

    // Tap login button
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    // Expect navigation to HomeScreen (adjust based on your UI)
    expect(find.textContaining('Welcome'), findsOneWidget);
  });
}
