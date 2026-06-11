import 'package:dio/dio.dart';

import '../core/utils/api_decimal.dart';
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
    this.initiatedBy,
    this.status,
    this.paymentMethod,
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

  /// Ledger filter: staff `receivedById` from `staffSummary`.
  final String? initiatedBy;
  final String? status; // e.g. 'PAID', 'ACTIVE', 'PARTIALLY_PAID', ...
  final String? paymentMethod;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int skip;
  final int take;
  final String? sortBy; // e.g. 'createdAt', 'amountDue', ...
  final String sortOrder; // 'asc' | 'desc'

  /// Maps UI payment labels to backend enum strings.
  static String? paymentMethodForApi(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final u = raw.trim().toUpperCase();
    if (u == 'CARD') return 'CARD';
    return u;
  }

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
    if (initiatedBy != null && initiatedBy!.isNotEmpty)
      'initiatedBy': initiatedBy,
    if (status != null && status!.isNotEmpty) 'status': status,
    if (paymentMethod != null && paymentMethod!.isNotEmpty)
      'paymentMethod': paymentMethodForApi(paymentMethod),
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
    this.staffSummary = const [],
  });

  final List<TransactionModel> data;
  final int total;
  final int skip;
  final int take;
  final List<StaffSummaryEntry> staffSummary;

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
    final resp = await _dio.post('/invoices/payments', data: dto.toJson());
    return _fromJson(resp.data as Map<String, dynamic>);
  }

  /// POST /transaction/quick — creates an instantly paid transaction.
  ///
  /// The backend records the payment and marks status as PAID in one step.
  Future<TransactionModel> createQuickTransaction(
    QuickTransactionDto dto,
  ) async {
    var data = dto.toJson();
    final resp = await _dio.post('/invoices/payments/quick', data: data);
    return _fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// GET /transaction — returns a paginated, filtered list.
  Future<PaginatedTransactions> fetchTransactions(
    TransactionQuery query,
  ) async {
    final resp = await _dio.get(
      '/invoices/payments',
      queryParameters: query.toQueryParameters(),
    );

    final body = resp.data as Map<String, dynamic>;

    // Invoice-ledger response:
    // { payments: [...], total, skip, take, ... }
    if (body['payments'] is List) {
      final rawPayments = body['payments'] as List;
      final txns = rawPayments
          .whereType<Map>()
          .map((e) => _fromInvoicePaymentJson(Map<String, dynamic>.from(e)))
          .toList();
      return PaginatedTransactions(
        data: txns,
        total: _toInt(body['total']),
        skip: _toInt(body['skip']),
        take: _toInt(body['take']) == 0 ? query.take : _toInt(body['take']),
        staffSummary: _parseStaffSummary(body['staffSummary']),
      );
    }

    // Legacy transaction response shape:
    // { data: [...], total } or plain list
    final rawList = body['data'] is List
        ? body['data'] as List
        : resp.data is List
        ? resp.data as List
        : <dynamic>[];

    final totalFromApi = _toInt(body['total']);
    final total = totalFromApi > 0 ? totalFromApi : rawList.length;

    return PaginatedTransactions(
      data: rawList.map((e) => _fromJson(e as Map<String, dynamic>)).toList(),
      total: total,
      skip: query.skip,
      take: query.take,
      staffSummary: _parseStaffSummary(body['staffSummary']),
    );
  }

  /// GET /transaction/:id — returns a single transaction with full details.
  Future<TransactionModel> getTransactionById(String id) async {
    final resp = await _dio.get('/invoices/payments/$id');
    return _fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Update ────────────────────────────────────────────────────────────────

  /// PATCH /transaction/:id — partially updates a transaction (e.g. add payment, change status).
  Future<TransactionModel> updateTransaction(
    String id,
    Map<String, dynamic> patch,
  ) async {
    final resp = await _dio.patch('/invoices/payments/$id', data: patch);
    return _fromJson(resp.data as Map<String, dynamic>);
  }

  /// PATCH `/invoices/payments/:paymentId` — updates ledger payment timestamp.
  Future<TransactionModel> updatePaymentPaidAt(
    String paymentId,
    DateTime paidAt,
  ) async {
    final resp = await _dio.patch(
      '/invoices/payments/$paymentId',
      data: {'paidAt': paidAt.toIso8601String()},
    );
    return _fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  /// DELETE /transaction/:id — soft-deletes or cancels a transaction.
  Future<void> deleteTransaction(String id) async {
    await _dio.delete('/invoices/payments/$id');
  }

  // ── Banks ─────────────────────────────────────────────────────────────────

  /// GET /banks — returns a list of bank names available for Card / Transfer / Cheque.
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

  /// Parse numeric value from API (Prisma Decimal as string or `{s,e,d}`).
  static double _toDouble(dynamic v) => parseApiDecimal(v);

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static List<StaffSummaryEntry> _parseStaffSummary(dynamic raw) {
    if (raw is! List) return const [];
    final out = <StaffSummaryEntry>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final entry = StaffSummaryEntry.tryParse(Map<String, dynamic>.from(e));
      if (entry != null) out.add(entry);
    }
    return out;
  }

  static DateTime _toDateTime(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  /// Build display name from patient object (firstName, surname, or single-field names).
  static String _patientName(Map<String, dynamic>? j) {
    if (j == null) return '';
    final first = (j['firstName'] as String?)?.trim() ?? '';
    final last =
        (j['surname'] as String?)?.trim() ??
        (j['lastName'] as String?)?.trim() ??
        '';
    final fromParts = [first, last].where((s) => s.isNotEmpty).join(' ');
    if (fromParts.isNotEmpty) return fromParts;
    for (final key in ['fullName', 'name', 'displayName']) {
      final v = j[key]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  /// Build display name from staff object (firstName, lastName, or single name).
  static String _staffName(Map<String, dynamic>? j) {
    if (j == null) return '';
    final first = (j['firstName'] as String?)?.trim() ?? '';
    final last =
        (j['lastName'] as String?)?.trim() ??
        (j['surname'] as String?)?.trim() ??
        '';
    final fromParts = [first, last].where((s) => s.isNotEmpty).join(' ');
    if (fromParts.isNotEmpty) return fromParts;
    for (final key in ['name', 'fullName', 'displayName', 'userName']) {
      final v = j[key]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  /// Maps a raw JSON map (from the API) to a [TransactionModel].
  /// API uses transactionID, patient{firstName,surname}, createdBy{firstName,lastName};
  /// Decimal fields may come as strings.
  static TransactionModel _fromJson(Map<String, dynamic> j) {
    // Items (list may be omitted when only _count is returned)
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
        amount: _toDouble(pm['amount']),
        reference: pm['reference'] as String?,
        bankName: pm['bankName'] as String?,
        notes: pm['notes'] as String?,
        paidAt: _toDateTime(pm['paidAt']),
        receivedBy: pm['receivedById'] as String? ?? '',
      );
    }).toList();

    final patient = j['patient'] as Map<String, dynamic>?;
    final createdByObj = j['createdBy'] as Map<String, dynamic>?;
    final invoiceObj = j['invoice'];
    final invoiceMap = invoiceObj is Map
        ? Map<String, dynamic>.from(invoiceObj)
        : null;
    final invoiceId = (j['invoiceId'] ?? invoiceMap?['id'])?.toString();

    return TransactionModel(
      id: j['id'] as String? ?? '',
      invoiceId: invoiceId,
      transactionNumber:
          j['transactionID'] as String? ??
          j['transactionNumber'] as String? ??
          '',
      patientId: j['patientId'] as String? ?? '',
      patientName: j['patientName'] as String? ?? _patientName(patient),
      status: _parseStatus(
        j['status'] is String
            ? j['status'] as String
            : j['status']?.toString() ?? '',
      ),
      totalAmount: _toDouble(j['totalAmount']),
      discountAmount: _toDouble(j['discountAmount']),
      insuranceCovered: _toDouble(j['insuranceCovered']),
      amountPaid: _toDouble(j['amountPaid']),
      items: items,
      payments: payments,
      createdAt: _toDateTime(j['createdAt']),
      createdBy: _staffName(createdByObj).isEmpty
          ? (j['createdById'] as String? ?? '')
          : _staffName(createdByObj),
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
      case 'card':
        return PaymentMethod.card;
      case 'transfer':
        return PaymentMethod.transfer;
      case 'wallet':
        return PaymentMethod.wallet;
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

  /// Adapts invoice-ledger payment rows into [TransactionModel] for existing UI.
  static TransactionModel _fromInvoicePaymentJson(Map<String, dynamic> j) {
    final invoiceRaw = j['invoice'];
    final invoice = invoiceRaw is Map<String, dynamic>
        ? invoiceRaw
        : <String, dynamic>{};
    final receivedByRaw = j['receivedBy'];
    final createdByRaw = j['createdBy'];
    final receivedBy = receivedByRaw is Map<String, dynamic>
        ? receivedByRaw
        : null;
    final createdBy = createdByRaw is Map<String, dynamic>
        ? createdByRaw
        : null;
    final bankRaw = j['bank'];
    final bank = bankRaw is Map<String, dynamic> ? bankRaw : null;
    final patientRaw = invoice['patient'];
    final patient = patientRaw is Map<String, dynamic> ? patientRaw : null;
    final invoiceItemsRaw = invoice['invoiceItems'];
    final invoiceItems = invoiceItemsRaw is List ? invoiceItemsRaw : const [];

    final methodText = (j['method'] ?? j['source'] ?? 'cash').toString();
    final amount = _toDouble(j['amount']);
    final paidAt = _toDateTime(j['paidAt'] ?? j['createdAt']);
    var who = _staffName(receivedBy) == ''
        ? _staffName(createdBy)
        : _staffName(receivedBy);
    if (who.isEmpty) {
      for (final k in [
        'staffName',
        'receivedByName',
        'cashierName',
        'initiatedByName',
        'userName',
      ]) {
        final s = j[k]?.toString().trim() ?? '';
        if (s.isNotEmpty) {
          who = s;
          break;
        }
      }
    }
    if (who.isEmpty) {
      final st = j['staff'];
      if (st is Map) who = _staffName(Map<String, dynamic>.from(st));
    }
    // Prefer stable patient id: APIs often use `id` (UUID) rather than `patientId`.
    final patientId = (patient?['patientId'] ?? patient?['id'] ?? invoice['patientId'] ?? j['patientId'] ?? '')
        .toString();
    var patientName = _patientName(patient);
    if (patientName.isEmpty) {
      for (final v in [j['patientName'], invoice['patientName'], j['fullPatientName']]) {
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty) {
          patientName = s;
          break;
        }
      }
    }
    if (patientName.isEmpty) {
      patientName = 'Unknown patient';
    }
    final items = invoiceItems.whereType<Map>().map((raw) {
      final row = Map<String, dynamic>.from(raw);
      final serviceRaw = row['service'];
      final service = serviceRaw is Map<String, dynamic> ? serviceRaw : null;
      final drugRaw = row['drug'];
      final drug = drugRaw is Map<String, dynamic> ? drugRaw : null;
      final consumableRaw = row['consumable'];
      final consumable =
          consumableRaw is Map<String, dynamic> ? consumableRaw : null;
      final purchaseItemRaw = row['purchaseItem'];
      final purchaseItem =
          purchaseItemRaw is Map<String, dynamic> ? purchaseItemRaw : null;
      String? trimmed(dynamic v) {
        final s = v?.toString().trim() ?? '';
        return s.isEmpty ? null : s;
      }

      final customDesc = trimmed(row['customDescription']);
      final purchaseName = purchaseItem == null
          ? null
          : trimmed(
              purchaseItem['itemName'] ??
                  purchaseItem['name'] ??
                  purchaseItem['label'],
            );
      final consumableName = consumable == null
          ? null
          : trimmed(consumable['name'] ?? consumable['label']);
      final drugName =
          trimmed(drug?['genericName']) ?? trimmed(drug?['brandName']);
      final serviceName = trimmed(service?['name']);
      final description = customDesc ??
          purchaseName ??
          consumableName ??
          drugName ??
          serviceName ??
          'Invoice item';
      final quantity = _toInt(row['quantity']);
      final unitPrice = _toDouble(row['unitPrice']);
      final paid = _toDouble(row['amountPaid']);
      return TransactionItemModel(
        id: (row['id'] ?? '').toString(),
        description: description,
        source: service != null ? 'SERVICE' : (drug != null ? 'DRUG' : 'OTHER'),
        quantity: quantity == 0 ? 1 : quantity,
        unitPrice: unitPrice,
        totalPrice: unitPrice * (quantity == 0 ? 1 : quantity),
        paidAmount: paid,
      );
    }).toList();

    return TransactionModel(
      id: (j['id'] ?? '').toString(),
      invoiceId: (j['invoiceId'] ?? invoice['id'])?.toString(),
      transactionNumber: (invoice['invoiceID'] ?? invoice['id'] ?? '')
          .toString(),
      patientId: patientId,
      patientName: patientName,
      status: _parseStatus((invoice['status'] ?? 'active').toString()),
      totalAmount: amount,
      discountAmount: 0,
      insuranceCovered: 0,
      amountPaid: amount,
      items: items,
      payments: [
        TransactionPaymentModel(
          id: (j['id'] ?? '').toString(),
          method: _parsePaymentMethod(methodText),
          amount: amount,
          reference: j['reference']?.toString(),
          bankName: bank == null
              ? null
              : (bank['name'] ?? bank['bankName'])?.toString(),
          notes: j['notes']?.toString(),
          paidAt: paidAt,
          receivedBy: (j['receivedById'] ?? '').toString(),
        ),
      ],
      createdAt: paidAt,
      createdBy: who.isEmpty ? (j['receivedById'] ?? '').toString() : who,
      admissionId: null,
      notes: j['notes']?.toString(),
    );
  }
}
