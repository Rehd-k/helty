import 'package:auto_route/auto_route.dart';
import 'package:helty/app_router.gr.dart';

import '../product_module_guard.dart';

/// Laboratory order and results routes.
List<AutoRoute> laboratoryRoutes({bool initial = false}) => [
  AutoRoute(
    page: LabDashboardRoute.page,
    initial: initial,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: LabInvestigationsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: LabConfigRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: LabCreateOrderRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: LabOrderDetailRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: LabResultEntryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
];
