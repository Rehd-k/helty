import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationNavigationIntent {
  const NotificationNavigationIntent({
    required this.type,
    this.conversationId,
    this.pendingKey,
  });

  final String type;
  final String? conversationId;
  final String? pendingKey;

  static NotificationNavigationIntent? fromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final raw = jsonDecode(payload);
      if (raw is! Map) return null;
      final map = Map<String, dynamic>.from(raw);
      return NotificationNavigationIntent(
        type: map['type']?.toString() ?? 'unknown',
        conversationId: map['conversationId']?.toString(),
        pendingKey: map['notificationKey']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}

class NotificationNavigationNotifier
    extends Notifier<NotificationNavigationIntent?> {
  @override
  NotificationNavigationIntent? build() => null;

  void handleTap(NotificationResponse response) {
    final intent = NotificationNavigationIntent.fromPayload(response.payload);
    if (intent == null) return;
    state = intent;
    if (kDebugMode) {
      debugPrint('Notification tap intent: ${intent.type}');
    }
  }

  void consume() {
    state = null;
  }
}

final notificationNavigationProvider =
    NotifierProvider<
      NotificationNavigationNotifier,
      NotificationNavigationIntent?
    >(NotificationNavigationNotifier.new);
