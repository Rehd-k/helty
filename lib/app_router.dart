import 'package:auto_route/auto_route.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/guards/auth_guard.dart';
import 'package:helty/src/routing/product_routes.dart';
import 'package:helty/src/routing/route_groups/shared_routes.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.material();

  @override
  List<AutoRoute> get routes => [
    // ── Auth routes (no guard) ───────────────────────────────────────
    ...sharedAuthRoutes(),

    // ── Protected shell (product-composed children) ──────────────────
    AutoRoute(
      page: HomeRoute.page,
      guards: [const AuthGuard()],
      children: ProductRoutes.homeChildren(),
    ),

    // patient form is shown separately (modal/push)
  ];
}
