import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hospital_assets/ui/asset_theme.dart';
import '../../providers/auth_provider.dart';
import '../models/department_head_models.dart';
import '../services/department_head_api_service.dart';

@RoutePage()
class DepartmentStaffScreen extends ConsumerStatefulWidget {
  const DepartmentStaffScreen({super.key});

  @override
  ConsumerState<DepartmentStaffScreen> createState() =>
      _DepartmentStaffScreenState();
}

class _DepartmentStaffScreenState extends ConsumerState<DepartmentStaffScreen> {
  final _api = DepartmentHeadApiService();
  bool _loading = true;
  String? _error;
  List<DepartmentStaffMember> _staff = [];

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
      final staff = await _api.listStaff();
      if (!mounted) return;
      setState(() {
        _staff = staff;
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

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(authProvider).staff;
    final accent = colorForAccountType(actor?.accountType?.apiValue ?? '');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Department staff'),
        backgroundColor: accent.withValues(alpha: 0.12),
        foregroundColor: accent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _staff.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final s = _staff[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: accent.withValues(alpha: 0.16),
                        foregroundColor: accent,
                        child: Text(
                          s.fullName.isEmpty
                              ? '?'
                              : s.fullName[0].toUpperCase(),
                        ),
                      ),
                      title: Text(s.fullName),
                      subtitle: Text('${s.staffRole} · ${s.staffId}'),
                      trailing: s.isActive
                          ? Icon(Icons.check_circle_outline, color: accent)
                          : const Text('Inactive'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
