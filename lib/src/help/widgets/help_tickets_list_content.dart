import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';

import '../../models/super_admin_department_preview.dart';
import '../../providers/auth_provider.dart';
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
    if (ok != true || !mounted) return;
    final title = titleCtrl.text.trim();
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
    final isSuperAdmin = staffIsSuperAdmin(ref.watch(currentStaffProvider));
    return FlexPanel(
      child: Column(
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
                        : isSuperAdmin
                            ? _buildGroupedTicketList(theme, pad)
                            : ListView.separated(
                                padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
                                itemCount: _tickets.length,
                                separatorBuilder: (_, __) => Divider(
                                    height: 1, color: theme.dividerColor),
                                itemBuilder: (context, i) {
                                  final t = _tickets[i];
                                  return _ticketTile(theme, t);
                                },
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedTicketList(ThemeData theme, double pad) {
    final grouped = <String, List<SupportTicketSummary>>{};
    for (final t in _tickets) {
      grouped.putIfAbsent(t.requesterGroupKey, () => []).add(t);
    }
    final keys = grouped.keys.toList()
      ..sort((a, b) {
        final la = (grouped[a]!.first.requesterDisplayLabel ?? '').toLowerCase();
        final lb = (grouped[b]!.first.requesterDisplayLabel ?? '').toLowerCase();
        return la.compareTo(lb);
      });

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
      children: [
        for (final key in keys) ...[
          Builder(
            builder: (context) {
              final list = List<SupportTicketSummary>.from(grouped[key]!)
                ..sort((a, b) {
                  final da = a.updatedAt ?? a.createdAt;
                  final db = b.updatedAt ?? b.createdAt;
                  if (da == null && db == null) return 0;
                  if (da == null) return 1;
                  if (db == null) return -1;
                  return db.compareTo(da);
                });
              final sample = list.first;
              final requesterName = sample.requesterDisplayLabel;
              final subtitle = sample.createdBy != null &&
                      sample.createdBy!.staffId.isNotEmpty
                  ? 'Staff ID ${sample.createdBy!.staffId} · ${list.length} ticket(s)'
                  : '${list.length} ticket(s)';
              return ExpansionTile(
                key: PageStorageKey<String>('ticket_group_$key'),
                tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                initiallyExpanded: keys.length == 1,
                title: Text(
                  requesterName ?? subtitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: requesterName != null
                    ? Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, color: theme.dividerColor),
                    _ticketTile(theme, list[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _ticketTile(ThemeData theme, SupportTicketSummary t) {
    return ListTile(
      dense: widget.dense,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 2,
      ),
      title: Text(
        t.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${t.status}${t.updatedAt != null ? ' · ${_formatDate(t.updatedAt!)}' : ''}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => widget.onOpenTicket(t.id),
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
