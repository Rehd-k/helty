import 'package:dio/dio.dart';
import 'package:helty/src/health_content/models/health_content_models.dart';
import 'package:helty/src/services/api_service.dart';

class HealthContentService {
  HealthContentService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      for (final key in ['items', 'data', 'campaigns', 'news', 'articles']) {
        final nested = data[key];
        if (nested is List) return _asList(nested);
      }
    }
    return const [];
  }

  Future<List<HealthCampaign>> listCampaigns({
    int skip = 0,
    int take = 50,
    bool? isPublished,
  }) async {
    final resp = await _dio.get(
      '/health-content/campaigns',
      queryParameters: {
        'skip': skip,
        'take': take,
        if (isPublished != null) 'isPublished': isPublished,
      },
    );
    return _asList(resp.data).map(HealthCampaign.fromJson).toList();
  }

  Future<HealthCampaign> createCampaign(HealthContentWritePayload payload) async {
    final resp = await _dio.post(
      '/health-content/campaigns',
      data: payload.toJson(),
    );
    return HealthCampaign.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  Future<HealthCampaign> updateCampaign(
    String id,
    HealthContentWritePayload payload,
  ) async {
    final resp = await _dio.patch(
      '/health-content/campaigns/$id',
      data: payload.toJson(),
    );
    return HealthCampaign.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  Future<void> deleteCampaign(String id) async {
    await _dio.delete('/health-content/campaigns/$id');
  }

  Future<List<HealthNewsArticle>> listNews({
    int skip = 0,
    int take = 50,
    bool? isPublished,
  }) async {
    final resp = await _dio.get(
      '/health-content/news',
      queryParameters: {
        'skip': skip,
        'take': take,
        if (isPublished != null) 'isPublished': isPublished,
      },
    );
    return _asList(resp.data).map(HealthNewsArticle.fromJson).toList();
  }

  Future<HealthNewsArticle> createNews(HealthContentWritePayload payload) async {
    final resp = await _dio.post(
      '/health-content/news',
      data: payload.toJson(),
    );
    return HealthNewsArticle.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  Future<HealthNewsArticle> updateNews(
    String id,
    HealthContentWritePayload payload,
  ) async {
    final resp = await _dio.patch(
      '/health-content/news/$id',
      data: payload.toJson(),
    );
    return HealthNewsArticle.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  Future<void> deleteNews(String id) async {
    await _dio.delete('/health-content/news/$id');
  }
}
