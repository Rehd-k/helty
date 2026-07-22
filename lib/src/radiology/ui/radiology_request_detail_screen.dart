import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/printing/pdf/radiology_clinical_notes_pdf.dart';
import 'package:helty/src/printing/pdf/radiology_report_pdf.dart';
import 'package:helty/src/radiology/ui/radiology_ui_helpers.dart';
import 'package:helty/src/radiology/ui/widgets/radiology_image_viewer.dart';
import 'package:printing/printing.dart';

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
  Map<String, List<RadiologyImage>> _itemImages = {};
  bool _loading = true;
  bool _statusUpdating = false;
  String? _itemActionId;
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
      final itemImages = await fetchRadiologyOrderImagesByItem(service, order);
      if (!mounted) return;
      setState(() {
        _order = order;
        _itemImages = itemImages;
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
    await _runItemAction(itemId, () async {
      await service.createSchedule(itemId, {
        'scheduledAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> _addProcedure(String itemId) async {
    final service = ref.read(radiologyServiceProvider);
    final staff = ref.read(authProvider).staff;
    if (staff == null) return;
    await _runItemAction(itemId, () async {
      await service.createProcedure(itemId, {
        'performedById': staff.id,
        'startTime': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> _uploadImage(String itemId) async {
    final service = ref.read(radiologyServiceProvider);
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.single.path;
    if (path == null) return;
    setState(() => _itemActionId = itemId);
    try {
      final uploaded = await service.uploadImage(itemId, File(path));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Uploaded ${uploaded.fileName} by ${uploaded.uploadedBy?.displayName.isNotEmpty == true ? uploaded.uploadedBy!.displayName : 'staff'} at ${_fmt(uploaded.uploadedAt)}',
          ),
        ),
      );
      await _load();
      final listed = await service.listImages(itemId);
      if (!mounted) return;
      setState(() {
        _itemImages = {..._itemImages, itemId: listed};
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _itemActionId = null);
    }
  }

  Future<void> _saveReport(RadiologyOrderItem item) async {
    final staff = ref.read(authProvider).staff;
    if (staff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in as staff to save a report.')),
      );
      return;
    }
    final service = ref.read(radiologyServiceProvider);
    final report = item.report;
    final editor = _buildQuillController(report);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
          ),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report == null ? 'Create report' : 'Edit report',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                QuillSimpleToolbar(controller: editor),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(ctx).colorScheme.outlineVariant,
                      ),
                    ),
                    child: QuillEditor.basic(controller: editor),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Save report'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved != true) return;

    final plainText = editor.document.toPlainText().trim();
    final deltaJson = jsonEncode(editor.document.toDelta().toJson());
    final signedAt = DateTime.now().toIso8601String();
    final body = <String, dynamic>{
      'findings': plainText,
      'impression': deltaJson,
      'signedById': staff.id,
      'signedAt': signedAt,
    };
    await _runItemAction(item.id, () async {
      if (report == null) {
        await service.createReport(item.id, body);
      } else {
        await service.updateReport(item.id, body);
      }
    });
  }

  Future<void> _updateOrderStatus(RadiologyOrderStatus status) async {
    final order = _order;
    if (order == null) return;
    setState(() => _statusUpdating = true);
    try {
      await ref.read(radiologyServiceProvider).updateOrder(
        order.id,
        {'status': status.apiValue},
      );
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Order status set to ${orderStatusLabel(status)}.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _statusUpdating = false);
    }
  }

  Future<void> _updateItemStatus(
    String itemId,
    RadiologyOrderItemStatus status,
  ) async {
    await _runItemAction(itemId, () async {
      await ref.read(radiologyServiceProvider).updateOrderItem(itemId, {
        'status': status.apiValue,
      });
    });
  }

  Future<void> _runItemAction(String itemId, Future<void> Function() action) async {
    setState(() => _itemActionId = itemId);
    try {
      await action();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _itemActionId = null);
    }
  }

  QuillController _buildQuillController(RadiologyStudyReport? report) {
    if (report?.impression != null && report!.impression!.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(report.impression!);
        if (decoded is List) {
          return QuillController(
            document: Document.fromJson(
              decoded.map((e) => e as Map<String, dynamic>).toList(),
            ),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      } catch (_) {}
    }
    return QuillController.basic(
      config: QuillControllerConfig(),
    )..document.insert(0, reportPreviewText(report));
  }

  Future<void> _printOrderReport() async {
    final order = _order;
    if (order == null) return;
    await Printing.layoutPdf(
      onLayout: (_) async =>
          Uint8List.fromList(await buildRadiologyOrderReportPdf(order)),
    );
  }

  Future<void> _shareOrderReport() async {
    final order = _order;
    if (order == null) return;
    final bytes = await buildRadiologyOrderReportPdf(order);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'radiology_order_${order.id}.pdf',
    );
  }

  bool _hasClinicalNotes(RadiologyOrder order) {
    return order.items.any(
      (item) => (item.clinicalNotes ?? '').trim().isNotEmpty,
    );
  }

  Future<void> _printClinicalNotes() async {
    final order = _order;
    if (order == null) return;
    await Printing.layoutPdf(
      onLayout: (_) async =>
          Uint8List.fromList(await buildRadiologyClinicalNotesPdf(order)),
    );
  }

  Future<void> _shareClinicalNotes() async {
    final order = _order;
    if (order == null) return;
    final bytes = await buildRadiologyClinicalNotesPdf(order);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'radiology_clinical_notes_${order.id}.pdf',
    );
  }

  List<RadiologyImage> _imagesForItem(RadiologyOrderItem item) {
    return _itemImages[item.id] ?? item.images ?? const [];
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
        actions: [
          IconButton(
            onPressed: _hasClinicalNotes(_order!) ? _printClinicalNotes : null,
            icon: const Icon(Icons.note_alt_outlined),
            tooltip: 'Print clinical notes',
          ),
          IconButton(
            onPressed: _hasClinicalNotes(_order!) ? _shareClinicalNotes : null,
            icon: const Icon(Icons.note_add_outlined),
            tooltip: 'Share clinical notes',
          ),
          IconButton(
            onPressed: _order!.items.any((e) => e.report != null) ? _printOrderReport : null,
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print report',
          ),
          IconButton(
            onPressed: _order!.items.any((e) => e.report != null) ? _shareOrderReport : null,
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Share PDF',
          ),
          PopupMenuButton<RadiologyOrderStatus>(
            enabled: !_statusUpdating,
            tooltip: 'Order status',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: _updateOrderStatus,
            itemBuilder: (context) => RadiologyOrderStatus.values
                .map(
                  (status) => PopupMenuItem(
                    value: status,
                    child: Text(orderStatusLabel(status)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      body: ResponsiveBody(
        expand: false,
        builder: (context, bp) => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  '${item.scanType.displayLabel}${item.bodyPart?.isNotEmpty == true ? ' · ${item.bodyPart}' : ''}',
                ),
                subtitle: Text(
                  '${item.priority.name} · ${itemStatusLabel(item.status)}',
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
                    _ValueRow('Report preview', reportPreviewText(item.report)),
                  if (_imagesForItem(item).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Uploaded images/files',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    ..._imagesForItem(item).map(
                      (img) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RadiologyImageSlide(
                          service: ref.read(radiologyServiceProvider),
                          image: img,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((item.clinicalNotes ?? '').trim().isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: _printClinicalNotes,
                          icon: const Icon(Icons.note_alt_outlined),
                          label: const Text('Print notes'),
                        ),
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
                        label: const Text('Upload image/file'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _saveReport(item),
                        icon: const Icon(Icons.description_outlined),
                        label: Text(
                          item.report == null ? 'Add report' : 'Update report',
                        ),
                      ),
                      PopupMenuButton<RadiologyOrderItemStatus>(
                        enabled: _itemActionId != item.id,
                        tooltip: 'Change item status',
                        onSelected: (status) =>
                            _updateItemStatus(item.id, status),
                        itemBuilder: (context) =>
                            RadiologyOrderItemStatus.values
                                .map(
                                  (status) => PopupMenuItem(
                                    value: status,
                                    child: Text(itemStatusLabel(status)),
                                  ),
                                )
                                .toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.change_circle_outlined,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Item status',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
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
      ),
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
    final requestedByName = (order.requestedBy?.displayName ?? '').trim();
    final requestedByLabel = requestedByName.isNotEmpty
        ? requestedByName
        : (order.requestedById.isNotEmpty ? order.requestedById : '-');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order details'),
            const SizedBox(height: 8),
            Row(
              children: [
                PatientAvatar(
                  avatarUrl: order.patient?.avatarUrl,
                  firstName: order.patient?.firstName,
                  surname: order.patient?.surname,
                  displayName: order.patient?.displayName,
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ValueRow(
                    'Patient',
                    order.patient?.displayName ?? order.patientId,
                  ),
                ),
              ],
            ),
            _ValueRow('Requested by', requestedByLabel),
            _ValueRow('Status', orderStatusLabel(order.status)),
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
