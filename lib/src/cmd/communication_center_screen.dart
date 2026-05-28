import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/helper/date.formatter.dart';

import 'cmd_breakpoints.dart';
import 'cmd_providers.dart';
import 'models/cmd_models.dart';
import 'services/cmd_endpoints.dart';
import 'widgets/cmd_async_scaffold.dart';

@RoutePage()
class CMDCommunicationCenterScreen extends ConsumerStatefulWidget {
  const CMDCommunicationCenterScreen({super.key});

  @override
  ConsumerState<CMDCommunicationCenterScreen> createState() => _CMDCommunicationCenterScreenState();
}

class _CMDCommunicationCenterScreenState extends ConsumerState<CMDCommunicationCenterScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _audience = 'All staff';
  String _priority = 'Normal';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cmdAnnouncementsProvider);
    return CmdAsyncScaffold<List<CmdAnnouncement>>(
      title: 'Communication center',
      subtitle: 'Broadcasts and announcements',
      asyncValue: async,
      builder: (context, data) {
        return LayoutBuilder(
          builder: (context, c) {
            final narrow = CmdBreakpoints.fromWidth(c.maxWidth).isMobile;
            final audienceField = DropdownButtonFormField<String>(
              key: ValueKey(_audience),
              initialValue: _audience,
              decoration: const InputDecoration(labelText: 'Audience'),
              items: const [
                DropdownMenuItem(value: 'All staff', child: Text('All staff')),
                DropdownMenuItem(value: 'Clinical only', child: Text('Clinical only')),
                DropdownMenuItem(value: 'ER + wards', child: Text('ER + wards')),
              ],
              onChanged: (v) => setState(() => _audience = v ?? 'All staff'),
            );
            final priorityField = DropdownButtonFormField<String>(
              key: ValueKey(_priority),
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                DropdownMenuItem(value: 'High', child: Text('High')),
                DropdownMenuItem(value: 'Emergency', child: Text('Emergency')),
              ],
              onChanged: (v) => setState(() => _priority = v ?? 'Normal'),
            );
            return SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compose broadcast (POST ${CmdEndpoints.communicationsBroadcast})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _titleCtrl,
                            decoration: const InputDecoration(labelText: 'Title'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _bodyCtrl,
                            decoration: const InputDecoration(labelText: 'Message body'),
                            minLines: 3,
                            maxLines: 6,
                          ),
                          const SizedBox(height: 12),
                          narrow
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    audienceField,
                                    const SizedBox(height: 12),
                                    priorityField,
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: audienceField),
                                    const SizedBox(width: 16),
                                    Expanded(child: priorityField),
                                  ],
                                ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: () async {
                                final svc = ref.read(cmdCommandServiceProvider);
                                await svc.sendBroadcast(
                                  title: _titleCtrl.text.isEmpty ? '(no title)' : _titleCtrl.text,
                                  body: _bodyCtrl.text.isEmpty ? '(empty)' : _bodyCtrl.text,
                                  audience: _audience,
                                  priority: _priority,
                                );
                                if (context.mounted) {
                                  ref.invalidate(cmdAnnouncementsProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Broadcast sent')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.campaign_outlined),
                              label: const Text('Send'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Recent & scheduled',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...data.map(
                    (a) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(a.title),
                        subtitle: Text('${a.audience} · ${a.priority}'),
                        isThreeLine: true,
                        trailing: a.sentAt != null
                            ? Text(DateFormatter.dateTime(a.sentAt!))
                            : Text(
                                'Scheduled: ${a.scheduledFor != null ? DateFormatter.dateTime(a.scheduledFor!) : '—'}',
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
