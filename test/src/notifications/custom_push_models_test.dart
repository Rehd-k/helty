import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/notifications/custom_push/custom_push_models.dart';

void main() {
  group('CustomPushResult.fromJson', () {
    test('parses ALL broadcast response', () {
      final result = CustomPushResult.fromJson({
        'id': 'custom-push-log-uuid',
        'targetType': 'ALL',
        'targetedPatients': 42,
        'successCount': 40,
        'failureCount': 2,
      });
      expect(result.id, 'custom-push-log-uuid');
      expect(result.targetType, 'ALL');
      expect(result.isBroadcast, isTrue);
      expect(result.targetedPatients, 42);
      expect(result.successCount, 40);
      expect(result.failureCount, 2);
    });

    test('parses SELECTED response', () {
      final result = CustomPushResult.fromJson({
        'id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'targetType': 'SELECTED',
        'targetedPatients': 2,
        'successCount': 2,
        'failureCount': 0,
      });
      expect(result.targetType, 'SELECTED');
      expect(result.isBroadcast, isFalse);
      expect(result.targetedPatients, 2);
      expect(result.successCount, 2);
      expect(result.failureCount, 0);
    });

    test('coerces numeric strings', () {
      final result = CustomPushResult.fromJson({
        'id': 'x',
        'targetType': 'ALL',
        'targetedPatients': '3',
        'successCount': '1',
        'failureCount': '2',
      });
      expect(result.targetedPatients, 3);
      expect(result.successCount, 1);
      expect(result.failureCount, 2);
    });
  });

  group('validateCustomPushFields', () {
    test('requires title and body', () {
      expect(
        validateCustomPushFields(title: '  ', body: 'Hello'),
        'Title is required.',
      );
      expect(
        validateCustomPushFields(title: 'Hi', body: ''),
        'Message body is required.',
      );
    });

    test('enforces max lengths', () {
      expect(
        validateCustomPushFields(
          title: 'a' * (kCustomPushTitleMaxLength + 1),
          body: 'ok',
        ),
        contains('Title must be at most'),
      );
      expect(
        validateCustomPushFields(
          title: 'ok',
          body: 'b' * (kCustomPushBodyMaxLength + 1),
        ),
        contains('Message body must be at most'),
      );
    });

    test('accepts empty image URL', () {
      expect(
        validateCustomPushFields(
          title: 'Holiday hours',
          body: 'The hospital will close at 2pm on Friday.',
        ),
        isNull,
      );
    });

    test('rejects non-http image URL', () {
      expect(
        validateCustomPushFields(
          title: 'Hi',
          body: 'Body',
          imageUrl: 'ftp://cdn.example.com/x.png',
        ),
        contains('HTTP(S)'),
      );
      expect(
        validateCustomPushFields(
          title: 'Hi',
          body: 'Body',
          imageUrl: 'not-a-url',
        ),
        contains('HTTP(S)'),
      );
    });

    test('accepts https image URL', () {
      expect(
        validateCustomPushFields(
          title: 'Hi',
          body: 'Body',
          imageUrl: 'https://cdn.example.com/notice.png',
        ),
        isNull,
      );
    });
  });
}
