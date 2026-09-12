import 'package:flutter_test/flutter_test.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/ui/home/home_screen.dart';

void main() {
  group('cmdUnifiedMenuItems', () {
    test('starts with CMD dashboard, then CMAC and accounts head items', () {
      expect(
        cmdUnifiedMenuItems.first.route,
        isA<CMDDashboardRoute>(),
      );
      expect(
        cmdUnifiedMenuItems.any((m) => m.route is CmacOverviewRoute),
        isTrue,
      );
      expect(
        cmdUnifiedMenuItems.any((m) => m.route is AccountsDashboardRoute),
        isTrue,
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
