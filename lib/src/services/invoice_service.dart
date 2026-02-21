import 'package:dio/dio.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import 'api_service.dart';

class InvoiceService {
  InvoiceService() : _dio = ApiService().dio;
  final Dio _dio;

  // ── Get all invoices (with optional filters) ──
  Future<List<Invoice>> getInvoices({
    String? patientId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/invoices',
        queryParameters: {
          if (patientId != null) 'patientId': patientId,
          if (status != null) 'status': status,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data as List<dynamic>;
      return data.map((json) => Invoice.fromJson(json)).toList();
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

  // ── Create new invoice (with items) ──
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
  Future<InvoiceItem> addItemToInvoice({
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

      return InvoiceItem.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to add item: ${e.message}');
    }
  }

  // ── Update invoice status (e.g. mark as paid) ──
  Future<Invoice> updateInvoiceStatus({
    required String id,
    required String status,
  }) async {
    try {
      final response = await _dio.patch(
        '/invoices/$id',
        data: {'status': status},
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
