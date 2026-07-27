import 'package:auto_route/auto_route.dart';
import 'package:helty/app_router.gr.dart';

import '../product_module_guard.dart';

/// Billing, invoices, payments, and service-catalog routes.
List<AutoRoute> billingRoutes({bool initial = false}) => [
  AutoRoute(
    page: PendingBillsRoute.page,
    initial: initial,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: BillingDashboardRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ReceivablesHmoRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ReceivablesDiscountRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DiscountPolicyManagementRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ClinicalPackageManagementRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: TransactionsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: SystemSetupRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: BankManagementRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ConsultingRoomsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: WardManagementRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: EnlistServiceRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: RenderServiceRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ViewServiceRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AddServiceRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AddCategoryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AddDepartmentRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: InpatientBillsListRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: BillingWardInpatientsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AwaitingBillingClearanceRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PatientBillingRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PatientWalletHistoryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
];
