import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';

/// Legacy route — redirects to patient enlist then purchase-item sales flow.
@RoutePage()
class NurseConsumableUsageScreen extends StatelessWidget {
  const NurseConsumableUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.router.replace(
        EnlistPaitientRoute(serviceName: 'Consumables'),
      );
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
