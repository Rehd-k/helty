import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../helper/app_timezone.dart';
import '../../nursing/models/nursing_models.dart';
import '../../services/api_service.dart';
import '../models/housekeeping_models.dart';

class HousekeepingApiService {
  HousekeepingApiService() : _dio = ApiService().dio;

  final Dio _dio;

  Never _throw(DioException e, String fallback) {
    if (e.error is AppException) throw e.error as AppException;
    final message = e.response?.data is Map
        ? (e.response!.data['message']?.toString() ?? fallback)
        : (e.message ?? fallback);
    throw UnknownException(message);
  }

  Future<List<HousekeepingWorker>> listWorkers() async {
    try {
      final response = await _dio.get<dynamic>('/housekeeping/workers');
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => HousekeepingWorker.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      _throw(e, 'Failed to load workers');
    }
  }

  Future<HousekeepingWorker> createWorker(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<dynamic>(
        '/housekeeping/workers',
        data: body,
      );
      return HousekeepingWorker.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      _throw(e, 'Failed to add worker');
    }
  }

  Future<void> assignArea(String workerId, String areaId) async {
    try {
      await _dio.post<dynamic>(
        '/housekeeping/workers/$workerId/areas',
        data: {'areaId': areaId},
      );
    } on DioException catch (e) {
      _throw(e, 'Failed to assign area');
    }
  }

  Future<void> unassignArea(String workerId, String areaId) async {
    try {
      await _dio.delete<dynamic>(
        '/housekeeping/workers/$workerId/areas/$areaId',
      );
    } on DioException catch (e) {
      _throw(e, 'Failed to remove assignment');
    }
  }

  Future<List<HousekeepingArea>> listAreas() async {
    try {
      final response = await _dio.get<dynamic>('/housekeeping/areas');
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => HousekeepingArea.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      _throw(e, 'Failed to load areas');
    }
  }

  Future<void> createArea(Map<String, dynamic> body) async {
    try {
      await _dio.post<dynamic>('/housekeeping/areas', data: body);
    } on DioException catch (e) {
      _throw(e, 'Failed to create area');
    }
  }

  Future<List<HousekeepingShiftEntry>> listShifts({DateTime? shiftDate}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/housekeeping/shifts',
        queryParameters: {
          if (shiftDate != null) 'shiftDate': AppTimezone.dateOnlyKey(shiftDate),
        },
      );
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map(
            (e) => HousekeepingShiftEntry.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      _throw(e, 'Failed to load shifts');
    }
  }

  Future<void> createShift({
    required String workerId,
    required DateTime shiftDate,
    required ShiftType shiftType,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/housekeeping/shifts',
        data: {
          'workerId': workerId,
          'shiftDate': AppTimezone.dateOnlyKey(shiftDate),
          'shiftType': shiftType.apiValue,
        },
      );
    } on DioException catch (e) {
      _throw(e, 'Failed to assign shift');
    }
  }

  Future<void> removeShift(String id) async {
    try {
      await _dio.delete<dynamic>('/housekeeping/shifts/$id');
    } on DioException catch (e) {
      _throw(e, 'Failed to remove shift');
    }
  }

  Future<List<HousekeepingSupplyLog>> listSupplies() async {
    try {
      final response = await _dio.get<dynamic>('/housekeeping/supplies');
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map(
            (e) => HousekeepingSupplyLog.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      _throw(e, 'Failed to load supply logs');
    }
  }

  Future<void> createSupply(Map<String, dynamic> body) async {
    try {
      await _dio.post<dynamic>('/housekeeping/supplies', data: body);
    } on DioException catch (e) {
      _throw(e, 'Failed to log supply');
    }
  }
}
