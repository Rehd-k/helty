import 'package:auto_route/auto_route.dart';
import 'package:helty/app_router.gr.dart';

/// Registered by the open inpatient bill so menu and other route changes
/// ask the same leave question as the back button.
class BillingLeaveGate {
  BillingLeaveGate._();

  static final BillingLeaveGate instance = BillingLeaveGate._();

  Future<bool> Function()? _ask;

  void register(Future<bool> Function() ask) {
    _ask = ask;
  }

  void unregister(Future<bool> Function() ask) {
    if (identical(_ask, ask)) _ask = null;
  }

  Future<bool> ask() async {
    final ask = _ask;
    if (ask == null) return true;
    return ask();
  }
}

/// Runs before any route change. If the inpatient bill is the page on screen,
/// the bill decides whether navigation may continue.
class BillingLeaveGuard extends AutoRouteGuard {
  const BillingLeaveGuard();

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    if (resolver.isReevaluating || !_billIsOnScreen(router)) {
      resolver.next(true);
      return;
    }
    if (resolver.routeName == PatientBillingRoute.name) {
      resolver.next(true);
      return;
    }
    final leave = await BillingLeaveGate.instance.ask();
    resolver.next(leave);
  }

  bool _billIsOnScreen(StackRouter router) {
    var name = router.current.name;
    var scope = router;
    final seen = <StackRouter>{};
    while (seen.add(scope)) {
      final inner = scope.innerRouterOf<StackRouter>(name);
      if (inner == null) break;
      name = inner.current.name;
      scope = inner;
    }
    return name == PatientBillingRoute.name;
  }
}
