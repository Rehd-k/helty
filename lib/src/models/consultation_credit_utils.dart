import 'consultation_credit_model.dart';

/// Matches backend `CONSULTATION_CREDIT_MAX_VISITS`.
const int consultationCreditMaxVisits = 2;

/// Client-side credit state derived from an invoice line + invoice header.
class DerivedConsultationCredit {
  const DerivedConsultationCredit({
    required this.name,
    this.invoiceItemId,
    required this.visitsConsumed,
    required this.visitsRemaining,
    this.expiresAt,
    required this.settled,
    required this.expired,
    required this.consumable,
  });

  final String name;
  final String? invoiceItemId;
  final int visitsConsumed;
  final int visitsRemaining;
  final DateTime? expiresAt;
  final bool settled;
  final bool expired;
  final bool consumable;

  ConsultationServiceLine toServiceLine() => ConsultationServiceLine(
        name: name,
        invoiceItemId: invoiceItemId,
        visitsConsumed: visitsConsumed,
        visitsRemaining: visitsRemaining,
        expiresAt: expiresAt,
        settled: settled,
        consumable: consumable,
      );
}

int _parseInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  if (value is DateTime) return value;
  return null;
}

String _str(dynamic v) => (v ?? '').toString();

bool _invoiceAppearsPaid(Map<String, dynamic> invoice) {
  final status = _str(invoice['status']).toUpperCase();
  if (status == 'PAID' || status == 'COMPLETED' || status == 'SETTLED') {
    return true;
  }
  return false;
}

String? _lineName(Map<String, dynamic> item) {
  final service = item['service'];
  final name = _str(
    item['name'] ??
        item['serviceName'] ??
        (service is Map ? service['name'] : null),
  ).trim();
  return name.isEmpty ? null : name;
}

/// Derives consumable credit from one invoice line per docs/consultation-credit-frontend.md.
DerivedConsultationCredit? deriveConsultationLineFromInvoiceItem(
  Map<String, dynamic> item, {
  String? encounterId,
  bool invoicePaid = true,
  DateTime? now,
}) {
  final name = _lineName(item);
  if (name == null) return null;

  final consumed = _parseInt(
    item['consultationVisitsConsumed'] ?? item['visitsConsumed'],
  );
  final expiresAt = _parseDate(
    item['consultationCreditExpiresAt'] ?? item['expiresAt'],
  );
  final settled = item['settled'] == true;

  var visitsRemaining = item.containsKey('visitsRemaining')
      ? _parseInt(item['visitsRemaining'])
      : (consultationCreditMaxVisits - consumed).clamp(0, consultationCreditMaxVisits);

  final clock = now ?? DateTime.now();
  final expired =
      expiresAt != null && !expiresAt.isAfter(clock);

  final hasEncounter =
      encounterId != null && encounterId.trim().isNotEmpty;

  final consumable = invoicePaid &&
      !hasEncounter &&
      !settled &&
      visitsRemaining > 0 &&
      expiresAt != null &&
      !expired;

  return DerivedConsultationCredit(
    name: name,
    invoiceItemId: _str(item['invoiceItemId'] ?? item['id']).trim().isEmpty
        ? null
        : _str(item['invoiceItemId'] ?? item['id']),
    visitsConsumed: consumed,
    visitsRemaining: visitsRemaining,
    expiresAt: expiresAt,
    settled: settled,
    expired: expired,
    consumable: consumable,
  );
}

/// All consultation lines on an invoice (with derived credit metadata).
List<ConsultationServiceLine> consultationLinesFromInvoice(
  Map<String, dynamic> invoiceJson,
) {
  final encounterId = _str(invoiceJson['encounterId']);
  final paid = _invoiceAppearsPaid(invoiceJson);
  final items =
      (invoiceJson['invoiceItems'] as List?) ??
      (invoiceJson['items'] as List?) ??
      const [];

  final lines = <ConsultationServiceLine>[];
  for (final e in items) {
    if (e is! Map) continue;
    final derived = deriveConsultationLineFromInvoiceItem(
      Map<String, dynamic>.from(e),
      encounterId: encounterId.isEmpty ? null : encounterId,
      invoicePaid: paid,
    );
    if (derived != null) lines.add(derived.toServiceLine());
  }
  return lines;
}

/// First consumable consultation line (FIFO — oldest invoice item order).
ConsultationServiceLine? primaryConsultationLineFromInvoice(
  Map<String, dynamic> invoiceJson,
) {
  final lines = consultationLinesFromInvoice(invoiceJson);
  for (final line in lines) {
    if (line.consumable) return line;
  }
  return lines.isEmpty ? null : lines.first;
}

/// Maps documented OPD start 400 messages to user-facing copy.
String mapOutpatientStartError(String message) {
  final m = message.trim();
  switch (m) {
    case 'No paid consultation invoice is on file for this patient.':
      return 'No paid consultation is on file. Send the patient to billing first.';
    case 'A consultation is already in progress for this patient.':
      return 'A consultation is already in progress for this patient.';
    case 'The consultation payment has expired (valid for 14 days after payment).':
      return 'Consultation payment expired (valid 14 days after payment).';
    case 'The consultation payment has already been used for the maximum number of visits (2).':
      return 'All consultation visits on this payment have been used.';
    case 'No paid consultation credit is currently available for this patient.':
      return 'No consultation credit is available right now.';
    default:
      return m.isEmpty ? 'Could not start outpatient encounter.' : m;
  }
}
