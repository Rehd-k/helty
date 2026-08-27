import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../helper/app_timezone.dart';
import '../../services/api_service.dart';
import '../models/theatre_models.dart';

/// Theatre / surgery API client. Endpoints under /surgery-requests and /theatre.
class TheatreApiService {
  TheatreApiService() : _dio = ApiService().dio;

  final Dio _dio;
  static const _surgeryPrefix = '/surgery-requests';
  static const _theatrePrefix = '/theatre';

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
      e.message ?? 'Theatre request failed.',
    );
    throw UnknownException(message);
  }

  // --- Surgery requests ---

  Future<SurgeryRequest> createSurgeryRequest({
    required String encounterId,
    required String patientId,
    required String requestedById,
    required String serviceId,
    String? admissionId,
    SurgeryPriority priority = SurgeryPriority.routine,
    String? clinicalNotes,
    DateTime? preferredDate,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _surgeryPrefix,
        data: {
          'encounterId': encounterId,
          'patientId': patientId,
          'requestedById': requestedById,
          'serviceId': serviceId,
          if (admissionId != null && admissionId.isNotEmpty)
            'admissionId': admissionId,
          'priority': priority.apiValue,
          if (clinicalNotes != null && clinicalNotes.isNotEmpty)
            'clinicalNotes': clinicalNotes,
          if (preferredDate != null)
            'preferredDate': AppTimezone.toBackendIso(preferredDate),
        },
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return SurgeryRequest.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<SurgeryRequestsResponse> getSurgeryRequests({
    String? encounterId,
    String? patientId,
    SurgeryRequestStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    int? skip,
    int? take,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _surgeryPrefix,
        queryParameters: {
          if (encounterId != null && encounterId.isNotEmpty)
            'encounterId': encounterId,
          if (patientId != null && patientId.isNotEmpty)
            'patientId': patientId,
          if (status != null) 'status': status.apiValue,
          if (fromDate != null) 'fromDate': AppTimezone.toBackendIso(fromDate),
          if (toDate != null) 'toDate': AppTimezone.toBackendIso(toDate),
          if (skip != null) 'skip': skip,
          if (take != null) 'take': take > 100 ? 100 : take,
        },
      );
      final data = response.data;
      if (data == null) {
        return const SurgeryRequestsResponse(requests: [], total: 0);
      }
      return SurgeryRequestsResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<List<SurgeryRequest>> getSurgeryRequestsForEncounter(
    String encounterId,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_surgeryPrefix/encounter/$encounterId',
      );
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => SurgeryRequest.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data is Map<String, dynamic>) {
        return SurgeryRequestsResponse.fromJson(data).requests;
      }
      return const [];
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<SurgeryRequest> getSurgeryRequestById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_surgeryPrefix/$id',
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return SurgeryRequest.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<SurgeryRequest> patchSurgeryRequest(
    String id, {
    SurgeryPriority? priority,
    String? clinicalNotes,
    DateTime? preferredDate,
    SurgeryRequestStatus? status,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_surgeryPrefix/$id',
        data: {
          if (priority != null) 'priority': priority.apiValue,
          if (clinicalNotes != null) 'clinicalNotes': clinicalNotes,
          if (preferredDate != null)
            'preferredDate': AppTimezone.toBackendIso(preferredDate),
          if (status != null) 'status': status.apiValue,
        },
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return SurgeryRequest.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // --- Theatre rooms ---

  Future<List<TheatreRoom>> getRooms() async {
    try {
      final response = await _dio.get<dynamic>('$_theatrePrefix/rooms');
      return TheatreRoomsResponse.fromJson(response.data).rooms;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<TheatreRoom> createRoom({
    required String name,
    bool isActive = true,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_theatrePrefix/rooms',
        data: {'name': name, 'isActive': isActive},
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return TheatreRoom.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<TheatreRoom> patchRoom(
    String id, {
    String? name,
    bool? isActive,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_theatrePrefix/rooms/$id',
        data: {
          if (name != null) 'name': name,
          if (isActive != null) 'isActive': isActive,
        },
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return TheatreRoom.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // --- Theatre schedules ---

  Future<TheatreSchedule> createSchedule({
    required String surgeryRequestId,
    required String theatreRoomId,
    required DateTime scheduledAt,
    int? estimatedDurationMins,
    String? surgeonId,
    String? anaesthetistId,
    String? scrubNurseId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_theatrePrefix/schedules',
        data: {
          'surgeryRequestId': surgeryRequestId,
          'theatreRoomId': theatreRoomId,
          'scheduledAt': AppTimezone.toBackendIso(scheduledAt),
          if (estimatedDurationMins != null)
            'estimatedDurationMins': estimatedDurationMins,
          if (surgeonId != null && surgeonId.isNotEmpty)
            'surgeonId': surgeonId,
          if (anaesthetistId != null && anaesthetistId.isNotEmpty)
            'anaesthetistId': anaesthetistId,
          if (scrubNurseId != null && scrubNurseId.isNotEmpty)
            'scrubNurseId': scrubNurseId,
        },
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return TheatreSchedule.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<TheatreSchedulesResponse> getSchedules({
    String? theatreRoomId,
    String? surgeonId,
    DateTime? fromDate,
    DateTime? toDate,
    int? skip,
    int? take,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_theatrePrefix/schedules',
        queryParameters: {
          if (theatreRoomId != null && theatreRoomId.isNotEmpty)
            'theatreRoomId': theatreRoomId,
          if (surgeonId != null && surgeonId.isNotEmpty)
            'surgeonId': surgeonId,
          if (fromDate != null) 'fromDate': AppTimezone.toBackendIso(fromDate),
          if (toDate != null) 'toDate': AppTimezone.toBackendIso(toDate),
          if (skip != null) 'skip': skip,
          if (take != null) 'take': take > 100 ? 100 : take,
        },
      );
      final data = response.data;
      if (data == null) {
        return const TheatreSchedulesResponse(schedules: [], total: 0);
      }
      return TheatreSchedulesResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<TheatreSchedule> patchSchedule(
    String id, {
    String? theatreRoomId,
    DateTime? scheduledAt,
    int? estimatedDurationMins,
    String? surgeonId,
    String? anaesthetistId,
    String? scrubNurseId,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_theatrePrefix/schedules/$id',
        data: {
          if (theatreRoomId != null) 'theatreRoomId': theatreRoomId,
          if (scheduledAt != null)
            'scheduledAt': AppTimezone.toBackendIso(scheduledAt),
          if (estimatedDurationMins != null)
            'estimatedDurationMins': estimatedDurationMins,
          if (surgeonId != null) 'surgeonId': surgeonId,
          if (anaesthetistId != null) 'anaesthetistId': anaesthetistId,
          if (scrubNurseId != null) 'scrubNurseId': scrubNurseId,
        },
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return TheatreSchedule.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // --- Theatre cases ---

  Future<SurgeryRequest> getCase(String surgeryRequestId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_theatrePrefix/cases/$surgeryRequestId',
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return SurgeryRequest.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<SurgeryRequest> startCase(String surgeryRequestId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_theatrePrefix/cases/$surgeryRequestId/start',
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return SurgeryRequest.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<SurgeryRequest> patchCase(
    String surgeryRequestId, {
    String? findings,
    String? complications,
    String? operativeNotes,
    String? performedById,
    List<TheatreTeamMember>? team,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_theatrePrefix/cases/$surgeryRequestId',
        data: {
          if (findings != null) 'findings': findings,
          if (complications != null) 'complications': complications,
          if (operativeNotes != null) 'operativeNotes': operativeNotes,
          if (performedById != null && performedById.isNotEmpty)
            'performedById': performedById,
          if (team != null) 'team': team.map((m) => m.toJson()).toList(),
        },
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return SurgeryRequest.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<List<TheatreOperativeNote>> getOperativeNotes(
    String surgeryRequestId,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_theatrePrefix/cases/$surgeryRequestId/operative-notes',
      );
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (e) => TheatreOperativeNote.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      }
      if (data is Map) {
        final raw = data['notes'] ?? data['data'] ?? data['items'];
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map(
                (e) => TheatreOperativeNote.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList();
        }
      }
      return const [];
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<TheatreOperativeNote> createOperativeNote(
    String surgeryRequestId, {
    required Map<String, dynamic> answersJson,
    required String narrative,
    String? additionalNotes,
    int schemaVersion = 1,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_theatrePrefix/cases/$surgeryRequestId/operative-notes',
        data: {
          'answersJson': answersJson,
          'narrative': narrative,
          'schemaVersion': schemaVersion,
          if (additionalNotes != null && additionalNotes.isNotEmpty)
            'additionalNotes': additionalNotes,
        },
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return TheatreOperativeNote.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<TheatreOperativeNote> updateOperativeNote(
    String surgeryRequestId,
    String noteId, {
    required Map<String, dynamic> answersJson,
    required String narrative,
    String? additionalNotes,
    int schemaVersion = 1,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_theatrePrefix/cases/$surgeryRequestId/operative-notes/$noteId',
        data: {
          'answersJson': answersJson,
          'narrative': narrative,
          'schemaVersion': schemaVersion,
          if (additionalNotes != null) 'additionalNotes': additionalNotes,
        },
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return TheatreOperativeNote.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<SurgeryRequest> completeCase(String surgeryRequestId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_theatrePrefix/cases/$surgeryRequestId/complete',
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return SurgeryRequest.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<TheatreCaseConsumable> addCaseConsumable(
    String surgeryRequestId, {
    required String consumableId,
    required String storeLocationId,
    required int quantity,
    required double unitPrice,
    bool billable = true,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_theatrePrefix/cases/$surgeryRequestId/consumables',
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
      return TheatreCaseConsumable.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteCaseConsumable(
    String surgeryRequestId,
    String consumableLineId,
  ) async {
    try {
      await _dio.delete<void>(
        '$_theatrePrefix/cases/$surgeryRequestId/consumables/$consumableLineId',
      );
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<SurgeryRequest> billCase(
    String surgeryRequestId, {
    required String billedByStaffId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_theatrePrefix/cases/$surgeryRequestId/bill',
        data: {'billedByStaffId': billedByStaffId},
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return SurgeryRequest.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<SurgeryRequest> transferCase(
    String surgeryRequestId, {
    required String admissionId,
    required String wardId,
    required String bedId,
    String? transferNotes,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_theatrePrefix/cases/$surgeryRequestId/transfer',
        data: {
          'admissionId': admissionId,
          'wardId': wardId,
          'bedId': bedId,
          if (transferNotes != null && transferNotes.isNotEmpty)
            'transferNotes': transferNotes,
        },
      );
      final data = response.data;
      if (data == null) throw const UnknownException('Empty response');
      return SurgeryRequest.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }
}
