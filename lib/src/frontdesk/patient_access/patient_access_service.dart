import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import 'patient_access_endpoints.dart';
import 'patient_access_models.dart';

class PatientAccessService {
  PatientAccessService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  /// `GET /frontdesk/patient-devices`
  Future<PatientDevicePage> listPatientDevices({
    String? status,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }
    final q = search?.trim() ?? '';
    if (q.isNotEmpty) {
      query['search'] = q;
    }

    final response = await _dio.get<dynamic>(
      PatientAccessEndpoints.patientDevices,
      queryParameters: query,
    );
    final map = patientAccessAsMap(response.data);
    // If payload unwrapped to a bare list, wrap it.
    if (map.isEmpty) {
      final list = patientAccessAsList(response.data);
      return PatientDevicePage(
        items: list
            .whereType<Map>()
            .map((e) => PatientDeviceRow.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        page: page,
        limit: limit,
        total: list.length,
      );
    }
    return PatientDevicePage.fromJson(map);
  }

  /// `GET /frontdesk/patients/:patientId/devices`
  Future<List<PatientDeviceRow>> listDevicesForPatient(String patientId) async {
    final response = await _dio.get<dynamic>(
      PatientAccessEndpoints.patientDevicesFor(patientId),
    );
    final list = patientAccessAsList(response.data);
    return list
        .whereType<Map>()
        .map((e) => PatientDeviceRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// `POST /frontdesk/patient-devices/:id/approve`
  Future<PatientDeviceRow?> approveDevice(String deviceId) async {
    final response = await _dio.post<dynamic>(
      PatientAccessEndpoints.approveDevice(deviceId),
    );
    final map = patientAccessAsMap(response.data);
    if (map.isEmpty) return null;
    return PatientDeviceRow.fromJson(map);
  }

  /// `DELETE /frontdesk/patient-devices/:id`
  Future<void> removeDevice(String deviceId) async {
    await _dio.delete<dynamic>(PatientAccessEndpoints.patientDevice(deviceId));
  }

  /// `GET /frontdesk/patients/:parentId/children`
  Future<List<FamilyChildRow>> listChildren(String parentId) async {
    final response = await _dio.get<dynamic>(
      PatientAccessEndpoints.children(parentId),
    );
    final list = patientAccessAsList(response.data);
    return list
        .whereType<Map>()
        .map((e) => FamilyChildRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// `POST /frontdesk/patients/:parentId/children`
  Future<FamilyChildRow?> linkChild({
    required String parentId,
    required String childPatientId,
  }) async {
    final response = await _dio.post<dynamic>(
      PatientAccessEndpoints.children(parentId),
      data: {'childPatientId': childPatientId},
    );
    final map = patientAccessAsMap(response.data);
    if (map.isEmpty) return null;
    return FamilyChildRow.fromJson(map);
  }

  /// `DELETE /frontdesk/patients/:parentId/children/:childId`
  Future<void> unlinkChild({
    required String parentId,
    required String childId,
  }) async {
    await _dio.delete<dynamic>(
      PatientAccessEndpoints.child(parentId, childId),
    );
  }
}
