import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

final reviewProvider = Provider<ReviewNotifier>((ref) => ReviewNotifier());

class ReviewNotifier {
  Future<void> submit({
    required String mealId,
    required double rating,
    required String comment,
  }) async {
    await ApiClient().dio.post(
      '/reviews',
      data: {'meal': mealId, 'rating': rating, 'comment': comment},
    );
  }
}
