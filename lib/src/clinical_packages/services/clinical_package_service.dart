import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../services/api_service.dart';
import '../models/clinical_package_models.dart';

class ClinicalPackageService {
  ClinicalPackageService() : _dio = ApiService().dio;
  final Dio _dio;

  static const String _base = '/clinical-packages';

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['packages', 'data', 'items']) {
        final list = data[key];
        if (list is List) return list;
      }
    }
    return const [];
  }

  Never _handleError(DioException e, String fallback) {
    if (e.error is AppException) throw e.error as AppException;
    final message = e.response?.data is Map
        ? (e.response!.data['message'] ?? e.message)?.toString()
        : e.message;
    throw UnknownException(
      message?.toString().isNotEmpty == true ? message! : fallback,
    );
  }

  Future<List<ClinicalPackage>> list() async {
    try {
      final resp = await _dio.get<dynamic>(_base);
      return _extractList(resp.data)
          .whereType<Map>()
          .map((e) => ClinicalPackage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      _handleError(e, 'Failed to load clinical packages.');
    }
  }

  Future<ClinicalPackage> get(String id) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>('$_base/$id');
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return ClinicalPackage.fromJson(data);
    } on DioException catch (e) {
      _handleError(e, 'Failed to load clinical package.');
    }
  }

  Future<ClinicalPackage> create(ClinicalPackagePayload payload) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        _base,
        data: payload.toJson(),
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return ClinicalPackage.fromJson(data);
    } on DioException catch (e) {
      _handleError(e, 'Failed to create clinical package.');
    }
  }

  Future<ClinicalPackage> patch(String id, ClinicalPackagePayload payload) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/$id',
        data: payload.toJson(),
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return ClinicalPackage.fromJson(data);
    } on DioException catch (e) {
      _handleError(e, 'Failed to update clinical package.');
    }
  }

  Future<DefaultAntenatalPackage?> getDefaultAntenatal() async {
    try {
      final resp = await _dio.get<dynamic>('$_base/default-antenatal');
      final data = resp.data;
      if (data == null) return null;
      if (data is Map && data.isEmpty) return null;
      if (data is Map<String, dynamic>) {
        return DefaultAntenatalPackage.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _handleError(e, 'Failed to load default antenatal package.');
    }
  }
}
