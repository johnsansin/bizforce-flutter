import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bizforce_mobile/screens/login_screen.dart';
import 'package:bizforce_mobile/state/app_state.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Work email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Sign in with OTP'), findsNothing);
    expect(find.text('Sign in with SAML'), findsNothing);
    expect(find.text('Google'), findsNothing);
    expect(find.text('Apple'), findsNothing);
  });
}
