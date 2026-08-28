import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/system_announcements/models/system_announcement.dart';
import 'package:helty/src/system_announcements/services/system_announcement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final systemAnnouncementServiceProvider = Provider<SystemAnnouncementService>(
  (ref) => SystemAnnouncementService(),
);

final activeAnnouncementsProvider =
    FutureProvider.autoDispose<List<SystemAnnouncement>>((ref) async {
  final svc = ref.watch(systemAnnouncementServiceProvider);
  return svc.listActive();
});

final allAnnouncementsProvider =
    FutureProvider.autoDispose<List<SystemAnnouncement>>((ref) async {
  final svc = ref.watch(systemAnnouncementServiceProvider);
  return svc.listAll(take: 100);
});

const _kDismissedIdsKey = 'system_announcement_dismissed_ids';
const _kModalSeenIdsKey = 'system_announcement_modal_seen_ids';

class AnnouncementDismissalStorage {
  static Future<Set<String>> loadDismissedBannerIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kDismissedIdsKey);
    return list?.toSet() ?? {};
  }

  static Future<void> dismissBannerId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadDismissedBannerIds();
    current.add(id);
    await prefs.setStringList(_kDismissedIdsKey, current.toList());
  }

  static Future<void> clearDismissedBannerIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDismissedIdsKey);
  }

  static Future<Set<String>> loadModalSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kModalSeenIdsKey);
    return list?.toSet() ?? {};
  }

  static Future<void> markModalSeenIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadModalSeenIds();
    current.addAll(ids);
    await prefs.setStringList(_kModalSeenIdsKey, current.toList());
  }

  /// Returns announcements that should trigger the login modal.
  static Future<List<SystemAnnouncement>> filterForLoginModal(
    List<SystemAnnouncement> active,
  ) async {
    final seen = await loadModalSeenIds();
    if (seen.isEmpty) return active;
    return active.where((a) => !seen.contains(a.id)).toList();
  }

  /// Remove stale seen/dismissed IDs when announcements are deleted or deactivated.
  static Future<void> pruneStaleIds(Set<String> activeIds) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = await loadDismissedBannerIds();
    final seen = await loadModalSeenIds();
    final prunedDismissed = dismissed.where(activeIds.contains).toList();
    final prunedSeen = seen.where(activeIds.contains).toList();
    await prefs.setStringList(_kDismissedIdsKey, prunedDismissed);
    await prefs.setStringList(_kModalSeenIdsKey, prunedSeen);
  }
}
