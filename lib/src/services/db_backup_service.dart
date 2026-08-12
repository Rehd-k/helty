import 'package:dio/dio.dart';

import '../services/api_service.dart';

class DbBackupResult {
  const DbBackupResult({
    required this.filename,
    required this.sizeBytes,
    required this.createdAt,
  });

  final String filename;
  final int sizeBytes;
  final String createdAt;

  factory DbBackupResult.fromJson(Map<String, dynamic> json) {
    return DbBackupResult(
      filename: json['filename'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class DbBackupService {
  DbBackupService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  Future<DbBackupResult> createBackup() async {
    final resp = await _dio.post('/admin/db-backups');
    return DbBackupResult.fromJson(resp.data as Map<String, dynamic>);
  }
}
