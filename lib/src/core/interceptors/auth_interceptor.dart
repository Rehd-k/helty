import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Attaches the Bearer token to every outgoing request.
///
/// This interceptor is deliberately **write-only** – it does not handle
/// 401s so that token refresh and logout can be centralized in a dedicated
/// refresh / auth error interceptor.
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
