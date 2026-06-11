import 'package:dio/dio.dart';

import '../helper/app_timezone.dart';
import '../models/medication_administration_model.dart';
import 'api_service.dart';

class MedicationAdministrationService {
  MedicationAdministrationService() : _dio = ApiService().dio;

  final Dio _dio;

  /// GET `/admissions/:admissionId/medication-administrations`
  Future<List<MedicationAdministrationModel>> listByAdmission(
    String admissionId,
  ) async {
    final response = await _dio.get<dynamic>(
      '/admissions/$admissionId/medication-administrations',
    );
    final raw = response.data;
    List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic>) {
      final inner = raw['data'] ?? raw['items'] ?? raw['results'];
      list = inner is List ? inner : const [];
    } else {
      list = const [];
    }
    return list
        .map(
          (e) => MedicationAdministrationModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// POST `/admissions/:admissionId/medication-administrations`
  ///
  /// [status] must match API enum, e.g. `GIVEN`, `MISSED`, `REFUSED`, `DELAYED`.
  Future<MedicationAdministrationModel> create({
    required String admissionId,
    required String medicationOrderId,
    required DateTime scheduledTime,
    DateTime? actualTime,
    required String status,
    double? quantity,
    String? reasonIfNotGiven,
    String? remarks,
  }) async {
    final body = <String, dynamic>{
      'medicationOrderId': medicationOrderId,
      'scheduledTime': AppTimezone.toBackendIso(scheduledTime),
      'status': status,
      if (actualTime != null) 'actualTime': AppTimezone.toBackendIso(actualTime),
      if (quantity != null) 'quantity': quantity,
      if (reasonIfNotGiven != null && reasonIfNotGiven.isNotEmpty)
        'reasonIfNotGiven': reasonIfNotGiven,
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/admissions/$admissionId/medication-administrations',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Create medication administration returned no data');
    }
    return MedicationAdministrationModel.fromJson(data);
  }
}
