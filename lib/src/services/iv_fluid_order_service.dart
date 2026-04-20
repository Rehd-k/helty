import 'package:dio/dio.dart';

import '../models/iv_fluid_order_model.dart';
import 'api_service.dart';

class IvFluidOrderService {
  IvFluidOrderService() : _dio = ApiService().dio;

  final Dio _dio;

  List<dynamic> _listData(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'] ?? raw['items'] ?? raw['results'];
      return inner is List ? inner : const [];
    }
    return const [];
  }

  /// GET `/admissions/:admissionId/iv-fluid-orders`
  Future<List<IvFluidOrderModel>> list(String admissionId) async {
    final response = await _dio.get<dynamic>(
      '/admissions/$admissionId/iv-fluid-orders',
    );
    return _listData(response.data)
        .map(
          (e) => IvFluidOrderModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// POST `/admissions/:admissionId/iv-fluid-orders/:orderId/monitorings`
  Future<void> createMonitoring({
    required String admissionId,
    required String orderId,
    required String currentRate,
    required String insertionSiteCondition,
    String? complications,
    DateTime? stoppedAt,
    String? reasonStopped,
  }) async {
    final body = <String, dynamic>{
      'currentRate': currentRate,
      'insertionSiteCondition': insertionSiteCondition,
      if (complications != null && complications.isNotEmpty)
        'complications': complications,
      if (stoppedAt != null) 'stoppedAt': stoppedAt.toUtc().toIso8601String(),
      if (reasonStopped != null && reasonStopped.isNotEmpty)
        'reasonStopped': reasonStopped,
    };
    await _dio.post<void>(
      '/admissions/$admissionId/iv-fluid-orders/$orderId/monitorings',
      data: body,
    );
  }

  /// PATCH `/admissions/:admissionId/iv-fluid-orders/:orderId`
  Future<IvFluidOrderModel> patchOrder({
    required String admissionId,
    required String orderId,
    String? status,
    String? rate,
    DateTime? expectedEndTime,
  }) async {
    final body = <String, dynamic>{
      if (status != null) 'status': status,
      if (rate != null) 'rate': rate,
      if (expectedEndTime != null)
        'expectedEndTime': expectedEndTime.toUtc().toIso8601String(),
    };
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admissions/$admissionId/iv-fluid-orders/$orderId',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('PATCH iv order returned no data');
    }
    return IvFluidOrderModel.fromJson(data);
  }
}
