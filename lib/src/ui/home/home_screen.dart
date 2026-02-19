import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';

import '../../widgets/responsive_scaffold.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _tabs = [
    DashboardRoute(),
    PatientListRoute(),
    AppointmentListRoute(),
  ];

  static const _labels = ['Dashboard', 'Patients', 'Appointments'];
  static const _icons = [Icons.dashboard, Icons.person, Icons.event];

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: _tabs,
      transitionBuilder: (context, child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);

        return ResponsiveScaffold(
          drawer: Drawer(
            child: ListView(
              children: [
                const DrawerHeader(child: Text('Helty')),
                for (var i = 0; i < _labels.length; i++)
                  ListTile(
                    leading: Icon(_icons[i]),
                    title: Text(_labels[i]),
                    selected: tabsRouter.activeIndex == i,
                    onTap: () => tabsRouter.setActiveIndex(i),
                  ),
              ],
            ),
          ),
          body: child,
          bottomItems: List.generate(
            _labels.length,
            (i) => BottomNavigationBarItem(
              icon: Icon(_icons[i]),
              label: _labels[i],
            ),
          ),
          currentIndex: tabsRouter.activeIndex,
          onItemTapped: tabsRouter.setActiveIndex,
        );
      },
    );
  }
}
