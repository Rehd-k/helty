import 'package:dio/dio.dart';
import 'package:helty/src/models/discount_policy_models.dart';
import 'package:helty/src/services/api_service.dart';

class DiscountPolicyService {
  DiscountPolicyService() : _dio = ApiService().dio;
  final Dio _dio;

  String _dioMessage(DioException e, String fallback) {
    final payload = e.response?.data;
    if (payload is Map) {
      final msg = payload['message'];
      if (msg != null) return msg.toString();
    }
    return e.message ?? fallback;
  }

  List<dynamic> _extractList(dynamic data, {String? key}) {
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      final candidates = [if (key != null) data[key], data['data'], data['items']];
      for (final entry in candidates) {
        if (entry is List) return entry;
      }
    }
    return const [];
  }

  Future<List<DiscountPolicy>> list({bool? active}) async {
    try {
      final response = await _dio.get(
        '/discount-policies',
        queryParameters: active == null ? null : {'active': active},
      );
      final list = _extractList(response.data, key: 'discountPolicies');
      return list
          .whereType<Map>()
          .map((e) => DiscountPolicy.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Failed to load discount policies: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<DiscountPolicy> create(DiscountPolicyPayload payload) async {
    try {
      final data = payload.toJson();
      data['mode'] = _normalizeMode(data['mode']?.toString());
      final response = await _dio.post('/discount-policies', data: data);
      return DiscountPolicy.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(
        'Failed to create discount policy: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<DiscountPolicy> update(String id, DiscountPolicyPayload payload) async {
    try {
      final data = payload.toJson();
      data['mode'] = _normalizeMode(data['mode']?.toString());
      final response = await _dio.patch(
        '/discount-policies/$id',
        data: data,
      );
      return DiscountPolicy.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(
        'Failed to update discount policy: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/discount-policies/$id');
    } on DioException catch (e) {
      throw Exception(
        'Failed to delete discount policy: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  String _normalizeMode(String? raw) {
    final mode = raw?.trim().toUpperCase();
    if (mode == 'FLAT') return 'FIXED';
    if (mode == 'PERCENT' || mode == 'FIXED') return mode!;
    return mode ?? 'PERCENT';
  }
}
