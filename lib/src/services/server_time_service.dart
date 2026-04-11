import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../models/server_time_model.dart';
import 'api_service.dart';

/// Fetches authoritative time from the API. Intended as the **first** HTTP call
/// on startup so the device clock can be validated before auth or other routes run.
class ServerTimeService {
  ServerTimeService([Dio? dio]) : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  static const String path = '/server-time';

  /// Maximum allowed absolute difference between server [ServerTimePayload.unixMs]
  /// and [DateTime.now] on the device (milliseconds).
  static const int maxAllowedSkewMs = 120000;

  Future<ServerTimePayload> fetch() async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(path);
      final data = resp.data;
      if (data == null) {
        throw const FormatException('server-time: empty response body');
      }
      return ServerTimePayload.fromJson(data);
    } on DioException catch (e) {
      final err = e.error;
      if (err is AppException) throw err;
      rethrow;
    }
  }

  /// `null` if the device clock is within [maxAllowedSkewMs] of the server.
  int? skewMsIfInvalid(ServerTimePayload server) {
    final localMs = DateTime.now().millisecondsSinceEpoch;
    final diff = (server.unixMs - localMs).abs();
    if (diff > maxAllowedSkewMs) return diff;
    return null;
  }
}
