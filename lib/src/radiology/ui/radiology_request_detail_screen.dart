import 'dart:io';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';

@RoutePage()
class RadiologyRequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;

  const RadiologyRequestDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<RadiologyRequestDetailScreen> createState() =>
      _RadiologyRequestDetailScreenState();
}

class _RadiologyRequestDetailScreenState
    extends ConsumerState<RadiologyRequestDetailScreen>
    with SingleTickerProviderStateMixin {
  RadiologyRequest? _request;
  List<RadiologyImage> _images = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  RadiologyService get _service => ref.read(radiologyServiceProvider);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final req = await _service.getRequest(widget.requestId);
      List<RadiologyImage> images = [];
      try {
        images = await _service.listImages(widget.requestId);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _request = req;
        _images = images;
        _loading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
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

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final file = File(path);
    setState(() => _loading = true);
    try {
      await _service.uploadImage(widget.requestId, file);
      if (!mounted) return;
      await _load();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Radiology request')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _request == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Radiology request'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.router.maybePop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final req = _request!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${req.scanType.name.replaceAll('_', ' ')}${req.bodyPart != null && req.bodyPart!.isNotEmpty ? ' · ${req.bodyPart}' : ''}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Schedule'),
            Tab(text: 'Procedure'),
            Tab(text: 'Images'),
            Tab(text: 'Report'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(request: req),
          _ScheduleTab(
            requestId: widget.requestId,
            schedule: req.schedule,
            onUpdated: _load,
          ),
          _ProcedureTab(
            requestId: widget.requestId,
            procedure: req.procedure,
            onUpdated: _load,
          ),
          _ImagesTab(
            requestId: widget.requestId,
            images: _images,
            service: _service,
            onUpload: _pickAndUploadImage,
            onDeleted: _load,
          ),
          _ReportTab(
            requestId: widget.requestId,
            report: req.report,
            onUpdated: _load,
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.request});

  final RadiologyRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _Row(
                  label: 'Patient',
                  value: request.patient?.displayName ?? '—',
                ),
                _Row(
                  label: 'Scan type',
                  value: request.scanType.name.replaceAll('_', ' '),
                ),
                _Row(label: 'Body part', value: request.bodyPart ?? '—'),
                _Row(label: 'Priority', value: request.priority.name),
                _Row(
                  label: 'Status',
                  value: request.status.name.replaceAll('_', ' '),
                ),
                if (request.createdAt != null)
                  _Row(
                    label: 'Created',
                    value: DateFormatter.formatFromBackend(
                      request.createdAt,
                      DateFormatter.shortDate,
                    ),
                  ),
                if (request.requestedBy != null)
                  _Row(
                    label: 'Requested by',
                    value: request.requestedBy!.displayName,
                  ),
                if (request.clinicalNotes != null &&
                    request.clinicalNotes!.isNotEmpty)
                  _Row(label: 'Clinical notes', value: request.clinicalNotes!),
                if (request.reasonForInvestigation != null &&
                    request.reasonForInvestigation!.isNotEmpty)
                  _Row(label: 'Reason', value: request.reasonForInvestigation!),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab({
    required this.requestId,
    required this.schedule,
    required this.onUpdated,
  });

  final String requestId;
  final RadiologySchedule? schedule;
  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context) {
    return _ScheduleTabContent(
      requestId: requestId,
      schedule: schedule,
      onUpdated: onUpdated,
    );
  }
}

class _ScheduleTabContent extends ConsumerStatefulWidget {
  const _ScheduleTabContent({
    required this.requestId,
    required this.schedule,
    required this.onUpdated,
  });

  final String requestId;
  final RadiologySchedule? schedule;
  final VoidCallback onUpdated;

  @override
  ConsumerState<_ScheduleTabContent> createState() =>
      _ScheduleTabContentState();
}

class _ScheduleTabContentState extends ConsumerState<_ScheduleTabContent> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final schedule = widget.schedule;

    if (schedule != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scheduled',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Row(
                    label: 'Date & time',
                    value: DateFormatter.formatFromBackend(
                      schedule.scheduledAt,
                      DateFormatter.dateTime,
                    ),
                  ),
                  if (schedule.radiographer != null)
                    _Row(
                      label: 'Radiographer',
                      value: schedule.radiographer!.displayName,
                    ),
                  if (schedule.machine != null)
                    _Row(
                      label: 'Machine',
                      value: schedule.machine?.name ?? '—',
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Not scheduled yet.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showScheduleDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showScheduleDialog(BuildContext context) async {
    DateTime? scheduledAt = DateTime.now();
    String? machineId;
    List<RadiologyMachine> machines = [];
    final service = ref.read(radiologyServiceProvider);
    try {
      machines = await service.listMachines();
    } catch (_) {}

    if (!context.mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Schedule'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(
                        scheduledAt != null
                            ? DateFormatter.dateTime(scheduledAt!)
                            : 'Pick date & time',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: scheduledAt ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null && ctx.mounted) {
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(
                              scheduledAt ?? DateTime.now(),
                            ),
                          );
                          if (time != null) {
                            setState(() {
                              scheduledAt = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                    if (machines.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: machineId,
                        decoration: const InputDecoration(labelText: 'Machine'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('—')),
                          ...machines.map(
                            (m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.name),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => machineId = v),
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
                  onPressed: scheduledAt == null
                      ? null
                      : () async {
                          try {
                            await service.createSchedule(widget.requestId, {
                              'scheduledAt': scheduledAt!.toIso8601String(),
                              if (machineId != null) 'machineId': machineId,
                            });
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(
                                ctx,
                              ).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          }
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == true && context.mounted) widget.onUpdated();
  }
}

class _ProcedureTab extends StatelessWidget {
  const _ProcedureTab({
    required this.requestId,
    required this.procedure,
    required this.onUpdated,
  });

  final String requestId;
  final RadiologyProcedure? procedure;
  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (procedure != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Procedure',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Row(
                    label: 'Start',
                    value: DateFormatter.formatFromBackend(
                      procedure!.startTime,
                      DateFormatter.dateTime,
                    ),
                  ),
                  if (procedure!.endTime != null)
                    _Row(
                      label: 'End',
                      value: DateFormatter.formatFromBackend(
                        procedure!.endTime,
                        DateFormatter.dateTime,
                      ),
                    ),
                  if (procedure!.performedBy != null)
                    _Row(
                      label: 'Performed by',
                      value: procedure!.performedBy!.displayName,
                    ),
                  if (procedure!.notes != null && procedure!.notes!.isNotEmpty)
                    _Row(label: 'Notes', value: procedure!.notes!),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 48,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No procedure recorded.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagesTab extends StatelessWidget {
  const _ImagesTab({
    required this.requestId,
    required this.images,
    required this.service,
    required this.onUpload,
    required this.onDeleted,
  });

  final String requestId;
  final List<RadiologyImage> images;
  final RadiologyService service;
  final VoidCallback onUpload;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file_rounded, size: 20),
              label: const Text('Upload image'),
            ),
          ),
        ),
        Expanded(
          child: images.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No images yet.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final img = images[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.image),
                        title: Text(img.fileName),
                        subtitle: img.uploadedAt != null
                            ? Text(
                                DateFormatter.formatFromBackend(
                                  img.uploadedAt,
                                  DateFormatter.shortDate,
                                ),
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete image?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                await service.deleteImage(img.id);
                                onDeleted();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              }
                            }
                          },
                        ),
                        onTap: () async {
                          try {
                            final bytes = await service.getImageFileBytes(
                              img.id,
                            );
                            if (!context.mounted) return;
                            await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                content: Image.memory(
                                  Uint8List.fromList(bytes),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not load image: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ReportTab extends StatelessWidget {
  const _ReportTab({
    required this.requestId,
    required this.report,
    required this.onUpdated,
  });

  final String requestId;
  final RadiologyStudyReport? report;
  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (report != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (report!.findings != null && report!.findings!.isNotEmpty)
                    _Row(label: 'Findings', value: report!.findings!),
                  if (report!.impression != null &&
                      report!.impression!.isNotEmpty)
                    _Row(label: 'Impression', value: report!.impression!),
                  if (report!.recommendations != null &&
                      report!.recommendations!.isNotEmpty)
                    _Row(
                      label: 'Recommendations',
                      value: report!.recommendations!,
                    ),
                  if (report!.severity != null)
                    _Row(label: 'Severity', value: report!.severity!.name),
                  if (report!.signedAt.isNotEmpty)
                    _Row(
                      label: 'Signed',
                      value:
                          '${report!.signedBy?.displayName ?? '—'} · ${DateFormatter.formatFromBackend(report!.signedAt, DateFormatter.dateTime)}',
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No report yet.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
