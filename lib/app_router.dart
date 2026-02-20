import 'package:auto_route/auto_route.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/guards/auth_guard.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.material();

  @override
  List<AutoRoute> get routes => [
    // ── Auth routes (no guard) ───────────────────────────────────────
    AutoRoute(page: LoginRoute.page, initial: true),
    AutoRoute(page: RegisterRoute.page),
    AutoRoute(page: ForgotPasswordRoute.page),
    AutoRoute(page: ResetPasswordRoute.page),

    // ── Protected shell ──────────────────────────────────────────────
    AutoRoute(
      page: HomeRoute.page,
      guards: [const AuthGuard()],
      children: [
        AutoRoute(page: DashboardRoute.page, initial: true),
        AutoRoute(page: PatientListRoute.page),
        AutoRoute(page: PatientFormRoute.page),
        AutoRoute(page: AppointmentListRoute.page),
        AutoRoute(page: TodayPatientsRoute.page),
        AutoRoute(page: PendingTransactionsRoute.page),
        AutoRoute(page: EnlistServiceRoute.page),
        AutoRoute(page: RenderServiceRoute.page),
        AutoRoute(page: ViewServiceRoute.page),
        // helper screens for creating new entities
        AutoRoute(page: AddServiceRoute.page),
        AutoRoute(page: AddCategoryRoute.page),
        AutoRoute(page: AddDepartmentRoute.page),
        AutoRoute(page: RegisterRoute.page),
      ],
    ),

    // patient form is shown separately (modal/push)
    AutoRoute(page: PatientFormRoute.page),
  ];
}
