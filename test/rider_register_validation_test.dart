import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_app/features/rider/screens/rider_register_screen.dart';

void main() {
  testWidgets('rider registration form validates all fields and enforces 10 digits for phone', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RiderRegisterScreen(),
        ),
      ),
    );

    // Initial check: Screen renders with title and button
    expect(find.text('Join as Delivery Rider'), findsOneWidget);
    expect(find.text('Create Rider Account'), findsOneWidget);

    // Tap submit button with empty form to trigger validation
    final submitButton = find.text('Create Rider Account');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify all validation error messages appear
    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your phone number'), findsOneWidget);
    expect(find.text('Enter your operating city or address'), findsOneWidget);
    expect(find.text('Enter vehicle model'), findsOneWidget);
    expect(find.text('Enter plate number'), findsOneWidget);
    expect(find.text('Enter a password'), findsOneWidget);

    // Test phone input restrictions: digits only and max 10 digits
    final phoneFinder = find.widgetWithText(TextFormField, 'e.g. 0771234567');
    expect(phoneFinder, findsOneWidget);
    await tester.enterText(phoneFinder, '077abc123456789xyz');
    await tester.pumpAndSettle();

    // Verify non-digits were stripped and text was truncated to 10 digits
    final phoneField = tester.widget<TextFormField>(phoneFinder);
    expect(phoneField.controller?.text, '0771234567');

    // Test invalid email validation
    final emailFinder = find.widgetWithText(TextFormField, 'e.g. kasun@homebite.com');
    await tester.enterText(emailFinder, 'invalidemail');
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);

    // Test invalid phone not starting with 0
    await tester.enterText(phoneFinder, '9876543210');
    await tester.pumpAndSettle();
    expect(find.text('Phone number must start with 0 (e.g. 0771234567)'), findsOneWidget);

    // Test phone with fewer than 10 digits
    await tester.enterText(phoneFinder, '077123');
    await tester.pumpAndSettle();
    expect(find.text('Phone number must be exactly 10 digits'), findsOneWidget);

    // Enter valid phone number
    await tester.enterText(phoneFinder, '0771234567');
    await tester.pumpAndSettle();
    expect(find.text('Phone number must be exactly 10 digits'), findsNothing);
    expect(find.text('Phone number must start with 0 (e.g. 0771234567)'), findsNothing);
  });
}
