import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_app/app.dart';

void main() {
  testWidgets('shows the Table & Hearth sign in screen', (tester) async {
    await tester.pumpWidget(const DeliveryApp());

    expect(find.text('TABLE &\nHEARTH'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
