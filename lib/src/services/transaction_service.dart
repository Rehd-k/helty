import 'package:dio/dio.dart';

import 'api_service.dart';
import '../transaction/transaction_models.dart';

/// DTO for creating a regular (draft→active) transaction.
class CreateTransactionDto {
  const CreateTransactionDto({
    required this.patientId,
    required this.staffId,
    required this.items,
    this.notes,
    this.admissionId,
  });

  final String patientId;
  final String staffId;
  final List<CreateTransactionItemDto> items;
  final String? notes;
  final String? admissionId;

  Map<String, dynamic> toJson() => {
    'patientId': patientId,
    'staffId': staffId,
    'items': items.map((i) => i.toJson()).toList(),
    if (notes != null) 'notes': notes,
    if (admissionId != null) 'admissionId': admissionId,
  };
}

/// DTO for a single line-item in a transaction.
class CreateTransactionItemDto {
  const CreateTransactionItemDto({
    required this.serviceId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.source = 'OTHER',
  });

  final String serviceId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String source;

  Map<String, dynamic> toJson() => {
    'serviceId': serviceId,
    'name': name,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'source': source,
    'totalPrice': unitPrice * quantity,
  };
}

/// DTO for creating a quick / instantly-paid transaction (POST /transaction/quick).
class QuickTransactionDto {
  const QuickTransactionDto({
    required this.patientId,
    required this.staffId,
    required this.items,
    required this.paymentMethod,
    required this.amountPaid,
    this.discount = 0,
    this.notes,
    this.mixedBreakdown,
    this.reference,
    this.bankName,
  });

  final String patientId;
  final String staffId;
  final List<CreateTransactionItemDto> items;
  final String paymentMethod;
  final double amountPaid;
  final double discount;
  final String? notes;
  final Map<String, double>? mixedBreakdown;
  final String? reference;
  final String? bankName;

  Map<String, dynamic> toJson() => {
    'patientId': patientId,
    'staffId': staffId,
    'items': items.map((i) => i.toJson()).toList(),
    'paymentMethod': paymentMethod,
    'discount': discount,
    'amountPaid': amountPaid,
    if (notes != null) 'notes': notes,
    if (mixedBreakdown != null) 'mixedBreakdown': mixedBreakdown,
    if (reference != null) 'reference': reference,
    if (bankName != null) 'bankName': bankName,
  };
}

/// Filters for fetching transaction lists (mirrors backend query params).
class TransactionQuery {
  const TransactionQuery({
    this.search,
    this.transactionId,
    this.patientId,
    this.patientName,
    this.phoneNumber,
    this.createdById,
    this.status,
    this.fromDate,
    this.toDate,
    this.skip = 0,
    this.take = 10,
    this.sortBy,
    this.sortOrder = 'desc',
  });

  final String? search; // generic full-text search
  final String? transactionId;
  final String? patientId;
  final String? patientName;
  final String? phoneNumber;
  final String? createdById;
  final String? status; // e.g. 'PAID', 'ACTIVE', 'PARTIALLY_PAID', ...
  final DateTime? fromDate;
  final DateTime? toDate;
  final int skip;
  final int take;
  final String? sortBy; // e.g. 'createdAt', 'amountDue', ...
  final String sortOrder; // 'asc' | 'desc'

  Map<String, dynamic> toQueryParameters() => {
    if (search != null && search!.isNotEmpty) 'q': search,
    if (transactionId != null && transactionId!.isNotEmpty)
      'transactionId': transactionId,
    if (patientId != null && patientId!.isNotEmpty) 'patientId': patientId,
    if (patientName != null && patientName!.isNotEmpty)
      'patientName': patientName,
    if (phoneNumber != null && phoneNumber!.isNotEmpty)
      'phoneNumber': phoneNumber,
    if (createdById != null && createdById!.isNotEmpty)
      'createdById': createdById,
    if (status != null && status!.isNotEmpty) 'status': status,
    if (fromDate != null) 'fromDate': fromDate!.toIso8601String(),
    if (toDate != null) 'toDate': toDate!.toIso8601String(),
    'skip': skip,
    'take': take,
    if (sortBy != null && sortBy!.isNotEmpty) 'sortBy': sortBy,
    'sortOrder': sortOrder,
  };
}

/// Wraps a paginated list response from the backend.
class PaginatedTransactions {
  const PaginatedTransactions({
    required this.data,
    required this.total,
    required this.skip,
    required this.take,
  });

  final List<TransactionModel> data;
  final int total;
  final int skip;
  final int take;

  bool get hasMore => skip + data.length < total;
  int get currentPage => (skip ~/ take) + 1;
  int get totalPages => (total / take).ceil();
}

/// CRUD service for the Transactions feature.
///
/// All methods map 1-to-1 to backend NestJS routes.
class TransactionService {
  TransactionService() : _dio = ApiService().dio;
  final Dio _dio;

  // ── Create ────────────────────────────────────────────────────────────────

  /// POST /transaction — creates a draft (active) transaction.
  Future<TransactionModel> createTransaction(CreateTransactionDto dto) async {
    final resp = await _dio.post('/transaction', data: dto.toJson());
    return _fromJson(resp.data as Map<String, dynamic>);
  }

  /// POST /transaction/quick — creates an instantly paid transaction.
  ///
  /// The backend records the payment and marks status as PAID in one step.
  Future<TransactionModel> createQuickTransaction(
    QuickTransactionDto dto,
  ) async {
    var data = dto.toJson();
    final resp = await _dio.post('/transaction/quick', data: data);
    return _fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// GET /transaction — returns a paginated, filtered list.
  Future<PaginatedTransactions> fetchTransactions(
    TransactionQuery query,
  ) async {
    final resp = await _dio.get(
      '/transaction',
      queryParameters: query.toQueryParameters(),
    );

    final body = resp.data as Map<String, dynamic>;

    // Support both { data: [...], total: N } and plain list responses.
    final rawList = body['data'] is List
        ? body['data'] as List
        : resp.data is List
        ? resp.data as List
        : <dynamic>[];

    final total = (body['total'] as num?)?.toInt() ?? rawList.length;

    return PaginatedTransactions(
      data: rawList.map((e) => _fromJson(e as Map<String, dynamic>)).toList(),
      total: total,
      skip: query.skip,
      take: query.take,
    );
  }

  /// GET /transaction/:id — returns a single transaction with full details.
  Future<TransactionModel> getTransactionById(String id) async {
    final resp = await _dio.get('/transaction/$id');
    return _fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Update ────────────────────────────────────────────────────────────────

  /// PATCH /transaction/:id — partially updates a transaction (e.g. add payment, change status).
  Future<TransactionModel> updateTransaction(
    String id,
    Map<String, dynamic> patch,
  ) async {
    final resp = await _dio.patch('/transaction/$id', data: patch);
    return _fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  /// DELETE /transaction/:id — soft-deletes or cancels a transaction.
  Future<void> deleteTransaction(String id) async {
    await _dio.delete('/transaction/$id');
  }

  // ── Banks ─────────────────────────────────────────────────────────────────

  /// GET /banks — returns a list of bank names available for POS / Transfer / Cheque.
  Future<List<String>> fetchBanks() async {
    final resp = await _dio.get('/banks');
    final data = resp.data;
    if (data is List) {
      return data
          .map((e) {
            if (e is String) return e;
            if (e is Map) return (e['name'] ?? e['bankName'] ?? '').toString();
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  // ── Parsing ───────────────────────────────────────────────────────────────

  /// Maps a raw JSON map (from the API) to a [TransactionModel].
  static TransactionModel _fromJson(Map<String, dynamic> j) {
    // Items
    final rawItems = (j['items'] as List? ?? []);
    final items = rawItems
        .map((e) => TransactionItemModel.fromMap(e as Map<String, dynamic>))
        .toList();

    // Payments (TransactionPayment in schema)
    final rawPayments = (j['payments'] as List? ?? []);
    final payments = rawPayments.map((e) {
      final pm = e as Map<String, dynamic>;
      return TransactionPaymentModel(
        id: pm['id'] as String? ?? '',
        method: _parsePaymentMethod(pm['method'] as String? ?? 'cash'),
        amount: (pm['amount'] as num?)?.toDouble() ?? 0,
        reference: pm['reference'] as String?,
        bankName: pm['bankName'] as String?,
        notes: pm['notes'] as String?,
        paidAt:
            DateTime.tryParse(pm['paidAt'] as String? ?? '') ?? DateTime.now(),
        receivedBy: pm['receivedById'] as String? ?? '',
      );
    }).toList();

    return TransactionModel(
      id: j['id'] as String? ?? '',
      transactionNumber: j['transactionNumber'] as String? ?? '',
      patientId: j['patientId'] as String? ?? '',
      patientName:
          j['patientName'] as String? ??
          (j['patient'] as Map<String, dynamic>?)?['firstName'] as String? ??
          '',
      status: _parseStatus(j['status'] as String? ?? ''),
      totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (j['discountAmount'] as num?)?.toDouble() ?? 0,
      insuranceCovered: (j['insuranceCovered'] as num?)?.toDouble() ?? 0,
      amountPaid: (j['amountPaid'] as num?)?.toDouble() ?? 0,
      items: items,
      payments: payments,
      createdAt:
          DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      createdBy: j['createdById'] as String? ?? '',
      admissionId: j['admissionId'] as String?,
      notes: j['notes'] as String?,
    );
  }

  static TransactionStatus _parseStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'draft':
        return TransactionStatus.draft;
      case 'active':
        return TransactionStatus.active;
      case 'partially_paid':
      case 'partiallypaid':
        return TransactionStatus.partiallyPaid;
      case 'paid':
        return TransactionStatus.paid;
      case 'cancelled':
        return TransactionStatus.cancelled;
      case 'refunded':
        return TransactionStatus.refunded;
      default:
        return TransactionStatus.active;
    }
  }

  static PaymentMethod _parsePaymentMethod(String raw) {
    switch (raw.toLowerCase()) {
      case 'pos':
        return PaymentMethod.pos;
      case 'transfer':
        return PaymentMethod.transfer;
      case 'cheque':
        return PaymentMethod.cheque;
      case 'insurance':
        return PaymentMethod.insurance;
      case 'waiver':
        return PaymentMethod.waiver;
      default:
        return PaymentMethod.cash;
    }
  }
}
