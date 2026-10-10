import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/customer/screens/customer_profile_screen.dart';
import 'package:delivery_app/features/customer/providers/customer_provider.dart';

void main() {
  testWidgets('tap Edit button in CustomerProfileScreen', (tester) async {
    final container = ProviderContainer();
    // seed user in customerProvider
    container.read(customerProvider.notifier).state = CustomerState(
      user: {
        'id': 'user123',
        'name': 'Sanuthi Lihansa',
        'email': 'sanuthilihansa21@gmail.com',
        'phone': '+94 78 465 4789',
        'address': 'Maradanahhhh',
      },
      isLoading: false,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CustomerProfileScreen(),
        ),
      ),
    );

    expect(find.text('Delivery & Contact Info'), findsOneWidget);
    final editButton = find.text('Edit');
    expect(editButton, findsOneWidget);

    await tester.tap(editButton);
    await tester.pumpAndSettle();

    expect(find.text('Edit Delivery & Contact'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Phone Number'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Delivery Address'), findsOneWidget);

    final cancelButton = find.text('Cancel');
    expect(cancelButton, findsOneWidget);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(find.text('Edit Delivery & Contact'), findsNothing);
  });

  testWidgets('edit and save customer profile successfully updates UI', (tester) async {
    final container = ProviderContainer();
    container.read(customerProvider.notifier).state = CustomerState(
      user: {
        'id': 'user123',
        'name': 'Sanuthi Lihansa',
        'email': 'sanuthilihansa21@gmail.com',
        'phone': '0771234567',
        'address': 'No. 12, Galle Road, Colombo',
      },
      isLoading: false,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CustomerProfileScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Verify pre-populated values
    final nameFinder = find.widgetWithText(TextFormField, 'Sanuthi Lihansa');
    final phoneFinder = find.widgetWithText(TextFormField, '0771234567');
    final addressFinder = find.widgetWithText(TextFormField, 'No. 12, Galle Road, Colombo');

    expect(nameFinder, findsOneWidget);
    expect(phoneFinder, findsOneWidget);
    expect(addressFinder, findsOneWidget);

    // Enter updated values
    await tester.enterText(nameFinder, 'Sanuthi Updated');
    await tester.enterText(phoneFinder, '0784654789');
    await tester.enterText(addressFinder, 'Maradana, Colombo 10');

    // Tap Cancel to test dismiss without saving
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Delivery & Contact'), findsNothing);
  });
}
