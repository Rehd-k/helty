import 'package:flutter_test/flutter_test.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/app/product_definition.dart';
import 'package:helty/src/app/product_environment.dart';
import 'package:helty/src/routing/initial_route_for_role.dart';

void main() {
  tearDown(() {
    ProductEnvironment.debugResetBind();
  });

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

  group('initialRouteForRole product boundaries', () {
    test('pharmacy product keeps pharmacy landing', () {
      ProductEnvironment.bind(AppProduct.pharmacy);
      expect(
        initialRouteForRole('PHARMACY_HEAD', 'pharmacy'),
        isA<PharmacyHeadDashboardRoute>(),
      );
    });

    test('pharmacy product falls back when physician lands', () {
      ProductEnvironment.bind(AppProduct.pharmacy);
      expect(
        initialRouteForRole('doctor', 'physician'),
        isA<FrontDeskDashboardRoute>(),
      );
    });

    test('diagnostics product keeps lab landing', () {
      ProductEnvironment.bind(AppProduct.diagnostics);
      expect(
        initialRouteForRole('LAB_HEAD', 'laboratory'),
        isA<LabDashboardRoute>(),
      );
    });

    test('diagnostics product falls back when pharmacy lands', () {
      ProductEnvironment.bind(AppProduct.diagnostics);
      expect(
        initialRouteForRole('PHARMACY_HEAD', 'pharmacy'),
        isA<FrontDeskDashboardRoute>(),
      );
    });

    test('diagnostics super admin lands on staff directory', () {
      ProductEnvironment.bind(AppProduct.diagnostics);
      expect(
        initialRouteForRole('SUPER_ADMIN', 'super_admin'),
        isA<SuperAdminStaffListRoute>(),
      );
    });

    test('pharmacy super admin lands on staff directory', () {
      ProductEnvironment.bind(AppProduct.pharmacy);
      expect(
        initialRouteForRole('admin', 'admin'),
        isA<SuperAdminStaffListRoute>(),
      );
    });
  });
}
