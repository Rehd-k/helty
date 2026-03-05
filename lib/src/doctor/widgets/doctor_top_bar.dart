import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';

/// Persistent top bar for doctor screens: name, department, on-call, notifications, quick search.
class DoctorTopBar extends ConsumerWidget {
  const DoctorTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(authProvider).staff;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  staff != null ? 'Dr ${staff.lastName}' : 'Doctor',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                if (staff?.departmentName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      staff!.departmentName!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_in_talk,
                        size: 14,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'On-call',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 280,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Quick search patient...',
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Badge(
              label: const Text('3'),
              child: Icon(
                Icons.notifications_outlined,
                color: colorScheme.onSurface,
              ),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
