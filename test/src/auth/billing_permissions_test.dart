import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/auth/billing_permissions.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/models/staff_model.dart';

Staff _staff({
  AccountType? accountType,
  String staffRole = '',
}) {
  return Staff(
    id: '1',
    staffId: 'S1',
    firstName: 'Test',
    lastName: 'User',
    staffRole: staffRole,
    accountType: accountType,
  );
}

BillingInvoiceItem _recurringLine({
  double amountPaid = 0,
  bool refundPending = false,
}) {
  return BillingInvoiceItem(
    id: 'line-1',
    serviceId: 'svc-1',
    quantity: 1,
    unitPrice: 1000,
    isRecurringDaily: true,
    usageSegments: const [],
    lineTotal: 3000,
    lineItemAmountPaid: amountPaid,
    lineCovered: 0,
    lineEffectiveDue: 3000,
    lineAmountDue: 3000,
    refundPending: refundPending,
  );
}

void main() {
  group('canDeleteInpatientInvoice', () {
    test('super admin can delete', () {
      expect(
        canDeleteInpatientInvoice(
          _staff(accountType: AccountType.super_admin),
        ),
        isTrue,
      );
      expect(
        canDeleteInpatientInvoice(_staff(staffRole: 'SUPER_ADMIN')),
        isTrue,
      );
    });

    test('account head can delete', () {
      expect(
        canDeleteInpatientInvoice(
          _staff(
            accountType: AccountType.accounting,
            staffRole: 'ACCOUNT_HEAD',
          ),
        ),
        isTrue,
      );
      expect(
        canDeleteInpatientInvoice(_staff(staffRole: 'ACCOUNTING_HEAD')),
        isTrue,
      );
    });

    test('billing head can delete', () {
      expect(
        canDeleteInpatientInvoice(
          _staff(
            accountType: AccountType.billing,
            staffRole: 'BILLING_HEAD',
          ),
        ),
        isTrue,
      );
    });

    test('accounting and billing staff cannot delete', () {
      expect(
        canDeleteInpatientInvoice(
          _staff(
            accountType: AccountType.accounting,
            staffRole: 'ACCOUNTING_STAFF',
          ),
        ),
        isFalse,
      );
      expect(
        canDeleteInpatientInvoice(
          _staff(
            accountType: AccountType.billing,
            staffRole: 'BILLING_STAFF',
          ),
        ),
        isFalse,
      );
    });

    test('null staff cannot delete', () {
      expect(canDeleteInpatientInvoice(null), isFalse);
    });
  });

  group('canEditRecurringInvoiceItemStartDate', () {
    final head = _staff(
      accountType: AccountType.billing,
      staffRole: 'BILLING_HEAD',
    );

    test('billing head can edit unpaid recurring service line', () {
      expect(
        canEditRecurringInvoiceItemStartDate(head, _recurringLine()),
        isTrue,
      );
    });

    test('denies paid lines', () {
      expect(
        canEditRecurringInvoiceItemStartDate(
          head,
          _recurringLine(amountPaid: 500),
        ),
        isFalse,
      );
    });

    test('denies refund-pending lines', () {
      expect(
        canEditRecurringInvoiceItemStartDate(
          head,
          _recurringLine(refundPending: true),
        ),
        isFalse,
      );
    });

    test('billing staff can edit', () {
      final staff = _staff(
        accountType: AccountType.billing,
        staffRole: 'BILLING_STAFF',
      );
      expect(
        canEditRecurringInvoiceItemStartDate(staff, _recurringLine()),
        isTrue,
      );
    });

    test('accounting staff cannot edit', () {
      final staff = _staff(
        accountType: AccountType.accounting,
        staffRole: 'ACCOUNTING_STAFF',
      );
      expect(
        canEditRecurringInvoiceItemStartDate(staff, _recurringLine()),
        isFalse,
      );
    });
  });
}
