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
  Timer? _presenceHeartbeatTimer;
  /// Rooms the client is actively viewing (for leaveConversation on dispose).
  final Set<String> _activeConversationIds = <String>{};
  /// Rooms the server already joined us to (from `joinedConversations`).
  final Set<String> _serverJoinedConversationIds = <String>{};

  final _receiveMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _joinedConversationsController =
      StreamController<List<String>>.broadcast();
  final _ticketMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _chatErrorController = StreamController<String>.broadcast();
  final _pendingOrdersTickController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController =
      StreamController<InternalChatConnectionState>.broadcast();

  Stream<Map<String, dynamic>> get receiveMessageStream =>
      _receiveMessageController.stream;
  Stream<List<String>> get joinedConversationsStream =>
      _joinedConversationsController.stream;
  Stream<Map<String, dynamic>> get ticketMessageStream =>
      _ticketMessageController.stream;
  Stream<String> get chatErrorStream => _chatErrorController.stream;
  Stream<Map<String, dynamic>> get pendingOrdersTickStream =>
      _pendingOrdersTickController.stream;
  Stream<InternalChatConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

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
    _emitConnectionState(InternalChatConnectionState.connecting);

    _socket!.on('receiveMessage', (data) {
      if (data is Map) {
        _receiveMessageController.add(Map<String, dynamic>.from(data));
      }
    });
    _socket!.on('joinedConversations', (data) {
      final ids = _parseJoinedConversationIds(data);
      if (ids.isEmpty) return;
      _serverJoinedConversationIds.addAll(ids);
      if (!_joinedConversationsController.isClosed) {
        _joinedConversationsController.add(ids);
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
    _socket!.on('pending_orders_tick', (data) {
      if (data is Map) {
        _pendingOrdersTickController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.onConnect((_) {
      _emitConnectionState(InternalChatConnectionState.connected);
      presenceHeartbeat();
      _presenceHeartbeatTimer?.cancel();
      _presenceHeartbeatTimer = Timer.periodic(
        const Duration(seconds: 45),
        (_) => presenceHeartbeat(),
      );
    });
    _socket!.onDisconnect((_) {
      _emitConnectionState(InternalChatConnectionState.disconnected);
      _presenceHeartbeatTimer?.cancel();
      _presenceHeartbeatTimer = null;
    });
    _socket!.onReconnect((_) async {
      _emitConnectionState(InternalChatConnectionState.reconnecting);
      _serverJoinedConversationIds.clear();
      final token = await TokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        _socket?.auth = {'token': token};
      }
    });
    _socket!.onConnectError((_) {
      _emitConnectionState(InternalChatConnectionState.error);
    });
    _socket!.onError((_) {
      _emitConnectionState(InternalChatConnectionState.error);
    });

    _socket!.connect();
  }

  Future<void> disconnect() async {
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
    _serverJoinedConversationIds.clear();
    _activeConversationIds.clear();
    _socket?.dispose();
    _socket = null;
    _emitConnectionState(InternalChatConnectionState.disconnected);
  }

  /// Join a room when opening a thread. On reconnect the server sends
  /// `joinedConversations` automatically — no manual re-join loop.
  void joinConversation(String conversationId) {
    if (conversationId.isEmpty) return;
    _activeConversationIds.add(conversationId);
    if (_serverJoinedConversationIds.contains(conversationId)) return;
    _socket?.emit('joinConversation', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _activeConversationIds.remove(conversationId);
    _socket?.emit('leaveConversation', {'conversationId': conversationId});
  }

  bool isJoinedOnServer(String conversationId) =>
      _serverJoinedConversationIds.contains(conversationId);

  void sendMessage({
    required String conversationId,
    String? content,
    String? type,
    String? fileUrl,
    void Function(Map<String, dynamic> ackPayload)? onAck,
    void Function()? onTimeout,
    Duration ackTimeout = const Duration(seconds: 8),
  }) {
    final payload = <String, dynamic>{
      'conversationId': conversationId,
      if (content != null && content.isNotEmpty) 'content': content,
      if (type != null && type.isNotEmpty) 'type': type,
      if (fileUrl != null && fileUrl.isNotEmpty) 'fileUrl': fileUrl,
    };
    final socket = _socket;
    if (socket == null || !socket.connected) {
      onTimeout?.call();
      return;
    }
    var completed = false;
    Timer? timeoutTimer;
    if (onAck != null || onTimeout != null) {
      timeoutTimer = Timer(ackTimeout, () {
        if (completed) return;
        completed = true;
        onTimeout?.call();
      });
    }
    socket.emitWithAck(
      'sendMessage',
      payload,
      ack: (raw) {
        if (completed) return;
        completed = true;
        timeoutTimer?.cancel();
        if (onAck == null) return;
        if (raw is Map) {
          onAck(Map<String, dynamic>.from(raw));
          return;
        }
        onAck(<String, dynamic>{'raw': raw});
      },
    );
  }

  void typing({required String conversationId, required bool typing}) {
    _socket?.emit('typing', {
      'conversationId': conversationId,
      'typing': typing,
    });
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
    _joinedConversationsController.close();
    _ticketMessageController.close();
    _chatErrorController.close();
    _pendingOrdersTickController.close();
    _connectionStateController.close();
  }

  void _emitConnectionState(InternalChatConnectionState next) {
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(next);
    }
  }

  static List<String> _parseJoinedConversationIds(dynamic raw) {
    final out = <String>{};
    void addId(dynamic v) {
      final id = v?.toString().trim();
      if (id != null && id.isNotEmpty) out.add(id);
    }

    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          addId(e['id'] ?? e['conversationId']);
        } else {
          addId(e);
        }
      }
      return out.toList();
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      for (final key in ['conversationIds', 'ids', 'conversations']) {
        final v = map[key];
        if (v is List) {
          for (final e in v) {
            if (e is Map) {
              addId(e['id'] ?? e['conversationId']);
            } else {
              addId(e);
            }
          }
          return out.toList();
        }
      }
      final single = map['conversationId'] ?? map['id'];
      addId(single);
    }
    return out.toList();
  }
}

enum InternalChatConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
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
