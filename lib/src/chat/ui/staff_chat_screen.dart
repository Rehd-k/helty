import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

import '../widgets/staff_chat_list_content.dart';

@RoutePage()
class StaffChatScreen extends ConsumerWidget {
  const StaffChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff chat'),
      ),
      body: StaffChatListContent(
        onOpenConversation: (id, {String? title}) {
          context.router.push(
            StaffChatThreadRoute(
              conversationId: id,
              title: title,
            ),
          );
        },
      ),
    );
  }
}
