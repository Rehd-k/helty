import 'package:auto_route/auto_route.dart';
import 'package:helty/app_router.gr.dart';

import '../../app/product_definition.dart';
import '../product_module_guard.dart';

/// Patient registration / front-desk / patient hub routes.
List<AutoRoute> registrationRoutes({
  bool initial = false,
  bool isHospital = true,
  Set<AppModule> enabledModules = const {},
}) {
  final modules = enabledModules.isEmpty ? kAllAppModules : enabledModules;

  final hubChildren = <AutoRoute>[
    AutoRoute(page: HubOverviewRoute.page, initial: true),
    AutoRoute(page: HubProfileRoute.page),
    AutoRoute(page: HubEncountersRoute.page),
    AutoRoute(page: HubVitalsRoute.page),
    AutoRoute(page: HubDocumentsRoute.page),
    AutoRoute(page: HubNotesRoute.page),
    if (modules.contains(AppModule.laboratory))
      AutoRoute(page: HubLabsRoute.page),
    if (modules.contains(AppModule.radiology))
      AutoRoute(page: HubImagingRoute.page),
    if (modules.contains(AppModule.pharmacy))
      AutoRoute(page: HubMedsRoute.page),
    if (modules.contains(AppModule.dialysis))
      AutoRoute(page: HubDialysisRoute.page),
    if (modules.contains(AppModule.theatre))
      AutoRoute(page: HubTheatreRoute.page),
  ];

  return [
    AutoRoute(
      page: FrontDeskDashboardRoute.page,
      initial: initial,
      guards: const [ProductModuleGuard()],
    ),
    if (isHospital)
      AutoRoute(
        page: PendingDeviceApprovalsRoute.page,
        guards: const [ProductModuleGuard()],
      ),
    AutoRoute(
      page: PatientDevicesRoute.page,
      guards: const [ProductModuleGuard()],
    ),
    if (isHospital)
      AutoRoute(
        page: FamilyLinksRoute.page,
        guards: const [ProductModuleGuard()],
      ),
    AutoRoute(
      page: PatientListRoute.page,
      guards: const [ProductModuleGuard()],
    ),
    AutoRoute(
      page: PatientFormRoute.page,
      guards: const [ProductModuleGuard()],
    ),
    AutoRoute(
      page: PatientChartSelectRoute.page,
      guards: const [ProductModuleGuard()],
    ),
    AutoRoute(
      page: PatientChartRoute.page,
      guards: const [ProductModuleGuard()],
    ),
    AutoRoute(
      page: PatientHubSearchRoute.page,
      guards: const [ProductModuleGuard()],
    ),
    AutoRoute(
      page: PatientHubRoute.page,
      guards: const [ProductModuleGuard()],
      children: hubChildren,
    ),
    if (isHospital)
      AutoRoute(
        page: AppointmentListRoute.page,
        guards: const [ProductModuleGuard()],
      ),
    if (isHospital)
      AutoRoute(
        page: AppointmentRequestsRoute.page,
        guards: const [ProductModuleGuard()],
      ),
    AutoRoute(
      page: TodayPatientsRoute.page,
      guards: const [ProductModuleGuard()],
    ),
    if (isHospital)
      AutoRoute(
        page: NewAppointmentRoute.page,
        guards: const [ProductModuleGuard()],
      ),
    AutoRoute(
      page: NewPatientRoute.page,
      guards: const [ProductModuleGuard()],
    ),
  ];
}
