import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../models/archived_encounter_models.dart';
import '../../services/patient_chart_service.dart';

class ArchivedDocumentViewer extends StatefulWidget {
  const ArchivedDocumentViewer({
    super.key,
    required this.document,
    required this.service,
  });

  final ArchivedEncounterDocument document;
  final PatientChartService service;

  @override
  State<ArchivedDocumentViewer> createState() => _ArchivedDocumentViewerState();
}

class _ArchivedDocumentViewerState extends State<ArchivedDocumentViewer> {
  bool _loading = true;
  String? _error;
  String? _tempPath;
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await widget.service.downloadArchivedDocument(widget.document.id);
      if (!mounted) return;
      if (widget.document.isImage) {
        setState(() {
          _bytes = Uint8List.fromList(bytes);
          _loading = false;
        });
        return;
      }
      final ext = widget.document.isPdf ? '.pdf' : '';
      final file = File(
        '${Directory.systemTemp.path}/archived_${widget.document.id}$ext',
      );
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      setState(() {
        _tempPath = file.path;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.document.fileName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_bytes != null) {
      return InteractiveViewer(
        child: Center(child: Image.memory(_bytes!, fit: BoxFit.contain)),
      );
    }
    if (_tempPath != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'PDF saved to temporary storage.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                widget.document.fileName,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Open with your system PDF viewer from:\n$_tempPath',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return const Center(child: Text('Unable to display file.'));
  }
}
