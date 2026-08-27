import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/auth/theatre_permissions.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/theatre/models/theatre_models.dart';

void main() {
  group('SurgeryRequestStatus', () {
    test('round-trips api values', () {
      for (final status in SurgeryRequestStatus.values) {
        expect(SurgeryRequestStatus.fromString(status.apiValue), status);
      }
    });
  });

  group('SurgeryRequest.fromJson', () {
    test('parses nested case and schedule', () {
      final request = SurgeryRequest.fromJson({
        'id': 'req-1',
        'encounterId': 'enc-1',
        'patientId': 'pat-1',
        'status': 'IN_PROGRESS',
        'priority': 'URGENT',
        'patient': {'id': 'pat-1', 'firstName': 'Jane', 'surname': 'Doe'},
        'service': {'id': 'svc-1', 'name': 'Appendectomy'},
        'schedule': {
          'id': 'sch-1',
          'surgeryRequestId': 'req-1',
          'theatreRoomId': 'room-1',
          'scheduledAt': '2026-06-25T09:00:00.000Z',
          'theatreRoom': {'id': 'room-1', 'name': 'OT 1'},
        },
        'case': {
          'id': 'case-1',
          'findings': 'Inflamed appendix',
          'consumables': [
            {
              'id': 'line-1',
              'consumableId': 'c-1',
              'storeLocationId': 'loc-1',
              'quantity': 2,
              'unitPrice': 7500,
              'billable': true,
            },
          ],
          'operativeNoteRecords': [
            {
              'id': 'note-1',
              'narrative': 'Procedure: Appendectomy',
              'additionalNotes': 'Uneventful',
              'answersJson': {
                'procedure': {'name': 'Appendectomy'},
              },
              'authoredBy': {
                'id': 's-1',
                'firstName': 'Ada',
                'lastName': 'Okeke',
              },
            },
          ],
        },
      });

      expect(request.id, 'req-1');
      expect(request.status, SurgeryRequestStatus.inProgress);
      expect(request.priority, SurgeryPriority.urgent);
      expect(request.patient?.displayName, 'Jane Doe');
      expect(request.service?.name, 'Appendectomy');
      expect(request.schedule?.theatreRoom?.name, 'OT 1');
      expect(request.theatreCase?.findings, 'Inflamed appendix');
      expect(request.theatreCase?.consumables.length, 1);
      expect(request.theatreCase?.operativeNoteRecords.length, 1);
      expect(
        request.theatreCase?.operativeNoteRecords.first.narrative,
        'Procedure: Appendectomy',
      );
    });
  });

  group('theatre permissions', () {
    Staff staffWithRole(String role, {AccountType? accountType}) {
      return Staff(
        id: 's1',
        staffId: 'ST-1',
        firstName: 'Test',
        lastName: 'User',
        staffRole: role,
        accountType: accountType,
      );
    }

    test('theatre head can bill and manage rooms', () {
      final head = staffWithRole(
        'THEATRE_HEAD',
        accountType: AccountType.theatre,
      );
      expect(canAccessTheatreModule(head), isTrue);
      expect(canManageTheatreClinical(head), isTrue);
      expect(canBillTheatreCase(head), isTrue);
      expect(canManageTheatreRooms(head), isTrue);
    });

    test('theatre receptionist can bill but not manage rooms', () {
      final reception = staffWithRole(
        'THEATRE_RECEPTIONIST',
        accountType: AccountType.theatre,
      );
      expect(canBillTheatreCase(reception), isTrue);
      expect(canManageTheatreRooms(reception), isFalse);
      expect(canManageTheatreClinical(reception), isFalse);
    });

    test('consultant can book surgery', () {
      final doctor = staffWithRole(
        'CONSULTANT',
        accountType: AccountType.physician,
      );
      expect(canBookSurgeryRequests(doctor), isTrue);
      expect(canAccessTheatreModule(doctor), isFalse);
    });

    test('resident can book surgery from an encounter', () {
      final resident = staffWithRole(
        'RESIDENT',
        accountType: AccountType.physician,
      );
      expect(canBookSurgeryRequests(resident), isTrue);
    });

    test('medical student cannot book surgery', () {
      final student = staffWithRole(
        'MEDICAL_STUDENT',
        accountType: AccountType.physician,
      );
      expect(canBookSurgeryRequests(student), isFalse);
      expect(canWriteOperativeNotes(student), isFalse);
    });

    test('consultant can write operative notes', () {
      final doctor = staffWithRole(
        'CONSULTANT',
        accountType: AccountType.physician,
      );
      expect(canWriteOperativeNotes(doctor), isTrue);
      expect(canManageTheatreClinical(doctor), isFalse);
    });

    test('theatre nurse can write operative notes', () {
      final nurse = staffWithRole(
        'THEATRE_NURSE',
        accountType: AccountType.theatre,
      );
      expect(canWriteOperativeNotes(nurse), isTrue);
    });
  });

  group('isSurgeryServiceCategoryName', () {
    test('accepts spec categories case-insensitively', () {
      expect(isSurgeryServiceCategoryName('Surgical Procedures'), isTrue);
      expect(isSurgeryServiceCategoryName('general procedures'), isTrue);
      expect(isSurgeryServiceCategoryName('Laboratory'), isFalse);
    });
  });
}
