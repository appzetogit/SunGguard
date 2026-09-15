import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';
import 'api_exceptions.dart';

class ApiClient {
  final Dio dio;
  final SecureStorageService secureStorage;

  /// Invoked once when the server rejects the stored token.
  ///
  /// Previously a 401 produced an [AuthException] that nothing caught: every
  /// datasource swallows errors and returns an empty list, so an expired
  /// session rendered as permanently blank screens with no way back to sign-in.
  static void Function()? onUnauthorized;

  /// Set while a sign-out triggered by [onUnauthorized] is in flight, so a
  /// burst of parallel 401s (the home screen fires two history calls at once)
  /// only logs the customer out once.
  static bool _handlingUnauthorized = false;

  static void resetUnauthorizedGuard() => _handlingUnauthorized = false;

  ApiClient({
    required this.dio,
    required this.secureStorage,
  }) {
    dio.options = BaseOptions(
      baseUrl: ApiEndpoints.defaultBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 45),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.getCustomerToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            debugPrint('==================== [API REQUEST] ====================');
            debugPrint('🚀 URL: ${options.method} ${options.baseUrl}${options.path}');
            if (options.data != null) {
              try {
                debugPrint('📦 PAYLOAD: ${jsonEncode(options.data)}');
              } catch (_) {
                debugPrint('📦 PAYLOAD: ${options.data}');
              }
            }
            if (options.queryParameters.isNotEmpty) {
              debugPrint('🔍 QUERY PARAMS: ${options.queryParameters}');
            }
            // Redacted: the bearer token is a live credential and debug logs
            // are readable by any app with logcat access.
            final safeHeaders = Map<String, dynamic>.from(options.headers);
            if (safeHeaders.containsKey('Authorization')) {
              safeHeaders['Authorization'] = 'Bearer <redacted>';
            }
            debugPrint('🔑 HEADERS: $safeHeaders');
            debugPrint('=======================================================');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('==================== [API RESPONSE] ====================');
            debugPrint('✅ STATUS [${response.statusCode}]: ${response.requestOptions.method} ${response.requestOptions.path}');
            try {
              debugPrint('📥 DATA: ${jsonEncode(response.data)}');
            } catch (_) {
              debugPrint('📥 DATA: ${response.data}');
            }
            debugPrint('========================================================');
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          if (kDebugMode) {
            debugPrint('==================== [API ERROR] ====================');
            debugPrint('❌ FAILED [${error.response?.statusCode}]: ${error.requestOptions.method} ${error.requestOptions.path}');
            debugPrint('⚠️ MESSAGE: ${error.message}');
            if (error.response?.data != null) {
              try {
                debugPrint('🚨 ERROR BODY: ${jsonEncode(error.response?.data)}');
              } catch (_) {
                debugPrint('🚨 ERROR BODY: ${error.response?.data}');
              }
            }
            debugPrint('=====================================================');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// The instance registered in the service locator, set during DI setup.
  static ApiClient? _shared;

  static set shared(ApiClient client) => _shared = client;

  /// Returns the shared client rather than building a throwaway one.
  ///
  /// Several pages call this directly. Each call used to construct a fresh
  /// Dio and SecureStorage, which meant those requests bypassed any
  /// interceptor added to the DI-registered client — including the 401
  /// handling above. Falling back to a new instance keeps the factory usable
  /// in tests and before DI has run.
  factory ApiClient.createDefault() {
    return _shared ??= ApiClient(
      dio: Dio(),
      secureStorage: SecureStorageService(),
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  dynamic _handleResponse(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('result')) {
        return data['result'];
      }
      if (data.containsKey('data')) {
        return data['data'];
      }
    }
    return data;
  }

  ApiException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    final response = error.response;
    if (response != null) {
      final statusCode = response.statusCode;
      final data = response.data;
      String message = 'Something went wrong. Please try again.';
      String? code;

      if (data is Map<String, dynamic>) {
        // `error` is a boolean in the backend envelope, never the message.
        final rawMessage = data['message'];
        if (rawMessage is String && rawMessage.trim().isNotEmpty) {
          message = rawMessage;
        } else if (data['error'] is String) {
          message = data['error'] as String;
        }
        if (data['result'] is Map<String, dynamic> && data['result']['code'] != null) {
          code = data['result']['code'].toString();
        } else if (data['code'] != null) {
          code = data['code'].toString();
        }
      }

      // A deactivated account keeps a valid JWT; the server answers 403
      // ACCOUNT_DEACTIVATED on protected routes. Sign out like a 401.
      if (statusCode == 401 ||
          (statusCode == 403 && code == 'ACCOUNT_DEACTIVATED')) {
        if (!_handlingUnauthorized && onUnauthorized != null) {
          _handlingUnauthorized = true;
          onUnauthorized!();
        }
        return AuthException(message: message);
      }

      return ApiException(
        message: message,
        statusCode: statusCode,
        code: code,
        data: data,
      );
    }

    return ApiException(message: error.message ?? 'Unknown network error');
  }
}
