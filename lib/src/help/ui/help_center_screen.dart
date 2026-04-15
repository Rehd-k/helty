import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

import '../widgets/help_tickets_list_content.dart';

@RoutePage()
class HelpCenterScreen extends ConsumerWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: HelpTicketsListContent(
        onOpenTicket: (id) {
          context.router.push(SupportTicketDetailRoute(ticketId: id));
        },
      ),
    );
  }
}
