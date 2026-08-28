import 'package:flutter/material.dart';
import 'package:helty/src/system_announcements/models/system_announcement.dart';
import 'package:helty/src/system_announcements/utils/announcement_icon_map.dart';

class AnnouncementModal extends StatelessWidget {
  const AnnouncementModal({
    super.key,
    required this.announcements,
    this.onDismiss,
  });

  final List<SystemAnnouncement> announcements;
  final VoidCallback? onDismiss;

  static Future<void> show(
    BuildContext context, {
    required List<SystemAnnouncement> announcements,
    VoidCallback? onDismiss,
  }) {
    if (announcements.isEmpty) return Future.value();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AnnouncementModal(
        announcements: announcements,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.campaign_outlined, color: cs.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('Announcements')),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: announcements.length,
          separatorBuilder: (_, __) => const Divider(height: 20),
          itemBuilder: (context, index) {
            final item = announcements[index];
            return _AnnouncementModalTile(announcement: item);
          },
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () {
            onDismiss?.call();
            Navigator.of(context).pop();
          },
          child: const Text('Got it'),
        ),
      ],
    );
  }
}

class _AnnouncementModalTile extends StatelessWidget {
  const _AnnouncementModalTile({required this.announcement});

  final SystemAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = announcementIconForKey(announcement.iconKey);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: cs.primary, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                announcement.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                announcement.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
