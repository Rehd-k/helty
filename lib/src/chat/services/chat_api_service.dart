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
