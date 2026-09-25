import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_router.gr.dart';
import '../../app/product_module_access.dart';
import '../../paitients/merge_patients_dialog.dart';
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
      const SnackBar(content: Text('Creating database backupâ€¦')),
    );
    try {
      final result = await DbBackupService().createBackup();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Backup saved as ${result.filename}')),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> _openMergePatients(BuildContext context) async {
    await runMergePatientsFlow(context, mode: MergePatientsMode.full);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  const _HubSectionHeader(
                    title: 'Department preview',
                    subtitle:
                        'Open any account type to match the sidebar and home '
                        'route to that departmentâ€™s lead experience. Your login '
                        'stays super admin.',
                  ),
                  const SizedBox(height: 24),
                  _HubCardGrid(
                    children: [
                      for (final dep
                          in ProductModuleAccess.allowedHubDepartments())
                        _HubCard(
                          key: ValueKey(dep.previewAccountType),
                          title: dep.tileTitle,
                          subtitle: dep.previewBannerLabel,
                          icon: Icons.open_in_new_rounded,
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
                        ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  const _HubSectionHeader(
                    title: 'Admin tools',
                    subtitle:
                        'Staff directory, patient records, backups, and '
                        'patient-facing health content.',
                  ),
                  const SizedBox(height: 24),
                  _HubCardGrid(
                    children: [
                      _HubCard(
                        title: 'Staff directory',
                        subtitle:
                            'Browse staff, open profiles, and view password '
                            'reset codes.',
                        icon: Icons.groups_outlined,
                        onTap: () => context.router.push(
                          const SuperAdminStaffListRoute(),
                        ),
                      ),
                      _HubCard(
                        title: 'Merge patients',
                        subtitle:
                            'Combine a duplicate record into a survivor. '
                            'Clinical and billing links move with it.',
                        icon: Icons.merge_type_outlined,
                        onTap: () => _openMergePatients(context),
                      ),
                      _HubCard(
                        title: 'Create database backup',
                        subtitle:
                            'Write a dated gzipped backup on the server. '
                            'Nightly backups run at 11:59 PM.',
                        icon: Icons.backup_outlined,
                        onTap: () => _createDbBackup(context),
                      ),
                      _HubCard(
                        title: 'Health campaigns',
                        subtitle:
                            'Create and publish patient health campaigns.',
                        icon: Icons.campaign_outlined,
                        onTap: () => context.router.push(
                          const HealthCampaignsAdminRoute(),
                        ),
                      ),
                      _HubCard(
                        title: 'Health news',
                        subtitle:
                            'Manage health news articles shown to patients.',
                        icon: Icons.newspaper_outlined,
                        onTap: () =>
                            context.router.push(const HealthNewsAdminRoute()),
                      ),
                    ],
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

class _HubSectionHeader extends StatelessWidget {
  const _HubSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _HubCardGrid extends StatelessWidget {
  const _HubCardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class _HubCard extends StatefulWidget {
  const _HubCard({
    super.key,
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
  State<_HubCard> createState() => _HubCardState();
}

class _HubCardState extends State<_HubCard> {
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
        clipBehavior: Clip.antiAlias,
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
                Icon(widget.icon, size: 22, color: cs.primary),
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
