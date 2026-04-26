import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/notifications/app_notification_provider.dart';
import '../models/chat_models.dart';
import '../services/chat_api_service.dart';
import '../services/internal_chat_socket.dart';

/// Message thread UI (embedded or inside [Scaffold]).
class StaffChatThreadContent extends ConsumerStatefulWidget {
  const StaffChatThreadContent({
    super.key,
    required this.conversationId,
    this.embedded = false,
    this.compactChrome = false,
    this.conversationTitle,
    this.onBack,
    this.maxBubbleWidthFraction = 0.78,
  });

  final String conversationId;
  final bool embedded;
  /// When [embedded] is true, hide the inner title row (shell provides chrome).
  final bool compactChrome;
  /// Shown above the thread when [embedded] (e.g. side panel) so the peer is clear.
  final String? conversationTitle;
  final VoidCallback? onBack;
  final double maxBubbleWidthFraction;

  @override
  ConsumerState<StaffChatThreadContent> createState() =>
      _StaffChatThreadContentState();
}

class _StaffChatThreadContentState extends ConsumerState<StaffChatThreadContent> {
  final _scrollController = ScrollController();
  final _messageCtrl = TextEditingController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<Map<String, dynamic>>? _recvSub;
  StreamSubscription<String>? _errSub;
  InternalChatSocket? _socket;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _socket = ref.read(internalChatSocketProvider);
      _load();
    });
  }

  @override
  void dispose() {
    _recvSub?.cancel();
    _errSub?.cancel();
    _socket?.leaveConversation(widget.conversationId);
    _scrollController.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(chatApiServiceProvider);
      final list = await api.listMessages(widget.conversationId, limit: 50);
      list.sort((a, b) {
        final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ta.compareTo(tb);
      });
      if (!mounted) return;
      setState(() {
        _messages = list;
        _loading = false;
      });
      _wireSocket();
      _markReadIfNeeded();
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _wireSocket() {
    final socket = ref.read(internalChatSocketProvider);
    socket.joinConversation(widget.conversationId);

    _recvSub?.cancel();
    _recvSub = socket.receiveMessageStream.listen((data) {
      var cid = data['conversationId']?.toString();
      Map<String, dynamic>? msgMap;
      if (data['message'] is Map) {
        msgMap = Map<String, dynamic>.from(data['message'] as Map);
        cid ??= msgMap['conversationId']?.toString();
      } else {
        msgMap = data;
      }
      if (cid != widget.conversationId) return;
      final m = ChatMessage.tryParse(msgMap);
      if (m == null || !mounted) return;
      setState(() {
        if (!_messages.any((x) => x.id == m.id)) {
          _messages = [..._messages, m];
        }
      });
      _markReadIfNeeded();
      _scrollToEnd();
    });

    _errSub?.cancel();
    _errSub = socket.chatErrorStream.listen((msg) {
      if (!mounted) return;
      showAppNotification(ref, msg, level: AppNotificationLevel.error);
    });
  }

  void _markReadIfNeeded() {
    if (_messages.isEmpty) return;
    final last = _messages.last;
    final api = ref.read(chatApiServiceProvider);
    unawaited(
      api
          .markRead(
            conversationId: widget.conversationId,
            lastReadMessageId: last.id,
          )
          .catchError((Object _) {}),
    );
    final socket = ref.read(internalChatSocketProvider);
    socket.markRead(
      conversationId: widget.conversationId,
      lastReadMessageId: last.id,
    );
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  String _headerLabel() {
    final t = widget.conversationTitle?.trim();
    if (t != null && t.isNotEmpty) return t;
    return 'Chat';
  }

  Future<void> _send() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    _messageCtrl.clear();
    final socket = ref.read(internalChatSocketProvider);
    if (socket.isConnected) {
      socket.sendMessage(
        conversationId: widget.conversationId,
        content: text,
        type: 'TEXT',
      );
    } else {
      try {
        await ref.read(chatApiServiceProvider).postMessage(
              conversationId: widget.conversationId,
              content: text,
              type: 'TEXT',
            );
        await _load();
      } catch (e) {
        if (!mounted) return;
        showAppNotification(ref, 'Send failed: $e',
            level: AppNotificationLevel.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffId = ref.watch(currentStaffProvider)?.id;
    final theme = Theme.of(context);
    final maxW = MediaQuery.sizeOf(context).width * widget.maxBubbleWidthFraction;

    if (widget.embedded && !widget.compactChrome) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EmbeddedHeader(
            title: _headerLabel(),
            onBack: widget.onBack,
          ),
          Expanded(child: _buildBody(theme, staffId, maxW)),
        ],
      );
    }
    if (widget.embedded && widget.compactChrome) {
      return _buildBody(theme, staffId, maxW);
    }

    return _buildBody(theme, staffId, maxW);
  }

  Widget _buildBody(ThemeData theme, String? staffId, double maxW) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final peerLine = widget.embedded &&
        widget.compactChrome &&
        widget.conversationTitle != null &&
        widget.conversationTitle!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (peerLine)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Text(
              widget.conversationTitle!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text(
                    'No messages yet. Say hello!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final m = _messages[i];
                    final mine = staffId != null &&
                        m.senderStaffId != null &&
                        m.senderStaffId == staffId;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        constraints:
                            BoxConstraints(maxWidth: maxW.clamp(120, 400)),
                        decoration: BoxDecoration(
                          color: mine
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(m.content ?? ''),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Message…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _send,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmbeddedHeader extends StatelessWidget {
  const _EmbeddedHeader({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
