/// OPD consultation visit bundle (paid line → up to 2 visits in 14 days).
class ConsultationCredit {
  const ConsultationCredit({
    required this.invoiceItemId,
    required this.invoiceId,
    required this.invoiceDisplayId,
    required this.serviceName,
    required this.visitsConsumed,
    required this.visitsRemaining,
    this.expiresAt,
    this.expired = false,
    this.settled = false,
    this.consumable = false,
  });

  final String invoiceItemId;
  final String invoiceId;
  final String invoiceDisplayId;
  final String serviceName;
  final int visitsConsumed;
  final int visitsRemaining;
  final DateTime? expiresAt;
  final bool expired;
  final bool settled;
  final bool consumable;

  bool get isExpired {
    if (expired) return true;
    final exp = expiresAt;
    if (exp == null) return false;
    return exp.isBefore(DateTime.now());
  }

  factory ConsultationCredit.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v ?? '').toString();

    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      if (value is DateTime) return value;
      return null;
    }

    int parseInt(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    return ConsultationCredit(
      invoiceItemId: str(json['invoiceItemId']),
      invoiceId: str(json['invoiceId']),
      invoiceDisplayId: str(json['invoiceID'] ?? json['invoiceDisplayId']),
      serviceName: str(json['serviceName']),
      visitsConsumed: parseInt(json['visitsConsumed']),
      visitsRemaining: parseInt(json['visitsRemaining']),
      expiresAt: parseDate(json['expiresAt']),
      expired: json['expired'] == true,
      settled: json['settled'] == true,
      consumable: json['consumable'] == true,
    );
  }
}

class ConsultationCreditsResponse {
  const ConsultationCreditsResponse({required this.credits});

  final List<ConsultationCredit> credits;

  factory ConsultationCreditsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['credits'];
    final list = raw is List ? raw : const [];
    return ConsultationCreditsResponse(
      credits: list
          .whereType<Map>()
          .map((e) => ConsultationCredit.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
    );
  }
}

/// One consultation line on a waiting-patient queue row.
class ConsultationServiceLine {
  const ConsultationServiceLine({
    required this.name,
    this.invoiceItemId,
    this.visitsConsumed = 0,
    this.visitsRemaining = 0,
    this.expiresAt,
    this.settled = false,
    this.consumable = false,
  });

  final String name;
  final String? invoiceItemId;
  final int visitsConsumed;
  final int visitsRemaining;
  final DateTime? expiresAt;
  final bool settled;
  final bool consumable;

  bool get isExpired {
    final exp = expiresAt;
    if (exp == null) return false;
    return exp.isBefore(DateTime.now());
  }

  bool get hasCreditMetadata =>
      visitsRemaining > 0 ||
      visitsConsumed > 0 ||
      expiresAt != null ||
      settled;

  factory ConsultationServiceLine.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v ?? '').toString();

    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      if (value is DateTime) return value;
      return null;
    }

    int parseInt(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    final name = str(json['name'] ?? json['serviceName']).trim();
    final itemId = str(json['invoiceItemId']);
    final consumed = parseInt(
      json['consultationVisitsConsumed'] ?? json['visitsConsumed'],
    );
    final expiresAt = parseDate(
      json['consultationCreditExpiresAt'] ?? json['expiresAt'],
    );
    final settled = json['settled'] == true;
    final hasRemainingKey =
        json.containsKey('visitsRemaining') &&
        json['visitsRemaining'] != null;
    final visitsRemaining = hasRemainingKey
        ? parseInt(json['visitsRemaining'])
        : (2 - consumed).clamp(0, 2);
    final expiredFlag = json['expired'] == true;
    final expired = expiredFlag ||
        (expiresAt != null && !expiresAt.isAfter(DateTime.now()));
    final consumable = json['consumable'] == true ||
        (!settled && visitsRemaining > 0 && !expired);

    return ConsultationServiceLine(
      name: name.isEmpty ? 'Consultation' : name,
      invoiceItemId: itemId.isEmpty ? null : itemId,
      visitsConsumed: consumed,
      visitsRemaining: visitsRemaining,
      expiresAt: expiresAt,
      settled: settled,
      consumable: consumable && !settled,
    );
  }
}
