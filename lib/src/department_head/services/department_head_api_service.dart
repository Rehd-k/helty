import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../helper/app_timezone.dart';
import '../../nursing/models/nursing_models.dart';
import '../../services/api_service.dart';
import '../models/department_head_models.dart';

class DepartmentHeadApiService {
  DepartmentHeadApiService() : _dio = ApiService().dio;

  final Dio _dio;

  Never _throw(DioException e, String fallback) {
    if (e.error is AppException) throw e.error as AppException;
    final message = e.response?.data is Map
        ? (e.response!.data['message']?.toString() ?? fallback)
        : (e.message ?? fallback);
    throw UnknownException(message);
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const UnknownException('Expected JSON object');
  }

  Future<List<DepartmentStaffMember>> listStaff({String? accountType}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/department-head/staff',
        queryParameters: {
          if (accountType != null) 'accountType': accountType,
        },
      );
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => DepartmentStaffMember.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      _throw(e, 'Failed to load department staff');
    }
  }

  Future<List<DepartmentRosterEntry>> listRosters({
    DateTime? shiftDate,
    String? shiftType,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/department-head/rosters',
        queryParameters: {
          if (shiftDate != null) 'shiftDate': AppTimezone.dateOnlyKey(shiftDate),
          if (shiftType != null) 'shiftType': shiftType,
        },
      );
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => DepartmentRosterEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      _throw(e, 'Failed to load shift roster');
    }
  }

  Future<DepartmentRosterSummary> rosterSummary({DateTime? shiftDate}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/department-head/rosters/summary',
        queryParameters: {
          if (shiftDate != null) 'shiftDate': AppTimezone.dateOnlyKey(shiftDate),
        },
      );
      return DepartmentRosterSummary.fromJson(_map(response.data));
    } on DioException catch (e) {
      _throw(e, 'Failed to load roster summary');
    }
  }

  Future<void> addToRoster({
    required String staffId,
    required DateTime shiftDate,
    required ShiftType shiftType,
    String? notes,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/department-head/rosters',
        data: {
          'staffId': staffId,
          'shiftDate': AppTimezone.dateOnlyKey(shiftDate),
          'shiftType': shiftType.apiValue,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes,
        },
      );
    } on DioException catch (e) {
      _throw(e, 'Failed to add to roster');
    }
  }

  Future<void> removeRoster(String id) async {
    try {
      await _dio.delete<dynamic>('/department-head/rosters/$id');
    } on DioException catch (e) {
      _throw(e, 'Failed to remove roster entry');
    }
  }
}
