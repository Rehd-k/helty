import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/frontdesk/patient_access/patient_access_models.dart';

void main() {
  group('PatientDeviceRow.fromJson', () {
    test('parses nested patient summary', () {
      final row = PatientDeviceRow.fromJson({
        'id': 'dev-1',
        'deviceLabel': 'Pixel 7',
        'platform': 'ANDROID',
        'status': 'PENDING',
        'createdAt': '2026-07-19T10:00:00.000Z',
        'patient': {
          'id': 'pat-uuid',
          'patientId': 'H-100',
          'firstName': 'Ada',
          'lastName': 'Lovelace',
        },
      });
      expect(row.id, 'dev-1');
      expect(row.deviceLabel, 'Pixel 7');
      expect(row.platform, 'ANDROID');
      expect(row.isPending, isTrue);
      expect(row.patient?.id, 'pat-uuid');
      expect(row.patient?.patientId, 'H-100');
      expect(row.patient?.displayName, 'Ada Lovelace');
      expect(row.createdAt, isNotNull);
    });

    test('parses APPROVED status', () {
      final row = PatientDeviceRow.fromJson({
        'id': 'dev-2',
        'deviceLabel': 'iPhone',
        'platform': 'IOS',
        'status': 'APPROVED',
      });
      expect(row.isApproved, isTrue);
      expect(row.isPending, isFalse);
    });
  });

  group('PatientDevicePage.fromJson', () {
    test('parses items and pagination meta', () {
      final page = PatientDevicePage.fromJson({
        'data': [
          {
            'id': 'd1',
            'deviceLabel': 'Phone',
            'platform': 'ANDROID',
            'status': 'PENDING',
          },
        ],
        'meta': {'page': 2, 'limit': 20, 'total': 45},
      });
      expect(page.items, hasLength(1));
      expect(page.page, 2);
      expect(page.limit, 20);
      expect(page.total, 45);
      expect(page.hasMore, isTrue);
    });

    test('parses bare items list', () {
      final page = PatientDevicePage.fromJson({
        'items': [
          {
            'id': 'd1',
            'deviceLabel': 'Phone',
            'platform': 'IOS',
            'status': 'PENDING',
          },
        ],
        'page': 1,
        'limit': 20,
        'total': 1,
      });
      expect(page.items, hasLength(1));
      expect(page.hasMore, isFalse);
    });
  });

  group('FamilyChildRow.fromJson', () {
    test('parses flat child fields', () {
      final child = FamilyChildRow.fromJson({
        'id': 'child-uuid',
        'patientId': 'H-200',
        'firstName': 'Alan',
        'lastName': 'Turing',
      });
      expect(child.id, 'child-uuid');
      expect(child.patientId, 'H-200');
      expect(child.displayName, 'Alan Turing');
    });

    test('parses nested child patient', () {
      final child = FamilyChildRow.fromJson({
        'childPatientId': 'child-uuid',
        'child': {
          'id': 'child-uuid',
          'patientId': 'H-201',
          'displayName': 'Grace Hopper',
        },
      });
      expect(child.id, 'child-uuid');
      expect(child.patientId, 'H-201');
      expect(child.displayName, 'Grace Hopper');
    });
  });

  group('unwrapPatientAccessPayload', () {
    test('unwraps sole data envelope', () {
      final raw = unwrapPatientAccessPayload({
        'data': [
          {'id': '1'},
        ],
      });
      expect(raw, isA<List>());
      expect((raw as List).length, 1);
    });

    test('keeps paginated map with data siblings', () {
      final raw = unwrapPatientAccessPayload({
        'data': [
          {'id': '1'},
        ],
        'page': 1,
        'total': 1,
      });
      expect(raw, isA<Map>());
      expect((raw as Map)['page'], 1);
    });
  });
}
