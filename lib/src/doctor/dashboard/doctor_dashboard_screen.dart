import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/widgets/doctor_top_bar.dart';

@RoutePage()
class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DoctorTopBar(),
            Expanded(child: AutoRouter()),
          ],
        ),
      ),
    );
  }
}
