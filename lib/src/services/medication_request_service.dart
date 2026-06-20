import 'package:dio/dio.dart';

import '../models/medication_request_model.dart';
import 'api_service.dart';
import 'medication_order_service.dart';

class MedicationRequestService {
  MedicationRequestService() : _dio = ApiService().dio;

  final Dio _dio;

  static List<MedicationRequestModel> _parseList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map(
            (e) => MedicationRequestModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    }
    if (raw is Map<String, dynamic>) {
      for (final key in ['data', 'items', 'requests']) {
        final list = raw[key];
        if (list is List) {
          return list
              .whereType<Map>()
              .map(
                (e) => MedicationRequestModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList();
        }
      }
    }
    return [];
  }

  static int _parseTotal(dynamic raw, int fallback) {
    if (raw is Map) {
      final t = raw['total'];
      if (t is int) return t;
      if (t is num) return t.toInt();
    }
    return fallback;
  }

  static String _errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return e.message ?? 'Request failed';
  }

  static Map<String, dynamic> _unwrapObject(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map<String, dynamic>) {
        return raw['data'] as Map<String, dynamic>;
      }
      return raw;
    }
    return {};
  }

  /// POST /medication-requests — nurse submits billing quantity.
  Future<MedicationRequestModel> create({
    required String medicationOrderId,
    required int requestedQuantity,
    required String requestedByNurseId,
    String? notes,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/medication-requests',
        data: {
          'medicationOrderId': medicationOrderId,
          'requestedQuantity': requestedQuantity,
          'requestedByNurseId': requestedByNurseId,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
      );
      final data = response.data;
      if (data == null) {
        throw StateError('Create medication request returned no data');
      }
      return MedicationRequestModel.fromJson(_unwrapObject(data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// GET /medication-requests — list with optional filters.
  Future<MedicationRequestListPage> list({
    String? status,
    String? encounterId,
    String? patientId,
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/medication-requests',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (encounterId != null && encounterId.isNotEmpty)
            'encounterId': encounterId,
          if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
          'skip': skip,
          'take': take,
        },
      );
      final data = response.data;
      final requests = _parseList(data);
      return MedicationRequestListPage(
        requests: requests,
        total: _parseTotal(data, requests.length),
      );
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// GET /pharmacy/medication-requests — pharmacy queue (defaults to REQUESTED).
  Future<MedicationRequestListPage> listPharmacyQueue({
    String? encounterId,
    String? patientId,
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/pharmacy/medication-requests',
        queryParameters: {
          if (encounterId != null && encounterId.isNotEmpty)
            'encounterId': encounterId,
          if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
          'skip': skip,
          'take': take,
        },
      );
      final data = response.data;
      final requests = _parseList(data);
      return MedicationRequestListPage(
        requests: requests,
        total: _parseTotal(data, requests.length),
      );
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// GET /medication-requests/encounter/:encounterId
  Future<List<MedicationRequestModel>> listByEncounter(
    String encounterId,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        '/medication-requests/encounter/$encounterId',
      );
      return _parseList(response.data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// PATCH /medication-requests/:id — edit before bill.
  Future<MedicationRequestModel> update({
    required String id,
    required String modifiedByStaffId,
    int? requestedQuantity,
    String? notes,
    String? drugId,
    String? alternativeDrugId,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/medication-requests/$id',
        data: {
          'modifiedByStaffId': modifiedByStaffId,
          if (requestedQuantity != null)
            'requestedQuantity': requestedQuantity,
          if (notes != null) 'notes': notes.trim(),
          if (drugId != null && drugId.isNotEmpty) 'drugId': drugId,
          if (alternativeDrugId != null && alternativeDrugId.isNotEmpty)
            'alternativeDrugId': alternativeDrugId,
        },
      );
      final data = response.data;
      if (data == null) {
        throw StateError('Update medication request returned no data');
      }
      return MedicationRequestModel.fromJson(_unwrapObject(data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// Updates request qty/notes; swaps drug via request PATCH or medication-order fallback.
  Future<MedicationRequestModel> updateWithAlternative({
    required MedicationRequestModel request,
    required String modifiedByStaffId,
    required int requestedQuantity,
    String? notes,
    String? newDrugId,
    String? newDrugName,
    String? dose,
    String? frequency,
    String? duration,
    int? clinicalQuantity,
    String? route,
    String? specialInstructions,
    required MedicationOrderService medicationOrderService,
  }) async {
    final orderId = request.medicationOrderId;
    final currentDrugId = request.medicationOrder?.drugId;
    final drugChanged =
        newDrugId != null &&
        newDrugId.isNotEmpty &&
        newDrugId != (currentDrugId ?? '');

    if (drugChanged) {
      try {
        return await update(
          id: request.id,
          modifiedByStaffId: modifiedByStaffId,
          requestedQuantity: requestedQuantity,
          notes: notes,
          drugId: newDrugId,
        );
      } on Exception catch (e) {
        final msg = e.toString().toLowerCase();
        final unsupported =
            msg.contains('drugid') ||
            msg.contains('alternative') ||
            msg.contains('property') ||
            msg.contains('should not exist') ||
            msg.contains('not allowed');
        if (!unsupported || orderId.isEmpty) rethrow;

        await medicationOrderService.update(
          id: orderId,
          drugId: newDrugId,
          drugName: newDrugName,
          dose: dose,
          frequency: frequency,
          duration: duration,
          quantity: clinicalQuantity,
          route: route,
          specialInstructions: specialInstructions,
        );
        return update(
          id: request.id,
          modifiedByStaffId: modifiedByStaffId,
          requestedQuantity: requestedQuantity,
          notes: notes,
        );
      }
    }

    return update(
      id: request.id,
      modifiedByStaffId: modifiedByStaffId,
      requestedQuantity: requestedQuantity,
      notes: notes,
    );
  }

  /// DELETE /medication-requests/:id — cancel request.
  Future<void> cancel({
    required String id,
    required String cancelledByStaffId,
  }) async {
    try {
      await _dio.delete(
        '/medication-requests/$id',
        queryParameters: {'cancelledByStaffId': cancelledByStaffId},
      );
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// POST /medication-requests/bill — create invoice lines for selected requests.
  Future<MedicationRequestBillResult> bill({
    required String encounterId,
    required String billedByStaffId,
    List<String>? requestIds,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/medication-requests/bill',
        data: {
          'encounterId': encounterId,
          'billedByStaffId': billedByStaffId,
          if (requestIds != null && requestIds.isNotEmpty)
            'requestIds': requestIds,
        },
      );
      final data = response.data;
      if (data == null) {
        throw StateError('Bill medication requests returned no data');
      }
      return MedicationRequestBillResult.fromJson(_unwrapObject(data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }
}
