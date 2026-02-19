import 'package:dio/dio.dart';

import '../models/staff_model.dart';
import 'api_service.dart';

class StaffService {
  StaffService() : _dio = ApiService().dio;
  final Dio _dio;

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<List<Staff>> fetchStaff({
    String? query,
    String? role,
    String? departmentId,
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    final resp = await _dio.get(
      '/staff',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (role != null) 'role': role,
        if (departmentId != null) 'departmentId': departmentId,
        if (isActive != null) 'isActive': isActive,
        'page': page,
        'limit': limit,
      },
    );
    final data = resp.data is List
        ? resp.data as List
        : (resp.data['data'] as List);
    return data.map((e) => Staff.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Staff> getStaffById(String id) async {
    final resp = await _dio.get('/staff/$id');
    return Staff.fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<Staff> createStaff(Staff s) async {
    final resp = await _dio.post('/staff', data: s.toJson());
    return Staff.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Staff> updateStaff(Staff s) async {
    final resp = await _dio.patch('/staff/${s.id}', data: s.toJson());
    return Staff.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Staff> deactivateStaff(String id) async {
    final resp = await _dio.patch('/staff/$id', data: {'isActive': false});
    return Staff.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Staff> activateStaff(String id) async {
    final resp = await _dio.patch('/staff/$id', data: {'isActive': true});
    return Staff.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteStaff(String id) async {
    await _dio.delete('/staff/$id');
  }

  // ── Password ──────────────────────────────────────────────────────────────

  Future<void> changePassword({
    required String staffId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      '/staff/$staffId/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
