import 'package:delivery_app/features/customer/providers/customer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('customer profile state keeps cached user while refresh is in progress', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(customerProvider.notifier);
    notifier.state = const CustomerState(
      user: {'name': 'Alice Example', 'email': 'alice@example.com'},
    );

    final refreshed = notifier.state.copyWith(isRefreshing: true);

    expect(refreshed.user?['name'], 'Alice Example');
    expect(refreshed.user?['email'], 'alice@example.com');
    expect(refreshed.isRefreshing, isTrue);
  });
}
