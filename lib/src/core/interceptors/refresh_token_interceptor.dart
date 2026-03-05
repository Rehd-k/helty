import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import '../storage/token_storage.dart';

/// Handles transparent access token refresh on 401 responses.
///
/// - If a 401 is received for a non-refresh call and a refresh token exists,
///   this interceptor will call `/auth/refresh` once, update the stored access
///   token, and retry the failed request.
/// - If refresh fails (or no refresh token exists), it clears all tokens so
///   the auth layer / guards can redirect to login.
class RefreshTokenInterceptor extends Interceptor {
  RefreshTokenInterceptor(
    this._dio, {
    Dio? refreshDio,
    this.refreshEndpoint = '/auth/refresh',
  }) : _refreshDio = refreshDio ?? Dio();

  /// The Dio instance used to retry the original request.
  final Dio _dio;

  /// A lightweight Dio instance used only for the refresh call (no interceptors).
  final Dio _refreshDio;

  final String refreshEndpoint;

  static const _retryKey = 'retry_after_refresh';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final statusCode = response?.statusCode;
    final request = err.requestOptions;

    final isUnauthorized = statusCode == 401;
    final isRefreshCall = request.path == refreshEndpoint;
    final alreadyRetried = request.extra[_retryKey] == true;

    if (!isUnauthorized || isRefreshCall || alreadyRetried) {
      if (isUnauthorized) {
        await TokenStorage.clearAll();
      }
      handler.next(err);
      return;
    }

    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await TokenStorage.clearAll();
        handler.next(err);
        return;
      }

      final refreshResp = await _refreshDio.post<dynamic>(
        refreshEndpoint,
        data: {'refreshToken': refreshToken},
      );

      final data = refreshResp.data as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String?;
      if (newAccessToken == null || newAccessToken.isEmpty) {
        await TokenStorage.clearAll();
        handler.next(
          DioException(
            requestOptions: request,
            error: const UnauthorizedException(),
            response: response,
            type: err.type,
          ),
        );
        return;
      }

      await TokenStorage.saveAccessToken(newAccessToken);

      final retryOptions = request
        ..headers['Authorization'] = 'Bearer $newAccessToken'
        ..extra[_retryKey] = true;

      final newResponse = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(newResponse);
    } catch (_) {
      await TokenStorage.clearAll();
      handler.next(
        DioException(
          requestOptions: request,
          error: const UnauthorizedException(),
          response: response,
          type: err.type,
        ),
      );
    }
  }
}


