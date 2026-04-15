import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/notifications/app_notification_provider.dart';
import '../models/chat_models.dart';
import '../services/chat_api_service.dart';

/// Conversation list for staff chat (embedded panel or full-screen shell).
class StaffChatListContent extends ConsumerStatefulWidget {
  const StaffChatListContent({
    super.key,
    required this.onOpenConversation,
    this.dense = false,
  });

  final void Function(String conversationId) onOpenConversation;
  final bool dense;

  @override
  ConsumerState<StaffChatListContent> createState() =>
      _StaffChatListContentState();
}

class _StaffChatListContentState extends ConsumerState<StaffChatListContent> {
  List<ChatConversationSummary> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(chatApiServiceProvider);
      final list = await api.listConversations();
      if (!mounted) return;
      list.sort((a, b) {
        final ta = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      setState(() {
        _conversations = list;
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

  Future<void> _openDirect() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start direct chat'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Other staff ID (UUID)',
            hintText: 'Staff.id from directory',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      ctrl.dispose();
      return;
    }
    final otherId = ctrl.text.trim();
    ctrl.dispose();
    if (otherId.isEmpty) return;

    try {
      final conv = await ref
          .read(chatApiServiceProvider)
          .openDirect(otherStaffId: otherId);
      if (!mounted) return;
      if (conv != null) {
        widget.onOpenConversation(conv.id);
        _load();
      }
    } catch (e) {
      if (!mounted) return;
      showAppNotification(ref, 'Could not open chat: $e',
          level: AppNotificationLevel.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pad = widget.dense ? 8.0 : 0.0;
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
                        Text(_error!,
                            style: TextStyle(color: theme.colorScheme.error)),
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
                              'Start a direct chat with another staff member.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
                          itemCount: _conversations.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: theme.dividerColor),
                          itemBuilder: (context, i) {
                            final c = _conversations[i];
                            final title = c.name?.isNotEmpty == true
                                ? c.name!
                                : 'Conversation';
                            return ListTile(
                              dense: widget.dense,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              title: Text(title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: c.lastMessagePreview != null
                                  ? Text(
                                      c.lastMessagePreview!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: c.unreadCount > 0
                                  ? Badge(
                                      label: Text('${c.unreadCount}'),
                                      child: const Icon(
                                          Icons.chat_bubble_outline_rounded),
                                    )
                                  : const Icon(Icons.chevron_right_rounded),
                              onTap: () =>
                                  widget.onOpenConversation(c.id),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
