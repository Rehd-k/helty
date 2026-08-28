import 'package:dio/dio.dart';
import 'package:helty/src/services/api_service.dart';
import 'package:helty/src/system_announcements/models/system_announcement.dart';

class SystemAnnouncementService {
  SystemAnnouncementService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      for (final key in ['items', 'data', 'announcements']) {
        final nested = data[key];
        if (nested is List) return _asList(nested);
      }
    }
    return const [];
  }

  Future<List<SystemAnnouncement>> listActive() async {
    final resp = await _dio.get('/system-announcements/active');
    return _asList(resp.data).map(SystemAnnouncement.fromJson).toList();
  }

  Future<List<SystemAnnouncement>> listAll({
    int skip = 0,
    int take = 50,
    bool? isActive,
  }) async {
    final resp = await _dio.get(
      '/system-announcements',
      queryParameters: {
        'skip': skip,
        'take': take,
        if (isActive != null) 'isActive': isActive,
      },
    );
    return _asList(resp.data).map(SystemAnnouncement.fromJson).toList();
  }

  Future<SystemAnnouncement> create(SystemAnnouncementWritePayload payload) async {
    final resp = await _dio.post(
      '/system-announcements',
      data: payload.toJson(),
    );
    return SystemAnnouncement.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  Future<SystemAnnouncement> update(
    String id,
    SystemAnnouncementWritePayload payload,
  ) async {
    final resp = await _dio.patch(
      '/system-announcements/$id',
      data: payload.toJson(),
    );
    return SystemAnnouncement.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  Future<void> delete(String id) async {
    await _dio.delete('/system-announcements/$id');
  }
}
