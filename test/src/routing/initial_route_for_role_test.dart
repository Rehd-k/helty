import 'package:flutter_test/flutter_test.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/routing/initial_route_for_role.dart';

void main() {
  group('initialRouteForRole CMD / CMAC', () {
    test('CMD lands on CMAC overview', () {
      expect(initialRouteForRole('CMD', 'cmd'), isA<CmacOverviewRoute>());
    });

    test('CMAC lands on CMAC overview', () {
      expect(initialRouteForRole('CMAC', 'cmac'), isA<CmacOverviewRoute>());
    });

    test('admin still lands on legacy CMD dashboard', () {
      expect(initialRouteForRole('admin', 'admin'), isA<CMDDashboardRoute>());
    });

    test('accounting lands on accounts dashboard', () {
      expect(
        initialRouteForRole('ACCOUNT_HEAD', 'accounting'),
        isA<AccountsDashboardRoute>(),
      );
    });
  });
}
