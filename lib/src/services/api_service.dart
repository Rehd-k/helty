import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/interceptors/auth_interceptor.dart';
import '../core/interceptors/error_interceptor.dart';
import '../core/interceptors/refresh_token_interceptor.dart';

/// Candidate API origins probed at startup; the fastest `/server-time` wins.
const kApiCandidateBaseUrls = <String>[
  'http://localhost:3000',
  'http://192.168.2.121:3000',
  'http://192.168.2.120:3000',
];

/// Singleton Dio client, pre-configured with auth + refresh + error interceptors.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;

  /// Set by [ClockSyncGate] after the startup endpoint race.
  String? resolvedBaseUrl;

  /// Same origin as [dio] `baseUrl` (scheme + host + port). Use for public routes like `/helty-desktop`.
  String get apiBaseUrl => dio.options.baseUrl;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: kApiCandidateBaseUrls.first,
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

  /// Called after startup (or Retry) endpoint selection.
  void setBaseUrl(String url) {
    final normalized = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    dio.options.baseUrl = normalized;
    resolvedBaseUrl = normalized;
  }
}
