import 'package:dio/dio.dart';

import '../models/admin_audit_log.dart';
import 'api_service.dart';

class AdminAuditService {
  AdminAuditService() : _dio = ApiService().dio;

  final Dio _dio;

  Future<AdminAuditPage> fetch({
    String? from,
    String? to,
    String? performedById,
    String? action,
    String? entity,
    String? query,
    String? cursor,
    int limit = 50,
  }) async {
    final response = await _dio.get<dynamic>(
      '/admin/audit-logs',
      queryParameters: {
        'from': ?from,
        'to': ?to,
        'performedById': ?performedById,
        'action': ?action,
        'entity': ?entity,
        'q': ?query,
        'cursor': ?cursor,
        'limit': limit,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return AdminAuditPage.fromJson(data);
    if (data is Map) {
      return AdminAuditPage.fromJson(Map<String, dynamic>.from(data));
    }
    return const AdminAuditPage(items: []);
  }
}
