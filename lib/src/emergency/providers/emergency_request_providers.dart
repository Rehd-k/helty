import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifications/local_notification_platform_service.dart';
import '../models/emergency_request_model.dart';
import '../services/emergency_request_service.dart';

final emergencyRequestStatusFilterProvider =
    StateProvider<EmergencyRequestStatus?>((ref) => EmergencyRequestStatus.submitted);

final emergencyRequestInboxProvider =
    FutureProvider.autoDispose<StaffEmergencyRequestListResponse>((ref) async {
      final status = ref.watch(emergencyRequestStatusFilterProvider);
      final service = ref.watch(emergencyRequestServiceProvider);
      return service.list(status: status);
    });

final emergencyRequestDetailProvider = FutureProvider.autoDispose
    .family<StaffEmergencyRequest, String>((ref, id) {
      return ref.watch(emergencyRequestServiceProvider).get(id);
    });

/// Polls the ED emergency inbox every 15s and fires local notifications for
/// newly seen SUBMITTED requests.
final emergencyRequestPollProvider = Provider.autoDispose<void>((ref) {
  final seen = <String>{};
  var primed = false;

  Future<void> tick() async {
    try {
      final service = ref.read(emergencyRequestServiceProvider);
      final response = await service.list(
        status: EmergencyRequestStatus.submitted,
        limit: 50,
      );
      final ids = response.data.map((e) => e.id).toSet();
      if (!primed) {
        seen.addAll(ids);
        primed = true;
        await _persistSeen(seen);
        return;
      }
      final stored = await _loadSeen();
      seen.addAll(stored);
      final newIds = ids.difference(seen);
      for (final id in newIds) {
        final item = response.data.firstWhere((e) => e.id == id);
        await ref
            .read(localNotificationPlatformServiceProvider)
            .show(
              id: id.hashCode.abs() % 100000,
              title: 'New emergency request',
              body: item.patient?.displayName ??
                  item.description ??
                  'Patient needs emergency help',
              payload: '{"type":"ed_emergency_request","id":"$id"}',
              details: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'ed_emergency_requests',
                  'ED emergency requests',
                  channelDescription:
                      'Alerts when patients request emergency services',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(),
              ),
            );
        seen.add(id);
      }
      await _persistSeen(seen);
      ref.invalidate(emergencyRequestInboxProvider);
    } catch (_) {
      // Poll failures are silent; inbox refresh indicator still works.
    }
  }

  tick();
  final timer = Timer.periodic(const Duration(seconds: 15), (_) => tick());
  ref.onDispose(timer.cancel);
});

const _seenKey = 'ed_emergency_request_seen_ids';

Future<Set<String>> _loadSeen() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(_seenKey)?.toSet() ?? {};
}

Future<void> _persistSeen(Set<String> ids) async {
  final prefs = await SharedPreferences.getInstance();
  final trimmed = ids.length > 200 ? ids.skip(ids.length - 200).toSet() : ids;
  await prefs.setStringList(_seenKey, trimmed.toList());
}
