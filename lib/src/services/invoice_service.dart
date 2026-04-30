import 'package:dio/dio.dart';
import 'package:helty/src/models/service_model.dart';
import '../models/invoice.dart';
import '../models/invoice_billing_models.dart';
import 'api_service.dart';

class InvoiceService {
  InvoiceService() : _dio = ApiService().dio;
  final Dio _dio;

  static const _kSplitInvoiceFallbackError = 'Unable to split invoice';

  List<dynamic> _extractList(dynamic data, {String? key}) {
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      final candidates = [
        if (key != null) data[key],
        data['data'],
        data['items'],
        data['invoices'],
        data['payments'],
        data['transactions'],
      ];
      for (final entry in candidates) {
        if (entry is List) return entry;
      }
    }
    return const [];
  }

  String _dioMessage(DioException e, String fallback) {
    final payload = e.response?.data;
    if (payload is Map) {
      final msg = payload['message'];
      if (msg != null) return msg.toString();
      final err = payload['error'];
      if (err != null) return err.toString();
    } else if (payload is String && payload.trim().isNotEmpty) {
      return payload;
    }
    return e.message ?? fallback;
  }

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
    bool allowIP = true,
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
          if (allowIP) 'allowIP': allowIP,
        },
      );

      final list = _extractList(response.data, key: 'invoices');
      return list
          .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Failed to load invoices: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  // ── Get single invoice by ID ──
  Future<Invoice> getInvoice(String id) async {
    try {
      final response = await _dio.get('/invoices/$id');
      return Invoice.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        'Failed to load invoice: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<List<Invoice>> getPatientInvoices(
    String patientId, [
    String? select,
  ]) async {
    try {
      final response = await _dio.get(
        '/invoices/patient/$patientId',
        queryParameters: select != null ? {'select': select} : null,
      );
      final list = _extractList(response.data, key: 'invoices');
      return list
          .whereType<Map>()
          .map((json) => Invoice.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Failed to load patient invoices: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<BillingInvoiceDetail> getBillingInvoice(String invoiceId) async {
    try {
      final response = await _dio.get('/invoices/$invoiceId');
      final payload = response.data as Map<String, dynamic>;
      return BillingInvoiceDetail.fromJson(payload);
    } on DioException catch (e) {
      throw Exception(
        'Failed to load invoice detail: ${_dioMessage(e, 'Unknown error')}',
      );
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
        'Failed to create invoice: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<BillingInvoiceDetail> createBillingInvoice({
    required String patientId,
    String? staffId,
    String? encounterId,
  }) async {
    try {
      final response = await _dio.post(
        '/invoices',
        data: {
          'patientId': patientId,
          if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
          if (encounterId != null && encounterId.isNotEmpty)
            'encounterId': encounterId,
        },
      );
      return BillingInvoiceDetail.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(
        'Failed to create billing invoice: ${_dioMessage(e, 'Unknown error')}',
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
      throw Exception('Failed to add item: ${_dioMessage(e, 'Unknown error')}');
    }
  }

  Future<BillingInvoiceDetail> addBillingItem({
    required String invoiceId,
    required AddInvoiceItemPayload payload,
  }) async {
    try {
      await _dio.post('/invoices/$invoiceId/items', data: payload.toJson());
      return getBillingInvoice(invoiceId);
    } on DioException catch (e) {
      throw Exception(
        'Failed to add invoice item: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<BillingInvoiceDetail> pauseRecurringItem({
    required String invoiceId,
    required String itemId,
  }) async {
    try {
      await _dio.post('/invoices/$invoiceId/items/$itemId/pause');
      return getBillingInvoice(invoiceId);
    } on DioException catch (e) {
      throw Exception(
        'Failed to pause recurring item: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<BillingInvoiceDetail> resumeRecurringItem({
    required String invoiceId,
    required String itemId,
  }) async {
    try {
      await _dio.post('/invoices/$invoiceId/items/$itemId/resume');
      return getBillingInvoice(invoiceId);
    } on DioException catch (e) {
      throw Exception(
        'Failed to resume recurring item: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<BillingInvoiceDetail> recordInvoicePayment({
    required String invoiceId,
    required RecordPaymentPayload payload,
  }) async {
    try {
      final response = await _dio.post(
        '/invoices/$invoiceId/payments',
        data: payload.toJson(),
      );
      if (response.data is Map<String, dynamic>) {
        return BillingInvoiceDetail.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      return getBillingInvoice(invoiceId);
    } on DioException catch (e) {
      throw Exception(
        'Failed to record payment: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  /// Allocates a billing payment to specific invoice lines (partial line pay).
  /// See `POST /invoices/:invoiceId/allocate-item-payments`.
  Future<BillingInvoiceDetail> allocateInvoiceItemPayments({
    required String invoiceId,
    required AllocateInvoiceItemPaymentsPayload payload,
  }) async {
    try {
      final response = await _dio.post(
        '/invoices/$invoiceId/allocate-item-payments',
        data: payload.toJson(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final inv = data['invoice'];
        if (inv is Map<String, dynamic>) {
          return BillingInvoiceDetail.fromJson(inv);
        }
        return BillingInvoiceDetail.fromJson(data);
      }
      return getBillingInvoice(invoiceId);
    } on DioException catch (e) {
      throw Exception(
        'Failed to allocate item payment: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<({Invoice original, Invoice splitOff})> splitInvoice({
    required String invoiceId,
    required List<String> invoiceItemIds,
  }) async {
    try {
      final response = await _dio.post(
        '/invoices/$invoiceId/split',
        data: {'invoiceItemIds': invoiceItemIds},
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception(_kSplitInvoiceFallbackError);
      }

      final originalRaw = data['original'];
      final splitOffRaw = data['splitOff'];
      if (originalRaw is! Map || splitOffRaw is! Map) {
        throw Exception(_kSplitInvoiceFallbackError);
      }

      return (
        original: Invoice.fromJson(Map<String, dynamic>.from(originalRaw)),
        splitOff: Invoice.fromJson(Map<String, dynamic>.from(splitOffRaw)),
      );
    } on DioException catch (e) {
      final msg = _dioMessage(e, _kSplitInvoiceFallbackError);
      throw Exception(msg.isEmpty ? _kSplitInvoiceFallbackError : msg);
    } catch (_) {
      throw Exception(_kSplitInvoiceFallbackError);
    }
  }

  Future<List<BillingInvoicePayment>> getInvoicePayments(
    String invoiceId,
  ) async {
    try {
      final response = await _dio.get('/invoices/$invoiceId/payments');
      final list = _extractList(response.data, key: 'payments');
      return list
          .whereType<Map>()
          .map(
            (e) => BillingInvoicePayment.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Failed to load payments: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<BillingWallet> getWallet(String patientId) async {
    try {
      final response = await _dio.get('/invoices/wallets/$patientId');
      return BillingWallet.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        'Failed to load wallet: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<BillingWallet> depositToWallet({
    required String patientId,
    required WalletDepositPayload payload,
  }) async {
    try {
      final response = await _dio.post(
        '/invoices/wallets/$patientId/deposits',
        data: payload.toJson(),
      );
      return BillingWallet.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        'Failed to deposit to wallet: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<List<BillingWalletTransaction>> getWalletTransactions(
    String patientId,
  ) async {
    try {
      final response = await _dio.get(
        '/invoices/wallets/$patientId/transactions',
      );
      final list = _extractList(response.data, key: 'transactions');
      return list
          .whereType<Map>()
          .map(
            (e) =>
                BillingWalletTransaction.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Failed to load wallet transactions: ${_dioMessage(e, 'Unknown error')}',
      );
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
      throw Exception(
        'Failed to update status: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  // ── Delete invoice ── (soft or hard – depending on backend)
  Future<void> deleteInvoice(String id) async {
    try {
      await _dio.delete('/invoices/$id');
    } on DioException catch (e) {
      throw Exception(
        'Failed to delete invoice: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  // ── Delete single item ──
  Future<void> deleteItem(String invoiceId, String itemId) async {
    try {
      await _dio.delete('/invoices/$invoiceId/items/$itemId');
    } on DioException catch (e) {
      throw Exception(
        'Failed to delete item: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }
}
