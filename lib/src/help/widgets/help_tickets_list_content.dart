import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/notifications/app_notification_provider.dart';
import '../models/support_ticket_models.dart';
import '../services/tickets_api_service.dart';

class HelpTicketsListContent extends ConsumerStatefulWidget {
  const HelpTicketsListContent({
    super.key,
    required this.onOpenTicket,
    this.dense = false,
  });

  final void Function(String ticketId) onOpenTicket;
  final bool dense;

  @override
  ConsumerState<HelpTicketsListContent> createState() =>
      _HelpTicketsListContentState();
}

class _HelpTicketsListContentState extends ConsumerState<HelpTicketsListContent> {
  List<SupportTicketSummary> _tickets = [];
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
      final api = ref.read(ticketsApiServiceProvider);
      final list = await api.listTickets();
      if (!mounted) return;
      setState(() {
        _tickets = list;
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

  Future<void> createTicketAndOpen() async {
    final titleCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New support ticket'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'Brief description of the issue',
          ),
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      titleCtrl.dispose();
      return;
    }
    final title = titleCtrl.text.trim();
    titleCtrl.dispose();
    if (title.isEmpty) return;

    try {
      final api = ref.read(ticketsApiServiceProvider);
      final created = await api.createTicket(title: title);
      if (!mounted) return;
      if (created != null) {
        widget.onOpenTicket(created.id);
        _load();
      }
    } catch (e) {
      if (!mounted) return;
      showAppNotification(ref, 'Could not create ticket: $e',
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
                  'Support tickets',
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
                onPressed: createTicketAndOpen,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('New'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading && _tickets.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _tickets.isEmpty
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
                  : _tickets.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(16 + pad),
                          children: [
                            Text(
                              'No support tickets yet.',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Create a ticket to reach IT or support.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
                          itemCount: _tickets.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: theme.dividerColor),
                          itemBuilder: (context, i) {
                            final t = _tickets[i];
                            return ListTile(
                              dense: widget.dense,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              title: Text(t.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                '${t.status}${t.updatedAt != null ? ' · ${_formatDate(t.updatedAt!)}' : ''}',
                                style: theme.textTheme.bodySmall,
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => widget.onOpenTicket(t.id),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
