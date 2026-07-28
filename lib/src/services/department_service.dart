import 'package:dio/dio.dart';

import 'api_service.dart';
import '../models/staff_attribution.dart';

/// A simple Department model (for dropdowns in forms).
class Department {
  const Department({
    required this.id,
    required this.name,
    this.headId,
    this.createdByName,
    this.createdAt,
  });

  final String id;
  final String name;

  /// Holds the staff-id of the head of department (maps to `headId` in the API).
  final String? headId;
  final String? createdByName;
  final DateTime? createdAt;

  /// Legacy alias so existing code that reads `.description` still works.
  String? get description => headId;

  factory Department.fromJson(Map<String, dynamic> json) => Department(
    id: json['id'] as String,
    name: json['name'] as String,
    headId: json['headId'] as String?,
    createdByName: formatStaffName(
      json['createdBy'] is Map
          ? Map<String, dynamic>.from(json['createdBy'] as Map)
          : null,
    ),
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
  );

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'name': name,
    if (headId != null) 'headId': headId,
  };
}

class DepartmentService {
  DepartmentService() : _dio = ApiService().dio;
  final Dio _dio;

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<List<Department>> fetchDepartments({String? query}) async {
    final resp = await _dio.get(
      '/departments',
      queryParameters: {if (query != null && query.isNotEmpty) 'q': query},
    );

    final data = resp.data is List
        ? resp.data as List
        : (resp.data['departments'] as List);
    return data
        .map((e) => Department.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Department> getDepartmentById(String id) async {
    final resp = await _dio.get('/departments/$id');
    return Department.fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<Department> createDepartment(Department d) async {
    final resp = await _dio.post('/departments', data: d.toJson());
    return Department.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Department> updateDepartment(Department d) async {
    final resp = await _dio.patch('/departments/${d.id}', data: d.toJson());
    return Department.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteDepartment(String id) async {
    await _dio.delete('/departments/$id');
  }
}
