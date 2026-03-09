import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

@RoutePage()
class ObstetricsPatientSelectScreen extends ConsumerStatefulWidget {
  const ObstetricsPatientSelectScreen({super.key});

  @override
  ConsumerState<ObstetricsPatientSelectScreen> createState() =>
      _ObstetricsPatientSelectScreenState();
}

class _ObstetricsPatientSelectScreenState
    extends ConsumerState<ObstetricsPatientSelectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.router.replace(EnlistPaitientRoute(serviceName: 'OBGYN'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
