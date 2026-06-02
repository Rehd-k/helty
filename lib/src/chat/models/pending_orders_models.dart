enum PendingOrdersDomain { lab, radiology, drug, unknown }

extension PendingOrdersDomainX on PendingOrdersDomain {
  static PendingOrdersDomain fromApi(String? raw) {
    switch (raw?.trim().toUpperCase()) {
      case 'LAB':
        return PendingOrdersDomain.lab;
      case 'RADIOLOGY':
        return PendingOrdersDomain.radiology;
      case 'DRUG':
        return PendingOrdersDomain.drug;
      default:
        return PendingOrdersDomain.unknown;
    }
  }
}

class PendingOrdersTick {
  const PendingOrdersTick({required this.tickAt, required this.items});

  final DateTime? tickAt;
  final List<PendingOrdersItem> items;

  static PendingOrdersTick? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final rawItems = json['items'];
    if (rawItems is! List)
      return const PendingOrdersTick(tickAt: null, items: []);
    final items = <PendingOrdersItem>[];
    for (final entry in rawItems) {
      if (entry is! Map) continue;
      final parsed = PendingOrdersItem.tryParse(
        Map<String, dynamic>.from(entry),
      );
      if (parsed != null) items.add(parsed);
    }
    return PendingOrdersTick(tickAt: _parseDate(json['tickAt']), items: items);
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is! String || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class PendingOrdersItem {
  const PendingOrdersItem({
    required this.notificationKey,
    required this.domain,
    required this.status,
    required this.eventAt,
    required this.title,
    required this.body,
  });

  final String notificationKey;
  final PendingOrdersDomain domain;
  final String status;
  final DateTime? eventAt;
  final String title;
  final String body;

  static PendingOrdersItem? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final key = json['notificationKey']?.toString().trim() ?? '';
    if (key.isEmpty) return null;
    return PendingOrdersItem(
      notificationKey: key,
      domain: PendingOrdersDomainX.fromApi(json['domain']?.toString()),
      status: json['status']?.toString().trim() ?? '',
      eventAt: PendingOrdersTick._parseDate(json['eventAt']),
      title: json['title']?.toString().trim() ?? '',
      body: json['body']?.toString().trim() ?? '',
    );
  }

  PendingNotificationState toNotificationState() {
    return PendingNotificationState(
      notificationKey: notificationKey,
      domain: domain,
      status: status,
      title: title.isEmpty ? _fallbackTitle(domain) : title,
      body: body.isEmpty ? 'Pending order requires attention.' : body,
    );
  }

  static String _fallbackTitle(PendingOrdersDomain domain) {
    switch (domain) {
      case PendingOrdersDomain.lab:
        return 'Lab order pending';
      case PendingOrdersDomain.radiology:
        return 'Radiology order pending';
      case PendingOrdersDomain.drug:
        return 'Drug not dispensed';
      case PendingOrdersDomain.unknown:
        return 'Pending order';
    }
  }
}

class PendingNotificationState {
  const PendingNotificationState({
    required this.notificationKey,
    required this.domain,
    required this.status,
    required this.title,
    required this.body,
  });

  final String notificationKey;
  final PendingOrdersDomain domain;
  final String status;
  final String title;
  final String body;

  bool isMeaningfullyDifferent(PendingNotificationState other) {
    return domain != other.domain ||
        status != other.status ||
        title != other.title ||
        body != other.body;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'notificationKey': notificationKey,
      'domain': domain.name.toUpperCase(),
      'status': status,
      'title': title,
      'body': body,
    };
  }

  static PendingNotificationState fromJson(Map<String, dynamic> json) {
    return PendingNotificationState(
      notificationKey: json['notificationKey']?.toString().trim() ?? '',
      domain: PendingOrdersDomainX.fromApi(json['domain']?.toString()),
      status: json['status']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? '',
      body: json['body']?.toString().trim() ?? '',
    );
  }
}

bool isDateInLocalToday(DateTime? utcLikeTimestamp) {
  if (utcLikeTimestamp == null) return false;
  final local = utcLikeTimestamp.toLocal();
  final now = DateTime.now();
  return local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
}
