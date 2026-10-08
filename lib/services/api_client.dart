import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';

class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry({required this.data, required this.expiry});
  bool get isExpired => DateTime.now().isAfter(expiry);
}

class ApiClient {
  factory ApiClient() => _instance;
  static final ApiClient _instance = ApiClient._internal();

  String? _cachedToken;

  ApiClient._internal()
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.resolvedBaseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.connectTimeout,
            headers: const {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_cachedToken != null && _cachedToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_cachedToken';
          } else {
            final token = await const FlutterSecureStorage().read(
              key: 'auth_token',
            );
            _cachedToken = token;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          assert(() {
            debugPrint('[API REQ] ${options.method} ${options.path} ${options.queryParameters.isNotEmpty ? options.queryParameters : ""}');
            return true;
          }());
          handler.next(options);
        },
        onResponse: (response, handler) {
          assert(() {
            final data = response.data;
            final shape = data is Map
                ? 'Map(keys: ${data.keys.toList()})'
                : (data is List ? 'List(length: ${data.length})' : '${data.runtimeType}');
            debugPrint('[API RES] ${response.requestOptions.path} ${response.statusCode} shape: $shape');
            return true;
          }());
          handler.next(response);
        },
        onError: (DioException err, handler) {
          assert(() {
            debugPrint('[API ERR] ${err.requestOptions.path} type: ${err.type} status: ${err.response?.statusCode} error: ${ApiClient.messageFrom(err)}');
            return true;
          }());
          handler.next(err);
        },
      ),
    );
  }

  void updateAuthToken(String? token) {
    _cachedToken = token;
  }

  final Dio dio;
  final Map<String, _CacheEntry> _cache = {};
  final Map<String, Future<Response<dynamic>>> _inFlight = {};

  String _cacheKey(String path, Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) return path;
    final sortedKeys = queryParameters.keys.toList()..sort();
    final queryStr = sortedKeys.map((k) => '$k=${queryParameters[k]}').join('&');
    return '$path?$queryStr';
  }

  /// Cached GET request with in-flight deduplication
  Future<Response<dynamic>> getCached(
    String path, {
    Map<String, dynamic>? queryParameters,
    Duration ttl = const Duration(seconds: 30),
    bool forceRefresh = false,
  }) async {
    final key = _cacheKey(path, queryParameters);

    if (!forceRefresh && _cache.containsKey(key)) {
      final entry = _cache[key]!;
      if (!entry.isExpired) {
        return Response<dynamic>(
          requestOptions: RequestOptions(path: path),
          data: entry.data,
          statusCode: 200,
        );
      } else {
        _cache.remove(key);
      }
    }

    if (_inFlight.containsKey(key)) {
      return _inFlight[key]!;
    }

    final future = dio.get(path, queryParameters: queryParameters);
    _inFlight[key] = future;

    try {
      final response = await future;
      if (response.statusCode == 200 && response.data != null) {
        _cache[key] = _CacheEntry(
          data: response.data,
          expiry: DateTime.now().add(ttl),
        );
      }
      return response;
    } finally {
      _inFlight.remove(key);
    }
  }

  void clearCache([String? prefix]) {
    if (prefix == null) {
      _cache.clear();
      _cachedToken = null;
    } else {
      _cache.removeWhere((key, _) => key.startsWith(prefix));
    }
  }

  void invalidateCache([String? prefix]) {
    clearCache(prefix);
  }


  static String messageFrom(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      if (data['message'] is String && (data['message'] as String).trim().isNotEmpty) {
        return (data['message'] as String).trim();
      }
      if (data['details'] is List && (data['details'] as List).isNotEmpty) {
        return (data['details'] as List).map((e) => e.toString()).join('\n');
      }
      if (data['error'] is String && (data['error'] as String).trim().isNotEmpty) {
        return (data['error'] as String).trim();
      }
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Please check your internet connection.';
    }
    if (error.response?.statusCode == 401) {
      return 'Your session has expired. Please log in again.';
    }
    if (error.response?.statusCode == 403) {
      return 'Access denied. You do not have permission for this action.';
    }
    if (error.response?.statusCode == 404) {
      return 'Requested resource was not found.';
    }
    if (error.response?.statusCode == 409) {
      return 'This record already exists. Please verify your details.';
    }
    if (error.response?.statusCode == 422) {
      return 'Invalid request data. Please check your inputs.';
    }
    if (error.response?.statusCode == 500) {
      return 'Internal server error. Please try again shortly.';
    }
    return 'Unable to connect to HomeBite. Check that the backend is running.';
  }
}
