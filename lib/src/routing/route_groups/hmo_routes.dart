import 'package:auto_route/auto_route.dart';
import 'package:helty/app_router.gr.dart';

import '../product_module_guard.dart';

/// HMO plans, detail, and tariff routes.
List<AutoRoute> hmoRoutes() => [
  AutoRoute(page: HmoListRoute.page, guards: const [ProductModuleGuard()]),
  AutoRoute(page: HmoDetailRoute.page, guards: const [ProductModuleGuard()]),
  AutoRoute(page: HmoFormRoute.page, guards: const [ProductModuleGuard()]),
  AutoRoute(
    page: HmoServicePricingRoute.page,
    guards: const [ProductModuleGuard()],
  ),
];
