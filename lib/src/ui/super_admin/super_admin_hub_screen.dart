import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_router.gr.dart';
import '../../app/product_module_access.dart';
import '../../paitients/patient_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/super_admin_preview_provider.dart';
import '../../routing/initial_route_for_role.dart';
import '../../services/db_backup_service.dart';

@RoutePage()
class SuperAdminHubScreen extends ConsumerWidget {
  const SuperAdminHubScreen({super.key});

  Future<void> _createDbBackup(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create database backup'),
        content: const Text(
          'Create a gzipped database backup on the server now? '
          'This can take a while on large databases.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create backup'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Creating database backup…')),
    );
    try {
      final result = await DbBackupService().createBackup();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Backup saved as ${result.filename}',
          ),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  Future<void> _openMergePatients(BuildContext context) async {
    final survivorCtrl = TextEditingController();
    final duplicateCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Merge patients'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Reassign all records from the duplicate patient onto the survivor, then delete the duplicate. Survivor keeps their hospital ID and phone.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: survivorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Survivor patient UUID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: duplicateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Duplicate patient UUID',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Merge'),
          ),
        ],
      ),
    );
    final survivorId = survivorCtrl.text.trim();
    final duplicateId = duplicateCtrl.text.trim();
    survivorCtrl.dispose();
    duplicateCtrl.dispose();
    if (confirmed != true) return;
    final messenger = ScaffoldMessenger.of(context);
    if (survivorId.isEmpty || duplicateId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter both survivor and duplicate IDs.')),
      );
      return;
    }
    if (survivorId == duplicateId) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Survivor and duplicate must differ.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm merge'),
        content: Text(
          'Merge $duplicateId into $survivorId? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm merge'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final survivor = await PatientService().mergePatients(
        survivorId: survivorId,
        duplicateId: duplicateId,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Merged into ${survivor.displayName} (${survivor.patientId}).',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Merge failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final staff = ref.watch(authProvider).staff;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin hub'),
        automaticallyImplyLeading: false,
      ),
      body: ResponsiveBody(
        expand: false,
        builder: (context, bp) => SingleChildScrollView(
          child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HubActionBanner(
                  title: 'Staff directory',
                  subtitle:
                      'Browse all staff, open full profiles, and view active '
                      'password reset codes when the API provides them.',
                  icon: Icons.groups_outlined,
                  onTap: () => context.router.push(const SuperAdminStaffListRoute()),
                ),
                const SizedBox(height: 12),
                _HubActionBanner(
                  title: 'Merge patients',
                  subtitle:
                      'Combine a duplicate patient record into a survivor. '
                      'All clinical and billing links move to the survivor.',
                  icon: Icons.merge_type_outlined,
                  onTap: () => _openMergePatients(context),
                ),
                const SizedBox(height: 12),
                _HubActionBanner(
                  title: 'Create database backup',
                  subtitle:
                      'Write a dated gzipped backup on the server. '
                      'Nightly backups also run automatically at 11:59 PM.',
                  icon: Icons.backup_outlined,
                  onTap: () => _createDbBackup(context),
                ),
                const SizedBox(height: 12),
                _HubActionBanner(
                  title: 'Health campaigns',
                  subtitle: 'Create and publish patient health campaigns.',
                  icon: Icons.campaign_outlined,
                  onTap: () =>
                      context.router.push(const HealthCampaignsAdminRoute()),
                ),
                const SizedBox(height: 12),
                _HubActionBanner(
                  title: 'Health news',
                  subtitle: 'Manage health news articles shown to patients.',
                  icon: Icons.newspaper_outlined,
                  onTap: () =>
                      context.router.push(const HealthNewsAdminRoute()),
                ),
                const SizedBox(height: 28),
                Text(
                  'Department preview',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Open any account type to match the sidebar and home route to that department’s lead experience. Your login stays super admin.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final departments =
                        ProductModuleAccess.allowedHubDepartments();
                    final w = constraints.maxWidth;
                    final cross = w >= 900
                        ? 4
                        : w >= 640
                        ? 3
                        : w >= 400
                        ? 2
                        : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cross,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: w >= 640 ? 1.45 : 1.25,
                      ),
                      itemCount: departments.length,
                      itemBuilder: (context, index) {
                        final dep = departments[index];
                        return _DepartmentCard(
                          title: dep.tileTitle,
                          subtitle: dep.previewBannerLabel,
                          onTap: () {
                            ref
                                .read(superAdminPreviewProvider.notifier)
                                .setPreview(
                                  staff,
                                  accountType: dep.previewAccountType,
                                  role: dep.previewRole,
                                  bannerLabel: dep.previewBannerLabel,
                                );
                            final route = initialRouteForRole(
                              dep.previewRole,
                              dep.previewAccountType,
                            );
                            context.router.navigate(route);
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _HubActionBanner extends StatelessWidget {
  const _HubActionBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: cs.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentCard extends StatefulWidget {
  const _DepartmentCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_DepartmentCard> createState() => _DepartmentCardState();
}

class _DepartmentCardState extends State<_DepartmentCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: cs.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _hover
                ? cs.primary.withValues(alpha: 0.45)
                : cs.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.open_in_new_rounded,
                  size: 22,
                  color: cs.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
