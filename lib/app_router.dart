import 'package:auto_route/auto_route.dart';
import 'package:helty/app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.material(); //.cupertino, .adaptive ..etc

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomeRoute.page,
      initial: true,
      children: [
        AutoRoute(page: DashboardRoute.page),
        AutoRoute(page: PatientListRoute.page),
        AutoRoute(page: AppointmentListRoute.page),
      ],
    ),
    // patient form is shown separately (modal/push)
    AutoRoute(page: PatientFormRoute.page),
  ];
}

// class $AppRouter {}
