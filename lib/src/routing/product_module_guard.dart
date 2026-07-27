import 'package:auto_route/auto_route.dart';

import '../app/product_definition.dart';
import '../app/product_environment.dart';
import 'route_module_map.dart';

/// Blocks navigation to routes whose [AppModule] is disabled for this product.
///
/// Primary protection is omitting those routes from [ProductRoutes.homeChildren].
/// This guard is defense-in-depth against deep links / programmatic pushes.
class ProductModuleGuard extends AutoRouteGuard {
  const ProductModuleGuard([this.module]);

  /// Optional explicit module; otherwise looked up from the route name.
  final AppModule? module;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final routeName = resolver.route.name;
    final required = module ?? moduleForRouteName(routeName);

    if (required != null && !ProductEnvironment.isModuleEnabled(required)) {
      resolver.next(false);
      return;
    }

    resolver.next(true);
  }
}
