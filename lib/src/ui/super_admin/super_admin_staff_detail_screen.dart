import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/staff_providers.dart';

@RoutePage()
class SuperAdminStaffDetailScreen extends ConsumerWidget {
  const SuperAdminStaffDetailScreen({
    super.key,
    required this.staffId,
  });

  final String staffId;

  static String _formatExpiry(DateTime? t) {
    if (t == null) return '—';
    final l = t.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final asyncStaff = ref.watch(currentStaffDetailProvider(staffId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff details'),
      ),
      body: asyncStaff.when(
        data: (staff) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentStaffDetailProvider(staffId));
            await ref.read(currentStaffDetailProvider(staffId).future);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                staff.fullName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Account'),
              _infoTile(context, 'Staff ID', staff.staffId),
              _infoTile(context, 'Role', staff.staffRole),
              if (staff.pharmacyRole != null &&
                  staff.pharmacyRole!.trim().isNotEmpty)
                _infoTile(context, 'Pharmacy role', staff.pharmacyRole!),
              _infoTile(
                context,
                'Account type',
                staff.accountType?.name ?? '—',
              ),
              _infoTile(
                context,
                'Status',
                staff.isActive ? 'Active' : 'Inactive',
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Contact'),
              _infoTile(context, 'Email', staff.email ?? '—'),
              _infoTile(context, 'Phone', staff.phone ?? '—'),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Organization'),
              _infoTile(context, 'Department ID', staff.departmentId ?? '—'),
              _infoTile(
                context,
                'Department',
                staff.departmentName ?? '—',
              ),
              if (staff.permissions.isNotEmpty) ...[
                const SizedBox(height: 8),
                _sectionTitle(context, 'Permissions'),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    staff.permissions.join(', '),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _sectionTitle(context, 'Password reset'),
              Card(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: staff.hasActivePasswordResetCode
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'A verification code is available for this staff member '
                              '(for example after they used “Forgot password”). '
                              'Share it only through a secure channel.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SelectableText(
                              staff.passwordResetCode!,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                letterSpacing: 4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (staff.passwordResetCodeExpiresAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Expires (local time): '
                                '${_formatExpiry(staff.passwordResetCodeExpiresAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.tonalIcon(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(
                                      text: staff.passwordResetCode!,
                                    ),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Code copied'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 20),
                                label: const Text('Copy code'),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'No active password reset code for this account.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Internal ID: ${staff.id}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.outline,
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: cs.error, size: 40),
                const SizedBox(height: 12),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(currentStaffDetailProvider(staffId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _infoTile(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
