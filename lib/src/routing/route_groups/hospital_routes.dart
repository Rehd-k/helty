import 'package:auto_route/auto_route.dart';
import 'package:helty/app_router.gr.dart';

import '../product_module_guard.dart';

/// Hospital-only Home children (clinical ops, CMD/CMAC, accounts, store, etc.).
List<AutoRoute> hospitalOnlyRoutes({bool initialCmd = true}) => [
  // Administration / super admin / CMD / CMAC
  AutoRoute(
    page: SuperAdminHubRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: SuperAdminStaffListRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: SuperAdminStaffDetailRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CMDDashboardRoute.page,
    initial: initialCmd,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CMDHospitalOverviewRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CMDFinancialCommandRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CMDStaffOversightRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CMDBedsFacilitiesRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CMDLabMonitoringRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CMDAlertsIncidentsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CMDReportsAnalyticsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CMDAuditComplianceRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CMDCommunicationCenterRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CustomPatientPushRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CMDPatientExperienceRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CMDSystemControlRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CmacOverviewRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CmacInsightsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CmacPatientActivityRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CmacClinicalRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CmacLaboratoryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CmacPharmacyRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CmacOperationsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CmacQualityRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CmacStaffRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CmacQualitySafetyHubRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CmacQualityReferralsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CmacQualityComplaintsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CmacQualityIncidentsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CmacQualityInfectionsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    path: 'cmac/quality/:entity/:recordId',
    page: CmacQualityDetailRoute.page,
    guards: const [ProductModuleGuard()],
  ),

  // Nursing
  AutoRoute(
    page: NursesDashboardRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: NursingRosterRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: NursingAssignmentsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: NurseConsumableUsageRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: WaitingPatientsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: InpatientsListRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: InpatientPatientViewRoute.page,
    guards: const [ProductModuleGuard()],
    children: [
      AutoRoute(page: InpatientOverviewRoute.page, initial: true),
      AutoRoute(page: InpatientVitalsRoute.page),
      AutoRoute(page: InpatientMedicationsRoute.page),
      AutoRoute(page: InpatientIVRoute.page),
      AutoRoute(page: InpatientIORoute.page),
      AutoRoute(page: InpatientNotesRoute.page),
      AutoRoute(page: InpatientWoundAssessmentRoute.page),
      AutoRoute(page: InpatientWardRoundTab.page),
      AutoRoute(page: InpatientProceduresRoute.page),
      AutoRoute(page: InpatientCarePlanRoute.page),
      AutoRoute(page: InpatientMonitoringRoute.page),
      AutoRoute(page: InpatientLabResultsRoute.page),
      AutoRoute(page: InpatientAlertsRoute.page),
      AutoRoute(page: InpatientHandoverRoute.page),
    ],
  ),

  // Physician / ED / encounters / obstetrics
  AutoRoute(
    page: DoctorDashboardRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DoctorOutpatientListRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DoctorOngoingEncountersRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DoctorWalkInQueueRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DoctorWaitingPatientsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DoctorEmergencyStartRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: EdBoardRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: EdEmergencyRequestsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: EdEmergencyRequestDetailRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: EdRegistrationRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: EdTriageRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: WardRoundsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DoctorPendingLabsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DoctorPendingImagingRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DoctorPendingPrescriptionsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DoctorCompletedEncountersRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ConsultationPaymentReportRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: EncounterEditHistoryDetailRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DoctorTemplatesRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DoctorProfileRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DoctorCompletedEncounterViewRoute.page,
    guards: const [ProductModuleGuard()],
    children: [
      AutoRoute(page: CompletedEncounterSummaryTab.page, initial: true),
      AutoRoute(page: CompletedEncounterHistoryTab.page),
      AutoRoute(page: CompletedEncounterExaminationTab.page),
      AutoRoute(page: CompletedEncounterNotesTab.page),
      AutoRoute(page: CompletedEncounterDiagnosisTab.page),
      AutoRoute(page: CompletedEncounterLabsTab.page),
      AutoRoute(page: CompletedEncounterImagingTab.page),
      AutoRoute(page: CompletedEncounterPrescriptionsTab.page),
      AutoRoute(page: CompletedEncounterAppointmentsTab.page),
      AutoRoute(page: CompletedEncounterFollowUpTab.page),
    ],
  ),
  AutoRoute(
    page: DoctorEncounterViewRoute.page,
    guards: const [ProductModuleGuard()],
    children: [
      AutoRoute(page: DoctorEncounterHistoryTab.page, initial: true),
      AutoRoute(page: DoctorEncounterExaminationTab.page),
      AutoRoute(page: DoctorEncounterDiagnosisTab.page),
      AutoRoute(page: DoctorEncounterInvestigationsTab.page),
      AutoRoute(page: DoctorEncounterImagingTab.page),
      AutoRoute(page: DoctorEncounterSurgeryTab.page),
      AutoRoute(page: DoctorEncounterPrescriptionTab.page),
      AutoRoute(page: DoctorEncounterProceduresTab.page),
      AutoRoute(page: DoctorEncounterNotesTab.page),
      AutoRoute(page: DoctorEncounterAdmissionTab.page),
      AutoRoute(page: DoctorEncounterFollowUpTab.page),
    ],
  ),
  AutoRoute(
    page: ObstetricsDashboardRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsPatientSelectRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsPregnanciesListRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsPregnancyViewRoute.page,
    guards: const [ProductModuleGuard()],
    children: [
      AutoRoute(page: ObstetricsPregnancyOverviewTab.page, initial: true),
      AutoRoute(page: ObstetricsAntenatalVisitsTab.page),
      AutoRoute(page: ObstetricsPregnancyClinicalOrdersTab.page),
      AutoRoute(page: ObstetricsPregnancyClinicalResultsTab.page),
      AutoRoute(page: ObstetricsLabourDeliveryTab.page),
      AutoRoute(page: ObstetricsPostnatalTab.page),
    ],
  ),
  AutoRoute(
    page: ObstetricsAddPregnancyRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsAddAntenatalVisitRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsEditAntenatalVisitRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsAddLabourDeliveryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsLabourDeliveryViewRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsAddPartogramEntryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsAddBabyRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsEditBabyRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsRegisterBabyRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsPostnatalListRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsAddPostnatalVisitRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsGynaeProceduresRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsAddGynaeProcedureRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ObstetricsEditGynaeProcedureRoute.page,
    guards: const [ProductModuleGuard()],
  ),

  // Purchases
  AutoRoute(
    page: PurchasesInventoryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PurchasesAddItemRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PurchasesAddSupplierRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PurchasesAddPurchaseRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PurchasesStockTransferRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PurchasesTransferHistoryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PurchasesPurchaseHistoryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PurchasesLocationRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PurchasesRequisitionHistoryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    path: 'purchases/usage-history',
    page: PurchasesUsageHistoryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PurchasesDashboardRoute.page,
    guards: const [ProductModuleGuard()],
  ),

  // Dialysis
  AutoRoute(
    page: DialysisDashboardRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DialysisSelectPatientRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DialysisPatientEncountersRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DialysisCreateSessionRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DialysisSessionDetailRoute.page,
    guards: const [ProductModuleGuard()],
  ),

  // Theatre
  AutoRoute(
    page: TheatreDashboardRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: TheatreScheduleFormRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: TheatreCaseDetailRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: TheatreRoomsRoute.page,
    guards: const [ProductModuleGuard()],
  ),

  // Accounts
  AutoRoute(
    page: AccountsDashboardRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsRevenueSummaryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsDailyCollectionsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsAgingReportRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsFinancialReportsHubRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsProfitLossRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsCashFlowRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsRevenueByServiceRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsRevenueByServiceDetailRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsExpenseVsBudgetRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsCollectionEfficiencyRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsPeriodComparisonRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsPaymentMixRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsAuditLogRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsComplianceRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsInvoiceChangesRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsLeakDetectionRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsStaffActivityRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsRefundHistoryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsWalletsOverviewRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsDailyCashReconRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsBankReconRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsApprovalsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsRefundRequestsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsPeriodCloseRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsJournalEntriesRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsChartOfAccountsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsBanksRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ReceivablesAnalyticsRoute.page,
    guards: const [ProductModuleGuard()],
  ),

  // Store
  AutoRoute(
    page: StoreDashboardRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: StoreCategoriesRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: StoreItemsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: StoreLocationsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: StoreStockRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: StoreMovementsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: StoreAnalyticsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: StoreConsumablesCatalogRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: StoreConsumableAnalyticsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    path: 'store/consumables/detail/:consumableId',
    page: StoreConsumableDetailRoute.page,
    guards: const [ProductModuleGuard()],
  ),

  // HMO
  AutoRoute(
    page: HmoListRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: HmoDetailRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: HmoFormRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: HmoServicePricingRoute.page,
    guards: const [ProductModuleGuard()],
  ),

  // ICT
  AutoRoute(
    page: DashboardRoute.page,
    guards: const [ProductModuleGuard()],
  ),
];
