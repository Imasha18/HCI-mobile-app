import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_app/features/customer/screens/customer_login_screen.dart';

void main() {
  testWidgets('shows the HomeBite customer sign in screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CustomerLoginScreen(),
        ),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
