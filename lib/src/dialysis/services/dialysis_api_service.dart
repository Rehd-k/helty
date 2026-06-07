import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../services/api_service.dart';
import '../models/dialysis_models.dart';

/// Dialysis API client. All endpoints under /dialysis.
class DialysisApiService {
  DialysisApiService() : _dio = ApiService().dio;

  final Dio _dio;
  static const _prefix = '/dialysis';

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
      e.message ?? 'Dialysis request failed.',
    );
    throw UnknownException(message);
  }

  Future<DialysisSession> createSession({
    required String patientId,
    String? doctorId,
    String? invoiceId,
    String? invoiceItemId,
    String? serviceId,
    String? notes,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_prefix/sessions',
        data: {
          'patientId': patientId,
          if (doctorId != null && doctorId.isNotEmpty) 'doctorId': doctorId,
          if (invoiceId != null && invoiceId.isNotEmpty) 'invoiceId': invoiceId,
          if (invoiceItemId != null && invoiceItemId.isNotEmpty)
            'invoiceItemId': invoiceItemId,
          if (serviceId != null && serviceId.isNotEmpty) 'serviceId': serviceId,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return DialysisSession.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<DialysisSessionsResponse> getSessions({
    String? patientId,
    DialysisSessionStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    int? skip,
    int? take,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_prefix/sessions',
        queryParameters: {
          if (patientId != null && patientId.isNotEmpty)
            'patientId': patientId,
          if (status != null) 'status': status.apiValue,
          if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
          if (toDate != null) 'toDate': toDate.toIso8601String(),
          if (skip != null) 'skip': skip,
          if (take != null) 'take': take > 100 ? 100 : take,
        },
      );
      final data = response.data;
      if (data == null) {
        return const DialysisSessionsResponse(sessions: [], total: 0);
      }
      return DialysisSessionsResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<DialysisSession> getSessionById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_prefix/sessions/$id',
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return DialysisSession.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<DialysisSession> updateSession(
    String id, {
    DialysisSessionStatus? status,
    String? notes,
    String? performedById,
    String? machineId,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_prefix/sessions/$id',
        data: {
          if (status != null) 'status': status.apiValue,
          if (notes != null) 'notes': notes,
          if (performedById != null && performedById.isNotEmpty)
            'performedById': performedById,
          if (machineId != null) 'machineId': machineId,
        },
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return DialysisSession.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<DialysisSessionConsumable> addSessionConsumable(
    String sessionId, {
    required String consumableId,
    required String storeLocationId,
    required int quantity,
    required double unitPrice,
    bool billable = true,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_prefix/sessions/$sessionId/consumables',
        data: {
          'consumableId': consumableId,
          'storeLocationId': storeLocationId,
          'quantity': quantity,
          'unitPrice': unitPrice,
          'billable': billable,
        },
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return DialysisSessionConsumable.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }
}
