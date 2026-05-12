import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../pharmacy/models/pharmacy_model.dart';
import '../store/models/consumable_models.dart';
import 'api_service.dart';

/// `GET /invoice-consumables` and related helpers (billable consumable invoices).
class InvoiceConsumablesApiService {
  InvoiceConsumablesApiService({Dio? dio})
      : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  static const String _prefix = '/invoice-consumables';

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
          : 'Invoice consumables request failed.',
    );
  }

  int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value == null) return fallback;
    return int.tryParse(value.toString()) ?? fallback;
  }

  PaginatedResponse<InvoiceWithConsumableLines> _parseList(Response<dynamic> resp) {
    dynamic data = resp.data;
    if (data == null) {
      return PaginatedResponse<InvoiceWithConsumableLines>(
        items: [],
        total: 0,
        page: 1,
        pageSize: 20,
      );
    }
    if (data is List) {
      final items = data
          .map(
            (e) => InvoiceWithConsumableLines.fromJson(
              e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      return PaginatedResponse<InvoiceWithConsumableLines>(
        items: items,
        total: items.length,
        page: 1,
        pageSize: items.isNotEmpty ? items.length : 20,
      );
    }
    if (data is! Map) {
      return PaginatedResponse<InvoiceWithConsumableLines>(
        items: [],
        total: 0,
        page: 1,
        pageSize: 20,
      );
    }
    var map = Map<String, dynamic>.from(data);
    final inner = map['data'];
    if (inner is Map && inner is! List) {
      final innerMap = Map<String, dynamic>.from(inner);
      if (innerMap.containsKey('data') || innerMap.containsKey('items')) {
        map = innerMap;
      }
    }
    final list = map['data'] ?? map['items'] ?? map['results'];
    final rawList = list is List ? list : <dynamic>[];
    final items = rawList
        .map(
          (e) => InvoiceWithConsumableLines.fromJson(
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
    return PaginatedResponse<InvoiceWithConsumableLines>(
      items: items,
      total: total,
      page: page,
      pageSize: pageSize > 0 ? pageSize : 20,
    );
  }

  /// List invoices that have at least one consumable line.
  Future<PaginatedResponse<InvoiceWithConsumableLines>> listInvoices({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    try {
      final resp = await _dio.get(
        _prefix,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
        },
      );
      return _parseList(resp);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// Partial or full return of a consumable invoice line (unpaid lines only).
  Future<Map<String, dynamic>> returnInvoiceItem({
    required String invoiceId,
    required String itemId,
    required int quantity,
    String? reason,
  }) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_prefix/$invoiceId/items/$itemId/return',
        data: {
          'quantity': quantity,
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
      );
      final data = resp.data;
      if (data == null) return {};
      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }
}
