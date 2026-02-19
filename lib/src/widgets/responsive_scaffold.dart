import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final List<BottomNavigationBarItem> bottomItems;
  final int currentIndex;
  final ValueChanged<int>? onItemTapped;
  final Widget? drawer;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    required this.bottomItems,
    required this.currentIndex,
    this.onItemTapped,
    this.drawer,
  });

  static const double _wideScreenBreakpoint = 800;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _wideScreenBreakpoint;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            if (drawer != null) SizedBox(width: 250, child: drawer),

            // if (Platform.isWindows)
            //   WindowTitleBarBox(
            //     child: Row(
            //       children: [
            //         Expanded(
            //           child: MoveWindow(
            //             child: Row(
            //               children: [
            //                 SizedBox(width: 20),
            //                 // SvgPicture.asset(
            //                 //   height: 40,
            //                 //   width: 40,
            //                 //   'assets/vectors/logo.svg',
            //                 // ),
            //                 SizedBox(width: 10),
            //                 Text('Averra Suite'),
            //               ],
            //             ),
            //           ),
            //         ),
            //         Row(
            //           spacing: 20,
            //           children: [
            //             SlidingNotificationDropdown(),
            //             const ThemeSwitchButton(),
            //             InkWell(
            //               child: const Icon(Icons.logout_outlined, size: 12),
            //               onTap: () {
            //                 // JwtService().logout();
            //                 // context.router.replaceAll([LoginRoute()]);
            //               },
            //             ),
            //             const WindowButtons(),
            //           ],
            //         ),
            //       ],
            //     ),
            //   ),
            Expanded(child: body),
          ],
        ),
      );
    }

    // mobile / narrow layout
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
