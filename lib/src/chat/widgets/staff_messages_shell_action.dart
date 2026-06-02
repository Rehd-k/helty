import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/staff_chat_shell_provider.dart';

/// Top-bar staff messages control with unread badge and tooltip.
class StaffMessagesShellAction extends ConsumerWidget {
  const StaffMessagesShellAction({
    super.key,
    required this.onTap,
    this.iconSize = 22,
    this.dense = false,
    this.iconColor,
  });

  final VoidCallback onTap;
  final double iconSize;
  final bool dense;
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(staffChatShellProvider).totalUnread;
    final badgeLabel = unread > 9 ? '9+' : '$unread';

    final icon = Icon(
      Icons.chat_bubble_outline_rounded,
      size: iconSize,
      color: iconColor,
    );

    if (dense) {
      return Tooltip(
        message: 'Staff Messages',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Badge(
              isLabelVisible: unread > 0,
              label: Text(badgeLabel),
              child: icon,
            ),
          ),
        ),
      );
    }

    return IconButton(
      tooltip: 'Staff Messages',
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(badgeLabel),
        child: icon,
      ),
    );
  }
}
