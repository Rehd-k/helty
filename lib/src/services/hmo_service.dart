import 'package:dio/dio.dart';

import '../models/hmo_models.dart';
import 'api_service.dart';

String _dioMessage(DioException e, String fallback) {
  final data = e.response?.data;
  if (data is Map && data['message'] != null) {
    return data['message'].toString();
  }
  return e.message ?? fallback;
}

/// `/hmos` API (docs/hmo-client.md).
class HmoService {
  HmoService() : _dio = ApiService().dio;
  final Dio _dio;

  Future<HmoPagedResult> list({
    String search = '',
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final resp = await _dio.get(
        '/hmos',
        queryParameters: {
          'skip': skip,
          'take': take,
          if (search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      final data = resp.data;
      List<dynamic> rawList = const [];
      int total = 0;
      int rSkip = skip;
      int rTake = take;

      if (data is List) {
        rawList = data;
        total = rawList.length;
      } else if (data is Map<String, dynamic>) {
        rawList =
            data['hmos'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            data['items'] as List<dynamic>? ??
            const [];
        total = (data['total'] as num?)?.toInt() ?? rawList.length;
        rSkip = (data['skip'] as num?)?.toInt() ?? skip;
        rTake = (data['take'] as num?)?.toInt() ?? take;
      }

      final items = rawList
          .whereType<Map>()
          .map((e) => HmoListItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      return HmoPagedResult(
        items: items,
        total: total,
        skip: rSkip,
        take: rTake,
      );
    } on DioException catch (e) {
      throw Exception('Failed to list HMOs: ${_dioMessage(e, 'Unknown error')}');
    }
  }

  Future<HmoDetail> getById(String id) async {
    try {
      final resp = await _dio.get('/hmos/$id');
      final data = resp.data;
      final map = data is Map<String, dynamic>
          ? data
          : (data is Map ? Map<String, dynamic>.from(data) : null);
      if (map == null) {
        throw StateError('Invalid HMO response');
      }
      return HmoDetail.fromJson(map);
    } on DioException catch (e) {
      throw Exception('Failed to load HMO: ${_dioMessage(e, 'Unknown error')}');
    }
  }

  Future<HmoDetail> create(HmoDetail detail, {List<HmoServicePriceRow>? servicePrices}) async {
    try {
      final resp = await _dio.post(
        '/hmos',
        data: detail.toCreateJson(servicePrices: servicePrices ?? detail.servicePrices),
      );
      final data = resp.data as Map<String, dynamic>;
      return HmoDetail.fromJson(data);
    } on DioException catch (e) {
      throw Exception('Failed to create HMO: ${_dioMessage(e, 'Unknown error')}');
    }
  }

  Future<HmoDetail> update(
    String id, {
    String? name,
    String? code,
    String? notes,
    double? defaultCoveragePercent,
    List<HmoServicePriceRow>? servicePrices,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (code != null) body['code'] = code;
      if (notes != null) body['notes'] = notes;
      if (defaultCoveragePercent != null) {
        body['defaultCoveragePercent'] = defaultCoveragePercent;
      }
      if (servicePrices != null) body['servicePrices'] = servicePrices.map((e) => e.toCreatePatchJson()).toList();

      final resp = await _dio.patch('/hmos/$id', data: body);
      return HmoDetail.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to update HMO: ${_dioMessage(e, 'Unknown error')}');
    }
  }

  /// Replace all service prices (send full list from client).
  Future<HmoDetail> replaceServicePrices(
    String id,
    List<HmoServicePriceRow> servicePrices,
  ) async {
    return update(id, servicePrices: servicePrices);
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/hmos/$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete HMO: ${_dioMessage(e, 'Unknown error')}');
    }
  }

  Future<HmoPatientsPagedResult> listPatients(
    String hmoId, {
    String search = '',
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final resp = await _dio.get(
        '/hmos/$hmoId/patients',
        queryParameters: {
          'skip': skip,
          'take': take,
          if (search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      final data = resp.data;
      List<dynamic> rawList = const [];
      int total = 0;
      int rSkip = skip;
      int rTake = take;

      if (data is List) {
        rawList = data;
        total = rawList.length;
      } else if (data is Map<String, dynamic>) {
        rawList =
            data['patients'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            const [];
        total = (data['total'] as num?)?.toInt() ?? rawList.length;
        rSkip = (data['skip'] as num?)?.toInt() ?? skip;
        rTake = (data['take'] as num?)?.toInt() ?? take;
      }

      final patients = rawList
          .whereType<Map>()
          .map((e) => HmoPatientRow.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      return HmoPatientsPagedResult(
        patients: patients,
        total: total,
        skip: rSkip,
        take: rTake,
      );
    } on DioException catch (e) {
      throw Exception(
        'Failed to list HMO patients: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }
}
