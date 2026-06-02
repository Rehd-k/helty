import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_notification_coordinator.dart';

class ChatLocalNotificationService {
  ChatLocalNotificationService(this._ref);

  final Ref _ref;

  Future<void> showIncomingMessageNotification({
    required String title,
    required String body,
    String? conversationId,
    String? messageId,
    bool isActiveConversation = false,
  }) async {
    final cid = conversationId ?? 'unknown';
    final mid = messageId ?? '${cid}:${DateTime.now().millisecondsSinceEpoch}';
    await _ref
        .read(chatNotificationCoordinatorProvider)
        .showChatNotification(
          title: title,
          body: body,
          conversationId: cid,
          messageId: mid,
          isActiveConversation: isActiveConversation,
        );
  }
}

final chatLocalNotificationServiceProvider =
    Provider<ChatLocalNotificationService>((ref) {
      return ChatLocalNotificationService(ref);
    });
