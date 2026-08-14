import 'package:auto_route/auto_route.dart';
import 'package:helty/app_router.gr.dart';

import '../product_module_guard.dart';

/// Auth + shell-adjacent routes available on every product.
List<AutoRoute> sharedAuthRoutes() => [
  AutoRoute(page: LoginRoute.page, initial: true),
  AutoRoute(page: RegisterRoute.page),
  AutoRoute(page: ForgotPasswordRoute.page),
  AutoRoute(page: ResetPasswordRoute.page),
];

/// Always-on Home children (help, chat, enlist helpers).
List<AutoRoute> sharedHomeChildren() => [
  AutoRoute(
    page: EnlistPaitientRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: NotAvailableRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: HelpCenterRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: SupportTicketDetailRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: StaffChatRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: StaffChatThreadRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  // Staff registration is available on all products for org admins.
  AutoRoute(
    page: RegisterRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: SuperAdminStaffListRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: SuperAdminStaffDetailRoute.page,
    guards: const [ProductModuleGuard()],
  ),
];
