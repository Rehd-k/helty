import 'package:dio/dio.dart';
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
  }) async {
    try {
      final response = await _dio.get(
        '/receivables/hmo',
        queryParameters: {
          if (skip != null) 'skip': skip,
          if (take != null) 'take': take,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (status != null && status.trim().isNotEmpty) 'status': status,
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
  }) async {
    try {
      final response = await _dio.get(
        '/receivables/discount',
        queryParameters: {
          if (skip != null) 'skip': skip,
          if (take != null) 'take': take,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (status != null && status.trim().isNotEmpty) 'status': status,
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
      final response = await _dio.get('/receivables/discount/owner/$staffId/statement');
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
}
