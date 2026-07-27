import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/frontdesk/patient_access/patient_access_models.dart';
import 'package:helty/src/frontdesk/patient_access/patient_access_providers.dart';
import 'package:helty/src/frontdesk/patient_access_permissions.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/widgets/empty.widget.dart';
import 'package:intl/intl.dart';

@RoutePage()
class PendingDeviceApprovalsScreen extends ConsumerStatefulWidget {
  const PendingDeviceApprovalsScreen({super.key});

  @override
  ConsumerState<PendingDeviceApprovalsScreen> createState() =>
      _PendingDeviceApprovalsScreenState();
}

class _PendingDeviceApprovalsScreenState
    extends ConsumerState<PendingDeviceApprovalsScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<PatientDeviceRow> _items = [];
  int _page = 1;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _actionId;

  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _load(reset: true);
    });
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    final page = reset ? 1 : _page + 1;
    try {
      final result = await ref
          .read(patientAccessServiceProvider)
          .listPatientDevices(
            status: 'PENDING',
            page: page,
            limit: _limit,
            search: _searchCtrl.text,
          );
      if (!mounted) return;
      setState(() {
        _page = result.page;
        _total = result.total;
        _items = reset ? result.items : [..._items, ...result.items];
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = _errorMessage(e);
      });
    }
  }

  String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        if (msg is List) return msg.join(', ');
        return msg.toString();
      }
      if (e.response?.statusCode == 403) {
        return 'You do not have permission to manage patient devices.';
      }
      if (e.response?.statusCode == 401) {
        return 'Session expired. Please sign in again.';
      }
      return e.message ?? e.toString();
    }
    return e.toString();
  }

  Future<void> _approve(PatientDeviceRow row) async {
    setState(() => _actionId = row.id);
    try {
      await ref.read(patientAccessServiceProvider).approveDevice(row.id);
      if (!mounted) return;
      setState(() {
        _items = _items.where((e) => e.id != row.id).toList();
        _total = (_total - 1).clamp(0, _total);
        _actionId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device approved.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
    }
  }

  Future<void> _remove(PatientDeviceRow row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove device?'),
        content: Text(
          'Remove "${row.deviceLabel}" for '
          '${row.patient?.displayName ?? 'this patient'}? '
          'They must log in again and wait for re-approval.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _actionId = row.id);
    try {
      await ref.read(patientAccessServiceProvider).removeDevice(row.id);
      if (!mounted) return;
      setState(() {
        _items = _items.where((e) => e.id != row.id).toList();
        _total = (_total - 1).clamp(0, _total);
        _actionId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device removed.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
    }
  }

  void _openPatientDevices(PatientDeviceRow row) {
    final patient = row.patient;
    final uuid = patient?.id ?? '';
    if (uuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient id missing for this device.')),
      );
      return;
    }
    context.router.push(
      PatientDevicesRoute(
        patientId: uuid,
        patientName: patient?.displayName,
        hospitalPatientId: patient?.patientId,
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd MMM yyyy, HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentStaffProvider);
    if (!canManagePatientAppAccess(staff)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Device approvals')),
        body: const Center(child: Text('Access denied for this account.')),
      );
    }

    final theme = Theme.of(context);
    final hasMore = _items.length < _total;

    return Scaffold(
      appBar: AppBar(title: const Text('Device approvals')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Patient hospital ID or name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _load(reset: true),
                    child: _items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              EmptyStateWidget(
                                icon: Icons.pending_actions_outlined,
                                title: 'No pending devices',
                                message:
                                    'New patient app sign-ins awaiting approval will show here.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _items.length + (hasMore ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              if (index >= _items.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Center(
                                    child: _loadingMore
                                        ? const CircularProgressIndicator()
                                        : TextButton(
                                            onPressed: () =>
                                                _load(reset: false),
                                            child: const Text('Load more'),
                                          ),
                                  ),
                                );
                              }

                              final row = _items[index];
                              final busy = _actionId == row.id;
                              final patient = row.patient;
                              return Card(
                                child: ListTile(
                                  onTap: () => _openPatientDevices(row),
                                  title: Text(
                                    patient?.displayName.isNotEmpty == true
                                        ? patient!.displayName
                                        : 'Unknown patient',
                                  ),
                                  subtitle: Text(
                                    [
                                      if (patient?.patientId.isNotEmpty == true)
                                        patient!.patientId,
                                      if (row.deviceLabel.isNotEmpty)
                                        row.deviceLabel,
                                      if (row.platform.isNotEmpty)
                                        row.platform,
                                      if (row.createdAt != null)
                                        _formatDate(row.createdAt),
                                    ].join(' · '),
                                  ),
                                  isThreeLine: true,
                                  trailing: busy
                                      ? const SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Wrap(
                                          spacing: 4,
                                          children: [
                                            IconButton(
                                              tooltip: 'Approve',
                                              icon: const Icon(
                                                Icons.check_circle_outline,
                                              ),
                                              onPressed: () => _approve(row),
                                            ),
                                            IconButton(
                                              tooltip: 'Remove',
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                              onPressed: () => _remove(row),
                                            ),
                                          ],
                                        ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
