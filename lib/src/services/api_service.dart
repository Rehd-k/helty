import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/interceptors/auth_interceptor.dart';
import '../core/interceptors/error_interceptor.dart';
import '../core/interceptors/refresh_token_interceptor.dart';

/// Base URL for every API call. Change to your server address.
const _kBaseUrl = 'http://localhost:3000';

// const _kBaseUrl = 'http://192.168.3.96:3000';

// const _kBaseUrl = 'http://72.62.185.238:5000';

/// Singleton Dio client, pre-configured with auth + refresh + error interceptors.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;

  /// Same origin as [dio] `baseUrl` (scheme + host + port). Use for public routes like `/helty-desktop`.
  String get apiBaseUrl => dio.options.baseUrl;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _kBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(), // attaches Bearer token
      RefreshTokenInterceptor(dio), // handles 401 + refresh
      ErrorInterceptor(), // maps DioException → AppException
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
    ]);
  }
}
