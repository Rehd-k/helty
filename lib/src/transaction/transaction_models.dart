/// Shared data models, mock data, and filtering logic for the Transactions feature.
library;

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS  (mirrors schema.prisma enums)
// ─────────────────────────────────────────────────────────────────────────────

enum TransactionStatus {
  draft,
  active,
  partiallyPaid,
  paid,
  cancelled,
  refunded;

  String get label => switch (this) {
    TransactionStatus.draft => 'Draft',
    TransactionStatus.active => 'Active',
    TransactionStatus.partiallyPaid => 'Partially Paid',
    TransactionStatus.paid => 'Paid',
    TransactionStatus.cancelled => 'Cancelled',
    TransactionStatus.refunded => 'Refunded',
  };
}

enum PaymentMethod {
  cash,
  card,
  transfer,
  wallet,
  cheque,
  insurance,
  waiver;

  String get label => switch (this) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.card => 'Card',
    PaymentMethod.transfer => 'Transfer',
    PaymentMethod.wallet => 'Wallet',
    PaymentMethod.cheque => 'Cheque',
    PaymentMethod.insurance => 'Insurance',
    PaymentMethod.waiver => 'Waiver',
  };
}

enum TransactionSortField {
  tranId,
  patientName,
  amountDue,
  amountPaid,
  debt,
  date,
  initiator,
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS  (Dart-side; maps to schema.prisma models)
// ─────────────────────────────────────────────────────────────────────────────

/// A rendered service included in a transaction (maps to `TransactionItem`).
class TransactionItemModel {
  const TransactionItemModel({
    required this.id,
    required this.description,
    required this.source,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.paidAmount = 0,
  });

  final String id;
  final String description;
  final String source; // e.g. LAB, CONSULTATION, PHARMACY …
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double paidAmount;

  /// [cost], [unitPrice], [totalPrice], [quantity], [paid], [paidAmount] may be num or string (e.g. Prisma Decimal).
  factory TransactionItemModel.fromMap(Map<String, dynamic> m) =>
      TransactionItemModel(
        id: m['id'] as String? ?? '',
        description: m['name'] as String? ?? m['description'] as String? ?? '',
        source: m['source'] as String? ?? 'OTHER',
        quantity: (_itemNum(m['quantity']) ?? 1).toInt(),
        unitPrice: _itemNum(m['cost']) ?? _itemNum(m['unitPrice']) ?? 0,
        totalPrice: _itemNum(m['cost']) ?? _itemNum(m['totalPrice']) ?? 0,
        paidAmount: _itemNum(m['paid']) ?? _itemNum(m['paidAmount']) ?? 0,
      );
}

double? _itemNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) {
    final n = num.tryParse(v);
    return n?.toDouble();
  }
  return null;
}

/// Mirrors the `TransactionPayment` model from schema.prisma.
class TransactionPaymentModel {
  const TransactionPaymentModel({
    required this.id,
    required this.method,
    required this.amount,
    this.reference,
    this.bankName,
    this.notes,
    required this.paidAt,
    required this.receivedBy,
  });

  final String id;
  final PaymentMethod method;
  final double amount;
  final String? reference;
  final String? bankName; // populated for Card / Transfer / Cheque
  final String? notes;
  final DateTime paidAt;
  final String receivedBy;
}

/// Top-level transaction.  Mirrors the `Transaction` model in schema.prisma.
class TransactionModel {
  const TransactionModel({
    required this.id,
    this.invoiceId,
    required this.transactionNumber,
    required this.patientId,
    required this.patientName,
    required this.status,
    required this.totalAmount,
    required this.discountAmount,
    required this.insuranceCovered,
    required this.amountPaid,
    required this.items,
    required this.payments,
    required this.createdAt,
    required this.createdBy,
    this.admissionId,
    this.notes,
  });

  final String id;
  final String? invoiceId;
  final String transactionNumber; // e.g. TXN-2023-001
  final String patientId;
  final String patientName;
  final TransactionStatus status;

  // Financial summary
  final double totalAmount;
  final double discountAmount;
  final double insuranceCovered;
  final double amountPaid;

  double get balance =>
      totalAmount - discountAmount - insuranceCovered - amountPaid;

  final List<TransactionItemModel> items;
  final List<TransactionPaymentModel> payments;

  final DateTime createdAt;
  final String createdBy; // Staff name / id

  final String? admissionId;
  final String? notes;
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER  model
// ─────────────────────────────────────────────────────────────────────────────

class TransactionFilter {
  const TransactionFilter({
    this.initiator,
    this.searchQuery = '',
    this.searchField = 'Transaction ID',
    this.dateRange,
    this.status,
    this.myTransactionsOnly = false,
    this.currentUser = '',
    this.sortField = TransactionSortField.date,
    this.sortAscending = false,
  });

  final String? initiator;
  final String searchQuery;
  final String searchField;
  final DateTimeRange? dateRange;
  final TransactionStatus? status;
  final bool myTransactionsOnly;
  final String currentUser;
  final TransactionSortField sortField;
  final bool sortAscending;

  TransactionFilter copyWith({
    String? initiator,
    String? searchQuery,
    String? searchField,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    TransactionStatus? status,
    bool? myTransactionsOnly,
    String? currentUser,
    TransactionSortField? sortField,
    bool? sortAscending,
  }) => TransactionFilter(
    initiator: initiator ?? this.initiator,
    searchQuery: searchQuery ?? this.searchQuery,
    searchField: searchField ?? this.searchField,
    dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
    status: status ?? this.status,
    myTransactionsOnly: myTransactionsOnly ?? this.myTransactionsOnly,
    currentUser: currentUser ?? this.currentUser,
    sortField: sortField ?? this.sortField,
    sortAscending: sortAscending ?? this.sortAscending,
  );

  static const TransactionFilter empty = TransactionFilter();
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER FUNCTION
// ─────────────────────────────────────────────────────────────────────────────

/// Applies [filter] on [transactions] and returns a sorted, filtered list.
///
/// Replace the body with a call to your NestJS API when ready —
/// this function is the single point of truth for what the UI displays.
List<TransactionMap> applyTransactionFilter(
  List<TransactionMap> transactions,
  TransactionFilter filter,
) {
  Iterable<TransactionMap> result = transactions;

  // ── "My transactions" shortcut
  if (filter.myTransactionsOnly && filter.currentUser.isNotEmpty) {
    result = result.where((t) => t['initiator'] == filter.currentUser);
  }

  // ── Specific user filter
  if (filter.initiator != null && filter.initiator != 'All Users') {
    result = result.where((t) => t['initiator'] == filter.initiator);
  }

  // ── Status filter
  if (filter.status != null) {
    result = result.where(
      (t) => t['status'] == filter.status!.name.toUpperCase(),
    );
  }

  // ── Search
  final q = filter.searchQuery.trim().toLowerCase();
  if (q.isNotEmpty) {
    result = result.where((t) {
      final field = switch (filter.searchField) {
        'Patient ID' => (t['patientId'] as String).toLowerCase(),
        'Patient Name' => (t['patientName'] as String).toLowerCase(),
        _ => (t['tranId'] as String).toLowerCase(),
      };
      return field.contains(q);
    });
  }

  // ── Date range  (compare against the raw date string — swap for DateTime when using real API)
  // When integrating with the API, pass dateRange as query params:
  //   GET /transactions?from=<ISO>&to=<ISO>
  if (filter.dateRange != null) {
    // NOTE: mock data stores date as a formatted string; real API returns ISO dates.
    // Skip date-range filter on mock data to avoid parse errors.
  }

  // ── Sort
  final list = result.toList();
  list.sort((a, b) {
    int cmp;
    switch (filter.sortField) {
      case TransactionSortField.tranId:
        cmp = (a['tranId'] as String).compareTo(b['tranId'] as String);
        break;
      case TransactionSortField.patientName:
        cmp = (a['patientName'] as String).compareTo(
          b['patientName'] as String,
        );
        break;
      case TransactionSortField.amountDue:
        cmp = (a['amountDue'] as num).compareTo(b['amountDue'] as num);
        break;
      case TransactionSortField.amountPaid:
        cmp = (a['amountPaid'] as num).compareTo(b['amountPaid'] as num);
        break;
      case TransactionSortField.debt:
        cmp = (a['debt'] as num).compareTo(b['debt'] as num);
        break;
      case TransactionSortField.initiator:
        cmp = (a['initiator'] as String).compareTo(b['initiator'] as String);
        break;
      case TransactionSortField.date:
        cmp = (a['date'] as String).compareTo(b['date'] as String);
        break;
    }
    return filter.sortAscending ? cmp : -cmp;
  });
  return list;
}

// ─────────────────────────────────────────────────────────────────────────────
// TOTALS
// ─────────────────────────────────────────────────────────────────────────────

/// Alias for readability
typedef TransactionMap = Map<String, dynamic>;

/// Staff aggregate row from GET `/invoices/payments` `staffSummary`.
class StaffSummaryEntry {
  const StaffSummaryEntry({
    required this.receivedById,
    required this.firstName,
    required this.lastName,
    required this.paymentCount,
  });

  final String receivedById;
  final String firstName;
  final String lastName;
  final int paymentCount;

  /// `lastName, firstName (paymentCount)` for filter dropdown labels.
  String get dropdownLabel {
    final ln = lastName.trim();
    final fn = firstName.trim();
    final name = () {
      if (ln.isNotEmpty && fn.isNotEmpty) return '$ln, $fn';
      if (ln.isNotEmpty) return ln;
      if (fn.isNotEmpty) return fn;
      return receivedById;
    }();
    return '$name ($paymentCount)';
  }

  static StaffSummaryEntry? tryParse(Map<String, dynamic> m) {
    final id = m['receivedById']?.toString().trim() ?? '';
    if (id.isEmpty) return null;
    final staffRaw = m['staff'];
    var fn = '';
    var ln = '';
    if (staffRaw is Map) {
      final sm = Map<String, dynamic>.from(staffRaw);
      fn = sm['firstName']?.toString().trim() ?? '';
      ln =
          sm['lastName']?.toString().trim() ??
          sm['surname']?.toString().trim() ??
          '';
    }
    final pc = m['paymentCount'];
    final count = pc is num
        ? pc.toInt()
        : (pc is String ? int.tryParse(pc) ?? 0 : 0);
    return StaffSummaryEntry(
      receivedById: id,
      firstName: fn,
      lastName: ln,
      paymentCount: count,
    );
  }
}

/// Converts a [TransactionModel] from the API into [TransactionMap] for table/totals.
TransactionMap transactionModelToMap(TransactionModel m) {
  String paymentMethodLabel = '—';
  String? bankName;
  String? reference;
  var displayAt = m.createdAt;
  if (m.payments.isNotEmpty) {
    final latest = m.payments.reduce(
      (a, b) => a.paidAt.isAfter(b.paidAt) ? a : b,
    );
    bankName = latest.bankName;
    reference = latest.reference;
    displayAt = latest.paidAt;
    final methods = m.payments.map((p) => p.method.label).toSet();
    paymentMethodLabel = methods.length == 1 ? methods.single : 'Mixed';
  }
  final dateStr = DateFormat('MMM d, y h:mm a').format(displayAt);
  final services = m.items
      .map(
        (i) => {
          'id': i.id,
          'name': i.description,
          'source': i.source,
          'quantity': i.quantity,
          'cost': i.unitPrice,
          'totalPrice': i.totalPrice,
          'paid': i.paidAmount,
        },
      )
      .toList();
  return {
    'tranId': m.transactionNumber.isNotEmpty ? m.transactionNumber : m.id,
    'invoiceId': m.invoiceId,
    'patientId': m.patientId,
    'patientName': m.patientName,
    'serviceCount': m.items.length,
    'amountDue': m.totalAmount,
    'amountPaid': m.amountPaid,
    'paymentMethod': paymentMethodLabel,
    'discount': m.discountAmount,

    /// Machine-readable time for receipts; aligned with latest payment [paidAt] when present.
    'createdAtIso': displayAt.toIso8601String(),
    'date': dateStr,
    'debt': m.balance,
    'status': m.status.label.toUpperCase().replaceAll(' ', '_'),
    'initiator': m.createdBy,
    'services': services,
    if (bankName != null && bankName.trim().isNotEmpty) 'bankName': bankName,
    if (reference != null && reference.trim().isNotEmpty)
      'reference': reference,
    'id': m.id,
  };
}

/// Calculates financial totals from a filtered transaction list.
/// Includes [transactionCount] for the summary section.
Map<String, dynamic> calculateTransactionTotals(List<TransactionMap> list) {
  double totalSales = 0,
      totalPaid = 0,
      transfer = 0,
      card = 0,
      cheque = 0,
      cash = 0,
      wallet = 0;

  for (final txn in list) {
    totalSales += (txn['amountDue'] as num).toDouble();
    totalPaid += (txn['amountPaid'] as num).toDouble();
    switch (txn['paymentMethod']) {
      case 'Transfer':
        transfer += (txn['amountPaid'] as num).toDouble();
        break;
      case 'Card':
      case 'CARD':
        card += (txn['amountPaid'] as num).toDouble();
        break;
      case 'Cheque':
        cheque += (txn['amountPaid'] as num).toDouble();
        break;
      case 'Cash':
        cash += (txn['amountPaid'] as num).toDouble();
        break;
      case 'Wallet':
        wallet += (txn['amountPaid'] as num).toDouble();
        break;
      case 'Mixed':
      case '—':
        // Don't attribute to a single method bucket
        break;
    }
  }

  return {
    'totalSales': totalSales,
    'totalPaid': totalPaid,
    'transfer': transfer,
    'card': card,
    'cheque': cheque,
    'cash': cash,
    'wallet': wallet,
    'grandTotal': totalPaid,
    'transactionCount': list.length,
  };
}
