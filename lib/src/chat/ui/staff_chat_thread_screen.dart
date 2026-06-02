import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/staff_chat_thread_content.dart';

@RoutePage()
class StaffChatThreadScreen extends ConsumerWidget {
  const StaffChatThreadScreen({
    super.key,
    required this.conversationId,
    this.title,
    this.peerStaffId,
  });

  final String conversationId;
  final String? title;
  final String? peerStaffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = title?.trim();
    return Scaffold(
      appBar: AppBar(title: Text(t != null && t.isNotEmpty ? t : 'Chat')),
      body: StaffChatThreadContent(
        conversationId: conversationId,
        conversationTitle: t,
        peerStaffId: peerStaffId,
      ),
    );
  }
}
