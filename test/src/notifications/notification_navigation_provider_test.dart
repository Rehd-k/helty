import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/notifications/notification_navigation_provider.dart';

void main() {
  group('NotificationNavigationIntent', () {
    test('parses chat payload', () {
      final intent = NotificationNavigationIntent.fromPayload(
        '{"type":"chat","conversationId":"c-123","messageId":"m-1"}',
      );
      expect(intent, isNotNull);
      expect(intent!.type, 'chat');
      expect(intent.conversationId, 'c-123');
    });

    test('returns null for malformed payload', () {
      final intent = NotificationNavigationIntent.fromPayload('{bad-json');
      expect(intent, isNull);
    });
  });

  group('NotificationNavigationNotifier', () {
    test('stores and clears tap intent', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(notificationNavigationProvider.notifier)
          .handleTap(
            const NotificationResponse(
              notificationResponseType:
                  NotificationResponseType.selectedNotification,
              payload: '{"type":"pending_order","notificationKey":"drug:1"}',
            ),
          );
      expect(container.read(notificationNavigationProvider), isNotNull);
      expect(
        container.read(notificationNavigationProvider)!.type,
        'pending_order',
      );
      container.read(notificationNavigationProvider.notifier).consume();
      expect(container.read(notificationNavigationProvider), isNull);
    });
  });
}
