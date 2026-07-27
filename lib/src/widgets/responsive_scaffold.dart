import 'package:flutter/material.dart';

import 'package:helty/src/core/layout/app_breakpoints.dart';

/// Responsive shell: sidebar on wide layouts, Material 3 [NavigationBar] on narrow.
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final List<BottomNavigationBarItem> bottomItems;
  final int currentIndex;
  final ValueChanged<int>? onItemTapped;
  final Widget? drawer;
  final double sidebarWidth;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    required this.bottomItems,
    required this.currentIndex,
    this.onItemTapped,
    this.drawer,
    this.sidebarWidth = 250,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final bp = AppBreakpoints.fromWidth(width);
    final isWide = bp.showSidebar;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            if (drawer != null) SizedBox(width: sidebarWidth, child: drawer),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex.clamp(0, bottomItems.length - 1),
        onDestinationSelected: onItemTapped,
        destinations: [
          for (final item in bottomItems)
            NavigationDestination(
              icon: item.icon,
              selectedIcon: item.activeIcon,
              label: item.label ?? '',
            ),
        ],
      ),
      drawer: drawer,
    );
  }
}
