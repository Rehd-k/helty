import 'package:flutter/material.dart';
import 'package:helty/src/system_announcements/models/system_announcement.dart';
import 'package:helty/src/system_announcements/utils/announcement_icon_map.dart';
import 'package:helty/src/system_announcements/widgets/announcement_modal.dart';

class AnnouncementBannerStrip extends StatelessWidget {
  const AnnouncementBannerStrip({
    super.key,
    required this.announcements,
    required this.onDismiss,
    this.onTap,
  });

  final List<SystemAnnouncement> announcements;
  final void Function(SystemAnnouncement announcement) onDismiss;
  final void Function(List<SystemAnnouncement> announcements)? onTap;

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: announcements
          .map(
            (a) => _AnnouncementBanner(
              announcement: a,
              onDismiss: () => onDismiss(a),
              onTap: () {
                if (onTap != null) {
                  onTap!(announcements);
                } else {
                  AnnouncementModal.show(context, announcements: announcements);
                }
              },
            ),
          )
          .toList(),
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner({
    required this.announcement,
    required this.onDismiss,
    required this.onTap,
  });

  final SystemAnnouncement announcement;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = announcementIconForKey(announcement.iconKey);
    return Material(
      color: cs.primaryContainer.withValues(alpha: 0.45),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  announcement.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                onPressed: onDismiss,
                icon: Icon(Icons.close, size: 18, color: cs.onPrimaryContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
