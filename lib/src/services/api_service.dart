import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/interceptors/auth_interceptor.dart';
import '../core/interceptors/error_interceptor.dart';

/// Base URL for every API call. Change to your server address.
const _kBaseUrl = 'http://localhost:3000';

/// Singleton Dio client, pre-configured with auth + error interceptors.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;

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
