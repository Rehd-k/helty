import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class DoctorProfileScreen extends ConsumerWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(authProvider).staff;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
              child: Text(
                staff != null
                    ? '${staff.firstName.substring(0, 1)}${staff.lastName.substring(0, 1)}'
                    : 'DR',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              staff != null ? 'Dr ${staff.firstName} ${staff.lastName}' : 'Doctor',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            if (staff?.departmentName != null) ...[
              const SizedBox(height: 4),
              Text(
                staff!.departmentName!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
