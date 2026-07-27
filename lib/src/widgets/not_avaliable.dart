import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/widgets/empty.widget.dart';

@RoutePage()
class NotAvailableScreen extends StatelessWidget {
  const NotAvailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          builder: (context, bp) => EmptyStateWidget(
            icon: Icons.construction_rounded,
            title: 'Not Available',
            message:
                'This module is currently disabled in testing mode.\n'
                'It will become available once testing restrictions are removed.',
            buttonText: 'Go Back',
            onPressed: () => context.router.maybePop(),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () => context.router.push(DashboardRoute()),
                child: const Text('Back to Home'),
              ),
              const SizedBox(height: 12),
              Text(
                'Testing Mode • ${DateTime.now().year}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
