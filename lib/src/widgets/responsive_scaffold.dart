import 'package:flutter/material.dart';

import 'package:helty/src/core/layout/app_breakpoints.dart';

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
      bottomNavigationBar: BottomNavigationBar(
        items: bottomItems,
        currentIndex: currentIndex,
        onTap: onItemTapped,
      ),
      drawer: drawer,
    );
  }
}
