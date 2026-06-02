import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifications/local_notification_platform_service.dart';
import '../../notifications/notification_navigation_provider.dart';
import '../models/pending_orders_models.dart';

class PendingOrdersNotificationService {
  PendingOrdersNotificationService(this._ref);

  final Ref _ref;
  final Map<String, PendingNotificationState> _activeByKey = {};
  bool _restored = false;

  static const String _channelId = 'pending_orders_tick';
  static const String _channelName = 'Pending orders';
  static const String _channelDescription =
      'Notifications for pending lab, radiology and paid-undispensed drug orders';
  static const String _ledgerStorageKey = 'pending_orders_notifications_ledger';

  Future<void> reconcile(List<PendingNotificationState> nextItems) async {
    await _ensureInitialized();
    final currentKeys = <String>{};

    for (final next in nextItems) {
      if (next.domain == PendingOrdersDomain.unknown) {
        if (kDebugMode) {
          debugPrint(
            'PendingOrdersNotificationService: ignoring unknown domain key=${next.notificationKey}',
          );
        }
        continue;
      }
      currentKeys.add(next.notificationKey);
      final prev = _activeByKey[next.notificationKey];
      if (prev == null) {
        await _showOrUpdate(next);
        _activeByKey[next.notificationKey] = next;
        continue;
      }
      if (prev.isMeaningfullyDifferent(next)) {
        await _showOrUpdate(next);
        _activeByKey[next.notificationKey] = next;
      }
    }

    final keysToRemove = _activeByKey.keys
        .where((k) => !currentKeys.contains(k))
        .toList(growable: false);
    for (final key in keysToRemove) {
      await _ref
          .read(localNotificationPlatformServiceProvider)
          .cancel(_notificationIdForKey(key));
      _activeByKey.remove(key);
    }
    await _persistLedger();
  }

  Future<void> _showOrUpdate(PendingNotificationState state) async {
    await _ref
        .read(localNotificationPlatformServiceProvider)
        .show(
          id: _notificationIdForKey(state.notificationKey),
          title: state.title,
          body: state.body,
          payload: jsonEncode(<String, dynamic>{
            'type': 'pending_order',
            'notificationKey': state.notificationKey,
          }),
          details: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
            windows: WindowsNotificationDetails(),
          ),
        );
  }

  int _notificationIdForKey(String key) => key.hashCode & 0x7fffffff;

  Future<void> _ensureInitialized() async {
    await _ref
        .read(localNotificationPlatformServiceProvider)
        .initialize(
          onTap: _ref.read(notificationNavigationProvider.notifier).handleTap,
        );
    if (_restored) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ledgerStorageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is! Map) continue;
            final map = Map<String, dynamic>.from(e);
            final state = PendingNotificationState.fromJson(map);
            _activeByKey[state.notificationKey] = state;
          }
        }
      } catch (_) {}
    }
    _restored = true;
  }

  Future<void> _persistLedger() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _activeByKey.values.map((e) => e.toJson()).toList();
    await prefs.setString(_ledgerStorageKey, jsonEncode(data));
  }
}

final pendingOrdersNotificationServiceProvider =
    Provider<PendingOrdersNotificationService>((ref) {
      return PendingOrdersNotificationService(ref);
    });
