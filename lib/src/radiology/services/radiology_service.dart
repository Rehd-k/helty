import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../services/api_service.dart';
import '../models/radiology_models.dart';

/// Radiology API service. Base path: /radiology.
/// All errors are rethrown as [AppException] (via ErrorInterceptor or _handleError).
class RadiologyService {
  RadiologyService() : _dio = ApiService().dio;
  final Dio _dio;

  static const String _base = '/radiology';

  String parseBackendError(dynamic data, String fallback) {
    if (data == null) return fallback;
    if (data is String && data.trim().isNotEmpty) return data;
    if (data is! Map) return fallback;

    final message = data['message']?.toString();
    final errors = data['errors'];
    if (errors is Map) {
      final flat = <String>[];
      errors.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          flat.add('$key: ${value.join(', ')}');
        } else if (value != null) {
          flat.add('$key: $value');
        }
      });
      if (flat.isNotEmpty) return flat.join('\n');
    }
    if (errors is List && errors.isNotEmpty) {
      return errors.join('\n');
    }
    if (message != null && message.trim().isNotEmpty) return message;
    return fallback;
  }

  Never _handleError(DioException e) {
    if (e.error is AppException) {
      throw e.error as AppException;
    }
    final message = parseBackendError(
      e.response?.data,
      e.message ?? 'Radiology request failed.',
    );
    throw UnknownException(
      message,
    );
  }

  // ─── Orders ─────────────────────────────────────────────────────────────

  Future<RadiologyOrder> createOrder(Map<String, dynamic> body) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/orders',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologyOrder.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyOrdersListResponse> listOrders({
    RadiologyOrderStatus? status,
    String? patientId,
    String? encounterId,
    String? fromDate,
    String? toDate,
    RadiologyPriority? priority,
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/orders',
        queryParameters: {
          if (status != null) 'status': status.apiValue,
          if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
          if (encounterId != null && encounterId.isNotEmpty)
            'encounterId': encounterId,
          if (fromDate != null) 'fromDate': fromDate,
          if (toDate != null) 'toDate': toDate,
          if (priority != null) 'priority': priority.apiValue,
          'skip': skip,
          'take': take > 100 ? 100 : take,
        },
      );
      final data = resp.data;
      if (data == null) {
        return const RadiologyOrdersListResponse(
          orders: [],
          total: 0,
          skip: 0,
          take: 20,
        );
      }
      return RadiologyOrdersListResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyOrdersListResponse> getWorklist({
    RadiologyOrderStatus? status,
    String? patientId,
    String? fromDate,
    String? toDate,
    RadiologyPriority? priority,
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/worklist',
        queryParameters: {
          if (status != null) 'status': status.apiValue,
          if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
          if (fromDate != null) 'fromDate': fromDate,
          if (toDate != null) 'toDate': toDate,
          if (priority != null) 'priority': priority.apiValue,
          'skip': skip,
          'take': take > 100 ? 100 : take,
        },
      );
      final data = resp.data;
      if (data == null) {
        return const RadiologyOrdersListResponse(
          orders: [],
          total: 0,
          skip: 0,
          take: 20,
        );
      }
      return RadiologyOrdersListResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyOrder> getOrder(String id) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>('$_base/orders/$id');
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologyOrder.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyOrder> updateOrder(
      String id, Map<String, dynamic> body) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/orders/$id',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologyOrder.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await _dio.delete('$_base/orders/$id');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyOrderItem> updateOrderItem(
    String orderItemId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/order-items/$orderItemId',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologyOrderItem.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── Schedule ───────────────────────────────────────────────────────────

  Future<RadiologySchedule> createSchedule(
    String orderItemId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/order-items/$orderItemId/schedule',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologySchedule.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologySchedule> updateSchedule(
    String orderItemId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/order-items/$orderItemId/schedule',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologySchedule.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologySchedule?> getSchedule(String orderItemId) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/order-items/$orderItemId/schedule',
      );
      final data = resp.data;
      if (data == null) return null;
      return RadiologySchedule.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _handleError(e);
    }
  }

  // ─── Procedure ──────────────────────────────────────────────────────────

  Future<RadiologyProcedure> createProcedure(
    String orderItemId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/order-items/$orderItemId/procedure',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologyProcedure.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyProcedure> updateProcedure(
    String orderItemId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/order-items/$orderItemId/procedure',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologyProcedure.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyProcedure?> getProcedure(String orderItemId) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/order-items/$orderItemId/procedure',
      );
      final data = resp.data;
      if (data == null) return null;
      return RadiologyProcedure.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _handleError(e);
    }
  }

  // ─── Images ──────────────────────────────────────────────────────────────

  Future<RadiologyImage> uploadImage(String orderItemId, File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/order-items/$orderItemId/images',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologyImage.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<List<RadiologyImage>> listImages(String orderItemId) async {
    try {
      final resp = await _dio.get<List<dynamic>>(
        '$_base/order-items/$orderItemId/images',
      );
      final data = resp.data;
      if (data == null) return [];
      return data
          .map((e) => RadiologyImage.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// Returns the URL for the image file (app must send auth header if required).
  String getImageFileUrl(String imageId) {
    final base = _dio.options.baseUrl;
    return '$base$_base/images/$imageId/file';
  }

  /// Fetches image file bytes (with auth). Use for in-app viewer.
  Future<List<int>> getImageFileBytes(String imageId) async {
    try {
      final resp = await _dio.get<List<int>>(
        '$_base/images/$imageId/file',
        options: Options(responseType: ResponseType.bytes),
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteImage(String imageId) async {
    try {
      await _dio.delete('$_base/images/$imageId');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── Report ─────────────────────────────────────────────────────────────

  Future<RadiologyStudyReport> createReport(
    String orderItemId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/order-items/$orderItemId/report',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologyStudyReport.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyStudyReport> updateReport(
    String orderItemId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/order-items/$orderItemId/report',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologyStudyReport.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyStudyReport?> getReport(String orderItemId) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/order-items/$orderItemId/report',
      );
      final data = resp.data;
      if (data == null) return null;
      return RadiologyStudyReport.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _handleError(e);
    }
  }

  // ─── Dashboard ──────────────────────────────────────────────────────────

  Future<RadiologyDashboardResponse> getDashboard() async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>('$_base/dashboard');
      final data = resp.data;
      if (data == null) {
        return const RadiologyDashboardResponse();
      }
      return RadiologyDashboardResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── Patient history ────────────────────────────────────────────────────

  Future<RadiologyPatientHistoryResponse> getPatientRadiologyHistory(
      String patientId) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/patients/$patientId/radiology-history',
      );
      final data = resp.data;
      if (data == null) {
        return RadiologyPatientHistoryResponse(patientId: patientId);
      }
      return RadiologyPatientHistoryResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── Machines ───────────────────────────────────────────────────────────

  Future<List<RadiologyMachine>> listMachines({bool activeOnly = true}) async {
    try {
      final resp = await _dio.get<List<dynamic>>(
        '$_base/machines',
        queryParameters: {'activeOnly': activeOnly},
      );
      final data = resp.data;
      if (data == null) return [];
      return data
          .map((e) => RadiologyMachine.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<List<RadiologyMachine>> listMachinesByModality(String modality) async {
    try {
      final resp = await _dio.get<List<dynamic>>(
        '$_base/machines/by-modality/$modality',
      );
      final data = resp.data;
      if (data == null) return [];
      return data
          .map((e) => RadiologyMachine.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyMachine> getMachine(String id) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>('$_base/machines/$id');
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologyMachine.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }
}
