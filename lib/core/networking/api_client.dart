import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../errors/api_exception.dart';

/// Centralized HTTP client. All API traffic goes through here:
/// base URL, auth headers, timeouts, logging (debug only), error mapping.
class ApiClient {
  ApiClient({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
              sendTimeout: AppConfig.sendTimeout,
              responseType: ResponseType.json,
              headers: const {'Content-Type': 'application/json'},
            )) {
    if (dio == null) {
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final email = _email;
          if (email != null && email.isNotEmpty) {
            options.headers['x-user-email'] = email;
          }
          if (kDebugMode) {
            debugPrint('[API] ${options.method} ${options.uri}');
          }
          handler.next(options);
        },
      ));
      if (kDebugMode) {
        _dio.interceptors.add(LogInterceptor(
          requestBody: false,
          responseBody: false,
          error: true,
        ));
      }
    }
  }

  final Dio _dio;
  String? _token;
  String? _email;

  /// Called by AuthRepository on login/logout/session-restore.
  void setAuth({String? token, String? email}) {
    _token = token;
    _email = email;
  }

  String get baseUrl => _dio.options.baseUrl;

  Future<T> get<T>(String path,
      {Map<String, dynamic>? query, T Function(dynamic json)? decode}) async {
    try {
      final res = await _dio.get<dynamic>(path, queryParameters: query);
      return _decode<T>(res.data, decode);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<T> post<T>(String path,
      {Object? body,
      Map<String, dynamic>? query,
      T Function(dynamic json)? decode}) async {
    try {
      final res =
          await _dio.post<dynamic>(path, data: body, queryParameters: query);
      return _decode<T>(res.data, decode);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<T> put<T>(String path,
      {Object? body, T Function(dynamic json)? decode}) async {
    try {
      final res = await _dio.put<dynamic>(path, data: body);
      return _decode<T>(res.data, decode);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<T> delete<T>(String path,
      {T Function(dynamic json)? decode}) async {
    try {
      final res = await _dio.delete<dynamic>(path);
      return _decode<T>(res.data, decode);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  T _decode<T>(dynamic data, T Function(dynamic json)? decode) {
    if (decode != null) {
      try {
        return decode(data);
      } catch (_) {
        throw ApiException.malformed;
      }
    }
    return data as T;
  }

  ApiException _map(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException.timeout;
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException.network;
    }
    final status = e.response?.statusCode;
    if (status != null) {
      String? detail;
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        detail = data['detail']?.toString() ?? data['message']?.toString();
      } else if (data is String && data.isNotEmpty) {
        detail = data.length > 220 ? null : data;
      }
      // Backend sometimes embeds the real cause in `detail`.
      if (detail == null || detail == 'null' || detail.isEmpty) detail = null;
      return ApiException.fromStatus(status, detail: detail);
    }
    if (e.type == DioExceptionType.badResponse) {
      return ApiException.malformed;
    }
    return ApiException.network;
  }
}
