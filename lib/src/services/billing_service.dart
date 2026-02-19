import 'package:dio/dio.dart';

import 'api_service.dart';

/// Billing status enum values (adjust to match your Prisma schema).
enum BillStatus { pending, partial, paid, cancelled, refunded }

class Bill {
  const Bill({
    required this.id,
    required this.patientId,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    required this.createdAt,
    this.notes,
    this.items = const [],
  });

  final String id;
  final String patientId;
  final double totalAmount;
  final double paidAmount;
  final BillStatus status;
  final DateTime createdAt;
  final String? notes;
  final List<Map<String, dynamic>> items;

  double get balance => totalAmount - paidAmount;

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: json['id'] as String,
    patientId: json['patientId'] as String,
    totalAmount: (json['totalAmount'] as num).toDouble(),
    paidAmount: (json['paidAmount'] as num? ?? 0).toDouble(),
    status: BillStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == (json['status'] as String).toLowerCase(),
      orElse: () => BillStatus.pending,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    notes: json['notes'] as String?,
    items: (json['items'] as List?)?.cast<Map<String, dynamic>>() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'patientId': patientId,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'status': status.name.toUpperCase(),
    if (notes != null) 'notes': notes,
    'items': items,
  };
}

class BillingService {
  BillingService() : _dio = ApiService().dio;
  final Dio _dio;

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<List<Bill>> fetchBills({
    String? patientId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final resp = await _dio.get(
      '/billing',
      queryParameters: {
        if (patientId != null) 'patientId': patientId,
        if (status != null) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    final data = resp.data is List
        ? resp.data as List
        : (resp.data['data'] as List);
    return data.map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Bill> getBillById(String id) async {
    final resp = await _dio.get('/billing/$id');
    return Bill.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<Bill>> getBillsForPatient(String patientId) async {
    final resp = await _dio.get('/billing/patient/$patientId');
    final data = resp.data is List
        ? resp.data as List
        : (resp.data['data'] as List);
    return data.map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<Bill> createBill(Bill bill) async {
    final resp = await _dio.post('/billing', data: bill.toJson());
    return Bill.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Bill> updateBill(String id, Map<String, dynamic> data) async {
    final resp = await _dio.patch('/billing/$id', data: data);
    return Bill.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Bill> recordPayment({
    required String billId,
    required double amount,
    String? method,
    String? reference,
  }) async {
    final resp = await _dio.post(
      '/billing/$billId/payments',
      data: {
        'amount': amount,
        if (method != null) 'method': method,
        if (reference != null) 'reference': reference,
      },
    );
    return Bill.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> cancelBill(String id) async {
    await _dio.patch('/billing/$id', data: {'status': 'CANCELLED'});
  }

  Future<Map<String, dynamic>> getRevenueSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final resp = await _dio.get(
      '/billing/summary',
      queryParameters: {
        if (startDate != null)
          'startDate': startDate.toIso8601String().split('T').first,
        if (endDate != null)
          'endDate': endDate.toIso8601String().split('T').first,
      },
    );
    return resp.data as Map<String, dynamic>;
  }
}
