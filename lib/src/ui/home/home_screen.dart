import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

import '../../providers/auth_provider.dart';
import '../../services/notificationbar.dart';
import '../../services/title_bar.dart';

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

  List<MenuItem> _menuForRole(String role) {
    final common = <MenuItem>[
      const MenuItem(
        label: 'Dashboard',
        icon: Icons.dashboard_rounded,
        route: DashboardRoute(),
      ),
      MenuItem(
        label: 'Patients',
        icon: Icons.people_alt_rounded,
        route: const PatientListRoute(),
        children: [
          const MenuItem(
            label: 'All Patients',
            icon: Icons.list_alt_rounded,
            route: PatientListRoute(),
          ),
          MenuItem(
            label: 'Add Patient',
            icon: Icons.person_add_rounded,
            route: PatientFormRoute(),
          ),
        ],
      ),
      const MenuItem(
        label: 'Appointments',
        icon: Icons.event_rounded,
        route: AppointmentListRoute(),
      ),
      const MenuItem(
        label: "Today's Patients",
        icon: Icons.today_rounded,
        route: TodayPatientsRoute(),
      ),
      const MenuItem(
        label: 'Pending Transactions',
        icon: Icons.pending_actions_rounded,
        route: PendingBillsRoute(),
      ),
      const MenuItem(
        label: 'Enlist Service',
        icon: Icons.add_task_rounded,
        route: EnlistPaitientRoute(),
      ),
      const MenuItem(
        label: 'Render Investigation',
        icon: Icons.science_rounded,
        route: RenderServiceRoute(),
      ),
      const MenuItem(
        label: 'View OPD Service',
        icon: Icons.view_agenda_rounded,
        route: ViewServiceRoute(),
      ),
    ];

    if (role == 'ADMIN') {
      common.add(
        const MenuItem(
          label: 'Register',
          icon: Icons.verified_user_rounded,
          route: RegisterRoute(),
        ),
      );
    }

    return common;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final menuItems = _menuForRole(auth.staff!.role);
    final isMobile = MediaQuery.of(context).size.width < 720;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          if (Platform.isWindows) _buildTitleBar(context),
          Expanded(
            child: isMobile
                ? _buildMobileLayout(context, menuItems)
                : _buildDesktopLayout(context, menuItems),
          ),
        ],
      ),
    );
  }

  // ── Desktop: persistent sidebar that collapses to icon rail ──────────────

  Widget _buildDesktopLayout(BuildContext context, List<MenuItem> menuItems) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: _sidebarOpen ? _kSidebarWidth : _kSidebarCollapsedWidth,
          child: _SidebarNavigation(
            menuItems: menuItems,
            collapsed: !_sidebarOpen,
            onToggle: () => setState(() => _sidebarOpen = !_sidebarOpen),
          ),
        ),
        Expanded(
          child: Container(color: const Color(0xFFF1F5F9), child: AutoRouter()),
        ),
      ],
    );
  }

  // ── Mobile: top bar with hamburger + drawer overlay ──────────────────────

  Widget _buildMobileLayout(BuildContext context, List<MenuItem> menuItems) {
    return Stack(
      children: [
        Column(
          children: [
            _MobileTopBar(onMenuTap: () => setState(() => _sidebarOpen = true)),
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

  Widget _buildTitleBar(BuildContext context) {
    return WindowTitleBarBox(
      child: Container(
        height: 48,
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
                        decoration: BoxDecoration(
                          color: _kSidebarAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          size: 20,
                          color: _kSidebarAccent,
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
                      const SizedBox(width: 6),
                      Text(
                        'Hospital Management',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _kSidebarTextMuted,
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
                  _TitleBarLogoutButton(),
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

// ---------------------------------------------------------------------------
// Sidebar Navigation
// ---------------------------------------------------------------------------

class _SidebarNavigation extends StatelessWidget {
  final List<MenuItem> menuItems;
  final bool collapsed;
  final VoidCallback onToggle;
  final bool closeLabel;

  const _SidebarNavigation({
    required this.menuItems,
    required this.collapsed,
    required this.onToggle,
    this.closeLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentName = context.router.current.name;

    return Container(
      color: _kSidebarBg,
      child: Column(
        children: [
          _buildHeader(context),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _kSidebarAccent.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Helty',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'Hospital Management',
                    style: TextStyle(color: _kSidebarTextMuted, fontSize: 11),
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
    this.closeLabel = false,
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
      onTap: () => context.router.push(widget.item.route),
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

  const _MobileTopBar({required this.onMenuTap});

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
        onTap: () => context.router.replaceAll([LoginRoute()]),
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
        onTap: () => context.router.replaceAll([LoginRoute()]),
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
        onTap: () => context.router.replaceAll([LoginRoute()]),
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
        onTap: () => context.router.replaceAll([LoginRoute()]),
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
