import 'package:dio/dio.dart';

import '../config/api_config.dart';

class ApiClient {
  ApiClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.connectTimeout,
          headers: {'Content-Type': 'application/json'},
        ),
      );

  final Dio dio;
}
