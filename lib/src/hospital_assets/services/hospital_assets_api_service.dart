import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../services/api_service.dart';
import '../models/hospital_asset_models.dart';

class HospitalAssetsApiService {
  HospitalAssetsApiService() : _dio = ApiService().dio;

  final Dio _dio;

  Never _throw(DioException e, String fallback) {
    if (e.error is AppException) throw e.error as AppException;
    final message = e.response?.data is Map
        ? (e.response!.data['message']?.toString() ?? fallback)
        : (e.message ?? fallback);
    throw UnknownException(message);
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const UnknownException('Expected JSON object');
  }

  Future<HospitalAssetAccessMe> me() async {
    try {
      final response = await _dio.get<dynamic>('/hospital-assets/me');
      return HospitalAssetAccessMe.fromJson(_map(response.data));
    } on DioException catch (e) {
      _throw(e, 'Failed to load inventory access');
    }
  }

  Future<List<HospitalAsset>> list({
    String? accountType,
    String? kind,
    String? status,
    String? q,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/hospital-assets',
        queryParameters: {
          if (accountType != null) 'accountType': accountType,
          if (kind != null) 'kind': kind,
          if (status != null) 'status': status,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        },
      );
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => HospitalAsset.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      _throw(e, 'Failed to load assets');
    }
  }

  Future<HospitalAsset> getById(String id) async {
    try {
      final response = await _dio.get<dynamic>('/hospital-assets/$id');
      return HospitalAsset.fromJson(_map(response.data));
    } on DioException catch (e) {
      _throw(e, 'Failed to load asset');
    }
  }

  Future<HospitalAsset> create(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<dynamic>('/hospital-assets', data: body);
      return HospitalAsset.fromJson(_map(response.data));
    } on DioException catch (e) {
      _throw(e, 'Failed to register asset');
    }
  }

  Future<HospitalAsset> update(String id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch<dynamic>(
        '/hospital-assets/$id',
        data: body,
      );
      return HospitalAsset.fromJson(_map(response.data));
    } on DioException catch (e) {
      _throw(e, 'Failed to update asset');
    }
  }

  Future<void> addLog(String id, Map<String, dynamic> body) async {
    try {
      await _dio.post<dynamic>('/hospital-assets/$id/logs', data: body);
    } on DioException catch (e) {
      _throw(e, 'Failed to add log');
    }
  }

  Future<void> transfer(String id, Map<String, dynamic> body) async {
    try {
      await _dio.post<dynamic>('/hospital-assets/$id/transfer', data: body);
    } on DioException catch (e) {
      _throw(e, 'Failed to transfer asset');
    }
  }

  Future<List<HospitalAssetAccessGrant>> listAccess() async {
    try {
      final response = await _dio.get<dynamic>('/hospital-assets/access');
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map(
            (e) =>
                HospitalAssetAccessGrant.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      _throw(e, 'Failed to load access grants');
    }
  }

  Future<void> grantAccess({
    required String staffId,
    required bool canView,
    required bool canLog,
    String? accountType,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/hospital-assets/access',
        data: {
          'staffId': staffId,
          'canView': canView,
          'canLog': canLog,
          if (accountType != null) 'accountType': accountType,
        },
      );
    } on DioException catch (e) {
      _throw(e, 'Failed to grant access');
    }
  }

  Future<void> revokeAccess(String id) async {
    try {
      await _dio.delete<dynamic>('/hospital-assets/access/$id');
    } on DioException catch (e) {
      _throw(e, 'Failed to revoke access');
    }
  }
}
