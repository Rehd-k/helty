import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/pharmacy/utils/medication_request_permissions.dart';

MedicationOrderModel _order({
  String drugId = 'drug-1',
  String status = 'Prescribed',
  String? invoiceItemId,
}) {
  return MedicationOrderModel(
    id: 'order-1',
    encounterId: 'enc-1',
    drugId: drugId,
    drugName: 'Paracetamol',
    status: status,
    invoiceItemId: invoiceItemId,
  );
}

void main() {
  group('medicationRequestDisableReason', () {
    test('returns null when request is allowed', () {
      expect(_order().medicationRequestDisableReason, isNull);
    });

    test('explains missing drug', () {
      expect(
        _order(drugId: ' ').medicationRequestDisableReason,
        'No drug is linked to this order',
      );
    });

    test('explains legacy billed orders', () {
      expect(
        _order(invoiceItemId: 'inv-item-1').medicationRequestDisableReason,
        'Legacy order — already billed at prescribe',
      );
    });

    test('allows dispensed orders for repeat requests', () {
      expect(_order(status: 'Dispensed').medicationRequestDisableReason, isNull);
      expect(_order(status: 'Dispensed').canRequestMedication, isTrue);
    });

    test('explains unsupported order status', () {
      expect(
        _order(status: 'Cancelled').medicationRequestDisableReason,
        'Order status is "Cancelled" — requests require Prescribed, Pending Dispense, or Dispensed',
      );
    });
  });

  group('nurseMedicationRequestDisableReason', () {
    test('returns null when nurse may request', () {
      expect(
        nurseMedicationRequestDisableReason(
          order: _order(),
          isOutpatient: false,
          isNurse: true,
          isAdmissionActive: true,
        ),
        isNull,
      );
    });

    test('explains inactive admission', () {
      expect(
        nurseMedicationRequestDisableReason(
          order: _order(),
          isOutpatient: false,
          isNurse: true,
          isAdmissionActive: false,
          admissionStatus: 'DISCHARGED',
        ),
        'Admission is DISCHARGED — requests are only allowed while admitted',
      );
    });

    test('allows dispensed orders for repeat requests', () {
      expect(
        nurseMedicationRequestDisableReason(
          order: _order(status: 'Dispensed'),
          isOutpatient: false,
          isNurse: true,
          isAdmissionActive: true,
        ),
        isNull,
      );
    });

    test('falls back to order-level reason', () {
      expect(
        nurseMedicationRequestDisableReason(
          order: _order(status: 'Cancelled'),
          isOutpatient: false,
          isNurse: true,
          isAdmissionActive: true,
        ),
        'Order status is "Cancelled" — requests require Prescribed, Pending Dispense, or Dispensed',
      );
    });
  });
}
