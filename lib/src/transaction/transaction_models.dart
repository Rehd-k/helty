/// Shared data models, mock data, and filtering logic for the Transactions feature.
library;

import 'package:flutter/material.dart' show DateTimeRange;

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
  pos,
  transfer,
  cheque,
  insurance,
  waiver;

  String get label => switch (this) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.pos => 'POS',
    PaymentMethod.transfer => 'Transfer',
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

  factory TransactionItemModel.fromMap(Map<String, dynamic> m) =>
      TransactionItemModel(
        id: m['id'] as String? ?? '',
        description: m['name'] as String? ?? m['description'] as String? ?? '',
        source: m['source'] as String? ?? 'OTHER',
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        unitPrice:
            (m['cost'] as num?)?.toDouble() ??
            (m['unitPrice'] as num?)?.toDouble() ??
            0,
        totalPrice:
            (m['cost'] as num?)?.toDouble() ??
            (m['totalPrice'] as num?)?.toDouble() ??
            0,
        paidAmount:
            (m['paid'] as num?)?.toDouble() ??
            (m['paidAmount'] as num?)?.toDouble() ??
            0,
      );
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
  final String? bankName; // populated for POS / Transfer / Cheque
  final String? notes;
  final DateTime paidAt;
  final String receivedBy;
}

/// Top-level transaction.  Mirrors the `Transaction` model in schema.prisma.
class TransactionModel {
  const TransactionModel({
    required this.id,
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

/// Calculates financial totals from a filtered transaction list.
Map<String, double> calculateTransactionTotals(List<TransactionMap> list) {
  double totalSales = 0,
      totalPaid = 0,
      transfer = 0,
      pos = 0,
      cheque = 0,
      cash = 0;

  for (final txn in list) {
    totalSales += (txn['amountDue'] as num).toDouble();
    totalPaid += (txn['amountPaid'] as num).toDouble();
    switch (txn['paymentMethod']) {
      case 'Transfer':
        transfer += (txn['amountPaid'] as num).toDouble();
        break;
      case 'POS':
        pos += (txn['amountPaid'] as num).toDouble();
        break;
      case 'Cheque':
        cheque += (txn['amountPaid'] as num).toDouble();
        break;
      case 'Cash':
        cash += (txn['amountPaid'] as num).toDouble();
        break;
    }
  }

  return {
    'totalSales': totalSales,
    'totalPaid': totalPaid,
    'transfer': transfer,
    'pos': pos,
    'cheque': cheque,
    'cash': cash,
    'grandTotal': totalPaid,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA
// ─────────────────────────────────────────────────────────────────────────────

/// In-memory mock transactions used during UI development.
/// Replace with a real API call via [TransactionRepository] when ready.
final List<TransactionMap> kMockTransactions = [
  {
    'tranId': 'TXN-2023-001',
    'patientId': 'PT-8021',
    'patientName': 'James Miller',
    'serviceCount': 5,
    'amountDue': 650.00,
    'amountPaid': 650.00,
    'paymentMethod': 'POS',
    'discount': 0.00,
    'date': 'Oct 24, 2023 08:45 AM',
    'debt': 0.00,
    'status': 'PAID',
    'initiator': 'Sarah Jenkins',
    'bankName': 'First Bank',
    'reference': 'POS-REF-4421',
    'services': [
      {
        'id': 'SVC-001',
        'name': 'General Consultation',
        'source': 'CONSULTATION',
        'cost': 150.00,
        'paid': 150.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-002',
        'name': 'Complete Blood Count (CBC)',
        'source': 'LAB',
        'cost': 85.00,
        'paid': 85.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-003',
        'name': 'Urinalysis',
        'source': 'LAB',
        'cost': 60.00,
        'paid': 60.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-004',
        'name': 'Chest X-Ray',
        'source': 'RADIOLOGY',
        'cost': 155.00,
        'paid': 155.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-005',
        'name': 'Paracetamol 500mg (x20)',
        'source': 'PHARMACY',
        'cost': 200.00,
        'paid': 200.00,
        'quantity': 20,
      },
    ],
  },
  {
    'tranId': 'TXN-2023-002',
    'patientId': 'PT-8022',
    'patientName': 'Emma Rodriguez',
    'serviceCount': 3,
    'amountDue': 380.00,
    'amountPaid': 200.00,
    'paymentMethod': 'Cash',
    'discount': 20.00,
    'date': 'Oct 24, 2023 09:15 AM',
    'debt': 160.00,
    'status': 'PARTIALLY_PAID',
    'initiator': 'Michael Chen',
    'services': [
      {
        'id': 'SVC-006',
        'name': 'Emergency Care',
        'source': 'CONSULTATION',
        'cost': 150.00,
        'paid': 100.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-007',
        'name': 'Wound Dressing',
        'source': 'OTHER',
        'cost': 80.00,
        'paid': 60.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-008',
        'name': 'Tetanus Injection',
        'source': 'PHARMACY',
        'cost': 150.00,
        'paid': 40.00,
        'quantity': 1,
      },
    ],
  },
  {
    'tranId': 'TXN-2023-003',
    'patientId': 'PT-8023',
    'patientName': 'David Kim',
    'serviceCount': 5,
    'amountDue': 1120.00,
    'amountPaid': 1120.00,
    'paymentMethod': 'Transfer',
    'discount': 0.00,
    'date': 'Oct 24, 2023 10:30 AM',
    'debt': 0.00,
    'status': 'PAID',
    'initiator': 'Sarah Jenkins',
    'bankName': 'GTBank',
    'reference': 'TRF-9921-GTB',
    'services': [
      {
        'id': 'SVC-009',
        'name': 'Cardiology Consult',
        'source': 'CONSULTATION',
        'cost': 250.00,
        'paid': 250.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-010',
        'name': 'ECG / EKG',
        'source': 'OTHER',
        'cost': 120.00,
        'paid': 120.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-011',
        'name': 'Echocardiogram',
        'source': 'RADIOLOGY',
        'cost': 350.00,
        'paid': 350.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-012',
        'name': 'Lipid Profile',
        'source': 'LAB',
        'cost': 200.00,
        'paid': 200.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-013',
        'name': 'Blood Pressure Monitoring (24h)',
        'source': 'OTHER',
        'cost': 200.00,
        'paid': 200.00,
        'quantity': 1,
      },
    ],
  },
  {
    'tranId': 'TXN-2023-004',
    'patientId': 'PT-8024',
    'patientName': 'Sarah Connor',
    'serviceCount': 6,
    'amountDue': 810.00,
    'amountPaid': 810.00,
    'paymentMethod': 'Cheque',
    'discount': 50.00,
    'date': 'Oct 23, 2023 14:20 PM',
    'debt': 0.00,
    'status': 'PAID',
    'initiator': 'Alan Grant',
    'bankName': 'Zenith Bank',
    'reference': 'CHQ-00142',
    'services': [
      {
        'id': 'SVC-014',
        'name': 'Specialist Consult (Ortho)',
        'source': 'CONSULTATION',
        'cost': 200.00,
        'paid': 200.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-015',
        'name': 'X-Ray (Left Arm)',
        'source': 'RADIOLOGY',
        'cost': 110.00,
        'paid': 110.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-016',
        'name': 'Cast Application',
        'source': 'OTHER',
        'cost': 180.00,
        'paid': 180.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-017',
        'name': 'Anti-inflammatory Medication',
        'source': 'PHARMACY',
        'cost': 120.00,
        'paid': 120.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-018',
        'name': 'Physiotherapy Session (x2)',
        'source': 'OTHER',
        'cost': 100.00,
        'paid': 100.00,
        'quantity': 2,
      },
      {
        'id': 'SVC-019',
        'name': 'Surgical Gloves & Consumables',
        'source': 'OTHER',
        'cost': 100.00,
        'paid': 100.00,
        'quantity': 1,
      },
    ],
  },
  {
    'tranId': 'TXN-2023-005',
    'patientId': 'PT-8025',
    'patientName': 'Aisha Bello',
    'serviceCount': 4,
    'amountDue': 490.00,
    'amountPaid': 0.00,
    'paymentMethod': 'Pending',
    'discount': 0.00,
    'date': 'Oct 23, 2023 11:05 AM',
    'debt': 490.00,
    'status': 'ACTIVE',
    'initiator': 'Sarah Jenkins',
    'services': [
      {
        'id': 'SVC-020',
        'name': 'Ante-natal Consultation',
        'source': 'CONSULTATION',
        'cost': 120.00,
        'paid': 0.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-021',
        'name': 'Obstetric Ultrasound',
        'source': 'RADIOLOGY',
        'cost': 180.00,
        'paid': 0.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-022',
        'name': 'Haemogram (FBC)',
        'source': 'LAB',
        'cost': 90.00,
        'paid': 0.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-023',
        'name': 'Iron Supplement (x30)',
        'source': 'PHARMACY',
        'cost': 100.00,
        'paid': 0.00,
        'quantity': 30,
      },
    ],
  },
  {
    'tranId': 'TXN-2023-006',
    'patientId': 'PT-8026',
    'patientName': 'Taiwo Adeyemi',
    'serviceCount': 3,
    'amountDue': 320.00,
    'amountPaid': 320.00,
    'paymentMethod': 'POS',
    'discount': 0.00,
    'date': 'Oct 22, 2023 16:00 PM',
    'debt': 0.00,
    'status': 'PAID',
    'initiator': 'Michael Chen',
    'bankName': 'UBA',
    'reference': 'POS-REF-5519',
    'services': [
      {
        'id': 'SVC-024',
        'name': 'ENT Consultation',
        'source': 'CONSULTATION',
        'cost': 150.00,
        'paid': 150.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-025',
        'name': 'Audiometry Test',
        'source': 'OTHER',
        'cost': 90.00,
        'paid': 90.00,
        'quantity': 1,
      },
      {
        'id': 'SVC-026',
        'name': 'Ear Drops (10ml)',
        'source': 'PHARMACY',
        'cost': 80.00,
        'paid': 80.00,
        'quantity': 1,
      },
    ],
  },
];
