import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/services/internal_chat_socket.dart';
import '../../models/staff_model.dart';
import '../../models/super_admin_department_preview.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_providers.dart';
import '../../widgets/notifications/app_notification_provider.dart';
import '../models/support_ticket_models.dart';
import '../services/tickets_api_service.dart';

class SupportTicketDetailContent extends ConsumerStatefulWidget {
  const SupportTicketDetailContent({
    super.key,
    required this.ticketId,
    this.embedded = false,
    this.compactChrome = false,
    this.onBack,
    this.maxBubbleWidthFraction = 0.78,
    this.onDetailChanged,
  });

  final String ticketId;
  final bool embedded;
  final bool compactChrome;
  final VoidCallback? onBack;
  final double maxBubbleWidthFraction;
  final void Function(SupportTicketDetail? detail)? onDetailChanged;

  @override
  ConsumerState<SupportTicketDetailContent> createState() =>
      _SupportTicketDetailContentState();
}

class _SupportTicketDetailContentState
    extends ConsumerState<SupportTicketDetailContent> {
  final _scrollController = ScrollController();
  SupportTicketDetail? _detail;
  bool _loading = true;
  String? _error;
  StreamSubscription<Map<String, dynamic>>? _ticketSub;
  StreamSubscription<String>? _errSub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ticketSub?.cancel();
    _errSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(ticketsApiServiceProvider);
      final d = await api.getTicket(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
      });
      widget.onDetailChanged?.call(d);
      _afterLoadSocket();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _afterLoadSocket() {
    final socket = ref.read(internalChatSocketProvider);
    socket.joinTicket(widget.ticketId);

    _ticketSub?.cancel();
    _ticketSub = socket.ticketMessageStream.listen((data) {
      final tid = data['ticketId']?.toString();
      if (tid != widget.ticketId) return;
      final msg = _messageFromSocket(data);
      if (msg == null || !mounted) return;
      setState(() {
        final list = List<TicketMessage>.from(_detail?.messages ?? []);
        if (!list.any((m) => m.id == msg.id)) {
          list.add(msg);
          if (_detail != null) {
            _detail = _detail!.copyWith(messages: list);
          }
        }
      });
      _scrollToEnd();
    });

    _errSub?.cancel();
    _errSub = socket.chatErrorStream.listen((msg) {
      if (!mounted) return;
      showAppNotification(ref, msg, level: AppNotificationLevel.error);
    });
  }

  TicketMessage? _messageFromSocket(Map<String, dynamic> data) {
    if (data['message'] is Map<String, dynamic>) {
      return TicketMessage.tryParse(
        Map<String, dynamic>.from(data['message'] as Map),
      );
    }
    return TicketMessage.tryParse(data);
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

  Future<void> _send(String text) async {
    if (text.isEmpty) return;
    final socket = ref.read(internalChatSocketProvider);
    if (socket.isConnected) {
      socket.sendTicketMessage(ticketId: widget.ticketId, content: text);
    } else {
      try {
        await ref.read(ticketsApiServiceProvider).postTicketMessage(
              ticketId: widget.ticketId,
              content: text,
            );
        await _load();
      } catch (e) {
        if (!mounted) return;
        showAppNotification(ref, 'Send failed: $e',
            level: AppNotificationLevel.error);
      }
    }
  }

  Future<void> _setStatus(String status) async {
    try {
      await ref.read(ticketsApiServiceProvider).updateStatus(
            ticketId: widget.ticketId,
            status: status,
          );
      await _load();
    } catch (e) {
      if (!mounted) return;
      showAppNotification(ref, 'Update failed: $e',
          level: AppNotificationLevel.error);
    }
  }

  Future<void> _pickStaffToAssign() async {
    final exclude =
        _detail?.assignments.map((a) => a.staffUuid).toSet() ?? {};
    final staff = await showDialog<Staff>(
      context: context,
      builder: (ctx) => _StaffPickerDialog(excludeStaffIds: exclude),
    );
    if (staff == null || !mounted) return;
    try {
      await ref.read(ticketsApiServiceProvider).assignTicket(
            ticketId: widget.ticketId,
            staffId: staff.id,
          );
      await _load();
    } catch (e) {
      if (!mounted) return;
      showAppNotification(ref, 'Assign failed: $e',
          level: AppNotificationLevel.error);
    }
  }

  Future<void> _unassignStaff(String staffUuid) async {
    try {
      await ref.read(ticketsApiServiceProvider).unassignTicket(
            ticketId: widget.ticketId,
            staffId: staffUuid,
          );
      await _load();
    } catch (e) {
      if (!mounted) return;
      showAppNotification(ref, 'Unassign failed: $e',
          level: AppNotificationLevel.error);
    }
  }

  Widget _buildSuperAdminAssignmentPanel(
    ThemeData theme,
    SupportTicketDetail d,
  ) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (d.createdBy != null && d.createdBy!.fullName.isNotEmpty) ...[
              Text('Requester', style: theme.textTheme.labelMedium),
              Text(
                d.createdBy!.fullName,
                style: theme.textTheme.bodyMedium,
              ),
              if (d.createdBy!.staffId.isNotEmpty)
                Text(
                  'Staff ID: ${d.createdBy!.staffId}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 12),
            ] else if (d.createdBy != null &&
                d.createdBy!.staffId.isNotEmpty) ...[
              Text('Requester', style: theme.textTheme.labelMedium),
              Text(
                'Staff ID: ${d.createdBy!.staffId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Text('Assigned to', style: theme.textTheme.labelMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickStaffToAssign,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('Assign'),
                ),
              ],
            ),
            if (d.assignments.isEmpty)
              Text(
                'No one assigned yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: d.assignments.map((a) {
                  final label = a.staff != null && a.staff!.fullName.isNotEmpty
                      ? a.staff!.fullName
                      : 'Staff';
                  return InputChip(
                    label: Text(label),
                    onDeleted: () => _unassignStaff(a.staffUuid),
                    deleteIcon: const Icon(Icons.close_rounded, size: 18),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffId = ref.watch(currentStaffProvider)?.id;
    final theme = Theme.of(context);
    final maxW = MediaQuery.sizeOf(context).width * widget.maxBubbleWidthFraction;

    if (widget.embedded && widget.compactChrome) {
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _detail?.title ?? 'Ticket',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_detail != null)
                  PopupMenuButton<String>(
                    onSelected: _setStatus,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'OPEN', child: Text('Open')),
                      PopupMenuItem(
                          value: 'IN_PROGRESS', child: Text('In progress')),
                      PopupMenuItem(value: 'RESOLVED', child: Text('Resolved')),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _detail!.status,
                            style: theme.textTheme.labelMedium,
                          ),
                          const Icon(Icons.arrow_drop_down_rounded),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildBody(theme, staffId, maxW)),
        ],
      );
    }

    if (widget.embedded && !widget.compactChrome) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TicketEmbeddedHeader(
            title: _detail?.title ?? 'Ticket',
            status: _detail?.status,
            onBack: widget.onBack,
            onStatus: _detail != null ? _setStatus : null,
          ),
          Expanded(child: _buildBody(theme, staffId, maxW)),
        ],
      );
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

    final isSuperAdmin = staffIsSuperAdmin(ref.watch(currentStaffProvider));
    final detail = _detail!;

    return Column(
      children: [
        if (isSuperAdmin) _buildSuperAdminAssignmentPanel(theme, detail),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: detail.messages.length,
            itemBuilder: (context, i) {
              final m = detail.messages[i];
              final mine = staffId != null &&
                  m.authorStaffId != null &&
                  m.authorStaffId == staffId;
              return Align(
                alignment:
                    mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  constraints: BoxConstraints(maxWidth: maxW.clamp(120, 400)),
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
        _TicketMessageComposer(onSend: _send),
      ],
    );
  }
}

class _TicketMessageComposer extends StatefulWidget {
  const _TicketMessageComposer({required this.onSend});

  final Future<void> Function(String text) onSend;

  @override
  State<_TicketMessageComposer> createState() => _TicketMessageComposerState();
}

class _TicketMessageComposerState extends State<_TicketMessageComposer> {
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

/// Searchable staff list for super-admin ticket assignment.
class _StaffPickerDialog extends ConsumerStatefulWidget {
  const _StaffPickerDialog({this.excludeStaffIds = const {}});

  final Set<String> excludeStaffIds;

  @override
  ConsumerState<_StaffPickerDialog> createState() => _StaffPickerDialogState();
}

class _StaffPickerDialogState extends ConsumerState<_StaffPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final asyncStaff = ref.watch(
      staffListProvider((
        query: _query.trim().isEmpty ? null : _query.trim(),
        staffRole: null,
        departmentId: null,
        limit: 50,
      )),
    );

    return AlertDialog(
      title: const Text('Assign ticket'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search staff',
                hintText: 'Name, email, or ID',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: asyncStaff.when(
                data: (list) {
                  final visible = list
                      .where((s) => !widget.excludeStaffIds.contains(s.id))
                      .toList();
                  if (visible.isEmpty) {
                    return Center(
                      child: Text(
                        list.isEmpty
                            ? 'No staff found.'
                            : 'Everyone listed is already assigned.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, i) {
                      final s = visible[i];
                      return ListTile(
                        title: Text(s.fullName),
                        subtitle: Text(
                          '${s.staffId}${s.email != null ? ' · ${s.email}' : ''}',
                        ),
                        onTap: () => Navigator.pop(context, s),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    '$e',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _TicketEmbeddedHeader extends StatelessWidget {
  const _TicketEmbeddedHeader({
    required this.title,
    this.status,
    this.onBack,
    this.onStatus,
  });

  final String title;
  final String? status;
  final VoidCallback? onBack;
  final Future<void> Function(String)? onStatus;

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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (status != null && onStatus != null)
            PopupMenuButton<String>(
              onSelected: (s) => onStatus!(s),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'OPEN', child: Text('Open')),
                PopupMenuItem(value: 'IN_PROGRESS', child: Text('In progress')),
                PopupMenuItem(value: 'RESOLVED', child: Text('Resolved')),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(status!, style: theme.textTheme.labelMedium),
                    const Icon(Icons.arrow_drop_down_rounded),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
