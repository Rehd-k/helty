import 'package:helty/src/core/utils/api_decimal.dart';

import 'consultation_credit_model.dart';
import 'consultation_credit_utils.dart';
import 'invoice.dart';

/// Lightweight row for paid invoices eligible for frontdesk re-enlist / OPD credit.
class PaidWithoutEncounterInvoice {
  const PaidWithoutEncounterInvoice({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.displayBillId,
    required this.serviceNames,
    required this.status,
    required this.totalAmount,
    required this.amountPaid,
    this.encounterId,
    this.createdAt,
    this.consultationServices = const [],
  });

  final String id;
  final String patientId;
  final String patientName;
  final String displayBillId;
  final List<String> serviceNames;
  final String status;
  final double totalAmount;
  final double amountPaid;
  final String? encounterId;
  final DateTime? createdAt;
  final List<ConsultationServiceLine> consultationServices;

  ConsultationServiceLine? get primaryConsultationCredit {
    for (final line in consultationServices) {
      if (line.consumable) return line;
    }
    if (consultationServices.isEmpty) return null;
    return consultationServices.first;
  }

  bool get hasEncounter =>
      encounterId != null && encounterId!.trim().isNotEmpty;

  bool get appearsPaid {
    final s = status.toUpperCase();
    if (s == 'PAID' || s == 'COMPLETED' || s == 'SETTLED') return true;
    if (totalAmount <= 0) return amountPaid > 0;
    return amountPaid >= totalAmount - 0.01;
  }

  bool get canReEnlist => appearsPaid && !hasEncounter;

  String get billLabel {
    final d = displayBillId.trim();
    if (d.isNotEmpty) return d;
    if (id.length <= 12) return id;
    return '${id.substring(0, 8)}…';
  }

  String get servicesLabel =>
      serviceNames.isEmpty ? '—' : serviceNames.join(', ');

  factory PaidWithoutEncounterInvoice.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v ?? '').toString();

    final patientRaw = json['patient'];
    final patientMap = patientRaw is Map<String, dynamic>
        ? patientRaw
        : patientRaw is Map
        ? Map<String, dynamic>.from(patientRaw)
        : null;

    final printed = str(json['patientName']).trim();
    String patientName = printed;
    if (patientName.isEmpty && patientMap != null) {
      final fn = str(
        patientMap['firstName'] ?? patientMap['firstname'],
      ).trim();
      final sn = str(patientMap['surname']).trim();
      patientName = '$fn $sn'.trim();
    }

    final patientId = str(
      json['patientId'] ?? patientMap?['patientId'] ?? patientMap?['id'],
    );

    final displayBill = str(
      json['invoiceID'] ?? json['invoiceId'] ?? json['invoiceDisplayId'],
    ).trim();

    final items =
        (json['invoiceItems'] as List?) ??
        (json['items'] as List?) ??
        (json['services'] as List?) ??
        const [];
    final serviceNames = <String>[];
    for (final e in items) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final service = m['service'];
      final name = str(
        m['name'] ??
            m['serviceName'] ??
            (service is Map ? service['name'] : null),
      ).trim();
      if (name.isNotEmpty) serviceNames.add(name);
    }

    double parseAmount(dynamic v) => parseApiDecimal(v);

    double total = parseAmount(json['totalAmount'] ?? json['total']);
    if (total <= 0 && items.isNotEmpty) {
      for (final e in items) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final cost = parseAmount(m['cost'] ?? m['price'] ?? m['amount']);
        final qty = parseAmount(m['qty'] ?? m['quantity'] ?? 1);
        total += cost * (qty <= 0 ? 1 : qty);
      }
    }

    DateTime? createdAt;
    final createdRaw = json['createdAt'] ?? json['date'];
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw);
    }

    final invoiceMap = Map<String, dynamic>.from(json);
    final consultationServices = consultationLinesFromInvoice(invoiceMap);

    return PaidWithoutEncounterInvoice(
      id: str(json['id']),
      patientId: patientId,
      patientName: patientName.isEmpty ? '—' : patientName,
      displayBillId: displayBill,
      serviceNames: serviceNames,
      status: str(json['status']),
      totalAmount: total,
      amountPaid: parseAmount(json['amountPaid'] ?? json['paidAmount']),
      encounterId: str(json['encounterId']).isEmpty
          ? null
          : str(json['encounterId']),
      createdAt: createdAt,
      consultationServices: consultationServices,
    );
  }

  factory PaidWithoutEncounterInvoice.fromInvoice(Invoice invoice) {
    final p = invoice.patient;
    final name = p.displayName.trim();
    final services = invoice.invoiceItems
        .map((i) => i.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    final display = strFromInvoiceDisplay(invoice);

    final invoiceJson = <String, dynamic>{
      'status': invoice.status,
      'encounterId': invoice.encounterId,
      'invoiceItems': invoice.invoiceItems
          .map((i) => {'name': i.name, 'serviceName': i.name})
          .toList(),
    };

    return PaidWithoutEncounterInvoice(
      id: invoice.id,
      patientId: invoice.patientId,
      patientName: name.isEmpty ? '—' : name,
      displayBillId: display,
      serviceNames: services,
      status: invoice.status,
      totalAmount: invoice.total,
      amountPaid: invoice.amountPaid,
      encounterId: invoice.encounterId,
      createdAt: invoice.createdAt,
      consultationServices: consultationLinesFromInvoice(invoiceJson),
    );
  }

  static String strFromInvoiceDisplay(Invoice invoice) {
    return invoice.id;
  }
}

/// Paginated response from GET /invoices/paid-without-encounter (queue mode).
class PaginatedPaidWithoutEncounterInvoices {
  const PaginatedPaidWithoutEncounterInvoices({
    required this.invoices,
    required this.total,
    this.skip = 0,
    this.take = 20,
  });

  final List<PaidWithoutEncounterInvoice> invoices;
  final int total;
  final int skip;
  final int take;

  bool get hasMore => skip + invoices.length < total;
}
