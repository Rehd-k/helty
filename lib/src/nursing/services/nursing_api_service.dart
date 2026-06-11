import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../helper/app_timezone.dart';
import '../../services/api_service.dart';
import '../models/nursing_models.dart';

/// Nursing roles API client (see docs/nursing-roles-frontend-guide.md).
class NursingApiService {
  NursingApiService() : _dio = ApiService().dio;

  final Dio _dio;

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

  Never _handleError(DioException e, String fallback) {
    if (e.error is AppException) {
      throw e.error as AppException;
    }
    final status = e.response?.statusCode;
    var message = parseBackendError(
      e.response?.data,
      e.message ?? fallback,
    );
    if (status == 403) {
      message =
          'You do not have permission for this nursing action. $message';
    }
    throw UnknownException(message);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const UnknownException('Expected JSON object');
  }

  Map<String, dynamic> _overviewParams({
    required String timeRange,
    DateTime? asOf,
  }) => {
    'timeRange': timeRange,
    if (asOf != null) 'asOf': AppTimezone.toBackendIso(asOf),
  };

  // ── Bootstrap ──────────────────────────────────────────────────────────────

  Future<NursingDashboardMe> fetchMe() async {
    try {
      final response = await _dio.get<dynamic>('/nurses/dashboard/me');
      return NursingDashboardMe.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      _handleError(e, 'Failed to load nursing profile');
    }
  }

  // ── Dashboard overviews ──────────────────────────────────────────────────────

  Future<NursingDashboardOverview> getOverview({
    required String timeRange,
    DateTime? asOf,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/nurses/dashboard/overview',
        queryParameters: _overviewParams(timeRange: timeRange, asOf: asOf),
      );
      return NursingDashboardOverview.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      _handleError(e, 'Failed to load nurse dashboard');
    }
  }

  Future<NursingDashboardOverview> getMatronOverview({
    required String timeRange,
    DateTime? asOf,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/nurses/dashboard/matron/overview',
        queryParameters: _overviewParams(timeRange: timeRange, asOf: asOf),
      );
      return NursingDashboardOverview.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      _handleError(e, 'Failed to load matron dashboard');
    }
  }

  Future<NursingDashboardOverview> getChargeOverview({
    required String timeRange,
    DateTime? asOf,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/nurses/dashboard/charge/overview',
        queryParameters: _overviewParams(timeRange: timeRange, asOf: asOf),
      );
      return NursingDashboardOverview.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      _handleError(e, 'Failed to load charge nurse dashboard');
    }
  }

  Future<NursingDashboardOverview> getLineOverview({
    required String timeRange,
    DateTime? asOf,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/nurses/dashboard/line/overview',
        queryParameters: _overviewParams(timeRange: timeRange, asOf: asOf),
      );
      return NursingDashboardOverview.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      _handleError(e, 'Failed to load line nurse dashboard');
    }
  }

  Future<NursingDashboardOverview> getOverviewForRole({
    required String staffRole,
    required String timeRange,
    DateTime? asOf,
  }) {
    final role = normalizeNursingStaffRole(staffRole);
    if (role == 'MATRON') {
      return getMatronOverview(timeRange: timeRange, asOf: asOf);
    }
    if (role.endsWith('_CHARGE_NURSE')) {
      return getChargeOverview(timeRange: timeRange, asOf: asOf);
    }
    if (role == 'INPATIENT_NURSE' || role == 'OUTPATIENT_NURSE') {
      return getLineOverview(timeRange: timeRange, asOf: asOf);
    }
    return getOverview(timeRange: timeRange, asOf: asOf);
  }

  // ── Rosters ──────────────────────────────────────────────────────────────────

  Future<List<NursingRosterEntry>> listRosters({
    String? nursingUnit,
    String? wardId,
    DateTime? shiftDate,
    String? shiftType,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/nursing/rosters',
        queryParameters: {
          if (nursingUnit != null && nursingUnit.isNotEmpty)
            'nursingUnit': nursingUnit,
          if (wardId != null && wardId.isNotEmpty) 'wardId': wardId,
          if (shiftDate != null) 'shiftDate': _dateOnly(shiftDate),
          if (shiftType != null && shiftType.isNotEmpty) 'shiftType': shiftType,
        },
      );
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => NursingRosterEntry.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList();
      }
      if (data is Map) {
        final items = data['items'] ?? data['rosters'] ?? data['data'];
        if (items is List) {
          return items
              .whereType<Map>()
              .map((e) => NursingRosterEntry.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList();
        }
      }
      return const [];
    } on DioException catch (e) {
      _handleError(e, 'Failed to load shift roster');
    }
  }

  Future<NursingRosterSummary> getRosterSummary({
    String? nursingUnit,
    String? wardId,
    DateTime? shiftDate,
    String? shiftType,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/nursing/rosters/summary',
        queryParameters: {
          if (nursingUnit != null && nursingUnit.isNotEmpty)
            'nursingUnit': nursingUnit,
          if (wardId != null && wardId.isNotEmpty) 'wardId': wardId,
          if (shiftDate != null) 'shiftDate': _dateOnly(shiftDate),
          if (shiftType != null && shiftType.isNotEmpty) 'shiftType': shiftType,
        },
      );
      return NursingRosterSummary.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      _handleError(e, 'Failed to load roster summary');
    }
  }

  Future<NursingRosterEntry> createRoster(NursingRosterEntry entry) async {
    try {
      final response = await _dio.post<dynamic>(
        '/nursing/rosters',
        data: entry.toCreateJson(),
      );
      return NursingRosterEntry.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      _handleError(e, 'Failed to create roster entry');
    }
  }

  Future<NursingRosterEntry> updateRoster(
    String id,
    NursingRosterEntry entry,
  ) async {
    try {
      final response = await _dio.patch<dynamic>(
        '/nursing/rosters/$id',
        data: entry.toUpdateJson(),
      );
      return NursingRosterEntry.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      _handleError(e, 'Failed to update roster entry');
    }
  }

  Future<void> deleteRoster(String id) async {
    try {
      await _dio.delete<dynamic>('/nursing/rosters/$id');
    } on DioException catch (e) {
      _handleError(e, 'Failed to delete roster entry');
    }
  }

  // ── Inpatient assignments ────────────────────────────────────────────────────

  Future<InpatientAssignmentsResponse> listInpatientAssignments({
    String? nursingUnit,
    String? wardId,
    int? skip,
    int? take,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/nursing/assignments/inpatient',
        queryParameters: {
          if (nursingUnit != null && nursingUnit.isNotEmpty)
            'nursingUnit': nursingUnit,
          if (wardId != null && wardId.isNotEmpty) 'wardId': wardId,
          if (skip != null) 'skip': skip,
          if (take != null) 'take': take,
        },
      );
      final data = response.data;
      if (data is List) {
        final items = data
            .whereType<Map>()
            .map((e) => InpatientNurseAssignment.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList();
        return InpatientAssignmentsResponse(
          assignments: items,
          total: items.length,
        );
      }
      return InpatientAssignmentsResponse.fromJson(_asMap(data));
    } on DioException catch (e) {
      _handleError(e, 'Failed to load inpatient assignments');
    }
  }

  Future<List<InpatientNurseAssignment>> listAdmissionNurseAssignments(
    String admissionId,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        '/admissions/$admissionId/nurse-assignments',
      );
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => InpatientNurseAssignment.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList();
      }
      if (data is Map) {
        final items = data['assignments'] ?? data['items'] ?? data['data'];
        if (items is List) {
          return items
              .whereType<Map>()
              .map((e) => InpatientNurseAssignment.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList();
        }
      }
      return const [];
    } on DioException catch (e) {
      _handleError(e, 'Failed to load admission nurse assignments');
    }
  }

  Future<InpatientNurseAssignment> createInpatientAssignment({
    required String admissionId,
    required String nurseId,
    required DateTime shiftDate,
    required String shiftType,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/admissions/$admissionId/nurse-assignments',
        data: {
          'nurseId': nurseId,
          'shiftDate': _dateOnly(shiftDate),
          'shiftType': shiftType,
        },
      );
      return InpatientNurseAssignment.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      _handleError(e, 'Failed to assign nurse to admission');
    }
  }

  Future<void> deleteInpatientAssignment({
    required String admissionId,
    required String assignmentId,
  }) async {
    try {
      await _dio.delete<dynamic>(
        '/admissions/$admissionId/nurse-assignments/$assignmentId',
      );
    } on DioException catch (e) {
      _handleError(e, 'Failed to remove nurse assignment');
    }
  }

  // ── Outpatient assignments ───────────────────────────────────────────────────

  Future<OutpatientAssignmentsResponse> listOutpatientAssignments({
    String? nursingUnit,
    int? skip,
    int? take,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/nursing/assignments/outpatient',
        queryParameters: {
          if (nursingUnit != null && nursingUnit.isNotEmpty)
            'nursingUnit': nursingUnit,
          if (skip != null) 'skip': skip,
          if (take != null) 'take': take,
        },
      );
      final data = response.data;
      if (data is List) {
        final items = data
            .whereType<Map>()
            .map((e) => OutpatientNurseAssignment.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList();
        return OutpatientAssignmentsResponse(
          assignments: items,
          total: items.length,
        );
      }
      return OutpatientAssignmentsResponse.fromJson(_asMap(data));
    } on DioException catch (e) {
      _handleError(e, 'Failed to load outpatient assignments');
    }
  }

  Future<OutpatientNurseAssignment> createOutpatientAssignment({
    required String nurseId,
    required String invoiceId,
    required String nursingUnit,
    required DateTime shiftDate,
    required String shiftType,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/nursing/assignments/outpatient',
        data: {
          'nurseId': nurseId,
          'invoiceId': invoiceId,
          'nursingUnit': nursingUnit,
          'shiftDate': _dateOnly(shiftDate),
          'shiftType': shiftType,
        },
      );
      return OutpatientNurseAssignment.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      _handleError(e, 'Failed to assign outpatient nurse');
    }
  }

  Future<void> deleteOutpatientAssignment(String id) async {
    try {
      await _dio.delete<dynamic>('/nursing/assignments/outpatient/$id');
    } on DioException catch (e) {
      _handleError(e, 'Failed to remove outpatient assignment');
    }
  }

  String _dateOnly(DateTime dt) => AppTimezone.dateOnlyKey(dt);
}
