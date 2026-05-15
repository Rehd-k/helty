import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/printing/pdf/radiology_report_pdf.dart';
import 'package:helty/src/radiology/ui/radiology_ui_helpers.dart';
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
      if (!mounted || _order == null) return;
      setState(() {
        _order = _orderWithItemImages(_order!, itemId, listed);
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

  RadiologyOrder _orderWithItemImages(
    RadiologyOrder order,
    String itemId,
    List<RadiologyImage> images,
  ) {
    return RadiologyOrder(
      id: order.id,
      patientId: order.patientId,
      requestedById: order.requestedById,
      items: order.items
          .map(
            (i) => i.id == itemId ? _copyItemWithImages(i, images) : i,
          )
          .toList(),
      encounterId: order.encounterId,
      departmentId: order.departmentId,
      status: order.status,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      patient: order.patient,
      requestedBy: order.requestedBy,
    );
  }

  RadiologyOrderItem _copyItemWithImages(
    RadiologyOrderItem item,
    List<RadiologyImage> images,
  ) {
    return RadiologyOrderItem(
      id: item.id,
      orderId: item.orderId,
      scanType: item.scanType,
      priority: item.priority,
      status: item.status,
      bodyPart: item.bodyPart,
      contrast: item.contrast,
      clinicalNotes: item.clinicalNotes,
      reasonForInvestigation: item.reasonForInvestigation,
      invoiceId: item.invoiceId,
      invoiceItemId: item.invoiceItemId,
      serviceId: item.serviceId,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      schedule: item.schedule,
      procedure: item.procedure,
      images: images,
      report: item.report,
    );
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
      body: RefreshIndicator(
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
                  if ((item.images ?? []).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Uploaded images/files',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    ...item.images!.map(
                      (img) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RadiologyAttachmentPreview(image: img),
                      ),
                    ),
                  ],
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
    );
  }

  String _fmt(String? value) {
    if (value == null || value.isEmpty) return '-';
    return DateFormatter.formatFromBackend(value, DateFormatter.dateTime);
  }
}

class _RadiologyAttachmentPreview extends ConsumerStatefulWidget {
  const _RadiologyAttachmentPreview({required this.image});

  final RadiologyImage image;

  @override
  ConsumerState<_RadiologyAttachmentPreview> createState() =>
      _RadiologyAttachmentPreviewState();
}

class _RadiologyAttachmentPreviewState
    extends ConsumerState<_RadiologyAttachmentPreview> {
  Future<Uint8List>? _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _loadBytes();
  }

  @override
  void didUpdateWidget(covariant _RadiologyAttachmentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.id != widget.image.id) {
      _bytesFuture = _loadBytes();
    }
  }

  Future<Uint8List> _loadBytes() async {
    final raw =
        await ref.read(radiologyServiceProvider).getImageFileBytes(widget.image.id);
    return Uint8List.fromList(raw);
  }

  String _uploadedLabel() {
    final at = widget.image.uploadedAt;
    final when = at == null || at.isEmpty
        ? '-'
        : DateFormatter.formatFromBackend(at, DateFormatter.dateTime);
    final by = widget.image.uploadedBy?.displayName.isNotEmpty == true
        ? widget.image.uploadedBy!.displayName
        : 'staff';
    return '${widget.image.mimeType ?? 'file'} · $when · $by';
  }

  void _openImageFullScreen(BuildContext context, Uint8List bytes) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final size = MediaQuery.sizeOf(ctx);
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: size.width * 0.92,
            height: size.height * 0.88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.image.fileName,
                          style: Theme.of(ctx).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Center(
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPdf = radiologyImageIsLikelyPdf(widget.image);
    final isRaster = radiologyImageIsLikelyRaster(widget.image);

    if (!isPdf && !isRaster) {
      return Card(
        child: ListTile(
          leading: Icon(Icons.insert_drive_file_outlined,
              color: theme.colorScheme.primary),
          title: Text(widget.image.fileName),
          subtitle: Text(_uploadedLabel()),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Uint8List>(
        future: _bytesFuture,
        builder: (context, snap) {
          if (snap.hasError) {
            return ListTile(
              leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
              title: Text(widget.image.fileName),
              subtitle: Text('Could not load file.\n${snap.error}'),
            );
          }
          if (!snap.hasData) {
            return ListTile(
              leading: const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text(widget.image.fileName),
              subtitle: Text(_uploadedLabel()),
            );
          }
          final bytes = snap.data!;

          if (isPdf) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  dense: true,
                  leading: Icon(Icons.picture_as_pdf,
                      color: theme.colorScheme.error),
                  title: Text(widget.image.fileName),
                  subtitle: Text(_uploadedLabel()),
                ),
                SizedBox(
                  height: 320,
                  child: PdfPreview(
                    build: (_) async => bytes,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    pdfFileName: widget.image.fileName,
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                dense: true,
                leading: const Icon(Icons.image_outlined),
                title: Text(widget.image.fileName),
                subtitle: Text(_uploadedLabel()),
              ),
              Material(
                color: theme.colorScheme.surfaceContainerHighest,
                child: InkWell(
                  onTap: () => _openImageFullScreen(context, bytes),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: Center(
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Preview not available for this file.',
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
