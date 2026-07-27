import 'package:auto_route/auto_route.dart';
import 'package:helty/app_router.gr.dart';

import '../product_module_guard.dart';

/// Pharmacy inventory, dispensing, and pharmacy-ops routes.
List<AutoRoute> pharmacyRoutes({bool initial = false}) => [
  AutoRoute(
    page: PharmacyDashboardRoute.page,
    initial: initial,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PharmacyHeadDashboardRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PharmacyReportsHubRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PharmacySalesBreakdownRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PharmacySalesBreakdownDetailRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PharmacyInventoryValuationRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: MedicineInventoryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AddDrugRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AddSupplierRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AddBatchRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    path: 'pharmacy/batchespreview-ward-pricing/:id',
    page: BatchesPreviewWardPricingRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: StockTransferRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: CreateRequisitionRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: SupplyHistoryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    path: 'pharmacy/dispense-history',
    page: DispenseHistoryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PharmacyLocationRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PharmacyPOSRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: DispenseRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    path: 'pharmacy/medication-requests',
    page: MedicationRequestsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    path: 'pharmacy/refill-requests',
    page: PharmacyRefillRequestsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: WaitingPatientRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: PurchaseItemSalesRoute.page,
    guards: const [ProductModuleGuard()],
  ),
];
