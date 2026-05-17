import 'package:flutter/material.dart';

import '../models/chat_models.dart';

Color chatPresenceColor(ChatPresenceStatus status, ColorScheme cs) {
  switch (status) {
    case ChatPresenceStatus.online:
      return Colors.green.shade600;
    case ChatPresenceStatus.away:
      return Colors.orange.shade700;
    case ChatPresenceStatus.offline:
      return cs.outline;
    case ChatPresenceStatus.unknown:
      return cs.outline.withValues(alpha: 0.5);
  }
}

/// Avatar with a small presence dot (bottom-right).
class StaffAvatarWithPresence extends StatelessWidget {
  const StaffAvatarWithPresence({
    super.key,
    required this.initials,
    required this.status,
    this.radius = 24,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String initials;
  final ChatPresenceStatus status;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dotColor = chatPresenceColor(status, cs);
    final showDot = status != ChatPresenceStatus.unknown;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? cs.tertiaryContainer,
          foregroundColor: foregroundColor ?? cs.onTertiaryContainer,
          child: Text(
            initials,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: radius * 0.58,
            ),
          ),
        ),
        if (showDot)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.42,
              height: radius * 0.42,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

String? chatPresenceSubtitle(ChatPresenceStatus status) {
  final label = status.label;
  return label.isEmpty ? null : label;
}
