import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../app_router.gr.dart';
import '../../shared/department_colors.dart';

@RoutePage()
class HousekeepingHomeScreen extends StatelessWidget {
  const HousekeepingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      (
        'Workers',
        Icons.people_outline,
        const HousekeepingWorkersRoute(),
      ),
      (
        'Areas & rooms',
        Icons.meeting_room_outlined,
        const HousekeepingAreasRoute(),
      ),
      (
        'Shifts',
        Icons.schedule_outlined,
        const HousekeepingShiftsRoute(),
      ),
      (
        'Supplies',
        Icons.cleaning_services_outlined,
        const HousekeepingSuppliesRoute(),
      ),
      (
        'Equipment inventory',
        Icons.inventory_2_outlined,
        const HospitalAssetsRoute(),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Housekeeping')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        children: [
          for (final tile in tiles)
            Card(
              color: DepartmentColors.security.withValues(alpha: 0.08),
              child: InkWell(
                onTap: () => context.router.push(tile.$3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tile.$2, color: DepartmentColors.security),
                    const SizedBox(height: 8),
                    Text(tile.$1),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
