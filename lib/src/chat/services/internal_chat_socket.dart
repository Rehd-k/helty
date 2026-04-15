import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/storage/token_storage.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

/// Socket.IO client for internal chat and ticket threads (see docs/flutter-internal-chat-integration.md).
class InternalChatSocket {
  InternalChatSocket(this._baseUrl);

  final String _baseUrl;
  io.Socket? _socket;

  final _receiveMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _ticketMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _chatErrorController = StreamController<String>.broadcast();

  Stream<Map<String, dynamic>> get receiveMessageStream =>
      _receiveMessageController.stream;
  Stream<Map<String, dynamic>> get ticketMessageStream =>
      _ticketMessageController.stream;
  Stream<String> get chatErrorStream => _chatErrorController.stream;

  bool get isConnected => _socket?.connected ?? false;

  static String socketUrlFromApiBase(String apiBaseUrl) {
    final u = Uri.parse(apiBaseUrl);
    return '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}';
  }

  Future<void> connect() async {
    await disconnect();
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return;

    final url = socketUrlFromApiBase(_baseUrl);
    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .build(),
    );

    _socket!.on('receiveMessage', (data) {
      if (data is Map) {
        _receiveMessageController.add(Map<String, dynamic>.from(data));
      }
    });
    _socket!.on('ticketMessage', (data) {
      if (data is Map) {
        _ticketMessageController.add(Map<String, dynamic>.from(data));
      }
    });
    _socket!.on('chat_error', (data) {
      final msg = data is Map && data['message'] != null
          ? '${data['message']}'
          : '$data';
      _chatErrorController.add(msg);
    });

    _socket!.connect();
  }

  Future<void> disconnect() async {
    _socket?.dispose();
    _socket = null;
  }

  void joinConversation(String conversationId) {
    _socket?.emit('joinConversation', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('leaveConversation', {'conversationId': conversationId});
  }

  void sendMessage({
    required String conversationId,
    String? content,
    String? type,
    String? fileUrl,
  }) {
    final payload = <String, dynamic>{
      'conversationId': conversationId,
      if (content != null && content.isNotEmpty) 'content': content,
      if (type != null && type.isNotEmpty) 'type': type,
      if (fileUrl != null && fileUrl.isNotEmpty) 'fileUrl': fileUrl,
    };
    _socket?.emit('sendMessage', payload);
  }

  void typing({required String conversationId, required bool typing}) {
    _socket?.emit('typing', {'conversationId': conversationId, 'typing': typing});
  }

  void markRead({
    required String conversationId,
    required String lastReadMessageId,
  }) {
    _socket?.emit('markRead', {
      'conversationId': conversationId,
      'lastReadMessageId': lastReadMessageId,
    });
  }

  void presenceHeartbeat() {
    _socket?.emit('presenceHeartbeat', {});
  }

  void joinTicket(String ticketId) {
    _socket?.emit('joinTicket', {'ticketId': ticketId});
  }

  void sendTicketMessage({
    required String ticketId,
    String? content,
    String? fileUrl,
  }) {
    _socket?.emit('sendTicketMessage', {
      'ticketId': ticketId,
      if (content != null && content.isNotEmpty) 'content': content,
      if (fileUrl != null && fileUrl.isNotEmpty) 'fileUrl': fileUrl,
    });
  }

  void dispose() {
    disconnect();
    _receiveMessageController.close();
    _ticketMessageController.close();
    _chatErrorController.close();
  }
}

/// Keeps one socket per app; connects when authenticated, disconnects on logout.
final internalChatSocketProvider = Provider<InternalChatSocket>((ref) {
  final base = ApiService().apiBaseUrl;
  final socket = InternalChatSocket(base);

  void sync(AuthState auth) {
    if (auth.isAuthenticated) {
      socket.connect().catchError((Object e, _) {
        if (kDebugMode) {
          debugPrint('InternalChatSocket connect error: $e');
        }
      });
    } else {
      socket.disconnect();
    }
  }

  ref.listen(authProvider, (_, next) => sync(next));
  sync(ref.read(authProvider));

  ref.onDispose(() {
    socket.dispose();
  });
  return socket;
});
