import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';

/// Legacy route — redirects to [EdRegistrationScreen].
@RoutePage()
class DoctorEmergencyStartScreen extends StatelessWidget {
  const DoctorEmergencyStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.router.replace(const EdRegistrationRoute());
      }
    });
    return Scaffold(
      body: ResponsiveBody(
        builder: (context, bp) =>
            const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
