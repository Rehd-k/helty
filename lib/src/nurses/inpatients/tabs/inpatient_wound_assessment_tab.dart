import 'dart:io' show File;

import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/helper/clinical_image_picker.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/staff_attribution.dart';
import 'package:helty/src/models/wound_assessment_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/wound_assessment_service.dart';

@RoutePage()
class InpatientWoundAssessmentScreen extends StatefulWidget {
  const InpatientWoundAssessmentScreen({super.key});

  @override
  State<InpatientWoundAssessmentScreen> createState() =>
      _InpatientWoundAssessmentScreenState();
}

class _InpatientWoundAssessmentScreenState
    extends State<InpatientWoundAssessmentScreen> {
  final _service = WoundAssessmentService();
  List<WoundAssessmentModel> _assessments = [];
  bool _loading = true;
  String? _error;
  String? _lastLoadedAdmissionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = InpatientViewScope.of(context)?.admissionId;
    if (id == null || id.isEmpty) {
      if (_lastLoadedAdmissionId != null || _loading) {
        setState(() {
          _assessments = [];
          _loading = false;
          _error = null;
          _lastLoadedAdmissionId = null;
        });
      }
      return;
    }
    if (id != _lastLoadedAdmissionId) {
      _lastLoadedAdmissionId = id;
      _load(id);
    }
  }

  Future<void> _load(String admissionId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.list(admissionId);
      list.sort((a, b) {
        final ta = a.recordedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.recordedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      if (!mounted) return;
      setState(() {
        _assessments = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _assessments = [];
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _showWoundPhoto(
    BuildContext context, {
    required String admissionId,
    required WoundAssessmentModel assessment,
  }) {
    final photoUrl = assessment.photoUrl?.trim();
    if (photoUrl == null || photoUrl.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => _WoundPhotoDialog(
        service: _service,
        admissionId: admissionId,
        assessmentId: assessment.id,
        photoUrl: photoUrl,
      ),
    );
  }

  Future<void> _openAddDialog(BuildContext context) async {
    final admissionId = InpatientViewScope.of(context)?.admissionId;
    if (admissionId == null || admissionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admission context missing.')),
      );
      return;
    }
    final nurseId = requireNurseIdFromScope(context);
    if (nurseId == null) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AddWoundAssessmentDialog(
        admissionId: admissionId,
        nurseId: nurseId,
        service: _service,
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wound assessment saved.')));
      await _load(admissionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final admissionId = InpatientViewScope.of(context)?.admissionId;

    if (admissionId == null || admissionId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Open this patient with an admission to view wound assessments.',
          ),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(
              onPressed: () => _load(admissionId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Wound assessments',
        subtitle: 'Document wound location, stage, and signs of infection',
        actions: [
          FilledButton.icon(
            onPressed: () => _openAddDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add assessment'),
          ),
        ],
        child: _assessments.isEmpty
            ? Text(
                'No wound assessments recorded yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Recorded')),
                    DataColumn(label: Text('Location')),
                    DataColumn(label: Text('Stage')),
                    DataColumn(label: Text('Size')),
                    DataColumn(label: Text('Exudate')),
                    DataColumn(label: Text('Photo')),
                    DataColumn(label: Text('Recorded by')),
                  ],
                  rows: _assessments
                      .map(
                        (w) => DataRow(
                          cells: [
                            DataCell(
                              Text(
                                DateFormatter.dateTime(
                                  w.recordedAt ?? DateTime.now(),
                                ),
                              ),
                            ),
                            DataCell(Text(w.woundLocation ?? '—')),
                            DataCell(Text(w.woundStage ?? '—')),
                            DataCell(Text(w.woundSize ?? '—')),
                            DataCell(Text(w.exudate ?? '—')),
                            DataCell(() {
                              final url = w.photoUrl?.trim();
                              if (url == null || url.isEmpty) {
                                return const Text('—');
                              }
                              return IconButton(
                                tooltip: 'View wound photo',
                                icon: const Icon(Icons.image_outlined),
                                onPressed: () => _showWoundPhoto(
                                  context,
                                  admissionId: admissionId,
                                  assessment: w,
                                ),
                              );
                            }()),
                            DataCell(Text(w.nurseDisplayName ?? '—')),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
      ),
    );
  }
}

class _WoundPhotoDialog extends StatelessWidget {
  const _WoundPhotoDialog({
    required this.service,
    required this.admissionId,
    required this.assessmentId,
    required this.photoUrl,
  });

  final WoundAssessmentService service;
  final String admissionId;
  final String assessmentId;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Wound photo'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 400),
        child: FutureBuilder<Uint8List>(
          future: service.getPhotoBytes(
            admissionId: admissionId,
            assessmentId: assessmentId,
            photoUrl: photoUrl,
          ),
          builder: (context, snap) {
            if (snap.hasError) {
              return Text(
                'Could not load image.\n${snap.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              );
            }
            if (!snap.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return InteractiveViewer(
              child: Image.memory(snap.data!, fit: BoxFit.contain),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

String _woundAssessmentDioMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['message'] != null) {
    return data['message'].toString();
  }
  return e.message ?? 'Request failed';
}

Widget _pickedPhotoPreview(PickedClinicalImage photo) {
  final bytes = photo.bytes;
  if (bytes != null && bytes.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(bytes, height: 120, fit: BoxFit.contain),
    );
  }
  if (!kIsWeb) {
    final path = photo.path;
    if (path != null && path.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(path), height: 120, fit: BoxFit.contain),
      );
    }
  }
  return const SizedBox.shrink();
}

/// Owns form controllers so disposal matches the dialog route lifecycle.
class _AddWoundAssessmentDialog extends StatefulWidget {
  const _AddWoundAssessmentDialog({
    required this.admissionId,
    required this.nurseId,
    required this.service,
  });

  final String admissionId;
  final String nurseId;
  final WoundAssessmentService service;

  @override
  State<_AddWoundAssessmentDialog> createState() =>
      _AddWoundAssessmentDialogState();
}

class _AddWoundAssessmentDialogState extends State<_AddWoundAssessmentDialog> {
  final _locationCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _stageCtrl = TextEditingController();
  final _exudateCtrl = TextEditingController();
  final _odorCtrl = TextEditingController();
  final _infectionCtrl = TextEditingController();

  PickedClinicalImage? _pickedPhoto;
  bool _saving = false;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _sizeCtrl.dispose();
    _stageCtrl.dispose();
    _exudateCtrl.dispose();
    _odorCtrl.dispose();
    _infectionCtrl.dispose();
    super.dispose();
  }

  void _close([bool? saved]) {
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(saved);
    });
  }

  Future<void> _submit() async {
    if (_locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wound location is required.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.service.create(
        admissionId: widget.admissionId,
        nurseId: widget.nurseId,
        woundLocation: _locationCtrl.text.trim(),
        woundSize: _sizeCtrl.text.trim(),
        woundStage: _stageCtrl.text.trim(),
        exudate: _exudateCtrl.text.trim(),
        odor: _odorCtrl.text.trim(),
        infectionSigns: _infectionCtrl.text.trim(),
        photo: _pickedPhoto,
      );
      if (!mounted) return;
      _close(true);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_woundAssessmentDioMessage(e))));
      setState(() => _saving = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Wound assessment'),
      content: SizedBox(
        width: inpatientDialogBodyWidth(context, preferred: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Wound location'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sizeCtrl,
                decoration: const InputDecoration(labelText: 'Wound size'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stageCtrl,
                decoration: const InputDecoration(labelText: 'Wound stage'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _exudateCtrl,
                decoration: const InputDecoration(labelText: 'Exudate'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _odorCtrl,
                decoration: const InputDecoration(labelText: 'Odor'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _infectionCtrl,
                decoration: const InputDecoration(labelText: 'Infection signs'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        final picked = await pickClinicalImage();
                        if (picked == null || !mounted) return;
                        setState(() => _pickedPhoto = picked);
                      },
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  _pickedPhoto == null ? 'Attach wound photo' : 'Change photo',
                ),
              ),
              if (_pickedPhoto != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _pickedPhoto!.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() => _pickedPhoto = null),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _pickedPhotoPreview(_pickedPhoto!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => _close(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
