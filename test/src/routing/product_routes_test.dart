import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/app/product_definition.dart';
import 'package:helty/src/app/product_environment.dart';
import 'package:helty/src/routing/product_routes.dart';
import 'package:helty/src/routing/route_module_map.dart';

void main() {
  tearDown(() {
    ProductEnvironment.debugResetBind();
  });

  group('route module map', () {
    test('maps known clinical routes', () {
      expect(moduleForRouteName('DoctorDashboardRoute'), AppModule.physician);
      expect(moduleForRouteName('LabDashboardRoute'), AppModule.laboratory);
      expect(moduleForRouteName('PharmacyDashboardRoute'), AppModule.pharmacy);
      expect(moduleForRouteName('CMDDashboardRoute'), AppModule.administration);
    });

    test('shared routes have no module', () {
      expect(moduleForRouteName('HelpCenterRoute'), isNull);
      expect(moduleForRouteName('StaffChatRoute'), isNull);
      expect(moduleForRouteName('LoginRoute'), isNull);
      expect(moduleForRouteName('SuperAdminStaffListRoute'), isNull);
      expect(moduleForRouteName('SuperAdminStaffDetailRoute'), isNull);
    });
  });

  group('ProductRoutes registration', () {
    test('hospital registers doctor, nursing, pharmacy, lab, cmd', () {
      final names = ProductRoutes.registeredHomeRouteNames(AppProduct.hospital);
      expect(names, contains('DoctorDashboardRoute'));
      expect(names, contains('NursesDashboardRoute'));
      expect(names, contains('PharmacyDashboardRoute'));
      expect(names, contains('LabDashboardRoute'));
      expect(names, contains('RadiologyDashboardRoute'));
      expect(names, contains('CMDDashboardRoute'));
      expect(names, contains('FrontDeskDashboardRoute'));
      expect(names, contains('BillingDashboardRoute'));
      expect(names, contains('SuperAdminStaffListRoute'));
      expect(names, contains('SuperAdminStaffDetailRoute'));
    });

    test('pharmacy omits lab, radiology, doctor, nursing, cmd', () {
      final names = ProductRoutes.registeredHomeRouteNames(AppProduct.pharmacy);
      expect(names, contains('FrontDeskDashboardRoute'));
      expect(names, contains('BillingDashboardRoute'));
      expect(names, contains('PharmacyDashboardRoute'));
      expect(names, contains('MedicineInventoryRoute'));
      expect(names, isNot(contains('LabDashboardRoute')));
      expect(names, isNot(contains('RadiologyDashboardRoute')));
      expect(names, isNot(contains('DoctorDashboardRoute')));
      expect(names, isNot(contains('NursesDashboardRoute')));
      expect(names, isNot(contains('CMDDashboardRoute')));
      expect(names, isNot(contains('DialysisDashboardRoute')));
      expect(names, isNot(contains('HubLabsRoute')));
      expect(names, contains('HubMedsRoute'));
      expect(names, contains('SuperAdminStaffListRoute'));
      expect(names, contains('SuperAdminStaffDetailRoute'));
    });

    test('diagnostics omits pharmacy, doctor, nursing, cmd', () {
      final names =
          ProductRoutes.registeredHomeRouteNames(AppProduct.diagnostics);
      expect(names, contains('FrontDeskDashboardRoute'));
      expect(names, contains('BillingDashboardRoute'));
      expect(names, contains('LabDashboardRoute'));
      expect(names, contains('RadiologyDashboardRoute'));
      expect(names, contains('HubLabsRoute'));
      expect(names, contains('HubImagingRoute'));
      expect(names, isNot(contains('PharmacyDashboardRoute')));
      expect(names, isNot(contains('HubMedsRoute')));
      expect(names, isNot(contains('DoctorDashboardRoute')));
      expect(names, isNot(contains('CMDDashboardRoute')));
      expect(names, contains('SuperAdminStaffListRoute'));
      expect(names, contains('SuperAdminStaffDetailRoute'));
    });

    test('exactly one initial Home child per product', () {
      for (final product in AppProduct.values) {
        final initials = ProductRoutes.homeChildren(product)
            .where((r) => r.initial)
            .map((r) => r.name)
            .toList();
        expect(initials, hasLength(1), reason: '$product initials: $initials');
        if (product == AppProduct.hospital) {
          expect(initials.single, 'CMDDashboardRoute');
        } else {
          expect(initials.single, 'FrontDeskDashboardRoute');
        }
      }
    });
  });

  group('ProductRoutes.isRouteAllowed', () {
    test('pharmacy blocks hospital-only deep links', () {
      expect(
        ProductRoutes.isRouteAllowed(
          'DoctorDashboardRoute',
          AppProduct.pharmacy,
        ),
        isFalse,
      );
      expect(
        ProductRoutes.isRouteAllowed(
          'LabDashboardRoute',
          AppProduct.pharmacy,
        ),
        isFalse,
      );
      expect(
        ProductRoutes.isRouteAllowed(
          'PharmacyDashboardRoute',
          AppProduct.pharmacy,
        ),
        isTrue,
      );
      expect(
        ProductRoutes.isRouteAllowed('HelpCenterRoute', AppProduct.pharmacy),
        isTrue,
      );
    });

    test('diagnostics blocks pharmacy deep links', () {
      expect(
        ProductRoutes.isRouteAllowed(
          'PharmacyDashboardRoute',
          AppProduct.diagnostics,
        ),
        isFalse,
      );
      expect(
        ProductRoutes.isRouteAllowed(
          'LabDashboardRoute',
          AppProduct.diagnostics,
        ),
        isTrue,
      );
      expect(
        ProductRoutes.isRouteAllowed(
          'SuperAdminStaffListRoute',
          AppProduct.diagnostics,
        ),
        isTrue,
      );
    });

    test('bound pharmacy product matches explicit pharmacy checks', () {
      ProductEnvironment.bind(AppProduct.pharmacy);
      expect(ProductRoutes.isRouteAllowed('DoctorDashboardRoute'), isFalse);
      expect(ProductRoutes.isRouteAllowed('PharmacyDashboardRoute'), isTrue);
      expect(
        ProductRoutes.isRouteRegistered('CMDDashboardRoute'),
        isFalse,
      );
    });
  });
}
