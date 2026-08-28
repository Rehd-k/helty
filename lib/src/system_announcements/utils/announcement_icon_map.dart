import 'package:flutter/material.dart';

/// Preset icon keys for system announcements (admin picker + display).
class AnnouncementIconOption {
  const AnnouncementIconOption(this.key, this.icon, this.label);

  final String key;
  final IconData icon;
  final String label;
}

const announcementIconOptions = <AnnouncementIconOption>[
  AnnouncementIconOption('info', Icons.info_outline, 'Info'),
  AnnouncementIconOption('warning', Icons.warning_amber_outlined, 'Warning'),
  AnnouncementIconOption('campaign', Icons.campaign_outlined, 'Campaign'),
  AnnouncementIconOption('announcement', Icons.announcement_outlined, 'Announcement'),
  AnnouncementIconOption('schedule', Icons.schedule_outlined, 'Schedule'),
  AnnouncementIconOption('event', Icons.event_outlined, 'Event'),
  AnnouncementIconOption('health', Icons.health_and_safety_outlined, 'Health'),
  AnnouncementIconOption('security', Icons.security_outlined, 'Security'),
  AnnouncementIconOption('maintenance', Icons.build_outlined, 'Maintenance'),
  AnnouncementIconOption('celebration', Icons.celebration_outlined, 'Celebration'),
];

IconData announcementIconForKey(String? key) {
  for (final option in announcementIconOptions) {
    if (option.key == key) return option.icon;
  }
  return Icons.info_outline;
}
