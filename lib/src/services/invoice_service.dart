import 'package:dio/dio.dart';
import 'package:helty/src/models/service_model.dart';
import '../models/invoice.dart';
import 'api_service.dart';

class InvoiceService {
  InvoiceService() : _dio = ApiService().dio;
  final Dio _dio;

  // ── Get all invoices (with optional filters) ──
  Future<List<Invoice>> getInvoices({
    String? patientId,
    String? status,
    String? query,
    String? category,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        '/invoices',
        queryParameters: {
          if (patientId != null) 'patientId': patientId,
          if (status != null) 'status': status,
          if (query != null && query.isNotEmpty) 'query': query,
          if (category != null && category.isNotEmpty) 'category': category,
          // Use full ISO-8601 strings (UTC) for NestJS-friendly date parsing
          if (from != null) 'fromDate': from.toUtc().toIso8601String(),
          if (to != null) 'toDate': to.toUtc().toIso8601String(),
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data;
      List<dynamic> list;

      if (data is List<dynamic>) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        // Support both { data: [...] } and { invoices: [...] } shapes
        final fromData = data['data'];
        final fromInvoices = data['invoices'];
        if (fromData is List) {
          list = fromData;
        } else if (fromInvoices is List) {
          list = fromInvoices;
        } else {
          list = const [];
        }
      } else {
        list = const [];
      }
      return list
          .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load invoices: ${e.message}');
    }
  }

  // ── Get single invoice by ID ──
  Future<Invoice> getInvoice(String id) async {
    try {
      final response = await _dio.get('/invoices/$id');
      return Invoice.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load invoice: ${e.message}');
    }
  }

  Future<Invoice> createInvoice({
    required String patientId,
    required String status,
    required List<Map<String, dynamic>>
    items, // [{serviceId, quantity, priceAtTime?}]
    String? staffId,
  }) async {
    try {
      final response = await _dio.post(
        '/invoices',
        data: {
          'patientId': patientId,
          'status': status,
          'staffId': staffId,
          'items': items, // backend should create InvoiceItems
        },
      );

      return Invoice.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Failed to create invoice: ${e.response?.data ?? e.message}',
      );
    }
  }

  // ── Add item to existing invoice ──
  Future<ServiceModel> addItemToInvoice({
    required String invoiceId,
    required String serviceId,
    required int quantity,
    required double priceAtTime,
  }) async {
    try {
      final response = await _dio.post(
        '/invoices/$invoiceId/items',
        data: {
          'serviceId': serviceId,
          'quantity': quantity,
          'priceAtTime': priceAtTime,
        },
      );

      return ServiceModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to add item: ${e.message}');
    }
  }

  // ── Update invoice status (e.g. mark as paid) ──
  Future<Invoice> updateInvoiceStatus({
    required String id,
    required String status,
    String? transactionId,
  }) async {
    try {
      final response = await _dio.patch(
        '/invoices/$id',
        data: {
          'status': status,
          if (transactionId != null) 'transactionId': transactionId,
        },
      );
      return Invoice.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update status: ${e.message}');
    }
  }

  // ── Delete invoice ── (soft or hard – depending on backend)
  Future<void> deleteInvoice(String id) async {
    try {
      await _dio.delete('/invoices/$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete invoice: ${e.message}');
    }
  }

  // ── Delete single item ──
  Future<void> deleteItem(String invoiceId, String itemId) async {
    try {
      await _dio.delete('/invoices/$invoiceId/items/$itemId');
    } on DioException catch (e) {
      throw Exception('Failed to delete item: ${e.message}');
    }
  }
}
