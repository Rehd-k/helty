import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';

import '../../widgets/notifications/app_notification_provider.dart';
import '../models/support_ticket_models.dart';
import '../services/tickets_api_service.dart';
import '../widgets/support_ticket_detail_content.dart';

@RoutePage()
class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  const SupportTicketDetailScreen({
    super.key,
    required this.ticketId,
  });

  final String ticketId;

  @override
  ConsumerState<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends ConsumerState<SupportTicketDetailScreen> {
  int _contentKey = 0;
  String _title = 'Support ticket';
  String? _status;

  Future<void> _setStatus(String status) async {
    try {
      await ref.read(ticketsApiServiceProvider).updateStatus(
            ticketId: widget.ticketId,
            status: status,
          );
      if (!mounted) return;
      setState(() {
        _status = status;
        _contentKey++;
      });
    } catch (e) {
      if (!mounted) return;
      showAppNotification(ref, 'Update failed: $e',
          level: AppNotificationLevel.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (_status != null)
            PopupMenuButton<String>(
              onSelected: _setStatus,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'OPEN', child: Text('Open')),
                PopupMenuItem(value: 'IN_PROGRESS', child: Text('In progress')),
                PopupMenuItem(value: 'RESOLVED', child: Text('Resolved')),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_status!),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) => SupportTicketDetailContent(
          key: ValueKey(_contentKey),
          ticketId: widget.ticketId,
          onDetailChanged: (SupportTicketDetail? d) {
            if (d == null) return;
            setState(() {
              _title = d.title;
              _status = d.status;
            });
          },
        ),
      ),
    );
  }
}
