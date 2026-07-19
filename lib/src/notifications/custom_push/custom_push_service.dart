import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import 'custom_push_endpoints.dart';
import 'custom_push_models.dart';

class CustomPushService {
  CustomPushService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  /// POST [CustomPushEndpoints.custom]
  ///
  /// Omits [patientIds] when empty (broadcast). Omits blank [imageUrl].
  Future<CustomPushResult> sendCustomPush({
    required String title,
    required String body,
    String? imageUrl,
    List<String>? patientIds,
  }) async {
    final data = <String, dynamic>{'title': title.trim(), 'body': body.trim()};
    final url = imageUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      data['imageUrl'] = url;
    }
    final ids = patientIds?.where((id) => id.trim().isNotEmpty).toList() ?? [];
    if (ids.isNotEmpty) {
      data['patientIds'] = ids;
    }

    final response = await _dio.post<dynamic>(
      CustomPushEndpoints.custom,
      data: data,
    );
    final raw = response.data;
    final map = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw as Map);
    return CustomPushResult.fromJson(map);
  }
}
