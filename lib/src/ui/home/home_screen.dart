import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

import '../../accounts/auth/accounting_permissions.dart';
import '../../app/product_definition.dart';
import '../../app/product_module_access.dart';
import '../../auth/billing_permissions.dart';
import '../../auth/dialysis_permissions.dart';
import '../../auth/theatre_permissions.dart';
import '../../auth/nursing_permissions.dart';
import '../../nursing/providers/nursing_providers.dart';
import '../../helper/theme.dart';
import '../../shared/department_colors.dart';
import '../../chat/providers/pending_orders_tick_provider.dart';
import '../../chat/providers/staff_chat_shell_provider.dart';
import '../../chat/services/internal_chat_socket.dart';
import '../../chat/widgets/staff_messages_shell_action.dart';
import '../../models/staff_model.dart';
import '../../models/super_admin_department_preview.dart';
import '../../providers/auth_provider.dart';
import '../../providers/super_admin_preview_provider.dart';
import '../../providers/module_request_flow_provider.dart';
import '../../providers/theme_mode_provider.dart';
import '../../notifications/notification_navigation_provider.dart';
import 'desktop_shell_side_panel.dart';
import 'shell_side_panel_provider.dart';
import '../../services/helty_desktop_update_service.dart';
import '../../services/title_bar.dart';
import '../../system_announcements/widgets/announcement_banner_host.dart';
import 'account_types.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

/// Semantic buckets for inactive menu icon tints — resolved via [ColorScheme], not hex.
enum MenuAccent { primary, secondary, tertiary, errorTone }

class MenuItem {
  final String label;
  final IconData icon;
  final PageRouteInfo route;
  final List<MenuItem>? children;

  /// When null, the sidebar derives a tone from item index or label hash.
  final MenuAccent? accent;

  /// Explicit department brand color (see [DepartmentColors]). When set,
  /// this takes priority over [accent] for the sidebar icon/label tint.
  final Color? color;

  const MenuItem({
    required this.label,
    required this.icon,
    required this.route,
    this.children,
    this.accent,
    this.color,
  });
}

/// CMAC oversight analytics — top-level for CMAC logins only.
const cmacExecutiveMenuItems = <MenuItem>[
  MenuItem(
    label: 'Oversight overview',
    icon: Icons.dashboard_rounded,
    route: CmacOverviewRoute(),
    color: DepartmentColors.administration,
  ),
  MenuItem(
    label: 'Insights',
    icon: Icons.lightbulb_outline_rounded,
    route: CmacInsightsRoute(),
    color: DepartmentColors.administration,
  ),
  MenuItem(
    label: 'Patient activity',
    icon: Icons.people_alt_rounded,
    route: CmacPatientActivityRoute(),
    color: DepartmentColors.outpatientClinic,
  ),
  MenuItem(
    label: 'Patient notifications',
    icon: Icons.notifications_active_outlined,
    route: CustomPatientPushRoute(),
    accent: MenuAccent.tertiary,
  ),
  patientHubMenuItem,
  MenuItem(
    label: 'Clinical',
    icon: Icons.medical_information_outlined,
    route: CmacClinicalRoute(),
    color: DepartmentColors.outpatientClinic,
  ),
  MenuItem(
    label: 'Laboratory',
    icon: Icons.biotech_rounded,
    route: CmacLaboratoryRoute(),
    color: DepartmentColors.laboratory,
  ),
  MenuItem(
    label: 'Pharmacy',
    icon: Icons.medication_rounded,
    route: CmacPharmacyRoute(),
    color: DepartmentColors.pharmacy,
  ),
  MenuItem(
    label: 'Operations',
    icon: Icons.schedule_rounded,
    route: CmacOperationsRoute(),
    color: DepartmentColors.administration,
  ),
  MenuItem(
    label: 'Quality analytics',
    icon: Icons.verified_user_rounded,
    route: CmacQualityRoute(),
    accent: MenuAccent.errorTone,
  ),
  MenuItem(
    label: 'Staff',
    icon: Icons.groups_rounded,
    route: CmacStaffRoute(),
    color: DepartmentColors.administration,
  ),
  MenuItem(
    label: 'Quality capture',
    icon: Icons.edit_note_rounded,
    route: CmacQualitySafetyHubRoute(),
    children: [
      MenuItem(
        label: 'Referrals',
        icon: Icons.swap_horiz_rounded,
        route: CmacQualityReferralsRoute(),
      ),
      MenuItem(
        label: 'Complaints',
        icon: Icons.record_voice_over_rounded,
        route: CmacQualityComplaintsRoute(),
      ),
      MenuItem(
        label: 'Incidents',
        icon: Icons.report_problem_rounded,
        route: CmacQualityIncidentsRoute(),
      ),
      MenuItem(
        label: 'Infections',
        icon: Icons.coronavirus_rounded,
        route: CmacQualityInfectionsRoute(),
      ),
    ],
  ),
];

/// CMD sidebar: full CMAC + Accounts & Audit menus flattened into one list
/// (head breadth, view-only actions).
final cmdUnifiedMenuItems = <MenuItem>[
  ...cmacExecutiveMenuItems,
  ...accountsHeadMenu,
  MenuItem(
    label: 'Hospital reports',
    icon: Icons.assessment_outlined,
    route: HospitalReportsHubRoute(),
    color: DepartmentColors.administration,
  ),
  const MenuItem(
    label: 'Health campaigns',
    icon: Icons.campaign_outlined,
    route: HealthCampaignsAdminRoute(),
    color: DepartmentColors.medicalRecords,
  ),
  const MenuItem(
    label: 'Health news',
    icon: Icons.newspaper_outlined,
    route: HealthNewsAdminRoute(),
    color: DepartmentColors.medicalRecords,
  ),
];

/// CMD (chief medical director) executive sidebar — top-level for CMD logins;
/// also nested under "CMD Panel" for full admins.
const cmdExecutiveMenuItems = <MenuItem>[
  MenuItem(
    label: 'Executive dashboard',
    icon: Icons.home_outlined,
    route: CMDDashboardRoute(),
    color: DepartmentColors.administration,
  ),
  MenuItem(
    label: 'Hospital overview',
    icon: Icons.account_balance_outlined,
    route: CMDHospitalOverviewRoute(),
    color: DepartmentColors.administration,
  ),
  MenuItem(
    label: 'Financial command',
    icon: Icons.payments_outlined,
    route: CMDFinancialCommandRoute(),
    color: DepartmentColors.accountingFinance,
  ),
  MenuItem(
    label: 'Staff oversight',
    icon: Icons.groups_outlined,
    route: CMDStaffOversightRoute(),
    color: DepartmentColors.administration,
  ),
  MenuItem(
    label: 'Beds & facilities',
    icon: Icons.bed_outlined,
    route: CMDBedsFacilitiesRoute(),
    color: DepartmentColors.administration,
  ),
  MenuItem(
    label: 'Lab monitoring',
    icon: Icons.biotech_outlined,
    route: CMDLabMonitoringRoute(),
    color: DepartmentColors.laboratory,
  ),
  MenuItem(
    label: 'Alerts & incidents',
    icon: Icons.crisis_alert_outlined,
    route: CMDAlertsIncidentsRoute(),
    color: DepartmentColors.emergency,
  ),
  MenuItem(
    label: 'Reports & analytics',
    icon: Icons.assessment_outlined,
    route: CMDReportsAnalyticsRoute(),
    color: DepartmentColors.administration,
  ),
  MenuItem(
    label: 'Audit & compliance',
    icon: Icons.fact_check_outlined,
    route: CMDAuditComplianceRoute(),
    color: DepartmentColors.administration,
  ),
  MenuItem(
    label: 'Communication',
    icon: Icons.campaign_outlined,
    route: CMDCommunicationCenterRoute(),
    color: DepartmentColors.administration,
  ),
  MenuItem(
    label: 'Patient notifications',
    icon: Icons.notifications_active_outlined,
    route: CustomPatientPushRoute(),
    color: DepartmentColors.administration,
  ),
  MenuItem(
    label: 'Patient experience',
    icon: Icons.star_outline,
    route: CMDPatientExperienceRoute(),
    color: DepartmentColors.administration,
  ),
  MenuItem(
    label: 'System control',
    icon: Icons.tune_outlined,
    route: CMDSystemControlRoute(),
    color: DepartmentColors.itDepartment,
  ),
];

enum UserRole { admin, staff, receptionist }

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------

const _kSidebarWidth = 260.0;
const _kSidebarCollapsedWidth = 64.0;

Color _accentColor(ColorScheme cs, MenuAccent accent) {
  switch (accent) {
    case MenuAccent.primary:
      return cs.primary;
    case MenuAccent.secondary:
      return cs.secondary;
    case MenuAccent.tertiary:
      return cs.tertiary;
    case MenuAccent.errorTone:
      return cs.error;
  }
}

/// Rounded tile behind nav icons: soft fill + border + shadow; stronger when selected.
class _NavIconBox extends StatelessWidget {
  const _NavIconBox({
    required this.icon,
    required this.isActive,
    required this.accent,
    required this.iconSize,
    required this.cs,
    required this.shell,
    this.explicitColor,
  });

  final IconData icon;
  final bool isActive;
  final MenuAccent accent;
  final double iconSize;
  final ColorScheme cs;
  final AppShellTheme shell;

  /// Department brand color override (see [MenuItem.color]). Falls back to
  /// the semantic [accent] tone when null.
  final Color? explicitColor;

  @override
  Widget build(BuildContext context) {
    final base = explicitColor ?? _accentColor(cs, accent);
    final inactiveIcon = explicitColor != null
        ? Color.lerp(shell.sidebarMuted, explicitColor, 0.72)!
        : Color.lerp(shell.sidebarMuted, base, 0.58)!;
    final fill = isActive
        ? Color.alphaBlend(
            base.withValues(alpha: 0.42),
            shell.sidebarBackground,
          )
        : Color.alphaBlend(
            base.withValues(alpha: 0.22),
            shell.sidebarBackground,
          );
    final borderColor = isActive
        ? base.withValues(alpha: 0.75)
        : shell.sidebarDivider.withValues(alpha: 0.7);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(iconSize > 19 ? 7 : 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Icon(icon, size: iconSize, color: isActive ? base : inactiveIcon),
    );
  }
}

void _maybeSidebarHaptic(BuildContext context) {
  if (MediaQuery.sizeOf(context).width < 720) {
    HapticFeedback.selectionClick();
  }
}

// ---------------------------------------------------------------------------
// HomeScreen – shell only; navigation happens via context.router.push()
// ---------------------------------------------------------------------------

@RoutePage()
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Desktop: full-width sidebar (true) vs icon-only rail (false). Default expanded.
  bool _desktopSidebarExpanded = true;

  /// Desktop: pointer over collapsed rail temporarily expands sidebar (peek).
  bool _desktopRailHover = false;

  /// Mobile drawer overlay; hidden by default so content uses full width.
  bool _mobileDrawerOpen = false;

  List<MenuItem> _menuForRole(Staff? staff, String role, String accountType) {
    final common = <MenuItem>[];
    bool moduleOn(AppModule module) => ProductModuleAccess.isModuleEnabled(module);

    if (staffIsSuperAdmin(staff)) {
      if (moduleOn(AppModule.administration)) {
        common.add(
          const MenuItem(
            label: 'Super Admin hub',
            icon: Icons.admin_panel_settings_outlined,
            route: SuperAdminHubRoute(),
          ),
        );
      }
      // Staff directory is shared-platform (all products), not hospital-only.
      common.add(
        const MenuItem(
          label: 'Staff directory',
          icon: Icons.groups_outlined,
          route: SuperAdminStaffListRoute(),
        ),
      );
      // Available on every product (Register is shared; services need billing).
      common.add(
        const MenuItem(
          label: 'Register',
          icon: Icons.verified_user_rounded,
          route: RegisterRoute(),
          color: DepartmentColors.administration,
        ),
      );
      // Hospital already exposes this under System Setup; slim products need a
      // top-level entry because administration routes are not registered.
      if (moduleOn(AppModule.billing) &&
          !moduleOn(AppModule.administration)) {
        common.add(
          const MenuItem(
            label: 'Add Service',
            icon: Icons.add_box_outlined,
            route: SystemSetupRoute(),
            color: DepartmentColors.itDepartment,
          ),
        );
      }
    }
    final r = role.toLowerCase();
    final at = accountType.toLowerCase();
    final canBillingDash = staffCanAccessPrivilegedBilling(staff);

    final isCmacAccount = at == 'cmac' || r == 'cmac';
    if (isCmacAccount && moduleOn(AppModule.administration)) {
      common.addAll(cmacExecutiveMenuItems);
      return common;
    }

    final isCmdAccount = at == 'cmd' || r == 'cmd';
    if (isCmdAccount && moduleOn(AppModule.administration)) {
      common.addAll(cmdUnifiedMenuItems);
      return common;
    }

    final isFrontDesk =
        at == 'front_desk' ||
        at == 'frontdesk' ||
        r == 'front_desk' ||
        r == 'receptionist';
    if (isFrontDesk && moduleOn(AppModule.registration)) {
      common.addAll(frontDesk);
    }

    final isBilling =
        at == 'billing' ||
        at == 'bills' ||
        r == 'billing' ||
        r == 'billing_head' ||
        r == 'billing_staff';
    if (isBilling && moduleOn(AppModule.billing)) {
      final billingMenu = canBillingDash
          ? bills
          : bills.where((m) => m.route is! BillingDashboardRoute).toList();
      // Billing staff bill patients but must not edit the hospital service catalog.
      common.addAll(
        r == 'billing_staff'
            ? billingMenu.where((m) => m.route is! SystemSetupRoute).toList()
            : billingMenu,
      );
      if (r == 'billing_head') {
        common.addAll(billingHeadExtraMenu);
      }
    }

    final bootstrap = ref.watch(nursingBootstrapDataProvider);
    if (isNursingStaff(staff) && moduleOn(AppModule.nursing)) {
      common.addAll(nurseMenuFor(staff, bootstrap));
    }

    final isPharmacyDept =
        at == 'pharmacy' ||
        at == 'pharmacy_store' ||
        at == 'pharmacy_dispensary' ||
        at == 'pharmacy_head';
    if (isPharmacyDept && moduleOn(AppModule.pharmacy)) {
      final isDispensary =
          at == 'pharmacy_dispensary' ||
          (at == 'pharmacy' && r == 'pharmacy_dispensary');
      if (isDispensary) {
        common.addAll(phamDispense);
      } else {
        common.addAll(pharmacy);
      }
      final isPharmacyHead =
          at == 'pharmacy_head' ||
          r == 'pharmacy_head' ||
          (staff?.pharmacyRole?.toLowerCase().replaceAll('-', '_') ==
              'pharmacy_head');
      if (isPharmacyHead) {
        common.addAll(pharmacyHeadExtraMenu);
      }
    }

    final isPurchasesDept =
        at == 'purchases' ||
        at == 'purchases_store' ||
        at == 'purchases_head' ||
        r == 'purchases_store' ||
        r == 'purchases_head';
    if (isPurchasesDept && moduleOn(AppModule.purchases)) {
      common.addAll(purchasesMenu);
    }

    final isPhysician =
        at == 'physician' ||
        at == 'consultant' ||
        at == 'inpatient_doctor' ||
        r == 'doctor' ||
        r == 'consultant' ||
        r == 'resident' ||
        r == 'intern' ||
        r == 'junior_resident' ||
        r == 'senior_resident' ||
        r == 'chief_resident' ||
        r == 'medical_student';
    if (isPhysician && moduleOn(AppModule.physician)) {
      common.addAll(doctors);
    }

    final isLab =
        at == 'laboratory' ||
        at == 'lab' ||
        r == 'lab_head' ||
        r == 'lab_scientist' ||
        r == 'lab_technician';
    if (isLab && moduleOn(AppModule.laboratory)) {
      common.addAll(labMenu);
    }

    if (at == 'radiology' && moduleOn(AppModule.radiology)) {
      common.addAll(radiologyMenu);
    }

    if (canAccessDialysisModule(staff) && moduleOn(AppModule.dialysis)) {
      common.addAll(dialysisMenu);
    }

    if (canAccessTheatreModule(staff) && moduleOn(AppModule.theatre)) {
      common.addAll(theatreMenu);
    }

    if ((at == 'ict' || r == 'ict_staff') && moduleOn(AppModule.ict)) {
      common.addAll([
        const MenuItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          route: DashboardRoute(),
          color: DepartmentColors.itDepartment,
        ),
      ]);
    }

    if ((at == 'medical_records' || r == 'medical_records') &&
        moduleOn(AppModule.medicalRecords)) {
      common.addAll(medicalRecordsMenu);
    }

    if ((at == 'accounting' || at == 'accounts') &&
        moduleOn(AppModule.accounting)) {
      common.addAll(
        isAccountHead(staff) ? accountsHeadMenu : accountsStaffMenu,
      );
    }

    if (role.toLowerCase() == 'admin' ||
        at == 'cmac' ||
        at == 'super_admin' ||
        r == 'super_admin') {
      // Product-scoped admin extras: only modules this build enables.
      if (moduleOn(AppModule.billing) && canBillingDash) {
        common.add(
          const MenuItem(
            label: 'Billing Dashboard',
            icon: Icons.dashboard_customize_outlined,
            route: BillingDashboardRoute(),
            color: DepartmentColors.billing,
          ),
        );
      }
      if (moduleOn(AppModule.accounting)) {
        common.add(
          const MenuItem(
            label: 'Receivables',
            icon: Icons.receipt_long_outlined,
            route: ReceivablesHmoRoute(),
            color: DepartmentColors.accountingFinance,
            children: [
              MenuItem(
                label: 'HMO Receivables',
                icon: Icons.health_and_safety_outlined,
                route: ReceivablesHmoRoute(),
                color: DepartmentColors.accountingFinance,
              ),
              MenuItem(
                label: 'Discount Receivables',
                icon: Icons.sell_outlined,
                route: ReceivablesDiscountRoute(),
                color: DepartmentColors.accountingFinance,
              ),
            ],
          ),
        );
        common.add(
          const MenuItem(
            label: 'Discount Policies',
            icon: Icons.rule_folder_outlined,
            route: DiscountPolicyManagementRoute(),
            color: DepartmentColors.administration,
          ),
        );
      }
      if (moduleOn(AppModule.administration)) {
        common.add(
          const MenuItem(
            label: 'Clinical packages',
            icon: Icons.medical_information_outlined,
            route: ClinicalPackageManagementRoute(),
            color: DepartmentColors.outpatientClinic,
          ),
        );
        common.add(
          MenuItem(
            label: 'CMD Panel',
            icon: Icons.dashboard_customize_outlined,
            route: const CMDDashboardRoute(),
            color: DepartmentColors.administration,
            children: cmdExecutiveMenuItems,
          ),
        );
        // Super admin already has Register from the dedicated block above.
        if (!staffIsSuperAdmin(staff)) {
          common.add(
            const MenuItem(
              label: 'Register',
              icon: Icons.verified_user_rounded,
              route: RegisterRoute(),
              color: DepartmentColors.administration,
            ),
          );
        }
      }
      if (moduleOn(AppModule.laboratory)) {
        common.add(
          const MenuItem(
            label: 'Laboratory',
            icon: Icons.biotech_rounded,
            route: LabDashboardRoute(),
            color: DepartmentColors.laboratory,
          ),
        );
      }
      if (moduleOn(AppModule.radiology)) {
        common.add(
          const MenuItem(
            label: 'Radiology',
            icon: Icons.radar_rounded,
            route: RadiologyDashboardRoute(),
            color: DepartmentColors.radiology,
          ),
        );
      }
      if (moduleOn(AppModule.store)) {
        common.add(
          const MenuItem(
            label: 'Store',
            icon: Icons.inventory_2_rounded,
            route: StoreDashboardRoute(),
          ),
        );
      }
      if (moduleOn(AppModule.administration)) {
        common.add(
          MenuItem(
            label: 'System Setup',
            icon: Icons.dashboard_outlined,
            route: CMDDashboardRoute(),
            color: DepartmentColors.itDepartment,
            children: [
              MenuItem(
                label: 'Add Service',
                icon: Icons.add_box_outlined,
                route: SystemSetupRoute(),
                color: DepartmentColors.itDepartment,
              ),
              MenuItem(
                label: 'Add Consulting Room',
                icon: Icons.add_box_outlined,
                route: ConsultingRoomsRoute(),
                color: DepartmentColors.itDepartment,
              ),
              MenuItem(
                label: 'Ward Management',
                icon: Icons.add_box_outlined,
                route: WardManagementRoute(),
                color: DepartmentColors.itDepartment,
              ),
              MenuItem(
                label: 'Bank Management',
                icon: Icons.account_balance_outlined,
                route: BankManagementRoute(),
                color: DepartmentColors.accountingFinance,
              ),
              MenuItem(
                label: 'Announcements',
                icon: Icons.campaign_outlined,
                route: AnnouncementManagementRoute(),
                color: DepartmentColors.itDepartment,
              ),
            ],
          ),
        );
      }
    }

    if (at == 'store' && moduleOn(AppModule.store)) {
      common.addAll(storeMenu);
    }

    final isHmoDesk = at == 'hmo' || r == 'hmo_staff' || r == 'hmo_desk';
    if (isHmoDesk && moduleOn(AppModule.hmo)) {
      common.addAll(hmoDeskMenu);
    }

    // Billing / accounting heads — HMO desk gets these from [hmoDeskMenu] instead.
    if (canManageHmos(staff) && !isHmoDesk && moduleOn(AppModule.hmo)) {
      common.addAll([
        MenuItem(
          label: 'HMO plans',
          icon: Icons.health_and_safety_outlined,
          route: HmoListRoute(),
        ),
        MenuItem(
          label: 'Add HMO',
          icon: Icons.add_business_outlined,
          route: HmoFormRoute(),
        ),
        MenuItem(
          label: 'HMO service pricing',
          icon: Icons.price_change_outlined,
          route: HmoServicePricingRoute(),
        ),
      ]);
    }

    return common;
  }

  static IconData _themeMenuIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationNavigationProvider, (previous, next) {
      if (next == null) return;
      if (next.type == 'chat' &&
          next.conversationId != null &&
          next.conversationId!.isNotEmpty) {
        if (MediaQuery.of(context).size.width < 720) {
          context.router.push(
            StaffChatThreadRoute(conversationId: next.conversationId!),
          );
        } else {
          ref
              .read(shellSidePanelProvider.notifier)
              .open(ShellSidePanelTab.chat);
        }
      } else if (next.type == 'ed_emergency_request') {
        final id = next.emergencyRequestId;
        if (id != null && id.isNotEmpty) {
          context.router.push(EdEmergencyRequestDetailRoute(id: id));
        } else {
          context.router.push(const EdEmergencyRequestsRoute());
        }
      }
      ref.read(notificationNavigationProvider.notifier).consume();
    });

    ref.watch(internalChatSocketProvider);
    ref.watch(staffChatShellProvider);
    ref.watch(pendingOrdersTickProvider);
    final state = ref.watch(authProvider);
    final auth = ref.watch(authProvider);
    final staff = auth.staff;
    final preview = ref.watch(superAdminPreviewProvider);
    var role = staff?.staffRole.toLowerCase() ?? '';
    var accountType = staff?.accountType?.name.toLowerCase() ?? '';
    if (staffIsSuperAdmin(staff) && preview.isActive) {
      role = preview.previewRole!;
      accountType = preview.previewAccountType!;
    }
    final menuItems = _menuForRole(staff, role, accountType);
    final isMobile = MediaQuery.of(context).size.width < 720;
    final previewBanner = preview.isActive
        ? _SuperAdminPreviewBanner(
            label: preview.previewBannerLabel!,
            onClear: () {
              ref.read(superAdminPreviewProvider.notifier).clear();
              context.router.navigate(const SuperAdminHubRoute());
            },
            onOpenHub: () {
              context.router.navigate(const SuperAdminHubRoute());
            },
          )
        : null;

    void openHelpCenter() {
      if (isMobile) {
        context.router.push(const HelpCenterRoute());
      } else {
        ref
            .read(shellSidePanelProvider.notifier)
            .toggle(ShellSidePanelTab.help);
      }
    }

    void openStaffChat() {
      if (isMobile) {
        context.router.push(const StaffChatRoute());
      } else {
        ref
            .read(shellSidePanelProvider.notifier)
            .toggle(ShellSidePanelTab.chat);
      }
      ref.read(staffChatShellProvider.notifier).refresh();
    }

    final shell = AppShellTheme.of(context);
    return Scaffold(
      backgroundColor: shell.contentBackground,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              if (Platform.isWindows)
                _buildTitleBar(context, openHelpCenter, openStaffChat),
              Expanded(
                child: isMobile
                    ? _buildMobileLayout(
                        context,
                        menuItems,
                        state,
                        openHelpCenter,
                        openStaffChat,
                        previewBanner,
                      )
                    : _buildDesktopLayout(
                        context,
                        menuItems,
                        state,
                        openHelpCenter,
                        openStaffChat,
                        previewBanner,
                      ),
              ),
            ],
          ),
          if (!isMobile) const DesktopShellSidePanel(),
        ],
      ),
    );
  }

  // ── Desktop: persistent sidebar that collapses to icon rail ──────────────

  Widget _buildDesktopLayout(
    BuildContext context,
    List<MenuItem> menuItems,
    state,
    VoidCallback openHelpCenter,
    VoidCallback openStaffChat,
    Widget? previewBanner,
  ) {
    final hoverPeek = !_desktopSidebarExpanded && _desktopRailHover;
    final sidebarWide = _desktopSidebarExpanded || hoverPeek;

    return Row(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _desktopRailHover = true),
          onExit: (_) => setState(() => _desktopRailHover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: sidebarWide ? _kSidebarWidth : _kSidebarCollapsedWidth,
            child: _SidebarNavigation(
              menuItems: menuItems,
              state: state,
              collapsed: !sidebarWide,
              onToggle: () => setState(
                () => _desktopSidebarExpanded = !_desktopSidebarExpanded,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!Platform.isWindows)
                _NonWindowsShellActions(
                  onHelpCenter: openHelpCenter,
                  onStaffChat: openStaffChat,
                ),
              if (previewBanner != null) previewBanner,
              const AnnouncementBannerHost(),
              Expanded(
                child: ColoredBox(
                  color: AppShellTheme.of(context).contentBackground,
                  child: const AutoRouter(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile: top bar with hamburger + drawer overlay ──────────────────────

  Widget _buildMobileLayout(
    BuildContext context,
    List<MenuItem> menuItems,
    state,
    VoidCallback openHelpCenter,
    VoidCallback openStaffChat,
    Widget? previewBanner,
  ) {
    return Stack(
      children: [
        Column(
          children: [
            _MobileTopBar(
              onMenuTap: () => setState(() => _mobileDrawerOpen = true),
              onHelpCenter: openHelpCenter,
              onStaffChat: openStaffChat,
            ),
            if (previewBanner != null) previewBanner,
            const AnnouncementBannerHost(),
            const Expanded(child: AutoRouter()),
          ],
        ),
        if (_mobileDrawerOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _mobileDrawerOpen = false),
              child: ColoredBox(
                color: Theme.of(
                  context,
                ).colorScheme.scrim.withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _kSidebarWidth,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              offset: _mobileDrawerOpen ? Offset.zero : const Offset(-1, 0),
              curve: Curves.easeInOut,
              child: Material(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                shadowColor: Theme.of(context).colorScheme.shadow,
                clipBehavior: Clip.none,
                child: _SidebarNavigation(
                  menuItems: menuItems,
                  state: state,
                  collapsed: false,
                  onToggle: () => setState(() => _mobileDrawerOpen = false),
                  closeLabel: true,
                  onNavigateTap: () =>
                      setState(() => _mobileDrawerOpen = false),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Windows Custom Title Bar ──────────────────────────────────────────────

  Widget _buildTitleBar(
    BuildContext context,
    VoidCallback openHelpCenter,
    VoidCallback openStaffChat,
  ) {
    final shell = AppShellTheme.of(context);
    return WindowTitleBarBox(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [shell.titleBarGradientStart, shell.titleBarGradientEnd],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: MoveWindow(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),

                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Helty',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: shell.sidebarOnBackground,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                spacing: 8,
                children: [
                  const _WindowsCheckForUpdatesButton(),
                  _WindowsShellHelpChatButtons(
                    onHelpCenter: openHelpCenter,
                    onStaffChat: openStaffChat,
                  ),
                  const WindowButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowsCheckForUpdatesButton extends StatefulWidget {
  const _WindowsCheckForUpdatesButton();

  @override
  State<_WindowsCheckForUpdatesButton> createState() =>
      _WindowsCheckForUpdatesButtonState();
}

class _WindowsCheckForUpdatesButtonState
    extends State<_WindowsCheckForUpdatesButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final shell = AppShellTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: 'Check for updates',
        child: InkWell(
          onTap: () => HeltyDesktopUpdateService.triggerCheckFromUi(),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.system_update_rounded,
              color: _hover ? shell.sidebarAccent : shell.sidebarMuted,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _WindowsShellHelpChatButtons extends StatelessWidget {
  const _WindowsShellHelpChatButtons({
    required this.onHelpCenter,
    required this.onStaffChat,
  });

  final VoidCallback onHelpCenter;
  final VoidCallback onStaffChat;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowsTitleBarIconAction(
          tooltip: 'Help Center',
          icon: Icons.help_outline_rounded,
          onTap: onHelpCenter,
        ),
        const SizedBox(width: 4),
        StaffMessagesShellAction(onTap: onStaffChat, iconSize: 18, dense: true),
      ],
    );
  }
}

class _WindowsTitleBarIconAction extends StatefulWidget {
  const _WindowsTitleBarIconAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_WindowsTitleBarIconAction> createState() =>
      _WindowsTitleBarIconActionState();
}

class _WindowsTitleBarIconActionState
    extends State<_WindowsTitleBarIconAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final shell = AppShellTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: widget.tooltip,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              widget.icon,
              color: _hover ? shell.sidebarAccent : shell.sidebarMuted,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _NonWindowsShellActions extends StatelessWidget {
  const _NonWindowsShellActions({
    required this.onHelpCenter,
    required this.onStaffChat,
  });

  final VoidCallback onHelpCenter;
  final VoidCallback onStaffChat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            const Spacer(),
            IconButton(
              tooltip: 'Help Center',
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: onHelpCenter,
            ),
            StaffMessagesShellAction(onTap: onStaffChat),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme Menu Row
// ---------------------------------------------------------------------------

class _ThemeMenuRow extends StatelessWidget {
  const _ThemeMenuRow({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        if (selected)
          Icon(
            Icons.check,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar Navigation
// ---------------------------------------------------------------------------

class _SidebarNavigation extends StatelessWidget {
  final List<MenuItem> menuItems;
  final AuthState state;
  final bool collapsed;
  final VoidCallback onToggle;
  final bool closeLabel;

  /// Called after navigating from the drawer (e.g. closes mobile drawer).
  final VoidCallback? onNavigateTap;

  const _SidebarNavigation({
    required this.menuItems,
    required this.collapsed,
    required this.onToggle,
    this.closeLabel = false,
    required this.state,
    this.onNavigateTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentName = context.router.current.name;
    final shell = AppShellTheme.of(context);

    return ColoredBox(
      color: shell.sidebarBackground,
      child: Column(
        children: [
          _buildHeader(context, state),
          const _SidebarDivider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                for (int i = 0; i < menuItems.length; i++)
                  _SidebarEntry(
                    item: menuItems[i],
                    index: i,
                    currentName: currentName,
                    collapsed: collapsed,
                    onNavigateTap: onNavigateTap,
                  ),
              ],
            ),
          ),
          const _SidebarDivider(),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthState state) {
    final cs = Theme.of(context).colorScheme;
    final shell = AppShellTheme.of(context);
    final staff = state.staff;
    final initials =
        "${(staff?.firstName.isNotEmpty ?? false) ? staff!.firstName[0].toUpperCase() : ''}${(staff?.lastName.isNotEmpty ?? false) ? staff!.lastName[0].toUpperCase() : ''}";
    final displayName = staff == null
        ? 'Signing out...'
        : '${staff.firstName.toUpperCase()} ${staff.lastName.toUpperCase()}';
    final displayRole = staff?.staffRole.toUpperCase() ?? 'LOGGING OUT';

    final avatar = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: .4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: CircleAvatar(
        radius: collapsed ? 18 : 20,
        backgroundColor: cs.primary,
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: cs.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: collapsed ? 16 : 18,
            ),
          ),
        ),
      ),
    );

    /// Icon rail (~64px): horizontal row does not fit avatar + toggle; stack vertically.
    if (collapsed && !closeLabel) {
      return SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
              const SizedBox(height: 12),
              _ToggleButton(
                collapsed: collapsed,
                onToggle: onToggle,
                closeLabel: closeLabel,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            avatar,
            if (!collapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: shell.sidebarOnBackground,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      displayRole,
                      style: TextStyle(color: shell.sidebarMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
            _ToggleButton(
              collapsed: collapsed,
              onToggle: onToggle,
              closeLabel: closeLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: collapsed ? _IconLogoutButton() : _FullLogoutButton(),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar toggle button
// ---------------------------------------------------------------------------

class _ToggleButton extends StatefulWidget {
  final bool collapsed;
  final VoidCallback onToggle;
  final bool closeLabel;

  const _ToggleButton({
    required this.collapsed,
    required this.onToggle,
    required this.closeLabel,
  });

  @override
  State<_ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<_ToggleButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final shell = AppShellTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _hover ? shell.sidebarHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.closeLabel || widget.collapsed
                ? Icons.menu_open_rounded
                : Icons.menu_rounded,
            color: shell.sidebarOnBackground,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar divider
// ---------------------------------------------------------------------------

class _SidebarDivider extends StatelessWidget {
  const _SidebarDivider();

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: AppShellTheme.of(context).sidebarDivider,
  );
}

// ---------------------------------------------------------------------------
// Sidebar menu entry
// ---------------------------------------------------------------------------

class _SidebarEntry extends StatefulWidget {
  final MenuItem item;
  final int index;
  final String? currentName;
  final bool collapsed;
  final VoidCallback? onNavigateTap;

  const _SidebarEntry({
    required this.item,
    required this.index,
    required this.currentName,
    required this.collapsed,
    this.onNavigateTap,
  });

  @override
  State<_SidebarEntry> createState() => _SidebarEntryState();
}

class _SidebarEntryState extends State<_SidebarEntry> {
  bool _hover = false;
  bool _expanded = false;

  MenuAccent get _accent =>
      widget.item.accent ??
      MenuAccent.values[widget.index % MenuAccent.values.length];

  void _navigateTo(BuildContext context, PageRouteInfo route) {
    // final inner = context.router.innerRouterOf<StackRouter>(
    //   'DoctorWalkInQueueRoute',
    // );
    // final routeTypeName = route.runtimeType.toString();
    // final isDoctorChild = _doctorDashboardChildNames.contains(routeTypeName);
    // if (inner != null && isDoctorChild) {
    //   inner.push(route);
    // } else {

    // }
    context.router.push(route);
    widget.onNavigateTap?.call();
  }

  bool get _isActive {
    final name = widget.currentName;
    if (name == widget.item.route.runtimeType.toString()) return true;
    if (widget.item.children != null) {
      return widget.item.children!.any(
        (c) => name == c.route.runtimeType.toString(),
      );
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _expanded = _isActive;
  }

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.item.children?.isNotEmpty ?? false;

    if (hasChildren && !widget.collapsed) {
      return _buildExpandable(context);
    }

    return _buildTile(
      context,
      icon: widget.item.icon,
      label: widget.item.label,
      isActive: _isActive,
      onTap: () => _navigateTo(context, widget.item.route),
    );
  }

  Widget _buildExpandable(BuildContext context) {
    final shell = AppShellTheme.of(context);
    return Column(
      children: [
        _buildTile(
          context,
          icon: widget.item.icon,
          label: widget.item.label,
          isActive: _isActive,
          trailing: AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: shell.sidebarMuted,
              size: 18,
            ),
          ),
          onTap: () {
            _maybeSidebarHaptic(context);
            setState(() => _expanded = !_expanded);
          },
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildChildren(context),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildChildren(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Column(
        children: [
          for (final child in widget.item.children!)
            _ChildEntry(
              item: child,
              currentName: widget.currentName,
              onNavigateTap: widget.onNavigateTap,
            ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final shell = AppShellTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isActive
              ? shell.sidebarSelectedRow
              : _hover
              ? shell.sidebarHover
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: cs.primary.withValues(alpha: 0.38), width: 1)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            splashColor: shell.ripple,
            highlightColor: shell.ripple.withValues(alpha: 0.35),
            onTap: () {
              _maybeSidebarHaptic(context);
              onTap();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.collapsed ? 0 : 12,
                vertical: 10,
              ),
              child: widget.collapsed
                  ? _collapsedIcon(icon, isActive, cs, shell)
                  : _expandedRow(icon, label, isActive, trailing, cs, shell),
            ),
          ),
        ),
      ),
    );
  }

  Widget _collapsedIcon(
    IconData icon,
    bool isActive,
    ColorScheme cs,
    AppShellTheme shell,
  ) {
    return Center(
      child: Tooltip(
        message: widget.item.label,
        preferBelow: false,
        child: AnimatedScale(
          scale: isActive ? 1.06 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: _NavIconBox(
            icon: icon,
            isActive: isActive,
            accent: _accent,
            iconSize: 22,
            cs: cs,
            shell: shell,
            explicitColor: widget.item.color,
          ),
        ),
      ),
    );
  }

  Widget _expandedRow(
    IconData icon,
    String label,
    bool isActive,
    Widget? trailing,
    ColorScheme cs,
    AppShellTheme shell,
  ) {
    final accentCol = widget.item.color ?? _accentColor(cs, _accent);
    return Row(
      children: [
        SizedBox(
          width: 13,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: isActive ? 4 : 0,
              height: isActive ? 28 : 0,
              decoration: BoxDecoration(
                color: accentCol,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        AnimatedScale(
          scale: isActive ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: _NavIconBox(
            icon: icon,
            isActive: isActive,
            accent: _accent,
            iconSize: 20,
            cs: cs,
            shell: shell,
            explicitColor: widget.item.color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? shell.sidebarOnActive
                  : shell.sidebarOnBackground,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13.5,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Child entry (sub-menu item)
// ---------------------------------------------------------------------------

class _ChildEntry extends StatefulWidget {
  final MenuItem item;
  final String? currentName;
  final VoidCallback? onNavigateTap;

  const _ChildEntry({
    required this.item,
    required this.currentName,
    this.onNavigateTap,
  });

  @override
  State<_ChildEntry> createState() => _ChildEntryState();
}

class _ChildEntryState extends State<_ChildEntry> {
  bool _hover = false;

  bool get _isActive =>
      widget.currentName == widget.item.route.runtimeType.toString();

  MenuAccent get _accent =>
      widget.item.accent ??
      MenuAccent.values[widget.item.label.hashCode.abs() %
          MenuAccent.values.length];

  @override
  Widget build(BuildContext context) {
    final shell = AppShellTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    final accentCol = widget.item.color ?? _accentColor(cs, _accent);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: _isActive
              ? shell.sidebarSelectedRow
              : _hover
              ? shell.sidebarHover
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: _isActive
              ? Border.all(color: cs.primary.withValues(alpha: 0.34), width: 1)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            splashColor: shell.ripple,
            highlightColor: shell.ripple.withValues(alpha: 0.35),
            onTap: () {
              _maybeSidebarHaptic(context);
              context.router.push(widget.item.route);
              widget.onNavigateTap?.call();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        width: _isActive ? 3 : 0,
                        height: _isActive ? 24 : 0,
                        decoration: BoxDecoration(
                          color: accentCol,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  AnimatedScale(
                    scale: _isActive ? 1.04 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: _NavIconBox(
                      icon: widget.item.icon,
                      isActive: _isActive,
                      accent: _accent,
                      iconSize: 17,
                      cs: cs,
                      shell: shell,
                      explicitColor: widget.item.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: TextStyle(
                        color: _isActive
                            ? shell.sidebarOnActive
                            : shell.sidebarOnBackground,
                        fontWeight: _isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile top bar
// ---------------------------------------------------------------------------

class _MobileTopBar extends ConsumerWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onHelpCenter;
  final VoidCallback onStaffChat;

  const _MobileTopBar({
    required this.onMenuTap,
    required this.onHelpCenter,
    required this.onStaffChat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);
    final shell = AppShellTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: shell.sidebarBackground,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          _IconButton(icon: Icons.menu_rounded, onTap: onMenuTap),
          const SizedBox(width: 12),
          Image.asset(
            'assets/logo.png',
            fit: BoxFit.cover,
            height: 20,
            width: 20,
          ),
          const SizedBox(width: 8),
          // Text(
          //   'Helty',
          //   style: TextStyle(
          //     color: shell.sidebarOnBackground,
          //     fontWeight: FontWeight.bold,
          //     fontSize: 16,
          //   ),
          // ),
          const Spacer(),
          _IconButton(icon: Icons.help_outline_rounded, onTap: onHelpCenter),
          StaffMessagesShellAction(
            onTap: onStaffChat,
            dense: true,
            iconSize: 22,
            iconColor: shell.sidebarOnBackground,
          ),
          PopupMenuButton<ThemeMode>(
            tooltip: 'Theme',
            padding: const EdgeInsets.all(8),
            iconSize: 22,
            splashRadius: 22,
            icon: Icon(
              _HomeScreenState._themeMenuIcon(currentMode),
              color: shell.sidebarOnBackground,
              size: 22,
            ),
            onSelected: (mode) {
              ref.read(themeModeProvider.notifier).setThemeMode(mode);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ThemeMode.light,
                child: _ThemeMenuRow(
                  icon: Icons.light_mode_outlined,
                  label: 'Light',
                  selected: currentMode == ThemeMode.light,
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: _ThemeMenuRow(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark',
                  selected: currentMode == ThemeMode.dark,
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.system,
                child: _ThemeMenuRow(
                  icon: Icons.brightness_auto_outlined,
                  label: 'System',
                  selected: currentMode == ThemeMode.system,
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),
          _MobileLogoutButton(),
        ],
      ),
    );
  }
}

class _IconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final shell = AppShellTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hover ? shell.sidebarHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, color: shell.sidebarOnBackground, size: 22),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Super Admin preview banner
// ---------------------------------------------------------------------------

class _SuperAdminPreviewBanner extends StatelessWidget {
  const _SuperAdminPreviewBanner({
    required this.label,
    required this.onClear,
    required this.onOpenHub,
  });

  final String label;
  final VoidCallback onClear;
  final VoidCallback onOpenHub;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.visibility_outlined, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Preview: $label',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(onPressed: onClear, child: const Text('Clear preview')),
            TextButton(onPressed: onOpenHub, child: const Text('Hub')),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logout buttons
// ---------------------------------------------------------------------------

Future<void> _logoutToLoginReplacingStack(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  await container.read(authProvider.notifier).logout();
  container.read(paidModuleRequestContextProvider.notifier).state = null;
  container.read(superAdminPreviewProvider.notifier).clear();
  context.router.replaceAll([LoginRoute()]);
}

class _IconLogoutButton extends StatefulWidget {
  @override
  State<_IconLogoutButton> createState() => _IconLogoutButtonState();
}

class _IconLogoutButtonState extends State<_IconLogoutButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final shell = AppShellTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => unawaited(_logoutToLoginReplacingStack(context)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _hover
                ? cs.error.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Tooltip(
            message: 'Logout',
            child: Icon(
              Icons.logout_rounded,
              color: _hover ? cs.error : shell.sidebarMuted,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _FullLogoutButton extends StatefulWidget {
  @override
  State<_FullLogoutButton> createState() => _FullLogoutButtonState();
}

class _FullLogoutButtonState extends State<_FullLogoutButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final shell = AppShellTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => unawaited(_logoutToLoginReplacingStack(context)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hover
                ? cs.error.withValues(alpha: 0.18)
                : shell.sidebarHover,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hover
                  ? cs.error.withValues(alpha: 0.55)
                  : shell.sidebarDivider,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: _hover ? cs.error : shell.sidebarMuted,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(
                  color: _hover ? cs.error : shell.sidebarOnBackground,
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleBarLogoutButton extends StatefulWidget {
  const _TitleBarLogoutButton();

  @override
  State<_TitleBarLogoutButton> createState() => _TitleBarLogoutButtonState();
}

class _TitleBarLogoutButtonState extends State<_TitleBarLogoutButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final shell = AppShellTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: () => unawaited(_logoutToLoginReplacingStack(context)),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.logout_rounded,
            color: _hover ? cs.error : shell.sidebarMuted,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _MobileLogoutButton extends StatefulWidget {
  @override
  State<_MobileLogoutButton> createState() => _MobileLogoutButtonState();
}

class _MobileLogoutButtonState extends State<_MobileLogoutButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final shell = AppShellTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => unawaited(_logoutToLoginReplacingStack(context)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.logout_rounded,
            color: _hover ? cs.error : shell.sidebarMuted,
            size: 20,
          ),
        ),
      ),
    );
  }
}
