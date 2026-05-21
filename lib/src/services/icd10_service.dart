import 'package:dio/dio.dart';

import 'package:helty/src/models/icd10_model.dart';
import 'package:helty/src/services/api_service.dart';

/// Paginated ICD-10 search result from `GET /icd10/search`.
class Icd10PagedResult {
  const Icd10PagedResult({
    required this.items,
    required this.total,
    required this.skip,
    required this.take,
  });

  final List<Icd10Model> items;
  final int total;
  final int skip;
  final int take;
}

/// ICD-10 lookup via backend `/icd10` endpoints.
class Icd10Service {
  Icd10Service() : _dio = ApiService().dio;

  final Dio _dio;

  /// Typeahead search — `GET /icd10/search`.
  Future<Icd10PagedResult> search(
    String q, {
    int take = 20,
    int skip = 0,
    String? specialty,
    String? icdGroup,
  }) async {
    final trimmed = q.trim();
    final resp = await _dio.get<Map<String, dynamic>>(
      '/icd10/search',
      queryParameters: {
        if (trimmed.isNotEmpty) 'q': trimmed,
        'skip': skip,
        'take': take,
        if (specialty != null && specialty.trim().isNotEmpty)
          'specialty': specialty.trim(),
        if (icdGroup != null && icdGroup.trim().isNotEmpty)
          'icdGroup': icdGroup.trim(),
      },
    );
    return _parsePaged(resp.data);
  }

  /// Convenience wrapper returning only [Icd10PagedResult.items].
  Future<List<Icd10Model>> searchList(
    String q, {
    int take = 20,
    int skip = 0,
  }) async {
    final page = await search(q, take: take, skip: skip);
    return page.items;
  }

  Icd10PagedResult _parsePaged(Map<String, dynamic>? data) {
    if (data == null) {
      return const Icd10PagedResult(items: [], total: 0, skip: 0, take: 0);
    }
    final rawList = data['items'] as List<dynamic>? ?? [];
    final items = rawList
        .map((e) => Icd10Model.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (data['total'] as num?)?.toInt() ?? items.length;
    final skip = (data['skip'] as num?)?.toInt() ?? 0;
    final take = (data['take'] as num?)?.toInt() ?? items.length;
    return Icd10PagedResult(
      items: items,
      total: total,
      skip: skip,
      take: take,
    );
  }
}
