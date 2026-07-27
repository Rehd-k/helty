import '../core/utils/patient_initials.dart';
import 'consultation_credit_model.dart';
import 'consultation_credit_utils.dart';

/// Row from `GET /invoices/by-service-categories`.
class InvoiceByServiceCategoryRow {
  const InvoiceByServiceCategoryRow({
    required this.invoiceId,
    required this.displayBillId,
    required this.patientName,
    required this.firstName,
    required this.surname,
    required this.serviceNames,
    required this.appearsPaid,
    required this.dateTime,
    this.patientId,
    this.invoiceStatus,
    this.avatarUrl,
    this.consultationServices = const [],
  });

  final String invoiceId;
  final String displayBillId;
  final String? patientId;
  final String patientName;
  final String firstName;
  final String surname;
  final List<String> serviceNames;
  final String? invoiceStatus;
  final bool appearsPaid;
  final DateTime dateTime;
  final String? avatarUrl;
  final List<ConsultationServiceLine> consultationServices;

  bool get hasPatientId => (patientId ?? '').trim().isNotEmpty;

  bool get isPaid => appearsPaid;

  String get billLabel {
    final d = displayBillId.trim();
    if (d.isNotEmpty) return d;
    if (invoiceId.length <= 12) {
      return invoiceId.isEmpty ? '—' : invoiceId;
    }
    return '${invoiceId.substring(0, 8)}…';
  }

  String get servicesLabel =>
      serviceNames.isEmpty ? '—' : serviceNames.join(', ');

  ConsultationServiceLine? get primaryConsultationCredit {
    for (final line in consultationServices) {
      if (line.consumable) return line;
    }
    if (consultationServices.isEmpty) return null;
    return consultationServices.first;
  }

  factory InvoiceByServiceCategoryRow.fromJson(Map<String, dynamic> json) {
    final invoice = _asMap(json['invoice']);
    final root = invoice ?? json;
    final patient = _asMap(json['patient']) ?? _asMap(root['patient']);

    final patientNameSingle =
        json['patientName']?.toString() ?? root['patientName']?.toString();
    final printed = patientNameSingle?.trim();
    final (splitFirst, splitSurname) =
        printed != null && printed.isNotEmpty
        ? _namesFromPatientName(printed)
        : ('', '');

    final rawServices =
        (root['invoiceItems'] as List?) ??
        (root['services'] as List?) ??
        (json['services'] as List?) ??
        (json['items'] as List?) ??
        (json['invoiceItems'] as List?) ??
        const [];

    final names = <String>[];
    for (final e in rawServices) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final n = _serviceLineName(m);
      if (n != null) names.add(n);
    }

    final invoiceUuid = root['id']?.toString().trim() ?? '';
    final legacyTxn =
        json['transactionID']?.toString() ?? json['transactionId']?.toString();
    final topInvoiceId =
        json['invoiceId']?.toString().trim() ??
        root['invoiceId']?.toString().trim() ??
        '';

    final resolvedId = invoiceUuid.isNotEmpty
        ? invoiceUuid
        : (legacyTxn != null && legacyTxn.toString().trim().isNotEmpty
              ? legacyTxn.toString().trim()
              : topInvoiceId);

    final displayBill =
        root['invoiceID']?.toString() ??
        root['invoiceId']?.toString() ??
        json['invoiceID']?.toString() ??
        json['invoiceId']?.toString();
    final displayTrimmed = displayBill?.toString().trim();
    final displayResolved =
        (displayTrimmed != null && displayTrimmed.isNotEmpty)
        ? displayTrimmed
        : (topInvoiceId.isNotEmpty ? topInvoiceId : '');

    final sn =
        (patient?['surname'] ?? root['surname'] ?? json['surname'])
            ?.toString() ??
        '';
    final fn =
        (patient?['firstName'] ??
                patient?['firstname'] ??
                root['firstName'] ??
                root['firstname'] ??
                json['firstname'] ??
                json['firstName'])
            ?.toString() ??
        '';

    final surname = sn.isNotEmpty ? sn : splitSurname;
    final firstName = fn.isNotEmpty ? fn : splitFirst;

    final combinedName = '$firstName $surname'.trim();
    final patientName = (printed != null && printed.isNotEmpty)
        ? printed
        : (combinedName.isNotEmpty ? combinedName : '—');

    final dtString =
        json['date']?.toString() ??
        root['date']?.toString() ??
        root['createdAt']?.toString() ??
        root['updatedAt']?.toString() ??
        json['createdAt']?.toString() ??
        json['datetime']?.toString();

    final status =
        (root['status'] ??
                json['status'] ??
                root['invoiceStatus'] ??
                json['invoiceStatus'] ??
                root['paymentStatus'] ??
                json['paymentStatus'])
            ?.toString();

    final appearsPaid = _computeAppearsPaid(root, json, rawServices);

    final invoiceMap = Map<String, dynamic>.from(root);
    final consultationServices = consultationLinesFromInvoice(invoiceMap);

    return InvoiceByServiceCategoryRow(
      invoiceId: resolvedId,
      displayBillId: displayResolved,
      patientId: _firstNonEmptyId(
        json['patientId'],
        root['patientId'],
        patient?['id'],
      ),
      patientName: patientName,
      firstName: firstName,
      surname: surname,
      serviceNames: names,
      invoiceStatus: status,
      appearsPaid: appearsPaid,
      dateTime: dtString != null
          ? DateTime.tryParse(dtString) ?? DateTime.now()
          : DateTime.now(),
      avatarUrl: avatarUrlFromJson(patient) ?? avatarUrlFromJson(json),
      consultationServices: consultationServices,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static (String firstName, String surname) _namesFromPatientName(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return ('', '');
    final parts = s.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return (parts[0], '');
    final surname = parts.last;
    final firstName = parts.sublist(0, parts.length - 1).join(' ');
    return (firstName, surname);
  }

  static String? _firstNonEmptyId(dynamic a, dynamic b, dynamic c) {
    for (final v in [a, b, c]) {
      final t = v?.toString().trim() ?? '';
      if (t.isNotEmpty) return t;
    }
    return null;
  }

  static double? _parseMoney(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim());
  }

  static String? _serviceLineName(Map<String, dynamic> item) {
    final custom = item['customDescription']?.toString().trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final svc = _asMap(item['service']);
    final name = (svc?['name'] ?? item['name'] ?? item['serviceName'])
        ?.toString()
        .trim();
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  /// Backend list payloads often omit top-level `status`; infer from amounts / lines.
  static bool _computeAppearsPaid(
    Map<String, dynamic> root,
    Map<String, dynamic> json,
    List<dynamic> rawServices,
  ) {
    final status =
        (root['status'] ??
                json['status'] ??
                root['invoiceStatus'] ??
                json['invoiceStatus'] ??
                root['paymentStatus'] ??
                json['paymentStatus'])
            ?.toString()
            .trim()
            .toUpperCase() ??
        '';
    if (status == 'PENDING' ||
        status == 'UNPAID' ||
        status == 'PARTIAL' ||
        status == 'OVERDUE') {
      return false;
    }
    if (status == 'PAID' || status == 'FULLY_PAID') return true;
    if (json['isPaid'] == true || root['isPaid'] == true) return true;
    if (json['fullyPaid'] == true || root['fullyPaid'] == true) return true;

    final due = _parseMoney(
      root['amountDue'] ??
          json['amountDue'] ??
          root['netAmountDue'] ??
          json['netAmountDue'] ??
          root['balanceDue'] ??
          json['balanceDue'],
    );
    if (due != null && due <= 0) return true;

    if (rawServices.isEmpty) return false;
    for (final e in rawServices) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final unit = _parseMoney(m['unitPrice']) ?? 0;
      final qtyRaw = m['quantity'];
      final qty = qtyRaw is num
          ? qtyRaw.toDouble()
          : (_parseMoney(qtyRaw) ?? 1.0);
      final lineTotal = unit * qty;
      final paid = _parseMoney(m['amountPaid']) ?? 0;
      if (lineTotal > 0 && paid + 1e-6 < lineTotal) return false;
    }
    return rawServices.isNotEmpty;
  }
}
