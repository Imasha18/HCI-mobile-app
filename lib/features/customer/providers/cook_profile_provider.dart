import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

final cookProfileFamilyProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, cookId) async {
  final response = await ApiClient().getCached(
    '/cooks/$cookId',
    ttl: const Duration(minutes: 2),
  );
  final data = response.data['data'] as Map<String, dynamic>;
  return data;
});
