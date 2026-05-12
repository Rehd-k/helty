import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../pharmacy/models/pharmacy_model.dart';
import '../../services/api_service.dart';
import '../models/consumable_models.dart';

/// Store consumables API (`/store/consumables` per backend contract).
///
/// **Route choice:** This client targets `/store/consumables`. If your server
/// only exposes `/pharmacy/consumables`, repoint [prefix] or add a gateway alias.
class StoreConsumableApiService {
  StoreConsumableApiService({Dio? dio})
      : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  static const String prefix = '/store/consumables';

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
          : 'Store consumables request failed.',
    );
  }

  Map<String, dynamic> _mapFromResponse(Response<dynamic> resp) {
    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const UnknownException('Invalid response format from store API.');
  }

  int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value == null) return fallback;
    return int.tryParse(value.toString()) ?? fallback;
  }

  PaginatedResponse<T> _parsePaginated<T>(
    Response<dynamic> resp,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    dynamic data = resp.data;
    if (data == null) {
      return PaginatedResponse<T>(items: [], total: 0, page: 1, pageSize: 20);
    }
    if (data is List) {
      final items = data
          .map(
            (e) => fromJson(
              e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      return PaginatedResponse<T>(
        items: items,
        total: items.length,
        page: 1,
        pageSize: items.isNotEmpty ? items.length : 20,
      );
    }
    if (data is! Map) {
      return PaginatedResponse<T>(items: [], total: 0, page: 1, pageSize: 20);
    }
    var map = Map<String, dynamic>.from(data);
    final inner = map['data'];
    if (inner is Map && inner is! List) {
      final innerMap = Map<String, dynamic>.from(inner);
      if (innerMap.containsKey('data') || innerMap.containsKey('items')) {
        map = innerMap;
      }
    }
    final list = map['data'] ?? map['items'] ?? map['results'] ?? map['list'];
    final rawList = list is List ? list : <dynamic>[];
    final items = rawList
        .map(
          (e) => fromJson(
            e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    final total = _toInt(
      map['total'] ?? map['totalCount'] ?? map['totalRecords'],
      items.length,
    );
    final skip = _toInt(map['skip'], 0);
    final take = _toInt(map['take'] ?? map['limit'], 20);
    final page = _toInt(map['page'], take > 0 ? (skip ~/ take) + 1 : 1);
    final pageSize = _toInt(map['pageSize'] ?? map['limit'], take);
    return PaginatedResponse<T>(
      items: items,
      total: total,
      page: page,
      pageSize: pageSize > 0 ? pageSize : 20,
    );
  }

  Future<PaginatedResponse<Consumable>> listConsumables([
    StoreConsumableListParams? params,
  ]) async {
    final p = params ?? const StoreConsumableListParams();
    try {
      final resp = await _dio.get(
        prefix,
        queryParameters: p.toQuery(),
      );
      return _parsePaginated(resp, (m) => Consumable.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse consumables: $e');
    }
  }

  Future<Consumable> getConsumable(String id) async {
    try {
      final resp = await _dio.get('$prefix/$id');
      return Consumable.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse consumable: $e');
    }
  }

  Future<Consumable> createConsumable(Consumable consumable) async {
    try {
      final resp = await _dio.post(prefix, data: consumable.toJson());
      return Consumable.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Consumable> updateConsumable(Consumable consumable) async {
    if (consumable.id == null || consumable.id!.isEmpty) {
      throw const ValidationException('Consumable id required for update.');
    }
    try {
      final resp = await _dio.patch(
        '$prefix/${consumable.id}',
        data: consumable.toJson(),
      );
      return Consumable.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteConsumable(String id) async {
    try {
      await _dio.delete('$prefix/$id');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<ConsumableBatch> createBatch(
    String consumableId,
    ConsumableBatch batch,
  ) async {
    if (consumableId.trim().isEmpty) {
      throw const ValidationException('Consumable id required.');
    }
    try {
      final resp = await _dio.post(
        '$prefix/${consumableId.trim()}/batches',
        data: batch.toCreateBody(),
      );
      return ConsumableBatch.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse consumable batch: $e');
    }
  }

  Future<PaginatedResponse<ConsumableBatch>> listBatches(
    String consumableId, [
    StoreConsumableListParams? params,
  ]) async {
    if (consumableId.trim().isEmpty) {
      throw const ValidationException('Consumable id required.');
    }
    final p = params ?? const StoreConsumableListParams();
    try {
      final resp = await _dio.get(
        '$prefix/${consumableId.trim()}/batches',
        queryParameters: p.toQuery(),
      );
      return _parsePaginated(resp, ConsumableBatch.fromJson);
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse consumable batches: $e');
    }
  }

  /// `GET /store/consumables/analytics/summary`
  Future<Map<String, dynamic>> getAnalyticsSummary({
    required String fromDate,
    required String toDate,
    String? storeLocationId,
    int topLimit = 10,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$prefix/analytics/summary',
        queryParameters: {
          'fromDate': fromDate,
          'toDate': toDate,
          if (storeLocationId != null && storeLocationId.trim().isNotEmpty)
            'storeLocationId': storeLocationId.trim(),
          'topLimit': topLimit,
        },
      );
      final data = resp.data;
      if (data == null) return {};
      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// `POST /store/consumables/usage`
  Future<ConsumableUsageEvent> recordUsage(RecordConsumableUsageDto dto) async {
    try {
      final resp = await _dio.post(
        '$prefix/usage',
        data: dto.toJson(),
      );
      return ConsumableUsageEvent.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// `POST /store/consumables/usage/:usageEventId/return`
  Future<ConsumableUsageEvent> returnUsageEvent(String usageEventId) async {
    try {
      final resp = await _dio.post('$prefix/usage/$usageEventId/return');
      return ConsumableUsageEvent.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// `GET /store/consumables/usage/history`
  Future<ConsumableUsageHistoryResponse> getUsageHistory({
    String? consumableId,
    String? patientId,
    String? encounterId,
    String? admissionId,
    String? fromDate,
    String? toDate,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final resp = await _dio.get(
        '$prefix/usage/history',
        queryParameters: {
          if (consumableId != null && consumableId.trim().isNotEmpty)
            'consumableId': consumableId.trim(),
          if (patientId != null && patientId.trim().isNotEmpty)
            'patientId': patientId.trim(),
          if (encounterId != null && encounterId.trim().isNotEmpty)
            'encounterId': encounterId.trim(),
          if (admissionId != null && admissionId.trim().isNotEmpty)
            'admissionId': admissionId.trim(),
          if (fromDate != null) 'fromDate': fromDate,
          if (toDate != null) 'toDate': toDate,
          'skip': skip,
          'limit': limit,
        },
      );
      return ConsumableUsageHistoryResponse.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }
}
