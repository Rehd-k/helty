import 'package:dio/dio.dart';

import '../../helper/app_timezone.dart';
import '../../services/api_service.dart';
import '../models/pharmacy_refill_models.dart';

/// Client for the pharmacy patient-refill queue (`/pharmacy/refill-requests`).
class PharmacyRefillService {
  PharmacyRefillService() : _dio = ApiService().dio;

  final Dio _dio;

  static List<PrescriptionRefillRequest> _parseList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map(
            (e) => PrescriptionRefillRequest.fromJson(
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
                (e) => PrescriptionRefillRequest.fromJson(
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

  static Map<String, dynamic> _unwrapObject(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map<String, dynamic>) {
        return raw['data'] as Map<String, dynamic>;
      }
      return raw;
    }
    return {};
  }

  static String _errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return e.message ?? 'Request failed';
  }

  /// GET /pharmacy/refill-requests — queue with optional filters (default PENDING).
  Future<RefillRequestListPage> list({
    RefillRequestStatus? status,
    String? patientId,
    DateTime? fromDate,
    DateTime? toDate,
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/pharmacy/refill-requests',
        queryParameters: {
          if (status != null) 'status': status.apiValue,
          if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
          if (fromDate != null) 'fromDate': AppTimezone.toBackendIso(fromDate),
          if (toDate != null) 'toDate': AppTimezone.toBackendIso(toDate),
          'skip': skip,
          'take': take,
        },
      );
      final data = response.data;
      final requests = _parseList(data);
      return RefillRequestListPage(
        data: requests,
        total: _parseTotal(data, requests.length),
        skip: skip,
        take: take,
      );
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// GET /pharmacy/refill-requests/:id — single request detail.
  Future<PrescriptionRefillRequest> getById(String id) async {
    try {
      final response = await _dio.get<dynamic>('/pharmacy/refill-requests/$id');
      return PrescriptionRefillRequest.fromJson(_unwrapObject(response.data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// PATCH /pharmacy/refill-requests/:id — approve, reject, or mark fulfilled.
  Future<PrescriptionRefillRequest> review({
    required String id,
    required RefillRequestStatus status,
    required String reviewedByStaffId,
    String? pharmacyNotes,
  }) async {
    try {
      final notes = pharmacyNotes?.trim();
      final response = await _dio.patch<Map<String, dynamic>>(
        '/pharmacy/refill-requests/$id',
        data: {
          'status': status.apiValue,
          'reviewedByStaffId': reviewedByStaffId,
          if (notes != null && notes.isNotEmpty) 'pharmacyNotes': notes,
        },
      );
      final data = response.data;
      if (data == null) {
        throw StateError('Review refill request returned no data');
      }
      return PrescriptionRefillRequest.fromJson(_unwrapObject(data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// POST /pharmacy/refill-requests/:id/bill — create the encounter invoice line.
  Future<RefillBillResult> bill({
    required String id,
    required String billedByStaffId,
    required String encounterId,
    required int quantity,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/pharmacy/refill-requests/$id/bill',
        data: {
          'billedByStaffId': billedByStaffId,
          'encounterId': encounterId,
          'quantity': quantity,
        },
      );
      final data = response.data;
      if (data == null) {
        throw StateError('Bill refill request returned no data');
      }
      return RefillBillResult.fromJson(_unwrapObject(data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  /// Marks a refill `FULFILLED` after a manual (Medicine Sales) bill/dispense.
  Future<PrescriptionRefillRequest> markFulfilled({
    required String id,
    required String reviewedByStaffId,
    String? pharmacyNotes,
  }) {
    return review(
      id: id,
      status: RefillRequestStatus.fulfilled,
      reviewedByStaffId: reviewedByStaffId,
      pharmacyNotes: pharmacyNotes,
    );
  }
}
