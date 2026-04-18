import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

import '../../chat/services/internal_chat_socket.dart';
import '../../models/staff_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/module_request_flow_provider.dart';
import 'desktop_shell_side_panel.dart';
import 'shell_side_panel_provider.dart';
import '../../services/helty_desktop_update_service.dart';
import '../../services/notificationbar.dart';
import '../../services/title_bar.dart';
import 'account_types.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class MenuItem {
  final String label;
  final IconData icon;
  final PageRouteInfo route;
  final List<MenuItem>? children;

  const MenuItem({
    required this.label,
    required this.icon,
    required this.route,
    this.children,
  });
}

enum UserRole { admin, staff, receptionist }

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------

const _kSidebarWidth = 260.0;
const _kSidebarCollapsedWidth = 64.0;
const _kSidebarBg = Color(0xFF0F172A); // slate-900
const _kSidebarAccent = Color(0xFF6366F1); // indigo-500
const _kSidebarAccentBg = Color(0xFF1E1B4B); // indigo-950
const _kSidebarText = Color(0xFFCBD5E1); // slate-300
const _kSidebarTextMuted = Color(0xFF64748B); // slate-500
const _kSidebarHover = Color(0xFF1E293B); // slate-800
const _kSidebarDivider = Color(0xFF1E293B);

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
  bool _sidebarOpen = true;

  List<MenuItem> _menuForRole(Staff? staff, String role, String accountType) {
    final common = <MenuItem>[];
    final r = role.toLowerCase();
    final at = accountType.toLowerCase();
    final canBillingDash = staffCanAccessPrivilegedBilling(staff);

    final isFrontDesk =
        at == 'front_desk' ||
        at == 'frontdesk' ||
        r == 'front_desk' ||
        r == 'receptionist';
    if (isFrontDesk) {
      common.addAll(frontDesk);
    }

    final isBilling =
        at == 'billing' ||
        at == 'bills' ||
        r == 'billing' ||
        r == 'billing_head' ||
        r == 'billing_staff';
    if (isBilling) {
      common.addAll(
        canBillingDash
            ? bills
            : bills
                  .where((m) => m.route is! BillingDashboardRoute)
                  .toList(),
      );
    }

    final isNurse =
        at == 'nurse' ||
        at == 'head_nurse' ||
        at == 'inpatient_nurse' ||
        at == 'outpatient_nurse' ||
        r == 'nurse' ||
        r == 'head_nurse' ||
        r == 'inpatient_nurse' ||
        r == 'outpatient_nurse';
    if (isNurse) {
      common.addAll(nurses);
    }

    final isPharmacyDept =
        at == 'pharmacy' ||
        at == 'pharmacy_store' ||
        at == 'pharmacy_dispensary' ||
        at == 'pharmacy_head';
    if (isPharmacyDept) {
      final isDispensary =
          at == 'pharmacy_dispensary' ||
          (at == 'pharmacy' && r == 'pharmacy_dispensary');
      if (isDispensary) {
        common.addAll(phamDispense);
      } else {
        common.addAll(pharmacy);
      }
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
    if (isPhysician) {
      common.addAll(doctors);
    }

    final isLab =
        at == 'laboratory' ||
        at == 'lab' ||
        r == 'lab_head' ||
        r == 'lab_scientist' ||
        r == 'lab_technician';
    if (isLab) {
      common.addAll(labMenu);
    }

    if (at == 'radiology') {
      common.addAll(radiologyMenu);
    }

    if (at == 'ict' || r == 'ict_staff') {
      common.addAll([
        const MenuItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          route: DashboardRoute(),
        ),
      ]);
    }

    if (at == 'medical_records' || r == 'medical_records') {
      common.addAll(medicalRecordsMenu);
    }

    if (at == 'accounting' || at == 'accounts') {
      common.addAll([
        const MenuItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          route: DashboardRoute(),
        ),
        if (canBillingDash)
          const MenuItem(
            label: 'Billing Dashboard',
            icon: Icons.dashboard_customize_outlined,
            route: BillingDashboardRoute(),
          ),
      ]);
    }

    if (role.toLowerCase() == 'admin' ||
        at == 'cmd' ||
        at == 'cmac' ||
        at == 'super_admin' ||
        r == 'super_admin') {
      common.addAll([
        if (canBillingDash)
          const MenuItem(
            label: 'Billing Dashboard',
            icon: Icons.dashboard_customize_outlined,
            route: BillingDashboardRoute(),
          ),
        MenuItem(
          label: 'CMD Panel',
          icon: Icons.dashboard_customize_outlined,
          route: const CMDDashboardRoute(),
          children: [
            const MenuItem(
              label: 'Executive dashboard',
              icon: Icons.home_outlined,
              route: CMDDashboardRoute(),
            ),
            const MenuItem(
              label: 'Hospital overview',
              icon: Icons.account_balance_outlined,
              route: CMDHospitalOverviewRoute(),
            ),
            const MenuItem(
              label: 'Financial command',
              icon: Icons.payments_outlined,
              route: CMDFinancialCommandRoute(),
            ),
            const MenuItem(
              label: 'Staff oversight',
              icon: Icons.groups_outlined,
              route: CMDStaffOversightRoute(),
            ),
            const MenuItem(
              label: 'Beds & facilities',
              icon: Icons.bed_outlined,
              route: CMDBedsFacilitiesRoute(),
            ),
            const MenuItem(
              label: 'Lab monitoring',
              icon: Icons.biotech_outlined,
              route: CMDLabMonitoringRoute(),
            ),
            const MenuItem(
              label: 'Alerts & incidents',
              icon: Icons.crisis_alert_outlined,
              route: CMDAlertsIncidentsRoute(),
            ),
            const MenuItem(
              label: 'Reports & analytics',
              icon: Icons.assessment_outlined,
              route: CMDReportsAnalyticsRoute(),
            ),
            const MenuItem(
              label: 'Audit & compliance',
              icon: Icons.fact_check_outlined,
              route: CMDAuditComplianceRoute(),
            ),
            const MenuItem(
              label: 'Communication',
              icon: Icons.campaign_outlined,
              route: CMDCommunicationCenterRoute(),
            ),
            const MenuItem(
              label: 'Patient experience',
              icon: Icons.star_outline,
              route: CMDPatientExperienceRoute(),
            ),
            const MenuItem(
              label: 'System control',
              icon: Icons.tune_outlined,
              route: CMDSystemControlRoute(),
            ),
          ],
        ),
        const MenuItem(
          label: 'Register',
          icon: Icons.verified_user_rounded,
          route: RegisterRoute(),
        ),
        const MenuItem(
          label: 'Laboratory',
          icon: Icons.biotech_rounded,
          route: LabDashboardRoute(),
        ),
        const MenuItem(
          label: 'Radiology',
          icon: Icons.radar_rounded,
          route: RadiologyDashboardRoute(),
        ),
        const MenuItem(
          label: 'Store',
          icon: Icons.inventory_2_rounded,
          route: StoreDashboardRoute(),
        ),
        MenuItem(
          label: 'System Setup',
          icon: Icons.dashboard_outlined,
          route: CMDDashboardRoute(),
          children: [
            MenuItem(
              label: 'Add Service',
              icon: Icons.add_box_outlined,
              route: SystemSetupRoute(),
            ),
            MenuItem(
              label: 'Add Consulting Room',
              icon: Icons.add_box_outlined,
              route: ConsultingRoomsRoute(),
            ),
            MenuItem(
              label: 'Ward Management',
              icon: Icons.add_box_outlined,
              route: WardManagementRoute(),
            ),
            MenuItem(
              label: 'Bank Management',
              icon: Icons.account_balance_outlined,
              route: BankManagementRoute(),
            ),
          ],
        ),
      ]);
    }

    if (at == 'store') {
      common.addAll(storeMenu);
    }

    return common;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(internalChatSocketProvider);
    final state = ref.watch(authProvider);
    final auth = ref.watch(authProvider);
    final staff = auth.staff;
    final role = staff?.role.toLowerCase() ?? '';
    final accountType = staff?.accountType?.name.toLowerCase() ?? '';
    final menuItems = _menuForRole(staff, role, accountType);
    final isMobile = MediaQuery.of(context).size.width < 720;

    void openHelpCenter() {
      if (isMobile) {
        context.router.push(const HelpCenterRoute());
      } else {
        ref.read(shellSidePanelProvider.notifier).toggle(ShellSidePanelTab.help);
      }
    }

    void openStaffChat() {
      if (isMobile) {
        context.router.push(const StaffChatRoute());
      } else {
        ref.read(shellSidePanelProvider.notifier).toggle(ShellSidePanelTab.chat);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              if (Platform.isWindows) _buildTitleBar(context, openHelpCenter, openStaffChat),
              Expanded(
                child: isMobile
                    ? _buildMobileLayout(
                        context,
                        menuItems,
                        state,
                        openHelpCenter,
                        openStaffChat,
                      )
                    : _buildDesktopLayout(
                        context,
                        menuItems,
                        state,
                        openHelpCenter,
                        openStaffChat,
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
  ) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: _sidebarOpen ? _kSidebarWidth : _kSidebarCollapsedWidth,
          child: _SidebarNavigation(
            menuItems: menuItems,
            state: state,
            collapsed: !_sidebarOpen,
            onToggle: () => setState(() => _sidebarOpen = !_sidebarOpen),
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
              Expanded(
                child: Container(
                  color: const Color(0xFFF1F5F9),
                  child: AutoRouter(),
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
  ) {
    return Stack(
      children: [
        Column(
          children: [
            _MobileTopBar(
              onMenuTap: () => setState(() => _sidebarOpen = true),
              onHelpCenter: openHelpCenter,
              onStaffChat: openStaffChat,
            ),
            const Expanded(child: AutoRouter()),
          ],
        ),
        if (_sidebarOpen) ...[
          // scrim
          GestureDetector(
            onTap: () => setState(() => _sidebarOpen = false),
            child: Container(color: Colors.black54),
          ),
          // drawer
          AnimatedSlide(
            duration: const Duration(milliseconds: 250),
            offset: _sidebarOpen ? Offset.zero : const Offset(-1, 0),
            curve: Curves.easeInOut,
            child: SizedBox(
              width: _kSidebarWidth,
              height: double.infinity,
              child: _SidebarNavigation(
                menuItems: menuItems,
                state: state,
                collapsed: false,
                onToggle: () => setState(() => _sidebarOpen = false),
                closeLabel: true,
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
    return WindowTitleBarBox(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
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
                              color: Colors.white,
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
                  const SlidingNotificationDropdown(),
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
              color: _hover ? _kSidebarAccent : _kSidebarTextMuted,
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
        _WindowsTitleBarIconAction(
          tooltip: 'Staff chat',
          icon: Icons.chat_bubble_outline_rounded,
          onTap: onStaffChat,
        ),
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

class _WindowsTitleBarIconActionState extends State<_WindowsTitleBarIconAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
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
              color: _hover ? _kSidebarAccent : _kSidebarTextMuted,
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
            IconButton(
              tooltip: 'Staff chat',
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: onStaffChat,
            ),
          ],
        ),
      ),
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

  const _SidebarNavigation({
    required this.menuItems,
    required this.collapsed,
    required this.onToggle,
    this.closeLabel = false,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final currentName = context.router.current.name;

    return Container(
      color: _kSidebarBg,
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
    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: .4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).primaryColor,
                child: Center(
                  child: Text(
                    "${state.staff!.firstName.isNotEmpty ? state.staff!.firstName[0].toUpperCase() : ''}${state.staff!.lastName.isNotEmpty ? state.staff!.lastName[0].toUpperCase() : ''}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
            if (!collapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${state.staff!.firstName.toUpperCase()} ${state.staff!.lastName.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      state.staff!.role.toUpperCase(),
                      style: TextStyle(color: _kSidebarTextMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
            // _ToggleButton(
            //   collapsed: collapsed,
            //   onToggle: onToggle,
            //   closeLabel: closeLabel,
            // ),
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _hover ? _kSidebarHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.closeLabel || widget.collapsed
                ? Icons.menu_open_rounded
                : Icons.menu_rounded,
            color: _kSidebarText,
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
    color: _kSidebarDivider,
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

  const _SidebarEntry({
    required this.item,
    required this.index,
    required this.currentName,
    required this.collapsed,
  });

  @override
  State<_SidebarEntry> createState() => _SidebarEntryState();
}

class _SidebarEntryState extends State<_SidebarEntry> {
  bool _hover = false;
  bool _expanded = false;

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
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _kSidebarTextMuted,
              size: 18,
            ),
          ),
          onTap: () => setState(() => _expanded = !_expanded),
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
            _ChildEntry(item: child, currentName: widget.currentName),
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 0 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? _kSidebarAccentBg
                : _hover
                ? _kSidebarHover
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: widget.collapsed
              ? _collapsedIcon(icon, isActive)
              : _expandedRow(icon, label, isActive, trailing),
        ),
      ),
    );
  }

  Widget _collapsedIcon(IconData icon, bool isActive) {
    return Center(
      child: Tooltip(
        message: widget.item.label,
        preferBelow: false,
        child: Icon(
          icon,
          color: isActive ? _kSidebarAccent : _kSidebarTextMuted,
          size: 22,
        ),
      ),
    );
  }

  Widget _expandedRow(
    IconData icon,
    String label,
    bool isActive,
    Widget? trailing,
  ) {
    return Row(
      children: [
        if (isActive)
          Container(
            width: 3,
            height: 18,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: _kSidebarAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else
          const SizedBox(width: 13),
        Icon(
          icon,
          color: isActive ? _kSidebarAccent : _kSidebarTextMuted,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : _kSidebarText,
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

  const _ChildEntry({required this.item, required this.currentName});

  @override
  State<_ChildEntry> createState() => _ChildEntryState();
}

class _ChildEntryState extends State<_ChildEntry> {
  bool _hover = false;

  bool get _isActive =>
      widget.currentName == widget.item.route.runtimeType.toString();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.router.push(widget.item.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _isActive
                ? _kSidebarAccentBg
                : _hover
                ? _kSidebarHover
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.only(left: 2, right: 14),
                decoration: BoxDecoration(
                  color: _isActive ? _kSidebarAccent : _kSidebarTextMuted,
                  shape: BoxShape.circle,
                ),
              ),
              Icon(
                widget.item.icon,
                color: _isActive ? _kSidebarAccent : _kSidebarTextMuted,
                size: 17,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    color: _isActive ? Colors.white : _kSidebarText,
                    fontWeight: _isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile top bar
// ---------------------------------------------------------------------------

class _MobileTopBar extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onHelpCenter;
  final VoidCallback onStaffChat;

  const _MobileTopBar({
    required this.onMenuTap,
    required this.onHelpCenter,
    required this.onStaffChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: _kSidebarBg,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _IconButton(icon: Icons.menu_rounded, onTap: onMenuTap),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kSidebarAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              size: 18,
              color: _kSidebarAccent,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Helty',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          _IconButton(
            icon: Icons.help_outline_rounded,
            onTap: onHelpCenter,
          ),
          _IconButton(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: onStaffChat,
          ),
          const SlidingNotificationDropdown(),
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hover ? _kSidebarHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, color: _kSidebarText, size: 22),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logout buttons
// ---------------------------------------------------------------------------

void _logoutToLoginReplacingStack(BuildContext context) {
  ProviderScope.containerOf(context, listen: false)
      .read(paidModuleRequestContextProvider.notifier)
      .state = null;
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => _logoutToLoginReplacingStack(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _hover
                ? const Color(0xFF7F1D1D).withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Tooltip(
            message: 'Logout',
            child: Icon(
              Icons.logout_rounded,
              color: _hover ? Colors.red.shade400 : _kSidebarTextMuted,
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => _logoutToLoginReplacingStack(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hover
                ? const Color(0xFF7F1D1D).withValues(alpha: 0.25)
                : _kSidebarHover,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hover
                  ? Colors.red.shade800.withValues(alpha: 0.5)
                  : _kSidebarDivider,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: _hover ? Colors.red.shade400 : _kSidebarTextMuted,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(
                  color: _hover ? Colors.red.shade400 : _kSidebarText,
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: () => _logoutToLoginReplacingStack(context),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.logout_rounded,
            color: _hover ? Colors.red.shade400 : _kSidebarTextMuted,
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => _logoutToLoginReplacingStack(context),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.logout_rounded,
            color: _hover ? Colors.red.shade400 : _kSidebarTextMuted,
            size: 20,
          ),
        ),
      ),
    );
  }
}
