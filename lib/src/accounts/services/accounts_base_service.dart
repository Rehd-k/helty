import 'package:dio/dio.dart';
import 'package:helty/src/services/api_service.dart';

/// Shared HTTP helpers for accounts services.
abstract class AccountsBaseService {
  AccountsBaseService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  final Dio _dio;
  Dio get dio => _dio;

  String dioMessage(DioException e, String fallback) {
    final payload = e.response?.data;
    if (payload is Map && payload['message'] != null) {
      return payload['message'].toString();
    }
    return e.message ?? fallback;
  }

  /// Unwraps `{ data: ... }` envelopes used by some backend handlers.
  dynamic unwrapPayload(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map.containsKey('data') &&
          (map.length == 1 ||
              map['data'] is Map ||
              map['data'] is List)) {
        return map['data'];
      }
    }
    return data;
  }

  Map<String, dynamic> asMap(dynamic data) {
    final raw = unwrapPayload(data);
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw FormatException('Expected JSON object');
  }

  List<dynamic> asList(dynamic data, {String? key}) {
    final raw = unwrapPayload(data);
    if (raw is List<dynamic>) return raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final k in [key, 'data', 'items', 'rows', 'logs', 'results']) {
        if (k != null && map[k] is List) return map[k] as List<dynamic>;
      }
    }
    return const [];
  }

  Never throwApi(DioException e, String label) {
    throw Exception('$label: ${dioMessage(e, 'Unknown error')}');
  }
}
