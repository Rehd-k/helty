import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../models/chat_models.dart';
import '../services/chat_api_service.dart';
import '../services/internal_chat_socket.dart';

class StaffChatShellState {
  const StaffChatShellState({
    this.totalUnread = 0,
    this.loading = false,
  });

  final int totalUnread;
  bool get hasUnread => totalUnread > 0;
  final bool loading;

  StaffChatShellState copyWith({int? totalUnread, bool? loading}) {
    return StaffChatShellState(
      totalUnread: totalUnread ?? this.totalUnread,
      loading: loading ?? this.loading,
    );
  }
}

class StaffChatShellNotifier extends Notifier<StaffChatShellState> {
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  String? _activeConversationId;

  @override
  StaffChatShellState build() {
    ref.listen(internalChatSocketProvider, (_, __) {
      _bindSocket();
    });
    ref.onDispose(() {
      _socketSub?.cancel();
    });
    Future.microtask(refresh);
    _bindSocket();
    return const StaffChatShellState();
  }

  void _bindSocket() {
    _socketSub?.cancel();
    _socketSub = ref
        .read(internalChatSocketProvider)
        .receiveMessageStream
        .listen(_onIncomingMessage);
  }

  void setActiveConversationId(String? conversationId) {
    _activeConversationId = conversationId;
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    try {
      final list = await ref.read(chatApiServiceProvider).listConversations();
      final total = list.fold<int>(0, (sum, c) => sum + c.unreadCount);
      state = StaffChatShellState(totalUnread: total, loading: false);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  void _onIncomingMessage(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    Map<String, dynamic> msgMap;
    if (map['message'] is Map) {
      msgMap = Map<String, dynamic>.from(map['message'] as Map);
    } else {
      msgMap = map;
    }
    final m = ChatMessage.tryParse(msgMap);
    if (m == null) {
      unawaited(refresh());
      return;
    }

    final me = ref.read(currentStaffProvider)?.id;
    final fromOther =
        me == null || m.senderStaffId == null || m.senderStaffId != me;
    final conversationId = map['conversationId']?.toString() ??
        msgMap['conversationId']?.toString();

    if (fromOther &&
        conversationId != null &&
        conversationId != _activeConversationId) {
      unawaited(SystemSound.play(SystemSoundType.alert));
    }

    unawaited(refresh());
  }
}

final staffChatShellProvider =
    NotifierProvider<StaffChatShellNotifier, StaffChatShellState>(
  StaffChatShellNotifier.new,
);
