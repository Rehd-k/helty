import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/system_announcements/models/system_announcement.dart';
import 'package:helty/src/system_announcements/providers/system_announcement_providers.dart';
import 'package:helty/src/system_announcements/widgets/announcement_banner_strip.dart';

/// Shows active announcement banners above shell content, with per-item dismiss.
class AnnouncementBannerHost extends ConsumerStatefulWidget {
  const AnnouncementBannerHost({super.key});

  @override
  ConsumerState<AnnouncementBannerHost> createState() =>
      _AnnouncementBannerHostState();
}

class _AnnouncementBannerHostState extends ConsumerState<AnnouncementBannerHost> {
  Set<String> _dismissedIds = {};
  bool _loadedDismissals = false;

  @override
  void initState() {
    super.initState();
    _loadDismissals();
  }

  Future<void> _loadDismissals() async {
    final ids = await AnnouncementDismissalStorage.loadDismissedBannerIds();
    if (!mounted) return;
    setState(() {
      _dismissedIds = ids;
      _loadedDismissals = true;
    });
  }

  Future<void> _dismiss(SystemAnnouncement announcement) async {
    await AnnouncementDismissalStorage.dismissBannerId(announcement.id);
    if (!mounted) return;
    setState(() => _dismissedIds = {..._dismissedIds, announcement.id});
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedDismissals) return const SizedBox.shrink();

    final async = ref.watch(activeAnnouncementsProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (active) {
        final visible = active
            .where((a) => !_dismissedIds.contains(a.id))
            .toList();
        if (visible.isEmpty) return const SizedBox.shrink();
        return AnnouncementBannerStrip(
          announcements: visible,
          onDismiss: _dismiss,
        );
      },
    );
  }
}
