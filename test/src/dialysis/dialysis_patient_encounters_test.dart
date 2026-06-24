import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/dialysis/utils/dialysis_patient_encounters_utils.dart';

Map<String, dynamic> _encounter({
  required String id,
  required String status,
  String? createdAt,
}) {
  return {
    'id': id,
    'status': status,
    if (createdAt != null) 'createdAt': createdAt,
  };
}

void main() {
  group('sortEncountersNewestFirst', () {
    test('sorts by createdAt descending', () {
      final older = _encounter(
        id: '1',
        status: 'COMPLETED',
        createdAt: '2024-01-01T10:00:00.000Z',
      );
      final newer = _encounter(
        id: '2',
        status: 'ONGOING',
        createdAt: '2024-06-01T10:00:00.000Z',
      );

      final sorted = sortEncountersNewestFirst([older, newer]);

      expect(sorted.map((e) => e['id']).toList(), ['2', '1']);
    });
  });

  group('filterEncountersByStatus', () {
    test('returns all encounters when filter is all', () {
      final encounters = [
        _encounter(id: '1', status: 'ONGOING'),
        _encounter(id: '2', status: 'COMPLETED'),
      ];

      expect(
        filterEncountersByStatus(encounters, DialysisEncounterStatusFilter.all).length,
        2,
      );
    });

    test('filters by status', () {
      final encounters = [
        _encounter(id: '1', status: 'ONGOING'),
        _encounter(id: '2', status: 'COMPLETED'),
      ];

      final filtered = filterEncountersByStatus(
        encounters,
        DialysisEncounterStatusFilter.completed,
      );

      expect(filtered.length, 1);
      expect(filtered.first['id'], '2');
    });
  });

  group('filterEncountersByDateRange', () {
    test('includes encounters within range', () {
      final encounters = [
        _encounter(
          id: '1',
          status: 'COMPLETED',
          createdAt: '2024-06-15T10:00:00.000Z',
        ),
        _encounter(
          id: '2',
          status: 'COMPLETED',
          createdAt: '2023-01-01T10:00:00.000Z',
        ),
      ];
      final start = DateTime(2024, 6, 1);
      final end = DateTime(2024, 6, 30, 23, 59, 59, 999);

      final filtered = filterEncountersByDateRange(encounters, start, end);

      expect(filtered.length, 1);
      expect(filtered.first['id'], '1');
    });
  });

  group('encounterNotesPreviewFromMap', () {
    test('returns triageNotes when present', () {
      final preview = encounterNotesPreviewFromMap({
        'triageNotes': '  Patient tolerated session well  ',
      });
      expect(preview, 'Patient tolerated session well');
    });
  });
}
