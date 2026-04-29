import 'package:dio/dio.dart';

import 'api_service.dart';
import '../models/medication_order_model.dart';

class MedicationOrderService {
  MedicationOrderService() : _dio = ApiService().dio;

  final Dio _dio;

  /// GET /medication-orders?encounterId= — list orders for an encounter.
  Future<List<MedicationOrderModel>> getByEncounter(String encounterId) async {
    final response = await _dio.get<dynamic>(
      '/medication-orders/encounter/$encounterId',
    );
    final raw = response.data;
    if (raw is List) {
      return raw
          .map((e) => MedicationOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (raw is Map<String, dynamic>) {
      final list = raw['data'] as List? ?? [];
      return list
          .map((e) => MedicationOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// POST /medication-orders — create prescription. Returns created order with id from API.
  Future<MedicationOrderModel> create({
    required String encounterId,
    required String patientId,
    required String drugId,
    required String drugName,
    required String staffId,
    String? dose,
    String? frequency,
    String? duration,
    int? quantity,
    String? route,
    String? specialInstructions,
    String? admissionId,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? notes,
    MedicationAdministrationStatus administrationStatus =
        MedicationAdministrationStatus.active,
  }) async {
    if (startDateTime != null &&
        endDateTime != null &&
        endDateTime.isBefore(startDateTime)) {
      throw ArgumentError('End date/time cannot be before start date/time.');
    }
    final body = <String, dynamic>{
      'encounterId': encounterId,
      'drugId': drugId,
      'drugName': drugName,
      'patientId': patientId,
      'doctorId': staffId,
      if (dose != null && dose.isNotEmpty) 'dose': dose,
      if (frequency != null && frequency.isNotEmpty) 'frequency': frequency,
      if (duration != null && duration.isNotEmpty) 'duration': duration,
      if (quantity != null && quantity > 0) 'quantity': quantity,
      if (route != null && route.isNotEmpty) 'route': route,
      if (specialInstructions != null && specialInstructions.isNotEmpty)
        'specialInstructions': specialInstructions,
      if (admissionId != null && admissionId.isNotEmpty) 'admissionId': admissionId,
      if (startDateTime != null) 'startDateTime': startDateTime.toUtc().toIso8601String(),
      if (endDateTime != null) 'endDateTime': endDateTime.toUtc().toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'administrationStatus': administrationStatus.apiValue,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/medication-orders',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Create medication order returned no data');
    }
    return MedicationOrderModel.fromJson(data);
  }

  /// PATCH `/medication-orders/:id` — swap drug on an existing order (when API supports it).
  Future<MedicationOrderModel> update({
    required String id,
    String? drugId,
    String? drugName,
    String? dose,
    String? frequency,
    String? duration,
    int? quantity,
    String? route,
    String? specialInstructions,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? notes,
    MedicationAdministrationStatus? administrationStatus,
  }) async {
    if (startDateTime != null &&
        endDateTime != null &&
        endDateTime.isBefore(startDateTime)) {
      throw ArgumentError('End date/time cannot be before start date/time.');
    }
    final body = <String, dynamic>{
      if (drugId != null && drugId.isNotEmpty) 'drugId': drugId,
      if (drugName != null && drugName.isNotEmpty) 'drugName': drugName,
      if (dose != null && dose.isNotEmpty) 'dose': dose,
      if (frequency != null && frequency.isNotEmpty) 'frequency': frequency,
      if (duration != null && duration.isNotEmpty) 'duration': duration,
      if (quantity != null && quantity > 0) 'quantity': quantity,
      if (route != null && route.isNotEmpty) 'route': route,
      if (specialInstructions != null && specialInstructions.isNotEmpty)
        'specialInstructions': specialInstructions,
      if (startDateTime != null) 'startDateTime': startDateTime.toUtc().toIso8601String(),
      if (endDateTime != null) 'endDateTime': endDateTime.toUtc().toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (administrationStatus != null)
        'administrationStatus': administrationStatus.apiValue,
    };
    final response = await _dio.patch<Map<String, dynamic>>(
      '/medication-orders/$id',
      data: body,
    );
    final raw = response.data;
    if (raw == null) {
      throw StateError('Update medication order returned no data');
    }
    final Map<String, dynamic> data = raw['data'] is Map<String, dynamic>
        ? raw['data'] as Map<String, dynamic>
        : raw;
    return MedicationOrderModel.fromJson(data);
  }
}
