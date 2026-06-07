import 'package:flutter/foundation.dart';

double _toDouble(Object? v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

Object? _pick(Map<String, dynamic> json, String camel, String snake) =>
    json[camel] ?? json[snake];

int _toInt(Object? v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

DateTime? _parseDate(Object? v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

// ── Dashboard ──────────────────────────────────────────────────────────────

@immutable
class AccountsDashboardBundle {
  const AccountsDashboardBundle({
    required this.grossRevenue,
    required this.netCollections,
    required this.outstandingAr,
    required this.overdueAmount,
    required this.hmoReceivables,
    required this.discountReceivables,
    required this.walletFloat,
    required this.pendingApprovalsCount,
    required this.leakAlertsCount,
    required this.recentPaymentsCount,
    required this.remittancesDue,
    required this.activityFeed,
    required this.paymentMixSnapshot,
    required this.fromUnifiedApi,
  });

  final double grossRevenue;
  final double netCollections;
  final double outstandingAr;
  final double overdueAmount;
  final double hmoReceivables;
  final double discountReceivables;
  final double walletFloat;
  final int pendingApprovalsCount;
  final int leakAlertsCount;
  final int recentPaymentsCount;
  final double remittancesDue;
  final List<AccountsActivityItem> activityFeed;
  final List<AccountsPaymentMixSlice> paymentMixSnapshot;
  final bool fromUnifiedApi;

  factory AccountsDashboardBundle.empty() => const AccountsDashboardBundle(
        grossRevenue: 0,
        netCollections: 0,
        outstandingAr: 0,
        overdueAmount: 0,
        hmoReceivables: 0,
        discountReceivables: 0,
        walletFloat: 0,
        pendingApprovalsCount: 0,
        leakAlertsCount: 0,
        recentPaymentsCount: 0,
        remittancesDue: 0,
        activityFeed: [],
        paymentMixSnapshot: [],
        fromUnifiedApi: false,
      );

  factory AccountsDashboardBundle.fromJson(Map<String, dynamic> json) {
    final feedRaw = _pick(json, 'activityFeed', 'activity_feed');
    final feed = (feedRaw is List ? feedRaw : const <dynamic>[])
        .whereType<Map>()
        .map((e) => AccountsActivityItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final mixRaw = _pick(json, 'paymentMixSnapshot', 'payment_mix_snapshot');
    final mix = (mixRaw is List ? mixRaw : const <dynamic>[])
        .whereType<Map>()
        .map(
          (e) =>
              AccountsPaymentMixSlice.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
    return AccountsDashboardBundle(
      grossRevenue: _toDouble(_pick(json, 'grossRevenue', 'gross_revenue')),
      netCollections:
          _toDouble(_pick(json, 'netCollections', 'net_collections')),
      outstandingAr: _toDouble(_pick(json, 'outstandingAr', 'outstanding_ar')),
      overdueAmount:
          _toDouble(_pick(json, 'overdueAmount', 'overdue_amount')),
      hmoReceivables:
          _toDouble(_pick(json, 'hmoReceivables', 'hmo_receivables')),
      discountReceivables: _toDouble(
        _pick(json, 'discountReceivables', 'discount_receivables'),
      ),
      walletFloat: _toDouble(_pick(json, 'walletFloat', 'wallet_float')),
      pendingApprovalsCount: _toInt(
        _pick(json, 'pendingApprovalsCount', 'pending_approvals_count'),
      ),
      leakAlertsCount:
          _toInt(_pick(json, 'leakAlertsCount', 'leak_alerts_count')),
      recentPaymentsCount: _toInt(
        _pick(json, 'recentPaymentsCount', 'recent_payments_count'),
      ),
      remittancesDue:
          _toDouble(_pick(json, 'remittancesDue', 'remittances_due')),
      activityFeed: feed,
      paymentMixSnapshot: mix,
      fromUnifiedApi: true,
    );
  }
}

@immutable
class AccountsActivityItem {
  const AccountsActivityItem({
    required this.id,
    required this.at,
    required this.category,
    required this.message,
    required this.actorLabel,
    required this.amount,
  });

  final String id;
  final DateTime at;
  final String category;
  final String message;
  final String actorLabel;
  final double? amount;

  factory AccountsActivityItem.fromJson(Map<String, dynamic> json) {
    return AccountsActivityItem(
      id: json['id']?.toString() ?? '',
      at: _parseDate(json['at']) ?? DateTime.now(),
      category: json['category']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      actorLabel: json['actorLabel']?.toString() ?? '',
      amount: json['amount'] != null ? _toDouble(json['amount']) : null,
    );
  }
}

@immutable
class AccountsPaymentMixSlice {
  const AccountsPaymentMixSlice({
    required this.method,
    required this.amount,
    required this.percent,
  });

  final String method;
  final double amount;
  final double percent;

  factory AccountsPaymentMixSlice.fromJson(Map<String, dynamic> json) {
    return AccountsPaymentMixSlice(
      method: json['method']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      percent: _toDouble(json['percent']),
    );
  }
}

// ── Audit ──────────────────────────────────────────────────────────────────

@immutable
class AccountsAuditLogEntry {
  const AccountsAuditLogEntry({
    required this.id,
    required this.at,
    required this.user,
    required this.action,
    required this.entity,
    required this.metadata,
  });

  final String id;
  final DateTime at;
  final String user;
  final String action;
  final String entity;
  final String metadata;

  factory AccountsAuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AccountsAuditLogEntry(
      id: json['id']?.toString() ?? '',
      at: _parseDate(json['at']) ?? DateTime.now(),
      user: json['user']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      entity: json['entity']?.toString() ?? '',
      metadata: json['metadata']?.toString() ?? json['detail']?.toString() ?? '',
    );
  }
}

@immutable
class AccountsComplianceItem {
  const AccountsComplianceItem({
    required this.code,
    required this.description,
    required this.status,
    required this.lastCheckedAt,
    required this.canAcknowledge,
  });

  final String code;
  final String description;
  final String status;
  final DateTime? lastCheckedAt;
  final bool canAcknowledge;

  factory AccountsComplianceItem.fromJson(Map<String, dynamic> json) {
    return AccountsComplianceItem(
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      lastCheckedAt: _parseDate(json['lastCheckedAt']),
      canAcknowledge: json['canAcknowledge'] == true,
    );
  }
}

@immutable
class AccountsAuditComplianceBundle {
  const AccountsAuditComplianceBundle({
    required this.logs,
    required this.compliance,
  });

  final List<AccountsAuditLogEntry> logs;
  final List<AccountsComplianceItem> compliance;

  factory AccountsAuditComplianceBundle.empty() =>
      const AccountsAuditComplianceBundle(logs: [], compliance: []);
}

@immutable
class AccountsLeakFlag {
  const AccountsLeakFlag({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedExposure,
    required this.severity,
  });

  final String id;
  final String title;
  final String description;
  final double estimatedExposure;
  final String severity;

  factory AccountsLeakFlag.fromJson(Map<String, dynamic> json) {
    return AccountsLeakFlag(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      estimatedExposure: _toDouble(json['estimatedExposure']),
      severity: json['severity']?.toString() ?? 'medium',
    );
  }
}

@immutable
class AccountsInvoiceChangeEntry {
  const AccountsInvoiceChangeEntry({
    required this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.changedAt,
    required this.changedBy,
    required this.changeType,
    required this.detail,
  });

  final String id;
  final String invoiceId;
  final String invoiceNumber;
  final DateTime changedAt;
  final String changedBy;
  final String changeType;
  final String detail;

  factory AccountsInvoiceChangeEntry.fromJson(Map<String, dynamic> json) {
    return AccountsInvoiceChangeEntry(
      id: json['id']?.toString() ?? '',
      invoiceId: json['invoiceId']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      changedAt: _parseDate(json['changedAt']) ?? DateTime.now(),
      changedBy: json['changedBy']?.toString() ?? '',
      changeType: json['changeType']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
    );
  }
}

@immutable
class AccountsStaffActivityRow {
  const AccountsStaffActivityRow({
    required this.staffId,
    required this.staffName,
    required this.role,
    required this.paymentsRecorded,
    required this.totalCollected,
    required this.refundsInitiated,
    required this.remittancesRecorded,
  });

  final String staffId;
  final String staffName;
  final String role;
  final int paymentsRecorded;
  final double totalCollected;
  final int refundsInitiated;
  final int remittancesRecorded;

  factory AccountsStaffActivityRow.fromJson(Map<String, dynamic> json) {
    return AccountsStaffActivityRow(
      staffId: json['staffId']?.toString() ?? '',
      staffName: json['staffName']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      paymentsRecorded: (json['paymentsRecorded'] as num?)?.toInt() ?? 0,
      totalCollected: _toDouble(json['totalCollected']),
      refundsInitiated: (json['refundsInitiated'] as num?)?.toInt() ?? 0,
      remittancesRecorded: (json['remittancesRecorded'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── Reports ────────────────────────────────────────────────────────────────

@immutable
class AccountsReportLine {
  const AccountsReportLine({
    required this.label,
    required this.amount,
    this.subLabel,
    this.isHeader,
    this.isTotal,
  });

  final String label;
  final double amount;
  final String? subLabel;
  final bool? isHeader;
  final bool? isTotal;

  factory AccountsReportLine.fromJson(Map<String, dynamic> json) {
    return AccountsReportLine(
      label: json['label']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      subLabel: json['subLabel']?.toString(),
      isHeader: json['isHeader'] as bool?,
      isTotal: json['isTotal'] as bool?,
    );
  }
}

@immutable
class AccountsDailyCollectionRow {
  const AccountsDailyCollectionRow({
    required this.date,
    required this.cash,
    required this.card,
    required this.transfer,
    required this.cheque,
    required this.wallet,
    required this.insurance,
    required this.total,
    required this.transactionCount,
  });

  final DateTime date;
  final double cash;
  final double card;
  final double transfer;
  final double cheque;
  final double wallet;
  final double insurance;
  final double total;
  final int transactionCount;

  factory AccountsDailyCollectionRow.fromJson(Map<String, dynamic> json) {
    return AccountsDailyCollectionRow(
      date: _parseDate(json['date']) ?? DateTime.now(),
      cash: _toDouble(json['cash']),
      card: _toDouble(json['card']),
      transfer: _toDouble(json['transfer']),
      cheque: _toDouble(json['cheque']),
      wallet: _toDouble(json['wallet']),
      insurance: _toDouble(json['insurance']),
      total: _toDouble(json['total']),
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class AccountsAgingBucket {
  const AccountsAgingBucket({
    required this.bucket,
    required this.count,
    required this.amount,
  });

  final String bucket;
  final int count;
  final double amount;

  factory AccountsAgingBucket.fromJson(Map<String, dynamic> json) {
    return AccountsAgingBucket(
      bucket: json['bucket']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      amount: _toDouble(json['amount']),
    );
  }
}

@immutable
class AccountsAgingRow {
  const AccountsAgingRow({
    required this.id,
    required this.partyName,
    required this.type,
    required this.totalDue,
    required this.current,
    required this.days30,
    required this.days60,
    required this.days90,
    required this.over90,
  });

  final String id;
  final String partyName;
  final String type;
  final double totalDue;
  final double current;
  final double days30;
  final double days60;
  final double days90;
  final double over90;

  factory AccountsAgingRow.fromJson(Map<String, dynamic> json) {
    return AccountsAgingRow(
      id: json['id']?.toString() ?? '',
      partyName: json['partyName']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      totalDue: _toDouble(json['totalDue']),
      current: _toDouble(json['current']),
      days30: _toDouble(json['days30']),
      days60: _toDouble(json['days60']),
      days90: _toDouble(json['days90']),
      over90: _toDouble(json['over90']),
    );
  }
}

@immutable
class AccountsAgingReport {
  const AccountsAgingReport({
    required this.buckets,
    required this.rows,
    required this.totalOutstanding,
  });

  final List<AccountsAgingBucket> buckets;
  final List<AccountsAgingRow> rows;
  final double totalOutstanding;

  factory AccountsAgingReport.empty() => const AccountsAgingReport(
        buckets: [],
        rows: [],
        totalOutstanding: 0,
      );

  factory AccountsAgingReport.fromJson(Map<String, dynamic> json) {
    final buckets = (json['buckets'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => AccountsAgingBucket.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final rows = (json['rows'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => AccountsAgingRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return AccountsAgingReport(
      buckets: buckets,
      rows: rows,
      totalOutstanding: _toDouble(json['totalOutstanding']),
    );
  }
}

@immutable
class AccountsProfitLossReport {
  const AccountsProfitLossReport({
    required this.period,
    required this.revenueLines,
    required this.expenseLines,
    required this.netProfit,
    required this.grossMarginPercent,
  });

  final String period;
  final List<AccountsReportLine> revenueLines;
  final List<AccountsReportLine> expenseLines;
  final double netProfit;
  final double grossMarginPercent;

  factory AccountsProfitLossReport.empty() => const AccountsProfitLossReport(
        period: '',
        revenueLines: [],
        expenseLines: [],
        netProfit: 0,
        grossMarginPercent: 0,
      );

  factory AccountsProfitLossReport.fromJson(Map<String, dynamic> json) {
    List<AccountsReportLine> lines(String key) =>
        (json[key] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => AccountsReportLine.fromJson(Map<String, dynamic>.from(e)))
            .toList();
    return AccountsProfitLossReport(
      period: json['period']?.toString() ?? '',
      revenueLines: lines('revenueLines'),
      expenseLines: lines('expenseLines'),
      netProfit: _toDouble(json['netProfit']),
      grossMarginPercent: _toDouble(json['grossMarginPercent']),
    );
  }
}

@immutable
class AccountsCashFlowReport {
  const AccountsCashFlowReport({
    required this.period,
    required this.operating,
    required this.investing,
    required this.financing,
    required this.netChange,
    required this.openingBalance,
    required this.closingBalance,
  });

  final String period;
  final List<AccountsReportLine> operating;
  final List<AccountsReportLine> investing;
  final List<AccountsReportLine> financing;
  final double netChange;
  final double openingBalance;
  final double closingBalance;

  factory AccountsCashFlowReport.empty() => const AccountsCashFlowReport(
        period: '',
        operating: [],
        investing: [],
        financing: [],
        netChange: 0,
        openingBalance: 0,
        closingBalance: 0,
      );

  factory AccountsCashFlowReport.fromJson(Map<String, dynamic> json) {
    List<AccountsReportLine> lines(String key) =>
        (json[key] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => AccountsReportLine.fromJson(Map<String, dynamic>.from(e)))
            .toList();
    return AccountsCashFlowReport(
      period: json['period']?.toString() ?? '',
      operating: lines('operating'),
      investing: lines('investing'),
      financing: lines('financing'),
      netChange: _toDouble(json['netChange']),
      openingBalance: _toDouble(json['openingBalance']),
      closingBalance: _toDouble(json['closingBalance']),
    );
  }
}

@immutable
class AccountsServiceRevenueRow {
  const AccountsServiceRevenueRow({
    required this.serviceCategory,
    required this.amount,
    required this.transactionCount,
    required this.percentOfTotal,
  });

  final String serviceCategory;
  final double amount;
  final int transactionCount;
  final double percentOfTotal;

  factory AccountsServiceRevenueRow.fromJson(Map<String, dynamic> json) {
    return AccountsServiceRevenueRow(
      serviceCategory: json['serviceCategory']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      percentOfTotal: _toDouble(json['percentOfTotal']),
    );
  }
}

@immutable
class AccountsExpenseBudgetRow {
  const AccountsExpenseBudgetRow({
    required this.category,
    required this.budget,
    required this.actual,
    required this.variance,
    required this.variancePercent,
  });

  final String category;
  final double budget;
  final double actual;
  final double variance;
  final double variancePercent;

  factory AccountsExpenseBudgetRow.fromJson(Map<String, dynamic> json) {
    return AccountsExpenseBudgetRow(
      category: json['category']?.toString() ?? '',
      budget: _toDouble(json['budget']),
      actual: _toDouble(json['actual']),
      variance: _toDouble(json['variance']),
      variancePercent: _toDouble(json['variancePercent']),
    );
  }
}

@immutable
class AccountsCollectionEfficiencyReport {
  const AccountsCollectionEfficiencyReport({
    required this.period,
    required this.billedAmount,
    required this.collectedAmount,
    required this.collectionRatePercent,
    required this.avgDaysToCollect,
    required this.writeOffAmount,
  });

  final String period;
  final double billedAmount;
  final double collectedAmount;
  final double collectionRatePercent;
  final double avgDaysToCollect;
  final double writeOffAmount;

  factory AccountsCollectionEfficiencyReport.empty() =>
      const AccountsCollectionEfficiencyReport(
        period: '',
        billedAmount: 0,
        collectedAmount: 0,
        collectionRatePercent: 0,
        avgDaysToCollect: 0,
        writeOffAmount: 0,
      );

  factory AccountsCollectionEfficiencyReport.fromJson(
    Map<String, dynamic> json,
  ) {
    return AccountsCollectionEfficiencyReport(
      period: json['period']?.toString() ?? '',
      billedAmount: _toDouble(json['billedAmount']),
      collectedAmount: _toDouble(json['collectedAmount']),
      collectionRatePercent: _toDouble(json['collectionRatePercent']),
      avgDaysToCollect: _toDouble(json['avgDaysToCollect']),
      writeOffAmount: _toDouble(json['writeOffAmount']),
    );
  }
}

@immutable
class AccountsPeriodComparisonPoint {
  const AccountsPeriodComparisonPoint({
    required this.label,
    required this.current,
    required this.previous,
    required this.percentChange,
  });

  final String label;
  final double current;
  final double previous;
  final double percentChange;

  factory AccountsPeriodComparisonPoint.fromJson(Map<String, dynamic> json) {
    return AccountsPeriodComparisonPoint(
      label: json['label']?.toString() ?? '',
      current: _toDouble(json['current']),
      previous: _toDouble(json['previous']),
      percentChange: _toDouble(json['percentChange']),
    );
  }
}

// ── Wallets & reconciliation ───────────────────────────────────────────────

@immutable
class AccountsWalletSummaryRow {
  const AccountsWalletSummaryRow({
    required this.patientId,
    required this.patientName,
    required this.balance,
    required this.lastTransactionAt,
    required this.transactionCount,
  });

  final String patientId;
  final String patientName;
  final double balance;
  final DateTime? lastTransactionAt;
  final int transactionCount;

  factory AccountsWalletSummaryRow.fromJson(Map<String, dynamic> json) {
    return AccountsWalletSummaryRow(
      patientId: json['patientId']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? '',
      balance: _toDouble(json['balance']),
      lastTransactionAt: _parseDate(json['lastTransactionAt']),
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class AccountsWalletsSummary {
  const AccountsWalletsSummary({
    required this.totalFloat,
    required this.activeWallets,
    required this.rows,
  });

  final double totalFloat;
  final int activeWallets;
  final List<AccountsWalletSummaryRow> rows;

  factory AccountsWalletsSummary.empty() => const AccountsWalletsSummary(
        totalFloat: 0,
        activeWallets: 0,
        rows: [],
      );

  factory AccountsWalletsSummary.fromJson(Map<String, dynamic> json) {
    final rows = (json['rows'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map(
          (e) => AccountsWalletSummaryRow.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
    return AccountsWalletsSummary(
      totalFloat: _toDouble(json['totalFloat']),
      activeWallets: (json['activeWallets'] as num?)?.toInt() ?? 0,
      rows: rows,
    );
  }
}

@immutable
class AccountsDailyCashRecon {
  const AccountsDailyCashRecon({
    required this.id,
    required this.date,
    required this.status,
    required this.expectedCash,
    required this.countedCash,
    required this.variance,
    required this.submittedBy,
    required this.closedBy,
    required this.notes,
  });

  final String id;
  final DateTime date;
  final String status;
  final double expectedCash;
  final double countedCash;
  final double variance;
  final String? submittedBy;
  final String? closedBy;
  final String? notes;

  factory AccountsDailyCashRecon.fromJson(Map<String, dynamic> json) {
    return AccountsDailyCashRecon(
      id: json['id']?.toString() ?? '',
      date: _parseDate(json['date']) ?? DateTime.now(),
      status: json['status']?.toString() ?? 'open',
      expectedCash: _toDouble(json['expectedCash']),
      countedCash: _toDouble(json['countedCash']),
      variance: _toDouble(json['variance']),
      submittedBy: json['submittedBy']?.toString(),
      closedBy: json['closedBy']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

@immutable
class AccountsBankReconRow {
  const AccountsBankReconRow({
    required this.id,
    required this.bankName,
    required this.statementDate,
    required this.bookBalance,
    required this.statementBalance,
    required this.variance,
    required this.status,
  });

  final String id;
  final String bankName;
  final DateTime statementDate;
  final double bookBalance;
  final double statementBalance;
  final double variance;
  final String status;

  factory AccountsBankReconRow.fromJson(Map<String, dynamic> json) {
    return AccountsBankReconRow(
      id: json['id']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? '',
      statementDate: _parseDate(json['statementDate']) ?? DateTime.now(),
      bookBalance: _toDouble(json['bookBalance']),
      statementBalance: _toDouble(json['statementBalance']),
      variance: _toDouble(json['variance']),
      status: json['status']?.toString() ?? 'open',
    );
  }
}

// ── Approvals & GL ─────────────────────────────────────────────────────────

@immutable
class AccountsApprovalRequest {
  const AccountsApprovalRequest({
    required this.id,
    required this.type,
    required this.amount,
    required this.requester,
    required this.status,
    required this.submittedAt,
    required this.detail,
    required this.entityRef,
  });

  final String id;
  final String type;
  final double amount;
  final String requester;
  final String status;
  final DateTime submittedAt;
  final String detail;
  final String entityRef;

  factory AccountsApprovalRequest.fromJson(Map<String, dynamic> json) {
    return AccountsApprovalRequest(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      requester: json['requester']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      submittedAt: _parseDate(json['submittedAt']) ?? DateTime.now(),
      detail: json['detail']?.toString() ?? '',
      entityRef: json['entityRef']?.toString() ?? '',
    );
  }
}

@immutable
class AccountsPendingRefundRequest {
  const AccountsPendingRefundRequest({
    required this.id,
    required this.invoiceId,
    required this.invoiceItemId,
    required this.lineDescription,
    required this.lineTotal,
    required this.amountPaid,
    required this.reason,
    required this.requester,
    required this.submittedAt,
    this.invoiceDisplayId,
    this.patientDisplayId,
    this.patientName,
  });

  final String id;
  final String invoiceId;
  final String invoiceItemId;
  final String lineDescription;
  final double lineTotal;
  final double amountPaid;
  final String reason;
  final String requester;
  final DateTime submittedAt;
  final String? invoiceDisplayId;
  final String? patientDisplayId;
  final String? patientName;

  factory AccountsPendingRefundRequest.fromJson(Map<String, dynamic> json) {
    final invoiceRaw = json['invoice'];
    final invoiceMap = invoiceRaw is Map
        ? Map<String, dynamic>.from(invoiceRaw)
        : null;
    final patientRaw = json['patient'] ?? invoiceMap?['patient'];
    final patientMap = patientRaw is Map
        ? Map<String, dynamic>.from(patientRaw)
        : null;
    final itemRaw = json['invoiceItem'] ?? json['item'];
    final itemMap = itemRaw is Map
        ? Map<String, dynamic>.from(itemRaw)
        : null;
    final patientFirst = patientMap?['firstName']?.toString().trim() ?? '';
    final patientLast = patientMap?['lastName']?.toString().trim() ?? '';
    final patientName = [patientFirst, patientLast]
        .where((s) => s.isNotEmpty)
        .join(' ');
    return AccountsPendingRefundRequest(
      id: json['id']?.toString() ?? '',
      invoiceId: json['invoiceId']?.toString() ??
          invoiceMap?['id']?.toString() ??
          '',
      invoiceItemId: json['invoiceItemId']?.toString() ??
          json['itemId']?.toString() ??
          itemMap?['id']?.toString() ??
          '',
      lineDescription: json['lineDescription']?.toString() ??
          json['description']?.toString() ??
          itemMap?['description']?.toString() ??
          '',
      lineTotal: _toDouble(
        json['lineTotal'] ?? itemMap?['lineTotal'] ?? json['amount'],
      ),
      amountPaid: _toDouble(
        json['amountPaid'] ?? itemMap?['amountPaid'],
      ),
      reason: json['reason']?.toString() ?? '',
      requester: json['requester']?.toString() ??
          json['requestedBy']?.toString() ??
          '',
      submittedAt: _parseDate(json['submittedAt']) ?? DateTime.now(),
      invoiceDisplayId: json['invoiceDisplayId']?.toString() ??
          invoiceMap?['invoiceID']?.toString() ??
          invoiceMap?['invoiceId']?.toString(),
      patientDisplayId: json['patientDisplayId']?.toString() ??
          patientMap?['patientId']?.toString(),
      patientName: patientName.isEmpty
          ? json['patientName']?.toString()
          : patientName,
    );
  }
}

@immutable
class AccountsRefundApproveResult {
  const AccountsRefundApproveResult({
    required this.invoiceDeleted,
    required this.invoiceId,
    required this.refundedAmount,
  });

  final bool invoiceDeleted;
  final String invoiceId;
  final double refundedAmount;

  factory AccountsRefundApproveResult.fromJson(Map<String, dynamic> json) {
    return AccountsRefundApproveResult(
      invoiceDeleted: json['invoiceDeleted'] == true,
      invoiceId: json['invoiceId']?.toString() ?? '',
      refundedAmount: _toDouble(json['refundedAmount']),
    );
  }
}

@immutable
class AccountsFiscalPeriod {
  const AccountsFiscalPeriod({
    required this.id,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.closedAt,
    required this.closedBy,
  });

  final String id;
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime? closedAt;
  final String? closedBy;

  factory AccountsFiscalPeriod.fromJson(Map<String, dynamic> json) {
    return AccountsFiscalPeriod(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      startDate: _parseDate(json['startDate']) ?? DateTime.now(),
      endDate: _parseDate(json['endDate']) ?? DateTime.now(),
      status: json['status']?.toString() ?? 'open',
      closedAt: _parseDate(json['closedAt']),
      closedBy: json['closedBy']?.toString(),
    );
  }
}

@immutable
class AccountsJournalEntry {
  const AccountsJournalEntry({
    required this.id,
    required this.entryDate,
    required this.reference,
    required this.description,
    required this.debitAccount,
    required this.creditAccount,
    required this.amount,
    required this.postedBy,
    required this.status,
  });

  final String id;
  final DateTime entryDate;
  final String reference;
  final String description;
  final String debitAccount;
  final String creditAccount;
  final double amount;
  final String postedBy;
  final String status;

  factory AccountsJournalEntry.fromJson(Map<String, dynamic> json) {
    return AccountsJournalEntry(
      id: json['id']?.toString() ?? '',
      entryDate: _parseDate(json['entryDate']) ?? DateTime.now(),
      reference: json['reference']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      debitAccount: json['debitAccount']?.toString() ?? '',
      creditAccount: json['creditAccount']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      postedBy: json['postedBy']?.toString() ?? '',
      status: json['status']?.toString() ?? 'posted',
    );
  }
}

@immutable
class AccountsChartAccount {
  const AccountsChartAccount({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.isActive,
    required this.balance,
  });

  final String id;
  final String code;
  final String name;
  final String type;
  final bool isActive;
  final double balance;

  factory AccountsChartAccount.fromJson(Map<String, dynamic> json) {
    return AccountsChartAccount(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      isActive: json['isActive'] != false,
      balance: _toDouble(json['balance']),
    );
  }
}

/// Period filter shared across accounts screens.
@immutable
class AccountsPeriodFilter {
  const AccountsPeriodFilter({required this.period, this.asOf});

  final String period;
  final DateTime? asOf;

  static const periods = ['today', 'week', 'month', 'quarter', 'year'];

  static String labelFor(String period) {
    switch (period) {
      case 'today':
        return 'Today';
      case 'week':
        return 'This week';
      case 'month':
        return 'This month';
      case 'quarter':
        return 'This quarter';
      case 'year':
        return 'This year';
      default:
        return period;
    }
  }
}
