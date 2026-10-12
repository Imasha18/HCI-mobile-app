import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/customer/screens/checkout_screen.dart';
import 'package:delivery_app/features/customer/providers/customer_provider.dart';
import 'package:delivery_app/features/customer/providers/cart_provider.dart';
import 'package:delivery_app/models/cart_model.dart';
import 'package:delivery_app/models/meal_model.dart';

class _MockCartNotifier extends CartNotifier {
  _MockCartNotifier(this._cart);
  final CartModel _cart;

  @override
  Future<CartModel> build() async => _cart;
}

void main() {
  const testMeal = MealModel(
    id: 'meal1',
    cookId: 'cook1',
    name: 'Rice & Curry',
    description: 'Traditional Sri Lankan rice and curry',
    price: 450.0,
    imageUrl: '',
    category: 'Rice',
  );

  const testCart = CartModel(
    items: [
      CartItem(meal: testMeal, quantity: 2),
    ],
  );

  testWidgets('renders delivery details and allows editing in CheckoutScreen', (tester) async {
    final container = ProviderContainer(
      overrides: [
        cartProvider.overrideWith(() => _MockCartNotifier(testCart)),
      ],
    );

    container.read(customerProvider.notifier).state = const CustomerState(
      user: {
        'id': 'user123',
        'name': 'Sanuthi Lihansa',
        'email': 'sanuthilihansa21@gmail.com',
        'phone': '+94 78 465 4789',
        'address': 'Maradana',
      },
      isLoading: false,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CheckoutScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial values in Delivery Details card
    expect(find.text('Delivery Details'), findsOneWidget);
    expect(find.text('Sanuthi Lihansa'), findsWidgets);
    expect(find.text('Maradana'), findsWidgets);
    expect(find.text('+94 78 465 4789'), findsWidgets);
    expect(find.text('Change'), findsOneWidget);

    // Tap Change to open dialog
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    expect(find.text('Change Delivery Details'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Sanuthi Lihansa'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Maradana'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '+94 78 465 4789'), findsOneWidget);

    // Edit delivery details
    final nameFinder = find.widgetWithText(TextFormField, 'Sanuthi Lihansa');
    final addressFinder = find.widgetWithText(TextFormField, 'Maradana');
    final phoneFinder = find.widgetWithText(TextFormField, '+94 78 465 4789');

    await tester.enterText(nameFinder, 'Kasun Perera');
    await tester.enterText(addressFinder, 'No. 45, Galle Road, Colombo 03');
    await tester.enterText(phoneFinder, '077 123 4567');

    // Tap Use for this order
    await tester.tap(find.text('Use for this order'));
    await tester.pumpAndSettle();

    // Dialog should be dismissed
    expect(find.text('Change Delivery Details'), findsNothing);

    // Delivery details on checkout should be updated
    expect(find.text('Kasun Perera'), findsWidgets);
    expect(find.text('No. 45, Galle Road, Colombo 03'), findsWidgets);
    expect(find.text('077 123 4567'), findsWidgets);
    expect(find.text('Delivery details updated for this order!'), findsOneWidget);
  });

  testWidgets('cancel dismisses Change Delivery Details dialog without updating', (tester) async {
    final container = ProviderContainer(
      overrides: [
        cartProvider.overrideWith(() => _MockCartNotifier(testCart)),
      ],
    );

    container.read(customerProvider.notifier).state = const CustomerState(
      user: {
        'id': 'user123',
        'name': 'Sanuthi Lihansa',
        'email': 'sanuthilihansa21@gmail.com',
        'phone': '+94 78 465 4789',
        'address': 'Maradana',
      },
      isLoading: false,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CheckoutScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Change
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    expect(find.text('Change Delivery Details'), findsOneWidget);

    // Edit name
    final nameFinder = find.widgetWithText(TextFormField, 'Sanuthi Lihansa');
    await tester.enterText(nameFinder, 'Temporary Name');

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Dialog dismissed and name unchanged
    expect(find.text('Change Delivery Details'), findsNothing);
    expect(find.text('Temporary Name'), findsNothing);
    expect(find.text('Sanuthi Lihansa'), findsWidgets);
  });
}
