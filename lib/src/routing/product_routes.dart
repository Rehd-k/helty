import 'package:auto_route/auto_route.dart';

import '../app/product_definition.dart';
import '../app/product_environment.dart';
import 'route_groups/billing_routes.dart';
import 'route_groups/hospital_routes.dart';
import 'route_groups/laboratory_routes.dart';
import 'route_groups/pharmacy_routes.dart';
import 'route_groups/radiology_routes.dart';
import 'route_groups/registration_routes.dart';
import 'route_groups/shared_routes.dart';
import 'route_module_map.dart';

/// Composes Home child routes for the active [AppProduct].
///
/// Hospital = shared + registration + billing + pharmacy + lab + radiology + hospital-only.
/// Pharmacy = shared + registration + billing + pharmacy.
/// Diagnostics = shared + registration + billing + laboratory + radiology.
class ProductRoutes {
  ProductRoutes._();

  /// Home children for [product]. Exactly one child is marked `initial`.
  static List<AutoRoute> homeChildren([AppProduct? product]) {
    final p = product ?? ProductEnvironment.currentProduct;
    final modules = productDefinitionFor(p).enabledModules;
    final isHospital = p == AppProduct.hospital;

    return [
      ...sharedHomeChildren(),
      if (modules.contains(AppModule.registration))
        ...registrationRoutes(
          initial: !isHospital,
          enabledModules: modules,
        ),
      if (modules.contains(AppModule.billing)) ...billingRoutes(),
      if (modules.contains(AppModule.pharmacy)) ...pharmacyRoutes(),
      if (modules.contains(AppModule.laboratory)) ...laboratoryRoutes(),
      if (modules.contains(AppModule.radiology)) ...radiologyRoutes(),
      if (isHospital) ...hospitalOnlyRoutes(initialCmd: true),
    ];
  }

  /// Flattened route names registered under Home for [product].
  static Set<String> registeredHomeRouteNames([AppProduct? product]) {
    final names = <String>{};
    void walk(List<AutoRoute> routes) {
      for (final route in routes) {
        names.add(route.name);
        final kids = route.children;
        if (kids != null && kids.isNotEmpty) {
          walk(kids);
        }
      }
    }

    walk(homeChildren(product));
    return names;
  }

  /// Whether [routeName] is registered for [product].
  static bool isRouteRegistered(String routeName, [AppProduct? product]) {
    return registeredHomeRouteNames(product).contains(routeName);
  }

  /// Whether navigating to [routeName] is allowed for [product].
  ///
  /// Shared routes (no module mapping) are allowed on every product.
  static bool isRouteAllowed(String routeName, [AppProduct? product]) {
    final p = product ?? ProductEnvironment.currentProduct;
    final module = moduleForRouteName(routeName);
    if (module != null &&
        !productDefinitionFor(p).isModuleEnabled(module)) {
      return false;
    }
    if (module == null) return true;
    return isRouteRegistered(routeName, p);
  }
}
