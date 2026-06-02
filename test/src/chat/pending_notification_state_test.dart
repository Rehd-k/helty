import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/chat/models/pending_orders_models.dart';

void main() {
  group('PendingNotificationState', () {
    test('serializes and deserializes consistently', () {
      const original = PendingNotificationState(
        notificationKey: 'lab:enc-123',
        domain: PendingOrdersDomain.lab,
        status: 'PENDING',
        title: 'Lab order pending',
        body: 'CBC result pending review',
      );

      final encoded = original.toJson();
      final decoded = PendingNotificationState.fromJson(encoded);

      expect(decoded.notificationKey, original.notificationKey);
      expect(decoded.domain, original.domain);
      expect(decoded.status, original.status);
      expect(decoded.title, original.title);
      expect(decoded.body, original.body);
    });

    test('detects meaningful differences', () {
      const a = PendingNotificationState(
        notificationKey: 'k1',
        domain: PendingOrdersDomain.radiology,
        status: 'PENDING',
        title: 'Radiology order pending',
        body: 'CT scan pending report',
      );
      const b = PendingNotificationState(
        notificationKey: 'k1',
        domain: PendingOrdersDomain.radiology,
        status: 'DONE',
        title: 'Radiology order pending',
        body: 'CT scan pending report',
      );
      expect(a.isMeaningfullyDifferent(b), isTrue);
    });
  });
}
