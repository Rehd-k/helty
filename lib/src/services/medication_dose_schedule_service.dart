import 'package:dio/dio.dart';

import '../models/medication_dose_schedule_model.dart';
import 'api_service.dart';

class MedicationDoseScheduleService {
  MedicationDoseScheduleService() : _dio = ApiService().dio;

  final Dio _dio;

  List<dynamic> _listData(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'] ?? raw['items'] ?? raw['results'];
      return inner is List ? inner : const [];
    }
    return const [];
  }

  /// GET `/admissions/:admissionId/medication-dose-schedules`
  Future<List<MedicationDoseScheduleItemModel>> listByAdmission(
    String admissionId, {
    bool activeOnly = true,
    bool dueOnly = false,
  }) async {
    final response = await _dio.get<dynamic>(
      '/admissions/$admissionId/medication-dose-schedules',
      queryParameters: {
        if (activeOnly) 'activeOnly': 'true',
        if (dueOnly) 'dueOnly': 'true',
      },
    );
    return _listData(response.data)
        .map(
          (e) => MedicationDoseScheduleItemModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// GET `/medication-orders/:id/dose-schedule`
  Future<MedicationDoseScheduleModel?> getByOrderId(String orderId) async {
    final response = await _dio.get<dynamic>(
      '/medication-orders/$orderId/dose-schedule',
    );
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      final inner = raw['doseSchedule'] ?? raw['dose_schedule'] ?? raw;
      if (inner is Map<String, dynamic>) {
        return MedicationDoseScheduleModel.fromJson(inner);
      }
    }
    return null;
  }
}
