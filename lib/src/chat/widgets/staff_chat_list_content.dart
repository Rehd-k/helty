import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/staff_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_providers.dart';
import '../../widgets/notifications/app_notification_provider.dart';
import '../models/chat_models.dart';
import '../services/chat_api_service.dart';
import '../providers/staff_chat_shell_provider.dart';
import '../services/internal_chat_socket.dart';
import 'chat_presence_widgets.dart';

/// Conversation list for staff chat (embedded panel or full-screen shell).
class StaffChatListContent extends ConsumerStatefulWidget {
  const StaffChatListContent({
    super.key,
    required this.onOpenConversation,
    this.dense = false,
  });

  /// [title] is the peer / conversation label for the thread screen (when known).
  final void Function(
    String conversationId, {
    String? title,
    String? peerStaffId,
  })
  onOpenConversation;
  final bool dense;

  @override
  ConsumerState<StaffChatListContent> createState() =>
      _StaffChatListContentState();
}

class _StaffChatListContentState extends ConsumerState<StaffChatListContent> {
  List<ChatConversationSummary> _conversations = [];
  Map<String, ChatPresenceStatus> _presenceByStaffId = {};
  bool _loading = true;
  String? _error;
  StreamSubscription<Map<String, dynamic>>? _chatSocketSub;
  Timer? _authoritativeReloadDebounce;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _chatSocketSub = ref
          .read(internalChatSocketProvider)
          .receiveMessageStream
          .listen(_onIncomingChatSocket);
    });
  }

  @override
  void dispose() {
    _chatSocketSub?.cancel();
    _authoritativeReloadDebounce?.cancel();
    super.dispose();
  }

  void _onIncomingChatSocket(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    Map<String, dynamic> msgMap = map;
    if (map['message'] is Map) {
      msgMap = Map<String, dynamic>.from(map['message'] as Map);
    }
    final cid =
        map['conversationId']?.toString() ??
        msgMap['conversationId']?.toString();
    if (cid == null || cid.isEmpty) {
      _scheduleAuthoritativeReload();
      return;
    }
    final message = ChatMessage.tryParse(msgMap);
    final me = ref.read(currentStaffProvider)?.id;
    final fromOther =
        message == null || me == null || message.senderStaffId == null
        ? true
        : message.senderStaffId != me;
    final activeConversationId = ref
        .read(staffChatShellProvider.notifier)
        .activeConversationId;

    setState(() {
      var found = false;
      _conversations = _conversations.map((c) {
        if (c.id != cid) return c;
        found = true;
        final nextUnread = fromOther && cid != activeConversationId
            ? c.unreadCount + 1
            : c.unreadCount;
        return ChatConversationSummary(
          id: c.id,
          name: c.name,
          unreadCount: nextUnread,
          lastMessagePreview: message?.content ?? c.lastMessagePreview,
          updatedAt: message?.createdAt ?? DateTime.now(),
          isGroup: c.isGroup,
          members: c.members,
        );
      }).toList();
      if (!found) {
        _scheduleAuthoritativeReload();
      } else {
        _conversations.sort((a, b) {
          final ta = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tb = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tb.compareTo(ta);
        });
      }
    });
    ref.read(staffChatShellProvider.notifier).refreshDebounced();
    _scheduleAuthoritativeReload();
  }

  void _scheduleAuthoritativeReload() {
    _authoritativeReloadDebounce?.cancel();
    _authoritativeReloadDebounce = Timer(
      const Duration(seconds: 2),
      () => unawaited(_load(silent: true)),
    );
  }

  /// [silent]: refresh list without full-screen loading spinner (socket / background).
  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final api = ref.read(chatApiServiceProvider);
      final results = await Future.wait([
        api.listConversations(),
        api.listOnlineUsers().catchError((_) => <ChatStaffPresence>[]),
      ]);
      final list = results[0] as List<ChatConversationSummary>;
      final online = results[1] as List<ChatStaffPresence>;
      if (!mounted) return;
      list.sort((a, b) {
        final ta = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      final presence = <String, ChatPresenceStatus>{};
      for (final u in online) {
        presence[u.staffId] = u.status == ChatPresenceStatus.unknown
            ? ChatPresenceStatus.online
            : u.status;
      }
      setState(() {
        _conversations = list;
        _presenceByStaffId = presence;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silent) _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openDirect() async {
    final picked =
        await showModalBottomSheet<({String id, String displayName})?>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          useSafeArea: true,
          builder: (ctx) => const _StaffDirectPickerSheet(),
        );
    if (picked == null || picked.id.isEmpty || !mounted) return;

    try {
      final conv = await ref
          .read(chatApiServiceProvider)
          .openDirect(otherStaffId: picked.id);
      if (!mounted) return;
      if (conv != null) {
        final me = ref.read(currentStaffProvider)?.id;
        final fromApi = conv.displayTitle(me);
        final title = fromApi != 'Conversation' && fromApi.isNotEmpty
            ? fromApi
            : picked.displayName;
        ref.read(internalChatSocketProvider).joinConversation(conv.id);
        widget.onOpenConversation(
          conv.id,
          title: title,
          peerStaffId: picked.id,
        );
        _load();
      }
    } catch (e) {
      if (!mounted) return;
      showAppNotification(
        ref,
        'Could not open chat: $e',
        level: AppNotificationLevel.error,
      );
    }
  }

  String _initials(String title) {
    final parts = title.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.single;
      return s.isNotEmpty ? s[0].toUpperCase() : '?';
    }
    final a = parts.first.isNotEmpty ? parts.first[0] : '';
    final b = parts.last.isNotEmpty ? parts.last[0] : '';
    return ('$a$b').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pad = widget.dense ? 8.0 : 0.0;
    final cs = theme.colorScheme;
    final myStaffId = ref.watch(currentStaffProvider)?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, 0, pad, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Conversations',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded, size: 22),
              ),
              FilledButton.tonalIcon(
                onPressed: _openDirect,
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: const Text('Direct'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading && _conversations.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _conversations.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16 + pad),
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                )
              : _conversations.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16 + pad),
                  children: [
                    Text(
                      'No conversations yet.',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start a direct chat with a colleague.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: _openDirect,
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('Message someone'),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final c = _conversations[i];
                    final title = c.displayTitle(myStaffId);
                    final peerId = c.peerStaffId(myStaffId);
                    final peerPresence = peerId != null
                        ? (_presenceByStaffId[peerId] ??
                              ChatPresenceStatus.offline)
                        : ChatPresenceStatus.unknown;
                    return Material(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => widget.onOpenConversation(
                          c.id,
                          title: title,
                          peerStaffId: peerId,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              StaffAvatarWithPresence(
                                initials: _initials(title),
                                status: peerPresence,
                                radius: 18,
                                backgroundColor: cs.primaryContainer,
                                foregroundColor: cs.onPrimaryContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    if (c.lastMessagePreview != null)
                                      Text(
                                        c.lastMessagePreview!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              if (c.unreadCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Badge(
                                    label: Text('${c.unreadCount}'),
                                    child: Icon(
                                      Icons.chat_bubble_rounded,
                                      size: 22,
                                      color: cs.primary,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: cs.outline,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Picks a staff member for a direct chat. Search field and controller live
/// here so they are disposed after the sheet is fully removed (avoids
/// "TextEditingController was used after being disposed").
class _StaffDirectPickerSheet extends ConsumerStatefulWidget {
  const _StaffDirectPickerSheet();

  @override
  ConsumerState<_StaffDirectPickerSheet> createState() =>
      _StaffDirectPickerSheetState();
}

class _StaffDirectPickerSheetState
    extends ConsumerState<_StaffDirectPickerSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _search = TextEditingController();
  late final TabController _tabCtrl;
  List<Staff> _staff = [];
  Map<String, ChatPresenceStatus> _presenceByStaffId = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() {});
    });
    _search.addListener(_onSearchChanged);
    _loadStaff();
  }

  void _onSearchChanged() => setState(() {});

  @override
  void dispose() {
    _tabCtrl.dispose();
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final staffFuture = ref
          .read(staffServiceProvider)
          .fetchStaff(page: 1, limit: 400, isActive: true);
      final onlineFuture = ref
          .read(chatApiServiceProvider)
          .listOnlineUsers()
          .catchError((_) => <ChatStaffPresence>[]);
      final results = await Future.wait([staffFuture, onlineFuture]);
      final list = results[0] as List<Staff>;
      final online = results[1] as List<ChatStaffPresence>;
      if (!mounted) return;
      final me = ref.read(currentStaffProvider)?.id;
      final presence = <String, ChatPresenceStatus>{};
      for (final u in online) {
        presence[u.staffId] = u.status == ChatPresenceStatus.unknown
            ? ChatPresenceStatus.online
            : u.status;
      }
      setState(() {
        _staff = me != null ? list.where((s) => s.id != me).toList() : list;
        _presenceByStaffId = presence;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  ChatPresenceStatus _presenceFor(String staffId) =>
      _presenceByStaffId[staffId] ?? ChatPresenceStatus.offline;

  bool _isOnlineOrAway(ChatPresenceStatus s) =>
      s == ChatPresenceStatus.online || s == ChatPresenceStatus.away;

  List<Staff> get _filtered {
    final q = _search.text.trim().toLowerCase();
    Iterable<Staff> base = _staff;
    if (_tabCtrl.index == 1) {
      base = base.where((s) => _isOnlineOrAway(_presenceFor(s.id)));
    }
    if (q.isEmpty) return base.toList();
    return base.where((s) {
      return s.fullName.toLowerCase().contains(q) ||
          s.staffRole.toLowerCase().contains(q) ||
          s.staffId.toLowerCase().contains(q) ||
          (s.departmentName?.toLowerCase().contains(q) ?? false) ||
          (s.email?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  String _initials(Staff s) {
    final a = s.firstName.trim().isNotEmpty ? s.firstName[0] : '';
    final b = s.lastName.trim().isNotEmpty ? s.lastName[0] : '';
    final t = ('$a$b').trim();
    if (t.isEmpty) return '?';
    return t.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final h = MediaQuery.sizeOf(context).height * 0.88;
    final filteredStaff = _filtered;
    return SizedBox(
      height: h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'Message a colleague',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: SearchBar(
              controller: _search,
              hintText: 'Search by name, role, or department',
              leading: const Icon(Icons.search_rounded),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Online'),
            ],
          ),
          const SizedBox(height: 4),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(_error!, style: TextStyle(color: cs.error)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filteredStaff.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _staff.isEmpty
                            ? 'No staff found.'
                            : _tabCtrl.index == 1
                            ? 'No colleagues online right now.'
                            : 'No matches for your search.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: filteredStaff.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final s = filteredStaff[i];
                      final presence = _presenceFor(s.id);
                      final presenceLabel = presence.label;
                      final sub = [
                        if (presenceLabel.isNotEmpty) presenceLabel,
                        if (s.staffRole.isNotEmpty) s.staffRole,
                        if (s.departmentName != null &&
                            s.departmentName!.isNotEmpty)
                          s.departmentName!,
                      ].join(' · ');
                      return Material(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.of(
                            context,
                          ).pop((id: s.id, displayName: s.fullName)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                StaffAvatarWithPresence(
                                  initials: _initials(s),
                                  status: presence,
                                  radius: 24,
                                  backgroundColor: cs.tertiaryContainer,
                                  foregroundColor: cs.onTertiaryContainer,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.fullName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (sub.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          sub,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                      if (s.staffId.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          s.staffId,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: cs.outline,
                                                letterSpacing: 0.2,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: cs.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
