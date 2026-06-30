import 'package:dio/dio.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/models/receivables_models.dart';
import 'package:helty/src/services/api_service.dart';

class ReceivablesService {
  ReceivablesService() : _dio = ApiService().dio;
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
      final candidates = <dynamic>[
        if (key != null) data[key],
        data['data'],
        data['receivables'],
        data['items'],
      ];
      for (final entry in candidates) {
        if (entry is List) return entry;
      }
    }
    return const [];
  }

  Future<List<ReceivableItem>> getHmoReceivables({
    int? skip,
    int? take,
    String? search,
    String? status,
    String? hmoId,
    String? hmoName,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _dio.get(
        '/receivables/hmo',
        queryParameters: {
          if (skip != null) 'skip': skip,
          if (take != null) 'take': take,
          if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (hmoId != null && hmoId.trim().isNotEmpty) 'hmoId': hmoId.trim(),
          if (hmoName != null && hmoName.trim().isNotEmpty)
            'hmoName': hmoName.trim(),
          if (from != null) 'fromDate': AppTimezone.toBackendIso(from),
          if (to != null) 'toDate': AppTimezone.toBackendIso(to),
        },
      );
      final list = _extractList(response.data);
      return list
          .whereType<Map>()
          .map((e) => ReceivableItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Failed to load HMO receivables: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<List<ReceivableItem>> getDiscountReceivables({
    int? skip,
    int? take,
    String? search,
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _dio.get(
        '/receivables/discount',
        queryParameters: {
          if (skip != null) 'skip': skip,
          if (take != null) 'take': take,
          if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (from != null) 'fromDate': AppTimezone.toBackendIso(from),
          if (to != null) 'toDate': AppTimezone.toBackendIso(to),
        },
      );
      final list = _extractList(response.data);
      return list
          .whereType<Map>()
          .map((e) => ReceivableItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Failed to load discount receivables: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<Map<String, dynamic>> getHmoStatement(String hmoId) async {
    try {
      final response = await _dio.get('/receivables/hmo/$hmoId/statement');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(
        'Failed to load HMO statement: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<Map<String, dynamic>> getOwnerStatement(String staffId) async {
    try {
      final response = await _dio.get(
        '/receivables/discount/owner/$staffId/statement',
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(
        'Failed to load owner statement: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<Map<String, dynamic>> recordRemittance(
    RecordRemittancePayload payload,
  ) async {
    try {
      final response = await _dio.post(
        '/receivables/remittances',
        data: payload.toJson(),
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(
        'Failed to record remittance: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Expected JSON object');
  }

  Future<HmoCoverageAnalytics> getHmoCoverageAnalytics({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final response = await _dio.get(
        '/receivables/analytics/hmo-coverage',
        queryParameters: {
          'fromDate': AppTimezone.toBackendIso(fromDate),
          'toDate': AppTimezone.toBackendIso(toDate),
        },
      );
      return HmoCoverageAnalytics.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        'Failed to load HMO coverage analytics: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<DiscountCoverageAnalytics> getDiscountCoverageAnalytics({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final response = await _dio.get(
        '/receivables/analytics/discount-coverage',
        queryParameters: {
          'fromDate': AppTimezone.toBackendIso(fromDate),
          'toDate': AppTimezone.toBackendIso(toDate),
        },
      );
      return DiscountCoverageAnalytics.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        'Failed to load discount coverage analytics: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<RemittanceCollectionsAnalytics> getRemittanceCollectionsAnalytics({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final response = await _dio.get(
        '/receivables/analytics/remittance-collections',
        queryParameters: {
          'fromDate': AppTimezone.toBackendIso(fromDate),
          'toDate': AppTimezone.toBackendIso(toDate),
        },
      );
      return RemittanceCollectionsAnalytics.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        'Failed to load remittance collection analytics: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }
}
