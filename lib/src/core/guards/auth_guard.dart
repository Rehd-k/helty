import 'package:auto_route/auto_route.dart';

import '../storage/token_storage.dart';

/// AutoRoute guard that redirects unauthenticated users to the login screen.
/// Applied to [HomeRoute] in app_router.dart.
class AuthGuard extends AutoRouteGuard {
  const AuthGuard();

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final hasToken = await TokenStorage.hasToken();
    if (hasToken) {
      resolver.next(true);
    } else {
      // Replace the entire stack with login.
      router.replaceAll([const _LoginRouteStub()]);
      resolver.next(false);
    }
  }
}

/// Stub so auth_guard.dart doesn't need to import app_router.gr.dart
/// (which would create a circular dependency). The real LoginRoute
/// from the generated file is used by the router itself.
class _LoginRouteStub extends PageRouteInfo<void> {
  const _LoginRouteStub({List<PageRouteInfo>? children})
    : super('LoginRoute', initialChildren: children);
}
