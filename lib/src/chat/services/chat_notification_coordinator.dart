import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_lifecycle_provider.dart';
import '../../notifications/local_notification_platform_service.dart';
import '../../notifications/notification_navigation_provider.dart';

class ChatNotificationCoordinator {
  ChatNotificationCoordinator(this.ref);

  final Ref ref;

  static const String chatChannelId = 'staff_chat_messages';
  static const String chatChannelName = 'Staff chat messages';
  static const String chatChannelDescription =
      'Notifications for incoming staff chat messages';

  Future<void> initialize() async {
    await ref
        .read(localNotificationPlatformServiceProvider)
        .initialize(
          onTap: ref.read(notificationNavigationProvider.notifier).handleTap,
        );
  }

  Future<void> showChatNotification({
    required String title,
    required String body,
    required String conversationId,
    required String messageId,
    required bool isActiveConversation,
  }) async {
    final lifecycle = ref.read(appLifecycleProvider);
    final foreground = lifecycle == AppLifecycleState.resumed;
    if (foreground && isActiveConversation) {
      return;
    }
    await initialize();
    final payload = jsonEncode(<String, dynamic>{
      'type': 'chat',
      'conversationId': conversationId,
      'messageId': messageId,
    });
    await ref
        .read(localNotificationPlatformServiceProvider)
        .show(
          id: _notificationId(messageId),
          title: title,
          body: body,
          payload: payload,
          details: const NotificationDetails(
            android: AndroidNotificationDetails(
              chatChannelId,
              chatChannelName,
              channelDescription: chatChannelDescription,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
            windows: WindowsNotificationDetails(),
          ),
        );
  }

  int _notificationId(String basis) => basis.hashCode & 0x7fffffff;
}

final chatNotificationCoordinatorProvider =
    Provider<ChatNotificationCoordinator>(ChatNotificationCoordinator.new);
