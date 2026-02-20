import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';

import '../../services/notificationbar.dart';
import '../../services/title_bar.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _tabs = [
    DashboardRoute(),
    PatientListRoute(),
    AppointmentListRoute(),
    TodayPatientsRoute(),
    PendingTransactionsRoute(),
    EnlistServiceRoute(),
    RenderServiceRoute(),
    ViewServiceRoute(),
  ];

  static const _labels = [
    'Dashboard',
    'All Patients',
    'Appointments',
    'Today\'s Patients',
    'Pending Transactions',
    'Enlist Service',
    'Render Investigation Service',
    'View OPD service',
  ];

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.list_alt_outlined,
    Icons.group_outlined,
    Icons.calendar_today_outlined,
    Icons.pending_actions_outlined,
    Icons.add_task_outlined,
    Icons.science_outlined,
    Icons.view_agenda_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (Platform.isWindows)
            WindowTitleBarBox(
              child: Container(
                height: 50,
                color: Colors.grey.shade900,
                child: Row(
                  children: [
                    Expanded(
                      child: MoveWindow(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.health_and_safety_outlined,
                                size: 24,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Helty Hospital Management',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        spacing: 16,
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
            ),
          Expanded(
            child: AutoTabsRouter(
              routes: _tabs,
              transitionBuilder: (context, child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              builder: (context, child) {
                final tabsRouter = AutoTabsRouter.of(context);
                final isMobile = MediaQuery.of(context).size.width < 600;

                if (isMobile) {
                  return Column(
                    children: [
                      Expanded(child: child),
                      BottomNavigationBar(
                        currentIndex: tabsRouter.activeIndex,
                        onTap: tabsRouter.setActiveIndex,
                        items: [
                          for (int i = 0; i < 3; i++)
                            BottomNavigationBarItem(
                              icon: Icon(_icons[i]),
                              label: _labels[i],
                            ),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    _SidebarNavigation(
                      activeIndex: tabsRouter.activeIndex,
                      onItemTapped: tabsRouter.setActiveIndex,
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.grey.shade50,
                        child: child,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavigation extends StatelessWidget {
  final int activeIndex;
  final Function(int) onItemTapped;

  const _SidebarNavigation({
    required this.activeIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getColorForIndex(0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Helty',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Hospital Management',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: HomeScreen._labels.length,
              itemBuilder: (context, index) => _NavItem(
                icon: HomeScreen._icons[index],
                label: HomeScreen._labels[index],
                isSelected: activeIndex == index,
                onTap: () => onItemTapped(index),
                color: _getColorForIndex(index),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _SidebarLogoutButton(),
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];
    return colors[index % colors.length];
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? widget.color.withValues(alpha: 0.1)
              : _isHovering
              ? Colors.grey.shade100
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: widget.isSelected
              ? Border.all(
                  color: widget.color.withValues(alpha: 0.3),
                  width: 1.5,
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.isSelected
                        ? widget.color
                        : Colors.grey.shade700,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: widget.isSelected
                            ? widget.color
                            : Colors.grey.shade800,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

class _TitleBarLogoutButton extends StatefulWidget {
  const _TitleBarLogoutButton();

  @override
  State<_TitleBarLogoutButton> createState() => _TitleBarLogoutButtonState();
}

class _TitleBarLogoutButtonState extends State<_TitleBarLogoutButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: () => context.router.replaceAll([LoginRoute()]),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.logout_outlined,
            color: _isHovering ? Colors.red.shade600 : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SidebarLogoutButton extends StatefulWidget {
  const _SidebarLogoutButton();

  @override
  State<_SidebarLogoutButton> createState() => _SidebarLogoutButtonState();
}

class _SidebarLogoutButtonState extends State<_SidebarLogoutButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovering ? Colors.red.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.router.replaceAll([LoginRoute()]),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.logout_outlined,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.red.shade600,
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
