import 'package:helty/src/core/utils/patient_display_name.dart';

class InvestigationBreakdownRow {
  const InvestigationBreakdownRow({
    required this.testName,
    required this.count,
    required this.amount,
  });

  final String testName;
  final int count;
  final num amount;

  factory InvestigationBreakdownRow.fromJson(Map<String, dynamic> json) {
    return InvestigationBreakdownRow(
      testName: json['testName']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?) ?? 0,
    );
  }
}

class InvestigationDepartmentBreakdownRow {
  const InvestigationDepartmentBreakdownRow({
    required this.departmentId,
    required this.departmentName,
    required this.count,
    required this.amount,
  });

  final String departmentId;
  final String departmentName;
  final int count;
  final num amount;

  factory InvestigationDepartmentBreakdownRow.fromJson(
    Map<String, dynamic> json,
  ) {
    return InvestigationDepartmentBreakdownRow(
      departmentId: json['departmentId']?.toString() ?? '',
      departmentName: json['departmentName']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?) ?? 0,
    );
  }
}

class InvestigationSummary {
  const InvestigationSummary({
    this.fromDate,
    this.toDate,
    this.totalCount = 0,
    this.totalAmount = 0,
    this.sampleCollectedCount,
    this.samplePendingCount,
    this.byTestName = const [],
    this.byDepartment = const [],
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final int totalCount;
  final num totalAmount;
  final int? sampleCollectedCount;
  final int? samplePendingCount;
  final List<InvestigationBreakdownRow> byTestName;
  final List<InvestigationDepartmentBreakdownRow> byDepartment;

  factory InvestigationSummary.fromJson(Map<String, dynamic> json) {
    return InvestigationSummary(
      fromDate: _parseDate(json['fromDate']),
      toDate: _parseDate(json['toDate']),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?) ?? 0,
      sampleCollectedCount: (json['sampleCollectedCount'] as num?)?.toInt(),
      samplePendingCount: (json['samplePendingCount'] as num?)?.toInt(),
      byTestName: _parseBreakdown(json['byTestName']),
      byDepartment: _parseDepartmentBreakdown(json['byDepartment']),
    );
  }
}

class InvestigationPatientRef {
  const InvestigationPatientRef({
    required this.id,
    this.patientId,
    this.title,
    this.firstName,
    this.otherName,
    this.surname,
  });

  final String id;
  final String? patientId;
  final String? title;
  final String? firstName;
  final String? otherName;
  final String? surname;

  String get displayName => patientDisplayNameFromJson({
        'title': title,
        'firstName': firstName,
        'otherName': otherName,
        'surname': surname,
      });

  factory InvestigationPatientRef.fromJson(Map<String, dynamic> json) {
    return InvestigationPatientRef(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString(),
      title: json['title']?.toString(),
      firstName: json['firstName']?.toString(),
      otherName: json['otherName']?.toString(),
      surname: (json['surname'] ?? json['lastName'])?.toString(),
    );
  }
}

class InvestigationInvoiceRef {
  const InvestigationInvoiceRef({
    required this.id,
    this.invoiceID,
    this.status,
  });

  final String id;
  final String? invoiceID;
  final String? status;

  factory InvestigationInvoiceRef.fromJson(Map<String, dynamic> json) {
    return InvestigationInvoiceRef(
      id: json['id']?.toString() ?? '',
      invoiceID: json['invoiceID']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

class InvestigationDepartmentRef {
  const InvestigationDepartmentRef({required this.id, this.name});

  final String id;
  final String? name;

  factory InvestigationDepartmentRef.fromJson(Map<String, dynamic> json) {
    return InvestigationDepartmentRef(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
    );
  }
}

class InvestigationListRow {
  const InvestigationListRow({
    required this.source,
    required this.id,
    required this.testName,
    required this.status,
    required this.amount,
    this.quantity = 1,
    this.patientName,
    this.patient,
    this.department,
    this.invoice,
    this.createdAt,
    this.sampleCollected,
    this.sampleCollectedAt,
    this.priority,
  });

  final String source;
  final String id;
  final String testName;
  final String status;
  final num amount;
  final int quantity;
  final String? patientName;
  final InvestigationPatientRef? patient;
  final InvestigationDepartmentRef? department;
  final InvestigationInvoiceRef? invoice;
  final DateTime? createdAt;
  final bool? sampleCollected;
  final DateTime? sampleCollectedAt;
  final String? priority;

  String get resolvedPatientName {
    final printed = patientName?.trim();
    if (printed != null && printed.isNotEmpty) return printed;
    return patient?.displayName ?? '—';
  }

  factory InvestigationListRow.fromJson(Map<String, dynamic> json) {
    return InvestigationListRow(
      source: json['source']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      testName: json['testName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      amount: (json['amount'] as num?) ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      patientName: json['patientName']?.toString(),
      patient: json['patient'] is Map<String, dynamic>
          ? InvestigationPatientRef.fromJson(
              json['patient'] as Map<String, dynamic>,
            )
          : null,
      department: json['department'] is Map<String, dynamic>
          ? InvestigationDepartmentRef.fromJson(
              json['department'] as Map<String, dynamic>,
            )
          : null,
      invoice: json['invoice'] is Map<String, dynamic>
          ? InvestigationInvoiceRef.fromJson(
              json['invoice'] as Map<String, dynamic>,
            )
          : null,
      createdAt: _parseDate(json['createdAt']),
      sampleCollected: json['sampleCollected'] as bool?,
      sampleCollectedAt: _parseDate(json['sampleCollectedAt']),
      priority: json['priority']?.toString(),
    );
  }
}

class InvestigationListResponse {
  const InvestigationListResponse({
    this.data = const [],
    this.total = 0,
    this.skip = 0,
    this.take = 20,
  });

  final List<InvestigationListRow> data;
  final int total;
  final int skip;
  final int take;

  factory InvestigationListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final rows = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => InvestigationListRow.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <InvestigationListRow>[];

    return InvestigationListResponse(
      data: rows,
      total: (json['total'] as num?)?.toInt() ?? rows.length,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      take: (json['take'] as num?)?.toInt() ?? 20,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

List<InvestigationBreakdownRow> _parseBreakdown(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => InvestigationBreakdownRow.fromJson(
            Map<String, dynamic>.from(e),
          ))
      .toList();
}

List<InvestigationDepartmentBreakdownRow> _parseDepartmentBreakdown(
  dynamic raw,
) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => InvestigationDepartmentBreakdownRow.fromJson(
            Map<String, dynamic>.from(e),
          ))
      .toList();
}
