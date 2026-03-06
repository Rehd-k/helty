import 'package:dio/dio.dart';

import 'api_service.dart';
import '../models/lab_order_model.dart';

class LabOrderService {
  LabOrderService() : _dio = ApiService().dio;

  final Dio _dio;

  /// GET /lab-orders?encounterId= — list lab orders for an encounter.
  Future<List<LabOrderModel>> getByEncounter(String encounterId) async {
    final response = await _dio.get<dynamic>(
      '/lab-orders',
      queryParameters: {'encounterId': encounterId},
    );
    final raw = response.data;
    if (raw is List) {
      return raw
          .map((e) => LabOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (raw is Map<String, dynamic>) {
      final list = raw['data'] as List? ?? [];
      return list
          .map((e) => LabOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// POST /lab-orders — create lab order. Returns created order with id from API.
  Future<LabOrderModel> create({
    required String encounterId,
    required String catalogTestId,
    required String testName,
    String? priority,
    String? clinicalNotes,
  }) async {
    final body = <String, dynamic>{
      'encounterId': encounterId,
      'catalogTestId': catalogTestId,
      'testName': testName,
      if (priority != null && priority.isNotEmpty) 'priority': priority,
      if (clinicalNotes != null && clinicalNotes.isNotEmpty) 'clinicalNotes': clinicalNotes,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/lab-orders',
      data: body,
    );
    final data = response.data;
    if (data == null) throw StateError('Create lab order returned no data');
    return LabOrderModel.fromJson(data);
  }

  /// PATCH /lab-orders/:id — update (e.g. status, resultValues).
  Future<LabOrderModel> update(String id, Map<String, dynamic> patch) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/lab-orders/$id',
      data: patch,
    );
    final data = response.data;
    if (data == null) throw StateError('Update lab order returned no data');
    return LabOrderModel.fromJson(data);
  }
}
