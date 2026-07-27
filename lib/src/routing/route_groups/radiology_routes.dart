import 'package:auto_route/auto_route.dart';
import 'package:helty/app_router.gr.dart';

import '../product_module_guard.dart';

/// Radiology request and results routes.
List<AutoRoute> radiologyRoutes({bool initial = false}) => [
  AutoRoute(
    page: RadiologyDashboardRoute.page,
    initial: initial,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: RadiologyInvestigationsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: RadiologyWorklistRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: RadiologyCreateRequestRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: RadiologyRequestDetailRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: RadiologyPatientHistoryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
];
