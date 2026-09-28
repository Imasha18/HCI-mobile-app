import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_app/app.dart';

void main() {
  testWidgets('shows the HomeBite customer sign in screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DeliveryApp()));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
