import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import '../models/pharmacy_reports_model.dart';

/// Sales breakdown grouping dimension.
enum PharmacySalesGroupBy { drug, therapeuticClass, payer, dispensary }

extension PharmacySalesGroupByX on PharmacySalesGroupBy {
  String get apiValue {
    switch (this) {
      case PharmacySalesGroupBy.drug:
        return 'drug';
      case PharmacySalesGroupBy.therapeuticClass:
        return 'therapeuticClass';
      case PharmacySalesGroupBy.payer:
        return 'payer';
      case PharmacySalesGroupBy.dispensary:
        return 'dispensary';
    }
  }

  String get label {
    switch (this) {
      case PharmacySalesGroupBy.drug:
        return 'Drug';
      case PharmacySalesGroupBy.therapeuticClass:
        return 'Therapeutic class';
      case PharmacySalesGroupBy.payer:
        return 'Payer';
      case PharmacySalesGroupBy.dispensary:
        return 'Dispensary';
    }
  }
}

class PharmacySalesBreakdownQuery {
  const PharmacySalesBreakdownQuery({
    required this.fromDate,
    required this.toDate,
    required this.groupBy,
    this.storeId,
    this.payerType,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final PharmacySalesGroupBy groupBy;
  final String? storeId;
  final String? payerType;

  Map<String, dynamic> toQuery() {
    return {
      'fromDate': fromDate.toUtc().toIso8601String(),
      'toDate': toDate.toUtc().toIso8601String(),
      'groupBy': groupBy.apiValue,
      if (storeId != null && storeId!.trim().isNotEmpty) 'storeId': storeId,
      if (payerType != null &&
          payerType!.trim().isNotEmpty &&
          payerType!.toLowerCase() != 'all')
        'payerType': payerType,
    };
  }
}

class PharmacySalesDetailQuery {
  const PharmacySalesDetailQuery({
    required this.fromDate,
    required this.toDate,
    required this.groupBy,
    this.groupKey,
    this.storeId,
    this.payerType,
    this.search,
    this.skip = 0,
    this.take = 50,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final PharmacySalesGroupBy groupBy;
  final String? groupKey;
  final String? storeId;
  final String? payerType;
  final String? search;
  final int skip;
  final int take;

  Map<String, dynamic> toQuery() {
    return {
      'fromDate': fromDate.toUtc().toIso8601String(),
      'toDate': toDate.toUtc().toIso8601String(),
      'groupBy': groupBy.apiValue,
      if (groupKey != null && groupKey!.trim().isNotEmpty) 'groupKey': groupKey,
      if (storeId != null && storeId!.trim().isNotEmpty) 'storeId': storeId,
      if (payerType != null &&
          payerType!.trim().isNotEmpty &&
          payerType!.toLowerCase() != 'all')
        'payerType': payerType,
      if (search != null && search!.trim().isNotEmpty) 'q': search!.trim(),
      'skip': skip,
      'take': take,
    };
  }
}

class PharmacyValuationQuery {
  const PharmacyValuationQuery({
    this.storeId,
    this.locationId,
    this.expiryWithinDays,
    this.search,
    this.skip = 0,
    this.take = 50,
  });

  final String? storeId;
  final String? locationId;
  final int? expiryWithinDays;
  final String? search;
  final int skip;
  final int take;

  Map<String, dynamic> toQuery({bool paginated = false}) {
    return {
      if (storeId != null && storeId!.trim().isNotEmpty) 'storeId': storeId,
      if (locationId != null && locationId!.trim().isNotEmpty)
        'locationId': locationId,
      if (expiryWithinDays != null) 'expiryWithinDays': expiryWithinDays,
      if (search != null && search!.trim().isNotEmpty) 'q': search!.trim(),
      if (paginated) 'skip': skip,
      if (paginated) 'take': take,
    };
  }
}

class PharmacyReportsService {
  PharmacyReportsService() : _dio = ApiService().dio;

  final Dio _dio;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      final map = _asMap(data);
      final nested =
          map['rows'] ?? map['data'] ?? map['items'] ?? map['results'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const <Map<String, dynamic>>[];
  }

  int _asTotal(dynamic data, int fallback) {
    if (data is Map) {
      final t = data['total'] ?? data['count'];
      if (t is num) return t.toInt();
      final parsed = int.tryParse('${t ?? ''}');
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  String _dioMessage(DioException e, String fallback) {
    final payload = e.response?.data;
    if (payload is Map && payload['message'] != null) {
      return payload['message'].toString();
    }
    return e.message ?? fallback;
  }

  Future<PharmacySalesBreakdown> getSalesBreakdown(
    PharmacySalesBreakdownQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/pharmacy/reports/sales-breakdown',
        queryParameters: query.toQuery(),
      );
      final map = _asMap(response.data);
      final totals = map['totals'] is Map
          ? PharmacySalesBreakdownTotals.fromJson(_asMap(map['totals']))
          : PharmacySalesBreakdownTotals.empty;
      final rows = _asList(response.data)
          .map(PharmacySalesBreakdownRow.fromJson)
          .toList();
      return PharmacySalesBreakdown(totals: totals, rows: rows);
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Unable to load sales breakdown.'));
    }
  }

  Future<PharmacySalesDetailPage> getSalesBreakdownDetails(
    PharmacySalesDetailQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/pharmacy/reports/sales-breakdown/details',
        queryParameters: query.toQuery(),
      );
      final rows = _asList(response.data)
          .map(PharmacySalesDetailRow.fromJson)
          .toList();
      return PharmacySalesDetailPage(
        total: _asTotal(response.data, rows.length),
        rows: rows,
      );
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Unable to load sales details.'));
    }
  }

  Future<PharmacyInventoryValuation> getInventoryValuation(
    PharmacyValuationQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/pharmacy/reports/inventory-valuation',
        queryParameters: query.toQuery(),
      );
      final map = _asMap(response.data);
      final totals = map['totals'] is Map
          ? PharmacyInventoryValuationTotals.fromJson(_asMap(map['totals']))
          : PharmacyInventoryValuationTotals.empty;
      final storesRaw = map['stores'] is List
          ? _asList(map['stores'])
          : _asList(response.data);
      final stores = storesRaw
          .map(PharmacyInventoryStoreValuation.fromJson)
          .toList();
      return PharmacyInventoryValuation(totals: totals, stores: stores);
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Unable to load inventory valuation.'));
    }
  }

  Future<PharmacyInventoryBatchPage> getInventoryValuationBatches(
    PharmacyValuationQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/pharmacy/reports/inventory-valuation/batches',
        queryParameters: query.toQuery(paginated: true),
      );
      final rows = _asList(response.data)
          .map(PharmacyInventoryBatchRow.fromJson)
          .toList();
      return PharmacyInventoryBatchPage(
        total: _asTotal(response.data, rows.length),
        rows: rows,
      );
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Unable to load inventory batches.'));
    }
  }
}
