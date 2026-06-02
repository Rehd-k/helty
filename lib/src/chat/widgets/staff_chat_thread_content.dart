import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/notifications/app_notification_provider.dart';
import '../models/chat_models.dart';
import '../services/chat_api_service.dart';
import '../providers/staff_chat_shell_provider.dart';
import '../services/internal_chat_socket.dart';
import 'chat_presence_widgets.dart';

/// Message thread UI (embedded or inside [Scaffold]).
class StaffChatThreadContent extends ConsumerStatefulWidget {
  const StaffChatThreadContent({
    super.key,
    required this.conversationId,
    this.embedded = false,
    this.compactChrome = false,
    this.conversationTitle,
    this.peerStaffId,
    this.onBack,
    this.maxBubbleWidthFraction = 0.78,
  });

  final String conversationId;
  final bool embedded;

  /// When [embedded] is true, hide the inner title row (shell provides chrome).
  final bool compactChrome;

  /// Shown above the thread when [embedded] (e.g. side panel) so the peer is clear.
  final String? conversationTitle;

  /// Direct-chat peer; used for `GET /chat/presence/:staffId`.
  final String? peerStaffId;
  final VoidCallback? onBack;
  final double maxBubbleWidthFraction;

  @override
  ConsumerState<StaffChatThreadContent> createState() =>
      _StaffChatThreadContentState();
}

class _StaffChatThreadContentState
    extends ConsumerState<StaffChatThreadContent> {
  static const int _messagePageSize = 50;
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  final Map<String, _PendingSendState> _pendingByMessageId = {};
  bool _loading = true;
  String? _error;
  bool _loadingOlder = false;
  bool _hasMoreHistory = true;
  String? _olderCursor;
  StreamSubscription<Map<String, dynamic>>? _recvSub;
  StreamSubscription<String>? _errSub;
  Timer? _presenceTimer;
  Timer? _markReadDebounce;
  InternalChatSocket? _socket;
  late final StaffChatShellNotifier _shellNotifier;
  String? _resolvedPeerStaffId;
  ChatPresenceStatus _peerPresence = ChatPresenceStatus.unknown;

  @override
  void initState() {
    super.initState();
    _shellNotifier = ref.read(staffChatShellProvider.notifier);
    _resolvedPeerStaffId = widget.peerStaffId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _shellNotifier.setActiveConversationId(widget.conversationId);
      _socket = ref.read(internalChatSocketProvider);
      _scrollController.addListener(_onScroll);
      _load();
      _refreshPeerPresence();
      _presenceTimer = Timer.periodic(
        const Duration(seconds: 45),
        (_) => _refreshPeerPresence(),
      );
    });
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _markReadDebounce?.cancel();
    _recvSub?.cancel();
    _errSub?.cancel();
    _scrollController.removeListener(_onScroll);
    _socket?.leaveConversation(widget.conversationId);
    _shellNotifier.setActiveConversationId(null);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _resolvePeerStaffIdIfNeeded() async {
    if (_resolvedPeerStaffId != null && _resolvedPeerStaffId!.isNotEmpty) {
      return;
    }
    final me = ref.read(currentStaffProvider)?.id;
    try {
      final list = await ref.read(chatApiServiceProvider).listConversations();
      ChatConversationSummary? match;
      for (final c in list) {
        if (c.id == widget.conversationId) {
          match = c;
          break;
        }
      }
      _resolvedPeerStaffId = match?.peerStaffId(me);
    } catch (_) {}
  }

  Future<void> _refreshPeerPresence() async {
    await _resolvePeerStaffIdIfNeeded();
    final peerId = _resolvedPeerStaffId;
    if (peerId == null || peerId.isEmpty || !mounted) return;
    try {
      final p = await ref.read(chatApiServiceProvider).getPresence(peerId);
      if (!mounted) return;
      setState(() => _peerPresence = p.status);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(chatApiServiceProvider);
      final list = await api.listMessages(
        widget.conversationId,
        limit: _messagePageSize,
      );
      list.sort((a, b) {
        final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ta.compareTo(tb);
      });
      if (!mounted) return;
      setState(() {
        _messages = list;
        _olderCursor = list.isNotEmpty ? list.first.id : null;
        _hasMoreHistory = list.length >= _messagePageSize;
        _pendingByMessageId.clear();
        _loading = false;
      });
      _wireSocket();
      _markReadIfNeeded();
      _scrollToEnd(force: true);
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
        if (m.senderStaffId == ref.read(currentStaffProvider)?.id) {
          final local = _takeMatchingLocalPending(content: m.content);
          if (local != null) {
            _messages = _messages.where((x) => x.id != local.id).toList();
            _pendingByMessageId.remove(local.id);
          }
        }
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
    _markReadDebounce?.cancel();
    _markReadDebounce = Timer(const Duration(milliseconds: 550), () {
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
      _shellNotifier.refreshDebounced();
    });
  }

  void _scrollToEnd({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (!force && !_isNearBottom()) return;
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

  String? _presenceLine() => chatPresenceSubtitle(_peerPresence);

  String? _formatMessageTimestamp(DateTime? createdAt) {
    if (createdAt == null) return null;
    final local = createdAt.toLocal();
    final now = DateTime.now();
    final msgDay = DateTime(local.year, local.month, local.day);
    final today = DateTime(now.year, now.month, now.day);
    final diffDays = today.difference(msgDay).inDays;
    final time = DateFormat('hh:mm a').format(local);
    if (diffDays == 0) return 'Today $time';
    if (diffDays == 1) return 'Yesterday $time';
    return '${DateFormat('MMM d').format(local)}, $time';
  }

  BorderRadius _bubbleRadius(bool mine) {
    // WhatsApp-like asymmetric corners: a sharper tail side.
    return mine
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(6),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(18),
          );
  }

  Future<void> _send(String text) async {
    if (text.isEmpty) return;
    final me = ref.read(currentStaffProvider)?.id;
    final localId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final localMessage = ChatMessage(
      id: localId,
      content: text,
      type: 'TEXT',
      createdAt: DateTime.now(),
      senderStaffId: me,
    );
    setState(() {
      _messages = [..._messages, localMessage];
      _pendingByMessageId[localId] = _PendingSendState.sending;
    });
    _scrollToEnd(force: true);

    final socket = ref.read(internalChatSocketProvider);
    if (socket.isConnected) {
      socket.sendMessage(
        conversationId: widget.conversationId,
        content: text,
        type: 'TEXT',
        onAck: (_) {
          if (!mounted) return;
          setState(() {
            if (_pendingByMessageId[localId] == _PendingSendState.sending) {
              _pendingByMessageId[localId] = _PendingSendState.sent;
            }
          });
        },
        onTimeout: () {
          if (!mounted) return;
          setState(() {
            _pendingByMessageId[localId] = _PendingSendState.failed;
          });
        },
      );
    } else {
      try {
        await ref
            .read(chatApiServiceProvider)
            .postMessage(
              conversationId: widget.conversationId,
              content: text,
              type: 'TEXT',
            );
        if (!mounted) return;
        setState(() {
          _pendingByMessageId[localId] = _PendingSendState.sent;
        });
        await _load();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _pendingByMessageId[localId] = _PendingSendState.failed;
        });
        showAppNotification(
          ref,
          'Send failed: $e',
          level: AppNotificationLevel.error,
        );
      }
    }
  }

  Future<void> _retryMessage(ChatMessage message) async {
    final text = message.content?.trim();
    if (text == null || text.isEmpty) return;
    setState(() {
      _messages = _messages.where((m) => m.id != message.id).toList();
      _pendingByMessageId.remove(message.id);
    });
    await _send(text);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingOlder || !_hasMoreHistory) {
      return;
    }
    if (_scrollController.position.pixels <= 80) {
      unawaited(_loadOlderMessages());
    }
  }

  Future<void> _loadOlderMessages() async {
    final cursor = _olderCursor;
    if (cursor == null || cursor.isEmpty) return;
    setState(() => _loadingOlder = true);
    try {
      final older = await ref
          .read(chatApiServiceProvider)
          .listMessages(
            widget.conversationId,
            cursor: cursor,
            limit: _messagePageSize,
          );
      older.sort((a, b) {
        final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ta.compareTo(tb);
      });
      if (!mounted) return;
      final before = _scrollController.hasClients
          ? _scrollController.position.maxScrollExtent
          : 0.0;
      setState(() {
        final knownIds = _messages.map((e) => e.id).toSet();
        final deduped = older.where((e) => !knownIds.contains(e.id)).toList();
        _messages = [...deduped, ..._messages];
        _olderCursor = _messages.isNotEmpty ? _messages.first.id : null;
        _hasMoreHistory = older.length >= _messagePageSize;
        _loadingOlder = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final after = _scrollController.position.maxScrollExtent;
        final delta = after - before;
        if (delta > 0) {
          _scrollController.jumpTo(_scrollController.offset + delta);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingOlder = false);
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    final remaining = position.maxScrollExtent - position.pixels;
    return remaining < 120;
  }

  ChatMessage? _takeMatchingLocalPending({String? content}) {
    if (content == null || content.trim().isEmpty) return null;
    final normalized = content.trim();
    for (final m in _messages) {
      if (!m.id.startsWith('local-')) continue;
      if ((m.content ?? '').trim() != normalized) continue;
      return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final staffId = ref.watch(currentStaffProvider)?.id;
    final theme = Theme.of(context);
    final maxW =
        MediaQuery.sizeOf(context).width * widget.maxBubbleWidthFraction;

    if (widget.embedded && !widget.compactChrome) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EmbeddedHeader(
            title: _headerLabel(),
            presence: _peerPresence,
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

    final peerLine =
        widget.embedded &&
        widget.compactChrome &&
        widget.conversationTitle != null &&
        widget.conversationTitle!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (peerLine)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversationTitle!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_presenceLine() != null)
                  Text(
                    _presenceLine()!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: chatPresenceColor(
                        _peerPresence,
                        theme.colorScheme,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final m = _messages[i];
                    final mine =
                        staffId != null &&
                        m.senderStaffId != null &&
                        m.senderStaffId == staffId;
                    final prevMine =
                        i > 0 &&
                        staffId != null &&
                        _messages[i - 1].senderStaffId != null &&
                        _messages[i - 1].senderStaffId == staffId;
                    final timestamp = _formatMessageTimestamp(m.createdAt);
                    final sendState = _pendingByMessageId[m.id];
                    final horizontalGap =
                        MediaQuery.sizeOf(context).width * 0.16;
                    final bubbleMaxWidth = maxW.clamp(150, 350).toDouble();
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: prevMine == mine ? 4 : 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (mine) SizedBox(width: horizontalGap),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: bubbleMaxWidth,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: mine
                                    ? theme.colorScheme.primaryContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: _bubbleRadius(mine),
                                border: Border.all(
                                  color: mine
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.15,
                                        )
                                      : theme.colorScheme.outlineVariant
                                            .withValues(alpha: 0.45),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.shadow.withValues(
                                      alpha: 0.1,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                    spreadRadius: -1,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    m.content ?? '',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.28,
                                      color: mine
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (timestamp != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          timestamp,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w500,
                                                color: mine
                                                    ? theme
                                                          .colorScheme
                                                          .onPrimaryContainer
                                                          .withValues(
                                                            alpha: 0.78,
                                                          )
                                                    : theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                              ),
                                        ),
                                        if (mine && sendState != null) ...[
                                          const SizedBox(width: 6),
                                          _SendStatusChip(
                                            state: sendState,
                                            onRetry:
                                                sendState ==
                                                    _PendingSendState.failed
                                                ? () => _retryMessage(m)
                                                : null,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (!mine) SizedBox(width: horizontalGap),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        if (_loadingOlder)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        _ChatMessageComposer(onSend: _send),
      ],
    );
  }
}

enum _PendingSendState { sending, sent, failed }

class _SendStatusChip extends StatelessWidget {
  const _SendStatusChip({required this.state, this.onRetry});

  final _PendingSendState state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (state) {
      case _PendingSendState.sending:
        return Icon(Icons.schedule_rounded, size: 12, color: cs.outline);
      case _PendingSendState.sent:
        return Icon(Icons.done_rounded, size: 12, color: cs.primary);
      case _PendingSendState.failed:
        return GestureDetector(
          onTap: onRetry,
          child: Icon(Icons.refresh_rounded, size: 12, color: cs.error),
        );
    }
  }
}

/// Owns its [TextEditingController] so disposal matches the input field lifecycle
/// (avoids "TextEditingController was used after being disposed" on panel close).
class _ChatMessageComposer extends StatefulWidget {
  const _ChatMessageComposer({required this.onSend});

  final Future<void> Function(String text) onSend;

  @override
  State<_ChatMessageComposer> createState() => _ChatMessageComposerState();
}

class _ChatMessageComposerState extends State<_ChatMessageComposer> {
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    _messageCtrl.clear();
    await widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _submit,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class _EmbeddedHeader extends StatelessWidget {
  const _EmbeddedHeader({
    required this.title,
    this.presence = ChatPresenceStatus.unknown,
    this.onBack,
  });

  final String title;
  final ChatPresenceStatus presence;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final line = chatPresenceSubtitle(presence);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (line != null)
                  Text(
                    line,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: chatPresenceColor(presence, cs),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
