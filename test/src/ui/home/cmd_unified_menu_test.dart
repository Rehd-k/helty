import 'package:flutter_test/flutter_test.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/ui/home/account_types.dart';
import 'package:helty/src/ui/home/home_screen.dart';

void main() {
  group('cmdUnifiedMenuItems', () {
    test('is a flat list of CMAC and accounts head menu items', () {
      expect(
        cmdUnifiedMenuItems.length,
        cmacExecutiveMenuItems.length + accountsHeadMenu.length,
      );
      expect(
        cmdUnifiedMenuItems.first.route,
        isA<CmacOverviewRoute>(),
      );
      expect(
        cmdUnifiedMenuItems.any((m) => m.route is AccountsDashboardRoute),
        isTrue,
      );
    });

    test('does not expose the legacy CMD dashboard', () {
      expect(
        cmdUnifiedMenuItems.any((m) => m.route is CMDDashboardRoute),
        isFalse,
      );
    });

    test('contains no grouping wrapper for CMAC or Accounts', () {
      expect(
        cmdUnifiedMenuItems.any(
          (m) => m.label == 'CMAC' || m.label == 'Accounts & Audit',
        ),
        isFalse,
      );
    });
  });
}
