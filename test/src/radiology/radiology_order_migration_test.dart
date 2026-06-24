import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';

void main() {
  group('Radiology order migration', () {
    test('parses create order response with multiple items', () {
      final json = <String, dynamic>{
        'id': 'order-1',
        'patientId': 'patient-1',
        'requestedById': 'staff-1',
        'status': 'PENDING',
        'items': [
          {
            'id': 'item-1',
            'orderId': 'order-1',
            'scanType': 'CT',
            'priority': 'ROUTINE',
            'status': 'PENDING',
          },
          {
            'id': 'item-2',
            'orderId': 'order-1',
            'scanType': 'MRI',
            'priority': 'URGENT',
            'status': 'PENDING',
          },
        ],
      };

      final order = RadiologyOrder.fromJson(json);
      expect(order.items.length, 2);
      expect(order.items.first.scanType, RadiologyModality.CT);
      expect(order.items.last.scanType, RadiologyModality.MRI);
    });

    test('supports partial item progress on same order', () {
      final json = <String, dynamic>{
        'id': 'order-2',
        'patientId': 'patient-2',
        'requestedById': 'staff-2',
        'status': 'ACTIVE',
        'items': [
          {
            'id': 'item-a',
            'orderId': 'order-2',
            'scanType': 'X_RAY',
            'priority': 'ROUTINE',
            'status': 'COMPLETED',
          },
          {
            'id': 'item-b',
            'orderId': 'order-2',
            'scanType': 'ULTRASOUND',
            'priority': 'URGENT',
            'status': 'IN_PROGRESS',
          },
        ],
      };

      final order = RadiologyOrder.fromJson(json);
      expect(order.status, RadiologyOrderStatus.ACTIVE);
      expect(order.items[0].status, RadiologyOrderItemStatus.COMPLETED);
      expect(order.items[1].status, RadiologyOrderItemStatus.IN_PROGRESS);
    });

    test('infers scan modality from study name', () {
      expect(
        RadiologyModality.inferFromStudyName('Chest X-Ray PA'),
        RadiologyModality.X_RAY,
      );
      expect(
        RadiologyModality.inferFromStudyName('CT Scan of Abdomen'),
        RadiologyModality.CT,
      );
      expect(
        RadiologyModality.inferFromStudyName('MRI Brain with contrast'),
        RadiologyModality.MRI,
      );
      expect(
        RadiologyModality.inferFromStudyName('Obstetric Ultrasound'),
        RadiologyModality.ULTRASOUND,
      );
      expect(
        RadiologyModality.inferFromStudyName('Bone Density Scan'),
        RadiologyModality.OTHER,
      );
    });

    test('parses item-level invoice linkage validation errors', () {
      final service = RadiologyService();
      final message = service.parseBackendError(
        {
          'message': 'Validation failed',
          'errors': {
            'items.0.invoiceId': ['invoiceId is required with invoiceItemId'],
            'items.0.serviceId': ['serviceId is required with invoice trio'],
          },
        },
        'fallback',
      );

      expect(message, contains('items.0.invoiceId'));
      expect(message, contains('items.0.serviceId'));
    });
  });
}
