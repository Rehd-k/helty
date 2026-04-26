/// Staff snapshot attached to a conversation member (API `members[].staff`).
class ChatPeerStaff {
  const ChatPeerStaff({
    required this.id,
    this.staffId,
    this.firstName,
    this.lastName,
  });

  final String id;
  final String? staffId;
  final String? firstName;
  final String? lastName;

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  static ChatPeerStaff? tryParse(dynamic o) {
    if (o is! Map) return null;
    final m = Map<String, dynamic>.from(o);
    final id = m['id']?.toString();
    if (id == null || id.isEmpty) return null;
    return ChatPeerStaff(
      id: id,
      staffId: m['staffId']?.toString(),
      firstName: m['firstName'] as String?,
      lastName: m['lastName'] as String?,
    );
  }
}

class ChatConversationSummary {
  const ChatConversationSummary({
    required this.id,
    this.name,
    this.unreadCount = 0,
    this.lastMessagePreview,
    this.updatedAt,
    this.isGroup = false,
    this.members = const [],
  });

  final String id;
  final String? name;
  final int unreadCount;
  final String? lastMessagePreview;
  final DateTime? updatedAt;
  final bool isGroup;
  final List<ChatPeerStaff> members;

  /// Resolves a row / app bar title: named group, or the other person in a direct chat.
  String displayTitle(String? myStaffId) {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    for (final p in members) {
      if (myStaffId != null && p.id == myStaffId) continue;
      if (p.fullName.isNotEmpty) return p.fullName;
    }
    return 'Conversation';
  }

  static ChatConversationSummary? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;
    final unread = json['unreadCount'];
    final t = json['type']?.toString();
    return ChatConversationSummary(
      id: id,
      name: _asNullableString(json['name']),
      unreadCount: unread is int ? unread : int.tryParse('$unread') ?? 0,
      lastMessagePreview: _lastMessagePreviewFromJson(json['lastMessage']) ??
          _asNullableString(json['lastMessagePreview']),
      updatedAt: _parseDate(json['updatedAt']),
      isGroup: json['isGroup'] as bool? ?? t == 'GROUP',
      members: _parseMembers(json['members']),
    );
  }

  static List<ChatPeerStaff> _parseMembers(dynamic v) {
    if (v is! List) return const [];
    final out = <ChatPeerStaff>[];
    for (final e in v) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final staff = m['staff'] ?? m['user'];
      final p = ChatPeerStaff.tryParse(staff);
      if (p != null) out.add(p);
    }
    return out;
  }

  static String? _asNullableString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  /// API may return a plain string, or a nested object
  /// `{ id, content, type, createdAt, senderId, ... }`.
  static String? _lastMessagePreviewFromJson(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is Map) {
      final m = Map<String, dynamic>.from(v);
      final content = m['content'];
      if (content is String && content.isNotEmpty) return content;
      final file = m['fileUrl'];
      if (file is String && file.isNotEmpty) return 'Attachment';
      final t = m['type'];
      if (t is String && t.isNotEmpty && t != 'TEXT') return t;
      return null;
    }
    return null;
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

  static String? _stringOrNull(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  static ChatMessage? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;
    return ChatMessage(
      id: id,
      content: _stringOrNull(json['content']),
      type: _stringOrNull(json['type']),
      fileUrl: _stringOrNull(json['fileUrl']),
      createdAt: ChatConversationSummary._parseDate(json['createdAt']),
      senderStaffId: json['senderStaffId']?.toString() ??
          json['senderId']?.toString() ??
          json['staffId']?.toString() ??
          json['authorId']?.toString(),
    );
  }
}
