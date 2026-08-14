import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_router.gr.dart';
import '../../app/product_module_access.dart';
import '../../paitients/patient_model.dart';
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
    final selection = await showDialog<_MergeSelection>(
      context: context,
      builder: (ctx) => const _MergePatientsDialog(),
    );
    if (selection == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final survivor = selection.survivor;
    final duplicate = selection.duplicate;
    final survivorUuid = survivor.id?.trim() ?? '';
    final duplicateUuid = duplicate.id?.trim() ?? '';
    if (survivorUuid.isEmpty || duplicateUuid.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Select both survivor and duplicate patients.'),
        ),
      );
      return;
    }
    if (survivorUuid == duplicateUuid) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Survivor and duplicate must differ.')),
      );
      return;
    }

    final survivorLabel =
        '${survivor.displayName} (${survivor.patientId})';
    final duplicateLabel =
        '${duplicate.displayName} (${duplicate.patientId})';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm merge'),
        content: Text(
          'Merge $duplicateLabel into $survivorLabel? This cannot be undone.',
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
      final merged = await PatientService().mergePatients(
        survivorId: survivorUuid,
        duplicateId: duplicateUuid,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Merged into ${merged.displayName} (${merged.patientId}).',
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

class _MergeSelection {
  const _MergeSelection({required this.survivor, required this.duplicate});

  final Patient survivor;
  final Patient duplicate;
}

class _MergePatientsDialog extends StatefulWidget {
  const _MergePatientsDialog();

  @override
  State<_MergePatientsDialog> createState() => _MergePatientsDialogState();
}

class _MergePatientsDialogState extends State<_MergePatientsDialog> {
  final _patientService = PatientService();
  Patient? _survivor;
  Patient? _duplicate;

  @override
  Widget build(BuildContext context) {
    final canMerge = _survivor != null && _duplicate != null;
    return AlertDialog(
      title: const Text('Merge patients'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Search by name or hospital patient ID. Reassign all records from the duplicate onto the survivor, then delete the duplicate. Survivor keeps their hospital ID and phone.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _PatientSearchPicker(
              label: 'Survivor (keep)',
              selected: _survivor,
              onSelected: (p) => setState(() => _survivor = p),
              onClear: () => setState(() => _survivor = null),
              search: _patientService.searchPatients,
            ),
            const SizedBox(height: 12),
            _PatientSearchPicker(
              label: 'Duplicate (merge away)',
              selected: _duplicate,
              onSelected: (p) => setState(() => _duplicate = p),
              onClear: () => setState(() => _duplicate = null),
              search: _patientService.searchPatients,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canMerge
              ? () => Navigator.pop(
                    context,
                    _MergeSelection(
                      survivor: _survivor!,
                      duplicate: _duplicate!,
                    ),
                  )
              : null,
          child: const Text('Merge'),
        ),
      ],
    );
  }
}

class _PatientSearchPicker extends StatefulWidget {
  const _PatientSearchPicker({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.onClear,
    required this.search,
  });

  final String label;
  final Patient? selected;
  final ValueChanged<Patient> onSelected;
  final VoidCallback onClear;
  final Future<List<Patient>> Function(String query, bool isAscending) search;

  @override
  State<_PatientSearchPicker> createState() => _PatientSearchPickerState();
}

class _PatientSearchPickerState extends State<_PatientSearchPicker> {
  final _controller = TextEditingController();
  List<Patient> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String value) async {
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.search(q, true);
      if (!mounted) return;
      setState(() {
        _results = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _results = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    if (selected != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            tooltip: 'Clear',
            onPressed: widget.onClear,
            icon: const Icon(Icons.clear),
          ),
        ),
        child: Text(
          '${selected.displayName} · ${selected.patientId}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: 'Search name or patient ID',
            border: const OutlineInputBorder(),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: () => _runSearch(_controller.text),
                    icon: const Icon(Icons.search),
                  ),
          ),
          textInputAction: TextInputAction.search,
          onChanged: (v) {
            if (v.trim().length >= 2) _runSearch(v);
          },
          onSubmitted: _runSearch,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: Material(
              type: MaterialType.transparency,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final p = _results[index];
                  return ListTile(
                    dense: true,
                    title: Text(p.displayName),
                    subtitle: Text(p.patientId),
                    onTap: () {
                      widget.onSelected(p);
                      _controller.clear();
                      setState(() => _results = const []);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
