class ChatConversationSummary {
  const ChatConversationSummary({
    required this.id,
    this.name,
    this.unreadCount = 0,
    this.lastMessagePreview,
    this.updatedAt,
    this.isGroup = false,
  });

  final String id;
  final String? name;
  final int unreadCount;
  final String? lastMessagePreview;
  final DateTime? updatedAt;
  final bool isGroup;

  static ChatConversationSummary? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;
    final unread = json['unreadCount'];
    return ChatConversationSummary(
      id: id,
      name: json['name'] as String?,
      unreadCount: unread is int ? unread : int.tryParse('$unread') ?? 0,
      lastMessagePreview: json['lastMessage'] as String? ??
          json['lastMessagePreview'] as String?,
      updatedAt: _parseDate(json['updatedAt']),
      isGroup: json['isGroup'] as bool? ?? json['type'] == 'GROUP',
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    this.content,
    this.type,
    this.fileUrl,
    this.createdAt,
    this.senderStaffId,
  });

  final String id;
  final String? content;
  final String? type;
  final String? fileUrl;
  final DateTime? createdAt;
  final String? senderStaffId;

  static ChatMessage? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;
    return ChatMessage(
      id: id,
      content: json['content'] as String?,
      type: json['type'] as String?,
      fileUrl: json['fileUrl'] as String?,
      createdAt: ChatConversationSummary._parseDate(json['createdAt']),
      senderStaffId: json['senderStaffId']?.toString() ??
          json['staffId']?.toString() ??
          json['authorId']?.toString(),
    );
  }
}
