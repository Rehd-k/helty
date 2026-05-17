import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';
import '../models/chat_models.dart';

class ChatApiService {
  ChatApiService(this._dio);

  final Dio _dio;

  Future<List<ChatConversationSummary>> listConversations() async {
    final res = await _dio.get<dynamic>('/chat/conversations');
    final data = _unwrapList(res.data);
    if (data == null) return [];
    final out = <ChatConversationSummary>[];
    for (final e in data) {
      if (e is Map) {
        final c = ChatConversationSummary.tryParse(Map<String, dynamic>.from(e));
        if (c != null) out.add(c);
      }
    }
    return out;
  }

  static List<dynamic>? _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final k in ['data', 'conversations', 'items', 'rows']) {
        final v = map[k];
        if (v is List) return v;
        if (v is Map) {
          final inner = v['conversations'] ?? v['data'] ?? v['items'];
          if (inner is List) return inner;
        }
      }
    }
    return null;
  }

  Future<List<ChatMessage>> listMessages(
    String conversationId, {
    String? cursor,
    int limit = 30,
  }) async {
    final res = await _dio.get<dynamic>(
      '/chat/conversations/$conversationId/messages',
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'limit': limit,
      },
    );
    final data = _unwrapMessageListResponse(res.data);
    if (data == null) return [];
    final out = <ChatMessage>[];
    for (final e in data) {
      if (e is Map) {
        final m = ChatMessage.tryParse(Map<String, dynamic>.from(e));
        if (m != null) out.add(m);
      }
    }
    return out;
  }

  /// Some APIs wrap rows as `data`, `data.messages`, or `messages` only.
  static List<dynamic>? _unwrapMessageListResponse(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final k in ['messages', 'data', 'items', 'rows']) {
        final v = map[k];
        if (v is List) return v;
        if (v is Map) {
          final inner = v['messages'] ?? v['data'] ?? v['items'];
          if (inner is List) return inner;
        }
      }
    }
    return null;
  }

  Future<void> markRead({
    required String conversationId,
    required String lastReadMessageId,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/chat/conversations/$conversationId/read',
      data: {'lastReadMessageId': lastReadMessageId},
    );
  }

  Future<void> postMessage({
    required String conversationId,
    String? content,
    String? type,
    String? fileUrl,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/chat/conversations/$conversationId/messages',
      data: {
        if (content != null && content.isNotEmpty) 'content': content,
        if (type != null && type.isNotEmpty) 'type': type,
        if (fileUrl != null && fileUrl.isNotEmpty) 'fileUrl': fileUrl,
      },
    );
  }

  /// `GET /chat/online-users` — staff currently online (and optionally away).
  Future<List<ChatStaffPresence>> listOnlineUsers() async {
    final res = await _dio.get<dynamic>('/chat/online-users');
    final data = _unwrapList(res.data) ?? _unwrapOnlineUsers(res.data);
    if (data == null) return [];
    final out = <ChatStaffPresence>[];
    for (final e in data) {
      if (e is Map) {
        final p = ChatStaffPresence.tryParse(Map<String, dynamic>.from(e));
        if (p != null) out.add(p);
      } else if (e is String && e.isNotEmpty) {
        out.add(ChatStaffPresence(
          staffId: e,
          status: ChatPresenceStatus.online,
        ));
      }
    }
    return out;
  }

  static List<dynamic>? _unwrapOnlineUsers(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    for (final k in ['onlineUsers', 'users', 'staff']) {
      final v = map[k];
      if (v is List) return v;
    }
    return null;
  }

  /// `GET /chat/presence/:staffId` — online / away / offline for one staff member.
  Future<ChatStaffPresence> getPresence(String staffId) async {
    final res = await _dio.get<dynamic>('/chat/presence/$staffId');
    final raw = res.data;
    Map<String, dynamic>? map;
    if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
      final inner = map['data'];
      if (inner is Map) map = Map<String, dynamic>.from(inner);
    }
    final parsed = map != null ? ChatStaffPresence.tryParse(map) : null;
    if (parsed != null && parsed.staffId.isNotEmpty) return parsed;
    final statusRaw = map?['status'] ?? map?['presence'];
    return ChatStaffPresence(
      staffId: staffId,
      status: ChatPresenceStatusX.fromApi(statusRaw?.toString()),
    );
  }

  Future<ChatConversationSummary?> openDirect({required String otherStaffId}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/chat/conversations/direct',
      data: {'otherStaffId': otherStaffId},
    );
    final data = res.data;
    if (data == null) return null;
    var map = Map<String, dynamic>.from(data);
    final inner = map['data'];
    if (inner is Map) {
      map = Map<String, dynamic>.from(inner);
    }
    return ChatConversationSummary.tryParse(map);
  }
}

final chatApiServiceProvider = Provider<ChatApiService>((ref) {
  return ChatApiService(ApiService().dio);
});
