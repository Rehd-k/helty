/// Requester / staff snapshot on a ticket (`createdBy` from API).
class TicketRequester {
  const TicketRequester({
    required this.id,
    this.staffId = '',
    this.firstName = '',
    this.lastName = '',
  });

  final String id;
  final String staffId;
  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName'.trim();

  static TicketRequester? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final id = m['id']?.toString();
    if (id == null || id.isEmpty) return null;
    return TicketRequester(
      id: id,
      staffId: m['staffId']?.toString() ?? '',
      firstName: m['firstName'] as String? ?? '',
      lastName: m['lastName'] as String? ?? '',
    );
  }
}

/// One assignment row on a ticket (`assignments` from API).
class TicketAssignment {
  const TicketAssignment({
    required this.staffUuid,
    this.staff,
  });

  /// Backend UUID of the assigned staff member (matches [AssignTicketDto.staffId]).
  final String staffUuid;
  final TicketRequester? staff;

  static TicketAssignment? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    String? uuid = m['staffId']?.toString() ?? m['assignedToId']?.toString();
    final nested = m['staff'];
    if ((uuid == null || uuid.isEmpty) && nested is Map) {
      uuid = nested['id']?.toString();
    }
    if (uuid == null || uuid.isEmpty) return null;
    return TicketAssignment(
      staffUuid: uuid,
      staff: TicketRequester.tryParse(nested),
    );
  }

  static List<TicketAssignment> parseList(dynamic raw) {
    if (raw is! List) return const [];
    final out = <TicketAssignment>[];
    for (final e in raw) {
      final a = tryParse(e);
      if (a != null) out.add(a);
    }
    return out;
  }
}

class SupportTicketSummary {
  const SupportTicketSummary({
    required this.id,
    required this.title,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.createdById,
    this.createdBy,
    this.assignments = const [],
  });

  final String id;
  final String title;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdById;
  final TicketRequester? createdBy;
  final List<TicketAssignment> assignments;

  /// Stable key for grouping by requester (super admin list).
  String get requesterGroupKey =>
      createdBy?.id ?? createdById ?? '__unknown_requester__';

  /// Display name for the requester. Null when missing — hide UI (no "Unknown").
  String? get requesterDisplayLabel {
    if (createdBy != null && createdBy!.fullName.isNotEmpty) {
      return createdBy!.fullName;
    }
    return null;
  }

  static SupportTicketSummary? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;
    final createdBy = TicketRequester.tryParse(json['createdBy']);
    final createdById = json['createdById']?.toString() ?? createdBy?.id;
    return SupportTicketSummary(
      id: id,
      title: json['title'] as String? ?? 'Untitled',
      status: json['status'] as String? ?? 'OPEN',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      createdById: createdById,
      createdBy: createdBy,
      assignments: TicketAssignment.parseList(json['assignments']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

class TicketMessage {
  const TicketMessage({
    required this.id,
    this.content,
    this.fileUrl,
    this.createdAt,
    this.authorStaffId,
  });

  final String id;
  final String? content;
  final String? fileUrl;
  final DateTime? createdAt;
  /// Staff row UUID (matches [Staff.id]), not display [Staff.staffId].
  final String? authorStaffId;

  static TicketMessage? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;
    return TicketMessage(
      id: id,
      content: json['content'] as String?,
      fileUrl: json['fileUrl'] as String?,
      createdAt: SupportTicketSummary._parseDate(json['createdAt']),
      authorStaffId: json['authorStaffId']?.toString() ??
          json['staffId']?.toString() ??
          json['senderId']?.toString(),
    );
  }
}

class SupportTicketDetail {
  const SupportTicketDetail({
    required this.id,
    required this.title,
    required this.status,
    this.messages = const [],
    this.createdAt,
    this.createdById,
    this.createdBy,
    this.assignments = const [],
  });

  final String id;
  final String title;
  final String status;
  final List<TicketMessage> messages;
  final DateTime? createdAt;
  final String? createdById;
  final TicketRequester? createdBy;
  final List<TicketAssignment> assignments;

  SupportTicketDetail copyWith({
    List<TicketMessage>? messages,
    String? status,
    String? title,
  }) {
    return SupportTicketDetail(
      id: id,
      title: title ?? this.title,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      createdById: createdById,
      createdBy: createdBy,
      assignments: assignments,
    );
  }

  static SupportTicketDetail? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;
    final rawMessages = json['messages'];
    final List<TicketMessage> messages = [];
    if (rawMessages is List) {
      for (final e in rawMessages) {
        if (e is Map<String, dynamic>) {
          final m = TicketMessage.tryParse(e);
          if (m != null) messages.add(m);
        } else if (e is Map) {
          final m = TicketMessage.tryParse(Map<String, dynamic>.from(e));
          if (m != null) messages.add(m);
        }
      }
    }
    final createdBy = TicketRequester.tryParse(json['createdBy']);
    final createdById = json['createdById']?.toString() ?? createdBy?.id;
    return SupportTicketDetail(
      id: id,
      title: json['title'] as String? ?? 'Untitled',
      status: json['status'] as String? ?? 'OPEN',
      messages: messages,
      createdAt: SupportTicketSummary._parseDate(json['createdAt']),
      createdById: createdById,
      createdBy: createdBy,
      assignments: TicketAssignment.parseList(json['assignments']),
    );
  }
}
