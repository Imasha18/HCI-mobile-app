import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/payment_model.dart';
import '../../../services/api_client.dart';

final paymentProvider = Provider<PaymentNotifier>((ref) => PaymentNotifier());

class PaymentNotifier {
  Future<PaymentModel> pay(String orderId) async {
    final response = await ApiClient().dio.post(
      '/payment/create',
      data: {'orderId': orderId, 'provider': 'card'},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PaymentModel(
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      status: data['status'] as String? ?? 'paid',
    );
  }
}
