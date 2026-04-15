class SupportTicketSummary {
  const SupportTicketSummary({
    required this.id,
    required this.title,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static SupportTicketSummary? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;
    return SupportTicketSummary(
      id: id,
      title: json['title'] as String? ?? 'Untitled',
      status: json['status'] as String? ?? 'OPEN',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
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
          json['staffId']?.toString(),
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
  });

  final String id;
  final String title;
  final String status;
  final List<TicketMessage> messages;
  final DateTime? createdAt;

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
        }
      }
    }
    return SupportTicketDetail(
      id: id,
      title: json['title'] as String? ?? 'Untitled',
      status: json['status'] as String? ?? 'OPEN',
      messages: messages,
      createdAt: SupportTicketSummary._parseDate(json['createdAt']),
    );
  }
}
