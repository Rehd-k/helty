import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';
import '../models/emergency_request_model.dart';

final emergencyRequestServiceProvider = Provider<EmergencyRequestService>((
  ref,
) {
  return EmergencyRequestService();
});

class EmergencyRequestService {
  EmergencyRequestService([Dio? dio]) : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  Future<StaffEmergencyRequestListResponse> list({
    EmergencyRequestStatus? status,
    int page = 1,
    int limit = 50,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/emergency/requests',
      queryParameters: {
        if (status != null) 'status': status.apiValue,
        'page': page,
        'limit': limit,
      },
    );
    return StaffEmergencyRequestListResponse.fromJson(resp.data ?? {});
  }

  Future<StaffEmergencyRequest> get(String id) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/emergency/requests/$id',
    );
    return StaffEmergencyRequest.fromJson(resp.data ?? {});
  }

  Future<StaffEmergencyRequest> updateStatus({
    required String id,
    required EmergencyRequestStatus status,
    String? staffNote,
  }) async {
    final resp = await _dio.patch<Map<String, dynamic>>(
      '/emergency/requests/$id',
      data: {
        'status': status.apiValue,
        if (staffNote != null) 'staffNote': staffNote,
      },
    );
    return StaffEmergencyRequest.fromJson(resp.data ?? {});
  }

  String mediaPath(String id, String kind) =>
      '/emergency/requests/$id/media/$kind';
}
