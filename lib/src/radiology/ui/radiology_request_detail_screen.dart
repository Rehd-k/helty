import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';

@RoutePage()
class RadiologyRequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;
  const RadiologyRequestDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<RadiologyRequestDetailScreen> createState() =>
      _RadiologyRequestDetailScreenState();
}

class _RadiologyRequestDetailScreenState
    extends ConsumerState<RadiologyRequestDetailScreen> {
  RadiologyOrder? _order;
  bool _loading = true;
  String? _error;
  String? _selectedItemId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(radiologyServiceProvider);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await service.getOrder(widget.requestId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _selectedItemId = order.items.isNotEmpty ? order.items.first.id : null;
        _loading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _addSchedule(String itemId) async {
    final service = ref.read(radiologyServiceProvider);
    try {
      await service.createSchedule(itemId, {
        'scheduledAt': DateTime.now().toIso8601String(),
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _addProcedure(String itemId) async {
    final service = ref.read(radiologyServiceProvider);
    final staff = ref.read(authProvider).staff;
    if (staff == null) return;
    try {
      await service.createProcedure(itemId, {
        'performedById': staff.id,
        'startTime': DateTime.now().toIso8601String(),
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _uploadImage(String itemId) async {
    final service = ref.read(radiologyServiceProvider);
    final picked = await FilePicker.platform.pickFiles(type: FileType.image);
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.single.path;
    if (path == null) return;
    try {
      await service.uploadImage(itemId, File(path));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _addReport(String itemId) async {
    final service = ref.read(radiologyServiceProvider);
    final staff = ref.read(authProvider).staff;
    if (staff == null) return;
    try {
      await service.createReport(itemId, {
        'signedById': staff.id,
        'signedAt': DateTime.now().toIso8601String(),
        'findings': 'Report generated from frontend action.',
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    if (_loading && order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Radiology order')),
        body: Center(
          child: Text(_error!),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Radiology order ${order!.id.substring(0, 8)}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OrderHeader(order: order),
          const SizedBox(height: 12),
          ...order.items.map(
            (item) => Card(
              child: ExpansionTile(
                key: ValueKey(item.id),
                initiallyExpanded: _selectedItemId == item.id,
                onExpansionChanged: (v) {
                  if (v) setState(() => _selectedItemId = item.id);
                },
                title: Text(
                  '${item.scanType.name.replaceAll('_', ' ')}${item.bodyPart?.isNotEmpty == true ? ' - ${item.bodyPart}' : ''}',
                ),
                subtitle: Text(
                  '${item.priority.name} | ${item.status.name.replaceAll('_', ' ')}',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _ValueRow('Clinical notes', item.clinicalNotes ?? '-'),
                  _ValueRow(
                    'Reason',
                    item.reasonForInvestigation ?? '-',
                  ),
                  _ValueRow('Created', _fmt(item.createdAt)),
                  _ValueRow('Updated', _fmt(item.updatedAt)),
                  if (item.schedule != null)
                    _ValueRow(
                      'Scheduled',
                      _fmt(item.schedule!.scheduledAt),
                    ),
                  if (item.procedure != null)
                    _ValueRow(
                      'Procedure start',
                      _fmt(item.procedure!.startTime),
                    ),
                  if (item.report != null)
                    _ValueRow('Report', item.report!.findings ?? 'Available'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _addSchedule(item.id),
                        icon: const Icon(Icons.schedule),
                        label: Text(item.schedule == null
                            ? 'Add schedule'
                            : 'Update schedule'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _addProcedure(item.id),
                        icon: const Icon(Icons.medical_services_outlined),
                        label: Text(item.procedure == null
                            ? 'Add procedure'
                            : 'Update procedure'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _uploadImage(item.id),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload image'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _addReport(item.id),
                        icon: const Icon(Icons.description_outlined),
                        label: Text(
                          item.report == null ? 'Add report' : 'Update report',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(String? value) {
    if (value == null || value.isEmpty) return '-';
    return DateFormatter.formatFromBackend(value, DateFormatter.dateTime);
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});
  final RadiologyOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order details'),
            const SizedBox(height: 8),
            _ValueRow('Patient', order.patient?.displayName ?? order.patientId),
            _ValueRow('Status', order.status.name),
            _ValueRow('Items', '${order.items.length}'),
            _ValueRow(
              'Created',
              order.createdAt == null
                  ? '-'
                  : DateFormatter.formatFromBackend(
                      order.createdAt,
                      DateFormatter.dateTime,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
