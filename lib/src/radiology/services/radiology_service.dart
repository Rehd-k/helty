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

  Never _handleError(DioException e) {
    if (e.error is AppException) {
      throw e.error as AppException;
    }
    final message = e.response?.data is Map
        ? (e.response!.data['message'] ?? e.message)?.toString()
        : e.message;
    throw UnknownException(
      message?.toString().isNotEmpty == true
          ? message!
          : 'Radiology request failed.',
    );
  }

  // ─── Requests ───────────────────────────────────────────────────────────

  Future<RadiologyRequest> createRequest(Map<String, dynamic> body) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/requests',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologyRequest.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyRequestsListResponse> listRequests({
    RadiologyRequestStatus? status,
    String? patientId,
    String? fromDate,
    String? toDate,
    RadiologyPriority? priority,
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/requests',
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
        return const RadiologyRequestsListResponse(
          requests: [],
          total: 0,
          skip: 0,
          take: 20,
        );
      }
      return RadiologyRequestsListResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyRequestsListResponse> getWorklist({
    RadiologyRequestStatus? status,
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
        return const RadiologyRequestsListResponse(
          requests: [],
          total: 0,
          skip: 0,
          take: 20,
        );
      }
      return RadiologyRequestsListResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyRequest> getRequest(String id) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>('$_base/requests/$id');
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologyRequest.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyRequest> updateRequest(
      String id, Map<String, dynamic> body) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/requests/$id',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologyRequest.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── Schedule ───────────────────────────────────────────────────────────

  Future<RadiologySchedule> createSchedule(
    String requestId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/requests/$requestId/schedule',
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
    String requestId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/requests/$requestId/schedule',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologySchedule.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologySchedule?> getSchedule(String requestId) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/requests/$requestId/schedule',
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
    String requestId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/requests/$requestId/procedure',
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
    String requestId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/requests/$requestId/procedure',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologyProcedure.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyProcedure?> getProcedure(String requestId) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/requests/$requestId/procedure',
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

  Future<RadiologyImage> uploadImage(String requestId, File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/requests/$requestId/images',
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

  Future<List<RadiologyImage>> listImages(String requestId) async {
    try {
      final resp = await _dio.get<List<dynamic>>(
        '$_base/requests/$requestId/images',
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
    String requestId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/requests/$requestId/report',
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
    String requestId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/requests/$requestId/report',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return RadiologyStudyReport.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<RadiologyStudyReport?> getReport(String requestId) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/requests/$requestId/report',
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
