import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/department_head_permissions.dart';
import '../../core/responsive.dart';
import '../../models/staff_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/staff_service.dart';
import '../models/hospital_asset_models.dart';
import '../services/hospital_assets_api_service.dart';
import 'asset_theme.dart';

@RoutePage()
class HospitalAssetAccessScreen extends ConsumerStatefulWidget {
  const HospitalAssetAccessScreen({super.key});

  @override
  ConsumerState<HospitalAssetAccessScreen> createState() =>
      _HospitalAssetAccessScreenState();
}

class _HospitalAssetAccessScreenState
    extends ConsumerState<HospitalAssetAccessScreen> {
  final _api = HospitalAssetsApiService();
  final _staffService = StaffService();
  bool _loading = true;
  String? _error;
  List<HospitalAssetAccessGrant> _grants = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final grants = await _api.listAccess();
      if (!mounted) return;
      setState(() {
        _grants = grants;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<List<Staff>> _staffIn(AccountType department) async {
    try {
      final options = await _staffService.fetchStaff(
        limit: 200,
        isActive: true,
        accountType: department,
      );
      return options.where((s) => s.accountType == department).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _grant() async {
    final actor = ref.read(authProvider).staff;
    final hospitalWide = isHospitalWideInventoryViewer(actor);
    var department = actor?.accountType ?? AccountType.store;
    if (!kInventoryDepartments.contains(department)) {
      department = AccountType.store;
    }

    var options = await _staffIn(department);
    if (!mounted) return;

    var staffId = options.isEmpty ? null : options.first.id;
    var canLog = true;
    final result =
        await showDialog<
          ({String staffId, AccountType department, bool canLog})
        >(
          context: context,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (context, setLocal) {
                return AlertDialog(
                  title: const Text('Allow logging'),
                  content: SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Everyone in a department can already view its inventory. '
                          'Use this to let a colleague add usage, repair, and movement logs.',
                        ),
                        const SizedBox(height: 12),
                        if (hospitalWide)
                          DropdownButtonFormField<AccountType>(
                            initialValue: department,
                            items: kInventoryDepartments
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) async {
                              if (v == null) return;
                              department = v;
                              options = await _staffIn(v);
                              staffId = options.isEmpty
                                  ? null
                                  : options.first.id;
                              setLocal(() {});
                            },
                            decoration: const InputDecoration(
                              labelText: 'Department',
                            ),
                          ),
                        if (hospitalWide) const SizedBox(height: 8),
                        if (options.isEmpty)
                          const Text('No staff in this department.')
                        else
                          DropdownButtonFormField<String>(
                            key: ValueKey('${department.apiValue}-$staffId'),
                            initialValue: staffId,
                            isExpanded: true,
                            items: options
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      '${s.fullName} (${s.staffRole})',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => staffId = v,
                            decoration: const InputDecoration(
                              labelText: 'Staff',
                            ),
                          ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Can log inventory events'),
                          value: canLog,
                          onChanged: (v) => setLocal(() => canLog = v),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: staffId == null
                          ? null
                          : () => Navigator.pop(ctx, (
                              staffId: staffId!,
                              department: department,
                              canLog: canLog,
                            )),
                      child: const Text('Grant'),
                    ),
                  ],
                );
              },
            );
          },
        );
    if (result == null) return;
    await _api.grantAccess(
      staffId: result.staffId,
      canView: true,
      canLog: result.canLog,
      accountType: hospitalWide ? result.department.apiValue : null,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    final accent = colorForAccountType(
      isHospitalWideInventoryViewer(staff)
          ? 'CMD'
          : (staff?.accountType?.apiValue ?? ''),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory logging grants'),
        backgroundColor: accent.withValues(alpha: 0.12),
        foregroundColor: accent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        onPressed: _grant,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Allow logging'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ResponsiveBody(
              expand: true,
              builder: (context, bp) {
                return Column(
                  children: [
                    InventoryScopeBanner(
                      accent: accent,
                      title: 'Same-department logging only',
                      subtitle:
                          'Grants cannot open another department’s inventory. '
                          'CMD, CMAC, and Director of Admin already see every department.',
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _grants.isEmpty
                          ? const Center(
                              child: Text('No extra logging grants yet.'),
                            )
                          : ListView.separated(
                              itemCount: _grants.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final g = _grants[i];
                                final color = colorForAccountType(
                                  g.accountType,
                                );
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: color.withValues(
                                        alpha: 0.18,
                                      ),
                                      foregroundColor: color,
                                      child: const Icon(Icons.person_outline),
                                    ),
                                    title: Text(g.staffName),
                                    subtitle: Text(
                                      g.canLog
                                          ? '${labelForAccountType(g.accountType)} · can log'
                                          : '${labelForAccountType(g.accountType)} · view only',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () async {
                                        await _api.revokeAccess(g.id);
                                        await _load();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
