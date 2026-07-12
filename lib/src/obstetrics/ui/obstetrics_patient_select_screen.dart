import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';

enum ObstetricsSelectTarget { pregnancies, gynae }

@RoutePage()
class ObstetricsPatientSelectScreen extends ConsumerStatefulWidget {
  const ObstetricsPatientSelectScreen({super.key, this.target});

  final ObstetricsSelectTarget? target;

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
      final target = widget.target ?? ObstetricsSelectTarget.pregnancies;
      final serviceName = target == ObstetricsSelectTarget.gynae
          ? 'OBGYN_GYNAE'
          : 'OBGYN';
      context.router.replace(EnlistPaitientRoute(serviceName: serviceName));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveBody(
        builder: (context, bp) => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
