import 'package:flutter/material.dart';

import '../../../app_router.gr.dart';
import 'home_screen.dart';

final frontDesk = <MenuItem>[
  MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: FrontDeskDashboardRoute(),
  ),
  MenuItem(
    label: 'ED Board',
    icon: Icons.emergency_outlined,
    route: EdBoardRoute(),
  ),
  MenuItem(
    label: 'ED Registration',
    icon: Icons.person_add_alt_1_outlined,
    route: EdRegistrationRoute(),
  ),
  MenuItem(
    label: 'View Waiting Patients',
    icon: Icons.add_alarm_outlined,
    route: NewPatientRoute(use: 'For Register'),
  ),
  MenuItem(
    label: 'Patients',
    icon: Icons.view_agenda_outlined,
    route: PatientListRoute(),
    children: [
      MenuItem(
        label: 'Add New Patient',
        icon: Icons.view_agenda_outlined,
        route: PatientFormRoute(),
      ),
      MenuItem(
        label: 'View Patients',
        icon: Icons.add_alarm_outlined,
        route: PatientListRoute(),
      ),
    ],
  ),
  MenuItem(
    label: 'Appointments',
    icon: Icons.calendar_month,
    route: AppointmentListRoute(),
    children: [
      MenuItem(
        label: 'Add New Appointment',
        icon: Icons.view_agenda_outlined,
        route: NewAppointmentRoute(),
      ),
      MenuItem(
        label: 'View Appointments',
        icon: Icons.add_alarm_outlined,
        route: AppointmentListRoute(),
      ),
    ],
  ),
];

/// Same entries as [frontDesk] plus completed encounters (medical records only).
final medicalRecordsMenu = <MenuItem>[
  ...frontDesk,
  MenuItem(
    label: 'Patient chart',
    icon: Icons.folder_shared_outlined,
    route: PatientChartSelectRoute(),
  ),
  MenuItem(
    label: 'Completed Encounters',
    icon: Icons.check_circle_outline,
    route: DoctorCompletedEncountersRoute(),
  ),
  MenuItem(
    label: 'Paid consultation report',
    icon: Icons.receipt_long_outlined,
    route: ConsultationPaymentReportRoute(),
  ),
];

final bills = <MenuItem>[
  MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_customize_outlined,
    route: BillingDashboardRoute(),
  ),
  MenuItem(
    label: 'Pending Transaction',
    icon: Icons.pending_actions_outlined,
    route: PendingBillsRoute(),
  ),
  MenuItem(
    label: 'Render Service',
    icon: Icons.dataset_outlined,
    route: EnlistPaitientRoute(serviceName: 'OPD'),
  ),
  MenuItem(
    label: 'Process Ward Payment',
    icon: Icons.access_time_filled_outlined,
    route: EnlistPaitientRoute(serviceName: 'inpatient'),
  ),
  MenuItem(
    label: 'Add Service',
    icon: Icons.add_box_outlined,
    route: SystemSetupRoute(),
  ),
  // MenuItem(
  //   label: 'Debt/Insurance Payment',
  //   icon: Icons.personal_injury_outlined,
  //   route: NotAvailableRoute(),
  // ),
  MenuItem(
    label: 'Transaction',
    icon: Icons.list_outlined,
    route: TransactionsRoute(),
  ),
];

/// HMO desk — same enlist → render-service workflow as billing (narrower than [bills]).
final hmoDeskMenu = <MenuItem>[
  MenuItem(
    label: 'HMO plans',
    icon: Icons.health_and_safety_outlined,
    route: HmoListRoute(),
  ),
  MenuItem(
    label: 'Add HMO',
    icon: Icons.add_business_outlined,
    route: HmoFormRoute(),
  ),
  MenuItem(
    label: 'HMO service pricing',
    icon: Icons.price_change_outlined,
    route: HmoServicePricingRoute(),
  ),
  MenuItem(
    label: 'Pending Transaction',
    icon: Icons.pending_actions_outlined,
    route: PendingBillsRoute(),
  ),
  MenuItem(
    label: 'Render Service',
    icon: Icons.dataset_outlined,
    route: EnlistPaitientRoute(serviceName: 'OPD'),
  ),
  MenuItem(
    label: 'Process Ward Payment',
    icon: Icons.access_time_filled_outlined,
    route: EnlistPaitientRoute(serviceName: 'inpatient'),
  ),
  const MenuItem(
    label: 'Receivables',
    icon: Icons.receipt_long_outlined,
    route: ReceivablesHmoRoute(),
    children: [
      MenuItem(
        label: 'HMO Receivables',
        icon: Icons.health_and_safety_outlined,
        route: ReceivablesHmoRoute(),
      ),
      MenuItem(
        label: 'Discount Receivables',
        icon: Icons.sell_outlined,
        route: ReceivablesDiscountRoute(),
      ),
    ],
  ),
];

final nurses = <MenuItem>[
  MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: NursesDashboardRoute(),
  ),
  MenuItem(
    label: 'ED Board',
    icon: Icons.emergency_outlined,
    route: EdBoardRoute(),
  ),
  MenuItem(
    label: 'Patient chart',
    icon: Icons.folder_shared_outlined,
    route: PatientChartSelectRoute(),
  ),
  MenuItem(
    label: 'Waiting Patients',
    icon: Icons.add_alarm_outlined,
    route: WaitingPatientsRoute(),
  ),
  MenuItem(
    label: 'Inpatients (Ward Census)',
    icon: Icons.bed,
    route: InpatientsListRoute(),
  ),
  MenuItem(
    label: 'Consumables',
    icon: Icons.medical_information_outlined,
    route: EnlistPaitientRoute(serviceName: 'Consumables'),
  ),
  MenuItem(
    label: 'O&G Dashboard',
    icon: Icons.pregnant_woman_rounded,
    route: ObstetricsDashboardRoute(),
  ),
  MenuItem(
    label: 'Pregnancies (by patient)',
    icon: Icons.family_restroom_rounded,
    route: ObstetricsPatientSelectRoute(),
  ),
  MenuItem(
    label: 'Gynaecology procedures',
    icon: Icons.medical_services_rounded,
    route: ObstetricsGynaeProceduresRoute(),
  ),
  MenuItem(
    label: 'Radiology',
    icon: Icons.radar_rounded,
    route: RadiologyDashboardRoute(),
  ),
  MenuItem(
    label: 'Appointments',
    icon: Icons.calendar_month,
    route: AppointmentListRoute(),
    children: [
      MenuItem(
        label: 'Add New Appointment',
        icon: Icons.view_agenda_outlined,
        route: NewAppointmentRoute(),
      ),
      MenuItem(
        label: 'View Appointments',
        icon: Icons.add_alarm_outlined,
        route: AppointmentListRoute(),
      ),
    ],
  ),
];

final doctors = <MenuItem>[
  MenuItem(
    label: 'My Appointments',
    icon: Icons.calendar_today_outlined,
    route: DoctorOutpatientListRoute(),
  ),
  MenuItem(
    label: 'Walk-in Queue',
    icon: Icons.people_outline,
    route: DoctorWalkInQueueRoute(),
  ),
  MenuItem(
    label: 'ED Board',
    icon: Icons.emergency_outlined,
    route: EdBoardRoute(),
  ),
  MenuItem(
    label: 'ED Registration',
    icon: Icons.person_add_alt_1_outlined,
    route: EdRegistrationRoute(),
  ),
  MenuItem(
    label: 'Ward Rounds',
    icon: Icons.medical_services_outlined,
    route: WardRoundsRoute(),
  ),
  MenuItem(label: 'Inpatients', icon: Icons.bed, route: InpatientsListRoute()),
  MenuItem(
    label: 'Consumables',
    icon: Icons.medical_information_outlined,
    route: EnlistPaitientRoute(serviceName: 'Consumables'),
  ),
  MenuItem(
    label: 'O&G Dashboard',
    icon: Icons.pregnant_woman_rounded,
    route: ObstetricsDashboardRoute(),
  ),
  MenuItem(
    label: 'Pregnancies (by patient)',
    icon: Icons.family_restroom_rounded,
    route: ObstetricsPatientSelectRoute(),
  ),
  MenuItem(
    label: 'Gynaecology procedures',
    icon: Icons.medical_services_rounded,
    route: ObstetricsGynaeProceduresRoute(),
  ),

  MenuItem(
    label: 'Completed Encounters',
    icon: Icons.check_circle_outline,
    route: DoctorCompletedEncountersRoute(),
  ),
  MenuItem(
    label: 'Templates',
    icon: Icons.description_outlined,
    route: DoctorTemplatesRoute(),
  ),
  MenuItem(
    label: 'Profile',
    icon: Icons.person_outline,
    route: DoctorProfileRoute(),
  ),
];

final pharmacy = <MenuItem>[
  MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: PharmacyDashboardRoute(),
  ),
  MenuItem(
    label: 'Medicine Inventory',
    icon: Icons.inventory_2_outlined,
    route: MedicineInventoryRoute(),
  ),

  MenuItem(
    label: 'Add Supplier',
    icon: Icons.person_add_alt_1_outlined,
    route: AddSupplierRoute(),
  ),
  MenuItem(
    label: 'Add Supply',
    icon: Icons.add_box_outlined,
    route: AddBatchRoute(),
  ),
  MenuItem(
    label: 'Dispense History',
    icon: Icons.receipt_long_outlined,
    route: DispenseHistoryRoute(),
  ),
  MenuItem(
    label: 'Stock Transfer',
    icon: Icons.move_to_inbox_outlined,
    route: StockTransferRoute(),
  ),
  MenuItem(
    label: 'Create Requisition',
    icon: Icons.receipt_long_outlined,
    route: CreateRequisitionRoute(),
  ),
  MenuItem(
    label: 'Supply History',
    icon: Icons.list_alt_outlined,
    route: SupplyHistoryRoute(),
  ),
  MenuItem(
    label: 'Pharmacy Locations',
    icon: Icons.location_on_outlined,
    route: PharmacyLocationRoute(),
  ),
  MenuItem(
    label: 'Medicine Sales',
    icon: Icons.add_alarm_outlined,
    route: EnlistPaitientRoute(serviceName: 'Pharmacy'),
  ),

  MenuItem(
    label: 'Pharmacy Waiting Patient',
    icon: Icons.add_alarm_outlined,
    route: WaitingPatientRoute(),
  ),
];

final phamDispense = <MenuItem>[
  MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: PharmacyDashboardRoute(),
  ),
  MenuItem(
    label: 'Medicine Inventory',
    icon: Icons.inventory_2_outlined,
    route: MedicineInventoryRoute(),
  ),

  MenuItem(
    label: 'Add Supplier',
    icon: Icons.person_add_alt_1_outlined,
    route: AddSupplierRoute(),
  ),
  MenuItem(
    label: 'Add Supply',
    icon: Icons.add_box_outlined,
    route: AddBatchRoute(),
  ),
  MenuItem(
    label: 'Dispense History',
    icon: Icons.receipt_long_outlined,
    route: DispenseHistoryRoute(),
  ),
  MenuItem(
    label: 'Stock Transfer',
    icon: Icons.move_to_inbox_outlined,
    route: StockTransferRoute(),
  ),
  MenuItem(
    label: 'Create Requisition',
    icon: Icons.receipt_long_outlined,
    route: CreateRequisitionRoute(),
  ),
  MenuItem(
    label: 'Supply History',
    icon: Icons.list_alt_outlined,
    route: SupplyHistoryRoute(),
  ),
  MenuItem(
    label: 'Pharmacy Locations',
    icon: Icons.location_on_outlined,
    route: PharmacyLocationRoute(),
  ),
  MenuItem(
    label: 'Medicine Sales',
    icon: Icons.add_alarm_outlined,
    route: EnlistPaitientRoute(serviceName: 'Pharmacy'),
  ),

  MenuItem(
    label: 'Pharmacy Waiting Patient',
    icon: Icons.add_alarm_outlined,
    route: WaitingPatientRoute(),
  ),
];

final purchasesMenu = <MenuItem>[
  MenuItem(
    label: 'Inventory',
    icon: Icons.inventory_2_outlined,
    route: PurchasesInventoryRoute(),
  ),
  MenuItem(
    label: 'Add Supplier',
    icon: Icons.person_add_alt_1_outlined,
    route: PurchasesAddSupplierRoute(),
  ),
  MenuItem(
    label: 'Add Purchases',
    icon: Icons.add_box_outlined,
    route: PurchasesAddPurchaseRoute(),
  ),
  MenuItem(
    label: 'Stock Transfer',
    icon: Icons.move_to_inbox_outlined,
    route: PurchasesStockTransferRoute(),
  ),
  MenuItem(
    label: 'Transfer History',
    icon: Icons.receipt_long_outlined,
    route: PurchasesTransferHistoryRoute(),
  ),
  MenuItem(
    label: 'Purchase History',
    icon: Icons.list_alt_outlined,
    route: PurchasesPurchaseHistoryRoute(),
  ),
  MenuItem(
    label: 'Stores',
    icon: Icons.location_on_outlined,
    route: PurchasesLocationRoute(),
  ),
  MenuItem(
    label: 'Requisition History',
    icon: Icons.history_outlined,
    route: PurchasesRequisitionHistoryRoute(),
  ),
  MenuItem(
    label: 'Usage History',
    icon: Icons.history_toggle_off_outlined,
    route: PurchasesUsageHistoryRoute(),
  ),
  MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: PurchasesDashboardRoute(),
  ),
];

final obstetrics = <MenuItem>[];

final labMenu = <MenuItem>[
  MenuItem(
    label: 'Laboratory',
    icon: Icons.biotech_rounded,
    route: LabDashboardRoute(),
  ),

  MenuItem(
    label: 'New patient',
    icon: Icons.add_circle_outline_rounded,
    route: EnlistPaitientRoute(serviceName: 'lab'),
  ),
  MenuItem(
    label: 'Waiting Patients',
    icon: Icons.receipt_long_outlined,
    route: NewPatientRoute(
      use: 'Laboratory',
      categoryQueries: const ['Laboratory', 'Laboratory Tests'],
    ),
  ),
];

final dialysisMenu = <MenuItem>[
  MenuItem(
    label: 'Dialysis',
    icon: Icons.bloodtype_rounded,
    route: DialysisDashboardRoute(),
  ),
  MenuItem(
    label: 'New patient',
    icon: Icons.add_circle_outline_rounded,
    route: EnlistPaitientRoute(serviceName: 'dialysis'),
  ),
  MenuItem(
    label: 'Waiting Patients',
    icon: Icons.receipt_long_outlined,
    route: NewPatientRoute(
      use: 'Dialysis',
      categoryQueries: const ['Dialysis', 'Dialysis Services'],
    ),
  ),
];

final radiologyMenu = <MenuItem>[
  MenuItem(
    label: 'Radiology',
    icon: Icons.radar_rounded,
    route: RadiologyDashboardRoute(),
  ),
  MenuItem(
    label: 'Worklist',
    icon: Icons.list_alt_rounded,
    route: RadiologyWorklistRoute(),
  ),
  MenuItem(
    label: 'New patient',
    icon: Icons.add_circle_outline_rounded,
    route: EnlistPaitientRoute(serviceName: 'Radiology'),
  ),
  MenuItem(
    label: 'Waiting Patients',
    icon: Icons.receipt_long_outlined,
    route: NewPatientRoute(
      use: 'Radiology',
      categoryQueries: const ['Radiology & Imaging'],
    ),
  ),
];

/// Shared receivables subtree for accounting roles.
final _accountsReceivablesMenu = <MenuItem>[
  const MenuItem(
    label: 'HMO Receivables',
    icon: Icons.health_and_safety_outlined,
    route: ReceivablesHmoRoute(),
  ),
  const MenuItem(
    label: 'Discount Receivables',
    icon: Icons.sell_outlined,
    route: ReceivablesDiscountRoute(),
  ),
  MenuItem(
    label: 'Receivables analytics',
    icon: Icons.analytics_outlined,
    route: ReceivablesAnalyticsRoute(),
  ),
  const MenuItem(
    label: 'AR aging report',
    icon: Icons.hourglass_bottom_rounded,
    route: AccountsAgingReportRoute(),
  ),
];

/// ACCOUNT_HEAD — full Accounts & Audit module.
final accountsHeadMenu = <MenuItem>[
  const MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: AccountsDashboardRoute(),
  ),
  const MenuItem(
    label: 'Revenue analytics',
    icon: Icons.bar_chart_rounded,
    route: BillingDashboardRoute(),
  ),
  const MenuItem(
    label: 'Collections ledger',
    icon: Icons.list_alt_rounded,
    route: TransactionsRoute(),
  ),
  const MenuItem(
    label: 'Daily collections',
    icon: Icons.calendar_today_rounded,
    route: AccountsDailyCollectionsRoute(),
  ),
  const MenuItem(
    label: 'Consultation report',
    icon: Icons.receipt_long_outlined,
    route: ConsultationPaymentReportRoute(),
  ),
  MenuItem(
    label: 'Receivables',
    icon: Icons.receipt_long_outlined,
    route: ReceivablesHmoRoute(),
    children: _accountsReceivablesMenu,
  ),
  MenuItem(
    label: 'Cash & banking',
    icon: Icons.account_balance_outlined,
    route: AccountsBanksRoute(),
    children: [
      const MenuItem(
        label: 'Bank accounts',
        icon: Icons.account_balance_outlined,
        route: AccountsBanksRoute(),
      ),
      const MenuItem(
        label: 'Patient wallets',
        icon: Icons.wallet_rounded,
        route: AccountsWalletsOverviewRoute(),
      ),
      const MenuItem(
        label: 'Daily cash recon',
        icon: Icons.calculate_rounded,
        route: AccountsDailyCashReconRoute(),
      ),
      const MenuItem(
        label: 'Bank reconciliation',
        icon: Icons.compare_arrows_rounded,
        route: AccountsBankReconRoute(),
      ),
    ],
  ),
  const MenuItem(
    label: 'Financial reports',
    icon: Icons.assessment_rounded,
    route: AccountsFinancialReportsHubRoute(),
  ),
  MenuItem(
    label: 'Audit & compliance',
    icon: Icons.policy_rounded,
    route: AccountsAuditLogRoute(),
    children: [
      const MenuItem(
        label: 'Audit log',
        icon: Icons.history_rounded,
        route: AccountsAuditLogRoute(),
      ),
      const MenuItem(
        label: 'Compliance checklist',
        icon: Icons.verified_user_outlined,
        route: AccountsComplianceRoute(),
      ),
      const MenuItem(
        label: 'Invoice changes',
        icon: Icons.edit_note_rounded,
        route: AccountsInvoiceChangesRoute(),
      ),
      const MenuItem(
        label: 'Refund history',
        icon: Icons.undo_rounded,
        route: AccountsRefundHistoryRoute(),
      ),
      const MenuItem(
        label: 'Leak detection',
        icon: Icons.shield_outlined,
        route: AccountsLeakDetectionRoute(),
      ),
      const MenuItem(
        label: 'Staff activity',
        icon: Icons.people_outline_rounded,
        route: AccountsStaffActivityRoute(),
      ),
    ],
  ),
  MenuItem(
    label: 'Approvals & GL',
    icon: Icons.fact_check_outlined,
    route: AccountsApprovalsRoute(),
    children: [
      const MenuItem(
        label: 'Pending approvals',
        icon: Icons.fact_check_outlined,
        route: AccountsApprovalsRoute(),
      ),
      const MenuItem(
        label: 'Item refund requests',
        icon: Icons.receipt_long_outlined,
        route: AccountsRefundRequestsRoute(),
      ),
      const MenuItem(
        label: 'Period close',
        icon: Icons.lock_clock_rounded,
        route: AccountsPeriodCloseRoute(),
      ),
      const MenuItem(
        label: 'Journal entries',
        icon: Icons.menu_book_rounded,
        route: AccountsJournalEntriesRoute(),
      ),
      const MenuItem(
        label: 'Chart of accounts',
        icon: Icons.account_tree_rounded,
        route: AccountsChartOfAccountsRoute(),
      ),
    ],
  ),
];

/// ACCOUNTING_STAFF — operational finance (no approvals, GL, or head-only reports).
final accountsStaffMenu = <MenuItem>[
  const MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: AccountsDashboardRoute(),
  ),
  const MenuItem(
    label: 'Revenue summary',
    icon: Icons.insights_outlined,
    route: AccountsRevenueSummaryRoute(),
  ),
  const MenuItem(
    label: 'Collections ledger',
    icon: Icons.list_alt_rounded,
    route: TransactionsRoute(),
  ),
  const MenuItem(
    label: 'Daily collections',
    icon: Icons.calendar_today_rounded,
    route: AccountsDailyCollectionsRoute(),
  ),
  const MenuItem(
    label: 'Consultation report',
    icon: Icons.receipt_long_outlined,
    route: ConsultationPaymentReportRoute(),
  ),
  MenuItem(
    label: 'Receivables',
    icon: Icons.receipt_long_outlined,
    route: ReceivablesHmoRoute(),
    children: _accountsReceivablesMenu,
  ),
  MenuItem(
    label: 'Cash & banking',
    icon: Icons.account_balance_outlined,
    route: AccountsBanksRoute(),
    children: [
      const MenuItem(
        label: 'Bank accounts (view)',
        icon: Icons.account_balance_outlined,
        route: AccountsBanksRoute(),
      ),
      const MenuItem(
        label: 'Patient wallets',
        icon: Icons.wallet_rounded,
        route: AccountsWalletsOverviewRoute(),
      ),
      const MenuItem(
        label: 'Daily cash recon',
        icon: Icons.calculate_rounded,
        route: AccountsDailyCashReconRoute(),
      ),
    ],
  ),
  const MenuItem(
    label: 'Financial reports',
    icon: Icons.assessment_rounded,
    route: AccountsFinancialReportsHubRoute(),
  ),
  MenuItem(
    label: 'Audit (read-only)',
    icon: Icons.policy_rounded,
    route: AccountsAuditLogRoute(),
    children: [
      const MenuItem(
        label: 'Audit log',
        icon: Icons.history_rounded,
        route: AccountsAuditLogRoute(),
      ),
      const MenuItem(
        label: 'Compliance checklist',
        icon: Icons.verified_user_outlined,
        route: AccountsComplianceRoute(),
      ),
      const MenuItem(
        label: 'Invoice changes',
        icon: Icons.edit_note_rounded,
        route: AccountsInvoiceChangesRoute(),
      ),
      const MenuItem(
        label: 'Refund history',
        icon: Icons.undo_rounded,
        route: AccountsRefundHistoryRoute(),
      ),
    ],
  ),
];

final storeMenu = <MenuItem>[
  MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: StoreDashboardRoute(),
  ),
  MenuItem(
    label: 'Categories',
    icon: Icons.category_outlined,
    route: StoreCategoriesRoute(),
  ),
  MenuItem(
    label: 'Items',
    icon: Icons.inventory_2_outlined,
    route: StoreItemsRoute(),
  ),
  MenuItem(
    label: 'Locations',
    icon: Icons.location_on_outlined,
    route: StoreLocationsRoute(),
  ),
  MenuItem(
    label: 'Stock',
    icon: Icons.inventory_2_outlined,
    route: StoreStockRoute(),
  ),
  MenuItem(
    label: 'Movements',
    icon: Icons.move_to_inbox_outlined,
    route: StoreMovementsRoute(),
  ),
  MenuItem(
    label: 'Analytics',
    icon: Icons.analytics_outlined,
    route: StoreAnalyticsRoute(),
  ),
  MenuItem(
    label: 'Consumables catalog',
    icon: Icons.medical_services_outlined,
    route: StoreConsumablesCatalogRoute(),
  ),
  MenuItem(
    label: 'Consumable analytics',
    icon: Icons.insights_outlined,
    route: StoreConsumableAnalyticsRoute(),
  ),
];
