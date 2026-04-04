import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agro_ai_app/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders without crashing', (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      print("FLUTTER ERROR: \${details.exception}");
      print(details.stack);
    };

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
