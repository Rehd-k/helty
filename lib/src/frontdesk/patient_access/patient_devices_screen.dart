import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/frontdesk/patient_access/patient_access_models.dart';
import 'package:helty/src/frontdesk/patient_access/patient_access_providers.dart';
import 'package:helty/src/frontdesk/patient_access_permissions.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:intl/intl.dart';

@RoutePage()
class PatientDevicesScreen extends ConsumerStatefulWidget {
  const PatientDevicesScreen({
    super.key,
    required this.patientId,
    this.patientName,
    this.hospitalPatientId,
  });

  /// Patient UUID (`Patient.id`).
  final String patientId;
  final String? patientName;
  final String? hospitalPatientId;

  @override
  ConsumerState<PatientDevicesScreen> createState() =>
      _PatientDevicesScreenState();
}

class _PatientDevicesScreenState extends ConsumerState<PatientDevicesScreen> {
  List<PatientDeviceRow> _items = [];
  bool _loading = true;
  String? _error;
  String? _actionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref
          .read(patientAccessServiceProvider)
          .listDevicesForPatient(widget.patientId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
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
      await _load();
      if (!mounted) return;
      setState(() => _actionId = null);
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
          'Remove "${row.deviceLabel}"? The patient must log in again '
          'and wait for re-approval.',
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
      await _load();
      if (!mounted) return;
      setState(() => _actionId = null);
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd MMM yyyy, HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentStaffProvider);
    final name = widget.patientName?.trim().isNotEmpty == true
        ? widget.patientName!
        : 'Patient devices';
    final subtitleParts = <String>[
      if (widget.hospitalPatientId?.trim().isNotEmpty == true)
        widget.hospitalPatientId!.trim(),
    ];

    if (!canManagePatientAppAccess(staff)) {
      return Scaffold(
        appBar: AppBar(title: Text(name)),
        body: const Center(child: Text('Access denied for this account.')),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        bottom: subtitleParts.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    subtitleParts.join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Text(
                            _error!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    )
                  : _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No registered devices.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final row = _items[index];
                        final busy = _actionId == row.id;
                        return Card(
                          child: ListTile(
                            title: Text(row.deviceLabel),
                            subtitle: Text(
                              [
                                if (row.platform.isNotEmpty) row.platform,
                                if (row.status.isNotEmpty) row.status,
                                if (row.createdAt != null)
                                  _formatDate(row.createdAt),
                              ].join(' · '),
                            ),
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
                                      if (row.isPending)
                                        IconButton(
                                          tooltip: 'Approve',
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                          ),
                                          onPressed: () => _approve(row),
                                        ),
                                      IconButton(
                                        tooltip: 'Remove',
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => _remove(row),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
