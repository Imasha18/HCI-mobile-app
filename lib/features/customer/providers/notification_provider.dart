import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/notification_model.dart';
import '../../../services/api_client.dart';

final notificationProvider = FutureProvider<List<NotificationModel>>((
  ref,
) async {
  final response = await ApiClient().dio.get('/notifications');
  return (response.data['data'] as List<dynamic>)
      .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
      .toList();
});
