import 'package:dio/dio.dart';

import 'api_service.dart';
import '../models/imaging_order_model.dart';

class ImagingOrderService {
  ImagingOrderService() : _dio = ApiService().dio;

  final Dio _dio;

  /// GET /imaging-orders?encounterId= — list imaging orders for an encounter.
  Future<List<ImagingOrderModel>> getByEncounter(String encounterId) async {
    final response = await _dio.get<dynamic>(
      '/imaging-orders',
      queryParameters: {'encounterId': encounterId},
    );
    final raw = response.data;
    if (raw is List) {
      return raw
          .map((e) => ImagingOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (raw is Map<String, dynamic>) {
      final list = raw['data'] as List? ?? [];
      return list
          .map((e) => ImagingOrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// POST /imaging-orders — create imaging order. Returns created order with id from API.
  Future<ImagingOrderModel> create({
    required String encounterId,
    required String catalogId,
    required String studyName,
    String? area,
    bool contrast = false,
    String? urgency,
    String? notesToRadiologist,
  }) async {
    final body = <String, dynamic>{
      'encounterId': encounterId,
      'catalogId': catalogId,
      'studyName': studyName,
      'contrast': contrast,
      if (area != null && area.isNotEmpty) 'area': area,
      if (urgency != null && urgency.isNotEmpty) 'urgency': urgency,
      if (notesToRadiologist != null && notesToRadiologist.isNotEmpty)
        'notesToRadiologist': notesToRadiologist,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/imaging-orders',
      data: body,
    );
    final data = response.data;
    if (data == null) throw StateError('Create imaging order returned no data');
    return ImagingOrderModel.fromJson(data);
  }
}
