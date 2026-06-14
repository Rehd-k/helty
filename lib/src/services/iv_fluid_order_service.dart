import 'package:dio/dio.dart';

import '../helper/app_timezone.dart';
import '../models/iv_fluid_order_model.dart';
import '../models/iv_monitoring_model.dart';
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

  /// POST `/admissions/:admissionId/iv-fluid-orders`
  Future<IvFluidOrderModel> create({
    required String admissionId,
    required String fluidType,
    required int volume,
    required int rate,
    required DateTime startTime,
    required DateTime expectedEndTime,
  }) async {
    final body = <String, dynamic>{
      'fluidType': fluidType,
      'volume': volume,
      'rate': rate,
      'startTime': AppTimezone.toBackendIso(startTime),
      'expectedEndTime': AppTimezone.toBackendIso(expectedEndTime),
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/admissions/$admissionId/iv-fluid-orders',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('POST iv order returned no data');
    }
    return IvFluidOrderModel.fromJson(data);
  }

  /// POST `/admissions/:admissionId/iv-fluid-orders/:orderId/monitorings`
  Future<void> createMonitoring({
    required String admissionId,
    required String orderId,
    required int currentRate,
    required String insertionSiteCondition,
    String? complications,
    DateTime? stoppedAt,
    String? reasonStopped,
    String? nurseId,
  }) async {
    final body = <String, dynamic>{
      'currentRate': currentRate,
      'insertionSiteCondition': insertionSiteCondition,
      if (nurseId != null && nurseId.isNotEmpty) 'nurseId': nurseId,
      if (complications != null && complications.isNotEmpty)
        'complications': complications,
      if (stoppedAt != null) 'stoppedAt': AppTimezone.toBackendIso(stoppedAt),
      if (reasonStopped != null && reasonStopped.isNotEmpty)
        'reasonStopped': reasonStopped,
    };
    await _dio.post<void>(
      '/admissions/$admissionId/iv-fluid-orders/$orderId/monitorings',
      data: body,
    );
  }

  /// GET `/admissions/:admissionId/iv-fluid-orders/:orderId/monitorings`
  Future<List<IvMonitoringModel>> listMonitorings({
    required String admissionId,
    required String orderId,
  }) async {
    final response = await _dio.get<dynamic>(
      '/admissions/$admissionId/iv-fluid-orders/$orderId/monitorings',
    );
    return _listData(response.data)
        .map(
          (e) => IvMonitoringModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// PATCH `/admissions/:admissionId/iv-fluid-orders/:orderId`
  Future<IvFluidOrderModel> patchOrder({
    required String admissionId,
    required String orderId,
    String? status,
    int? rate,
    DateTime? expectedEndTime,
  }) async {
    final body = <String, dynamic>{
      if (status != null) 'status': status,
      if (rate != null) 'rate': rate,
      if (expectedEndTime != null)
        'expectedEndTime': AppTimezone.toBackendIso(expectedEndTime),
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
