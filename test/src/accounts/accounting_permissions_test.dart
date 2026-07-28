import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/models/staff_model.dart';

Staff _staff({AccountType? accountType, String staffRole = ''}) {
  return Staff(
    id: '1',
    staffId: 'S1',
    firstName: 'Test',
    lastName: 'User',
    staffRole: staffRole,
    accountType: accountType,
  );
}

void main() {
  group('CMD accounts permissions', () {
    final cmd = _staff(accountType: AccountType.cmd, staffRole: 'CMD');
    final head = _staff(
      accountType: AccountType.accounting,
      staffRole: 'ACCOUNT_HEAD',
    );
    final accountingStaff = _staff(
      accountType: AccountType.accounting,
      staffRole: 'ACCOUNTING_STAFF',
    );

    test('CMD can access accounts module and head-level views', () {
      expect(canAccessAccountsModule(cmd), isTrue);
      expect(canViewAccountsHeadData(cmd), isTrue);
      expect(canViewFullRevenueAnalytics(cmd), isTrue);
      expect(canViewBillingAnalyticsDashboard(cmd), isTrue);
      expect(canViewProfitLoss(cmd), isTrue);
      expect(canViewRevenueByService(cmd), isTrue);
      expect(canViewLeakDetection(cmd), isTrue);
      expect(canViewStaffFinancialActivity(cmd), isTrue);
      expect(canViewBankReconciliation(cmd), isTrue);
      expect(canViewFinancialApprovals(cmd), isTrue);
      expect(canViewItemRefundRequests(cmd), isTrue);
      expect(canViewPeriodClose(cmd), isTrue);
      expect(canViewJournalEntries(cmd), isTrue);
      expect(canViewChartOfAccounts(cmd), isTrue);
    });

    test('CMD cannot perform accounts mutations', () {
      expect(isAccountHead(cmd), isFalse);
      expect(canManageBanks(cmd), isFalse);
      expect(canApproveFinancialActions(cmd), isFalse);
      expect(canApproveItemRefundRequests(cmd), isFalse);
      expect(canClosePeriod(cmd), isFalse);
      expect(canPostJournalEntries(cmd), isFalse);
      expect(canManageChartOfAccounts(cmd), isFalse);
      expect(canAcknowledgeCompliance(cmd), isFalse);
      expect(canPerformBankReconciliation(cmd), isFalse);
      expect(canSubmitDailyCashRecon(cmd), isFalse);
      expect(canRefundOrChangePaymentDate(cmd), isFalse);
      expect(canExportFullReports(cmd), isFalse);
    });

    test('Account Head retains mutation rights', () {
      expect(isAccountHead(head), isTrue);
      expect(canApproveFinancialActions(head), isTrue);
      expect(canClosePeriod(head), isTrue);
      expect(canPostJournalEntries(head), isTrue);
      expect(canManageChartOfAccounts(head), isTrue);
      expect(canManageBanks(head), isTrue);
      expect(canSubmitDailyCashRecon(head), isTrue);
    });

    test('Accounting staff can submit cash recon but not head mutations', () {
      expect(canAccessAccountsModule(accountingStaff), isTrue);
      expect(canViewAccountsHeadData(accountingStaff), isFalse);
      expect(canSubmitDailyCashRecon(accountingStaff), isTrue);
      expect(canApproveFinancialActions(accountingStaff), isFalse);
      expect(canPostJournalEntries(accountingStaff), isFalse);
    });
  });

  group('Billing head item refund requests', () {
    final billingHead = _staff(
      accountType: AccountType.billing,
      staffRole: 'BILLING_HEAD',
    );
    final billingStaff = _staff(
      accountType: AccountType.billing,
      staffRole: 'BILLING_STAFF',
    );

    test('Billing head can view and approve item refund requests', () {
      expect(canViewItemRefundRequests(billingHead), isTrue);
      expect(canApproveItemRefundRequests(billingHead), isTrue);
    });

    test('Billing staff cannot view or approve item refund requests', () {
      expect(canViewItemRefundRequests(billingStaff), isFalse);
      expect(canApproveItemRefundRequests(billingStaff), isFalse);
    });
  });
}
