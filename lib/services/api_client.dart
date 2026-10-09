import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. Please try again.';
      case DioExceptionType.badCertificate:
        return 'Secure connection to the server failed (invalid certificate).';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        // In browsers, a refused connection and a CORS rejection are both
        // reported as an opaque network error, so mention both causes.
        if (kIsWeb) {
          return 'Unable to connect to server at ${ApiConfig.resolvedBaseUrl}. '
              'The server may be offline, or the browser blocked the request '
              'due to CORS configuration.';
        }
        return 'Unable to connect to server. Please check your connection.';
      default:
        break;
    }

    final status = error.response?.statusCode;
    switch (status) {
      case 400:
        return 'Invalid request. Please check your inputs.';
      case 401:
        final path = error.requestOptions.path;
        if (path.contains('/auth/login')) return 'Invalid email or password.';
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'Access denied. You do not have permission for this action.';
      case 404:
        return 'Requested resource was not found.';
      case 409:
        return 'This record already exists. Please verify your details.';
      case 422:
        return 'Invalid request data. Please check your inputs.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
    }
    if (status != null && status >= 500) {
      return 'Server error. Please try again.';
    }
    if (status == null) {
      return kIsWeb
          ? 'Unable to connect to server. The browser may have blocked the request (CORS).'
          : 'Unable to connect to server.';
    }
    return 'Something went wrong (HTTP $status). Please try again.';
  }
}
