import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Attaches the Bearer token to every outgoing request.
/// On 401, clears stored tokens so the auth guard can redirect to login.
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

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token is invalid/expired — wipe it so the guard redirects to login.
      await TokenStorage.clearAll();
    }
    handler.next(err);
  }
}
