import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/dialysis/models/dialysis_models.dart';
import 'package:helty/src/dialysis/services/dialysis_api_service.dart';
import 'package:helty/src/providers/module_request_flow_provider.dart';

void main() {
  group('Dialysis models', () {
    test('parses session with patient, service, and consumables', () {
      final json = <String, dynamic>{
        'id': 'session-1',
        'patientId': 'patient-1',
        'status': 'IN_PROGRESS',
        'invoiceId': 'inv-1',
        'invoiceItemId': 'item-1',
        'serviceId': 'svc-1',
        'notes': 'First session',
        'createdAt': '2026-06-06T10:00:00.000Z',
        'patient': {
          'id': 'patient-1',
          'patientId': 'P-001',
          'firstName': 'Jane',
          'surname': 'Doe',
        },
        'service': {'id': 'svc-1', 'name': 'Haemodialysis Session'},
        'consumables': [
          {
            'id': 'sc-1',
            'sessionId': 'session-1',
            'consumableId': 'cons-1',
            'storeLocationId': 'loc-1',
            'quantity': 2,
            'unitPrice': 1500,
            'consumable': {'id': 'cons-1', 'name': 'Dialysis Filter'},
          },
        ],
      };

      final session = DialysisSession.fromJson(json);
      expect(session.id, 'session-1');
      expect(session.status, DialysisSessionStatus.inProgress);
      expect(session.patient?.displayName, 'Jane Doe');
      expect(session.service?.name, 'Haemodialysis Session');
      expect(session.consumables.length, 1);
      expect(session.consumables.first.consumable?.name, 'Dialysis Filter');
    });

    test('parses sessions list response', () {
      final json = <String, dynamic>{
        'sessions': [
          {'id': 's1', 'patientId': 'p1', 'status': 'PENDING'},
          {'id': 's2', 'patientId': 'p2', 'status': 'COMPLETED'},
        ],
        'total': 2,
      };

      final response = DialysisSessionsResponse.fromJson(json);
      expect(response.total, 2);
      expect(response.sessions.length, 2);
      expect(response.sessions.last.status, DialysisSessionStatus.completed);
    });

    test('filters dialysis invoice service lines', () {
      const ctx = PaidModuleRequestContext(
        moduleType: ModuleRequestFlowType.dialysis,
        patientId: 'p1',
        invoiceId: 'inv1',
        invoiceDisplayId: 'BILL-1',
        serviceLines: [
          PaidInvoiceServiceLine(
            invoiceItemId: 'i1',
            serviceName: 'HD Session',
            categoryName: 'Dialysis',
          ),
          PaidInvoiceServiceLine(
            invoiceItemId: 'i2',
            serviceName: 'CBC',
            categoryName: 'Laboratory',
          ),
          PaidInvoiceServiceLine(
            invoiceItemId: 'i3',
            serviceName: 'Consumables pack',
            categoryName: 'Dialysis Services',
          ),
        ],
      );

      final lines = dialysisServiceLines(ctx);
      expect(lines.length, 2);
      expect(lines.map((l) => l.invoiceItemId).toList(), ['i1', 'i3']);
    });

    test('parses backend validation errors', () {
      final service = DialysisApiService();
      final message = service.parseBackendError(
        {
          'message': 'Validation failed',
          'errors': {
            'invoiceItemId': ['Session already exists for this invoice line'],
          },
        },
        'fallback',
      );

      expect(message, contains('invoiceItemId'));
    });
  });
}
