import 'package:dio/dio.dart';

import 'api_service.dart';
import '../models/ward_models.dart';

class WardService {
  WardService() : _dio = ApiService().dio;

  final Dio _dio;

  // ── Wards ──────────────────────────────────────────────────────────────────

  Future<List<Ward>> fetchWards({String? departmentId, String? query}) async {
    final resp = await _dio.get(
      '/wards',
      queryParameters: {
        if (departmentId != null && departmentId.isNotEmpty)
          'departmentId': departmentId,
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );

    final data = resp.data;
    final list = data is List ? data : (data['wards'] as List);
    return list
        .whereType<Map<String, dynamic>>()
        .map(Ward.fromJson)
        .toList();
  }

  Future<Ward> getWardById(String id) async {
    final resp = await _dio.get('/wards/$id');
    return Ward.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Ward> createWard(Ward ward) async {
    final resp = await _dio.post('/wards', data: ward.toJson());
    return Ward.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Ward> updateWard(Ward ward) async {
    final resp = await _dio.patch('/wards/${ward.id}', data: ward.toJson());
    return Ward.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteWard(String id) async {
    await _dio.delete('/wards/$id');
  }

  // ── Beds ───────────────────────────────────────────────────────────────────

  Future<List<Bed>> fetchBedsForWard(String wardId) async {
    final resp = await _dio.get('/wards/$wardId/beds');
    final data = resp.data;
    final list = data is List ? data : (data['beds'] as List? ?? const []);
    return list
        .whereType<Map<String, dynamic>>()
        .map(Bed.fromJson)
        .toList();
  }

  Future<Bed> createBed({
    required String wardId,
    required Bed bed,
  }) async {
    final resp = await _dio.post(
      '/wards/$wardId/beds',
      data: bed.toJson(),
    );
    return Bed.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Bed> updateBed({
    required Bed bed,
  }) async {
    final resp = await _dio.patch(
      '/beds/${bed.id}',
      data: bed.toJson(),
    );
    return Bed.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteBed(String id) async {
    await _dio.delete('/beds/$id');
  }
}

