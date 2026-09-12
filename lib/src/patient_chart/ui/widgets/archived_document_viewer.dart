import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:printing/printing.dart';

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
  Uint8List? _bytes;

  bool get _useMobilePdfView {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await widget.service.downloadArchivedDocument(
        widget.document.id,
      );
      if (!mounted) return;
      setState(() {
        _bytes = Uint8List.fromList(bytes);
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
    if (widget.document.isImage && _bytes != null) {
      return InteractiveViewer(
        child: Center(child: Image.memory(_bytes!, fit: BoxFit.contain)),
      );
    }
    if (widget.document.isPdf && _bytes != null) {
      if (_useMobilePdfView) {
        return PDFView(
          pdfData: _bytes,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          onError: (error) {
            if (mounted) {
              setState(() => _error = error.toString());
            }
          },
        );
      }
      return PdfPreview(
        build: (_) async => _bytes!,
        canChangePageFormat: false,
        canChangeOrientation: false,
        pdfFileName: widget.document.fileName,
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              widget.document.fileName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'This file type cannot be previewed in the app.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
