import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/patient_chart_service.dart';

class ArchivedEncounterUploadSheet extends StatefulWidget {
  const ArchivedEncounterUploadSheet({
    super.key,
    required this.patientUuid,
    required this.service,
    required this.onUploaded,
  });

  final String patientUuid;
  final PatientChartService service;
  final VoidCallback onUploaded;

  @override
  State<ArchivedEncounterUploadSheet> createState() =>
      _ArchivedEncounterUploadSheetState();
}

class _ArchivedEncounterUploadSheetState
    extends State<ArchivedEncounterUploadSheet> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _occurredAt = DateTime.now();
  final List<String> _filePaths = [];
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
    );
    if (picked == null) return;
    setState(() {
      for (final f in picked.files) {
        if (f.path != null && !_filePaths.contains(f.path)) {
          _filePaths.add(f.path!);
        }
      }
    });
  }

  Future<void> _pickOccurredDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (!mounted) return;
    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _occurredAt.hour,
        time?.minute ?? _occurredAt.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_filePaths.isEmpty) {
      setState(() => _error = 'Select at least one file.');
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await widget.service.uploadArchivedEncounter(
        patientUuid: widget.patientUuid,
        encounterOccurredAt: _occurredAt,
        filePaths: _filePaths,
        title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      widget.onUploaded();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _uploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Upload archived visit',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visit date & time'),
              subtitle: Text(DateFormat.yMMMd().add_jm().format(_occurredAt)),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: _uploading ? null : _pickOccurredDate,
              ),
            ),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                hintText: 'OPD visit – Dr. Ade',
              ),
              enabled: !_uploading,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
              enabled: !_uploading,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pickFiles,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _filePaths.isEmpty
                    ? 'Select files (images or PDF)'
                    : '${_filePaths.length} file(s) selected',
              ),
            ),
            if (_filePaths.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._filePaths.map(
                (p) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.insert_drive_file_outlined, size: 20),
                  title: Text(
                    p.split(RegExp(r'[/\\]')).last,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _uploading
                        ? null
                        : () => setState(() => _filePaths.remove(p)),
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _uploading ? null : _submit,
              child: _uploading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
