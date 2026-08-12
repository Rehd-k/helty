import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/printing/pdf/simple_table_report_pdf.dart';
import 'package:helty/src/reports/services/hospital_reports_service.dart';
import 'package:printing/printing.dart';

@RoutePage()
class HospitalReportScreen extends StatefulWidget {
  const HospitalReportScreen({
    super.key,
    required this.kind,
    this.initialRequestType,
  });

  final HospitalReportKind kind;
  final String? initialRequestType;

  @override
  State<HospitalReportScreen> createState() => _HospitalReportScreenState();
}

class _HospitalReportScreenState extends State<HospitalReportScreen> {
  final _service = HospitalReportsService();

  late DateTimeRange _range;
  String? _requestType;
  bool _loading = false;
  String? _error;
  List<Map<String, String>> _rows = const [];
  List<String> _columns = const [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    _range = DateTimeRange(
      start: start,
      end: DateTime(now.year, now.month, now.day),
    );
    _requestType = widget.initialRequestType?.trim().isNotEmpty == true
        ? widget.initialRequestType!.trim().toLowerCase()
        : (widget.kind.requiresRequestType ? 'lab' : null);
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _range,
    );
    if (picked == null) return;
    setState(() => _range = picked);
  }

  Future<void> _load() async {
    if (widget.kind.requiresRequestType &&
        (_requestType == null || _requestType!.isEmpty)) {
      setState(() => _error = 'Select a request type (lab / radiology / pharmacy).');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchJson(
        kind: widget.kind,
        from: _range.start,
        to: _range.end,
        requestType: _requestType,
      );
      final rows = HospitalReportsService.flattenForTable(data);
      final cols = <String>{};
      for (final r in rows) {
        cols.addAll(r.keys);
      }
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _columns = cols.toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _rows = const [];
        _columns = const [];
      });
    }
  }

  Future<void> _export(HospitalReportExportFormat format) async {
    setState(() => _loading = true);
    try {
      final bytes = await _service.exportBytes(
        kind: widget.kind,
        from: _range.start,
        to: _range.end,
        format: format,
        requestType: _requestType,
      );
      final ext = format == HospitalReportExportFormat.xlsx ? 'xlsx' : 'csv';
      final type = widget.kind.requiresRequestType && _requestType != null
          ? '-$_requestType'
          : '';
      final name = '${widget.kind.exportBasename}$type.$ext';
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save report',
        fileName: name,
        bytes: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null ? 'Export cancelled' : 'Saved $name',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _printPdf() async {
    if (_rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Load the report before printing.')),
      );
      return;
    }
    final headers = _columns;
    final dataRows = _rows
        .map((r) => headers.map((h) => r[h] ?? '').toList())
        .toList();
    await Printing.layoutPdf(
      onLayout: (format) async {
        final bytes = await buildSimpleTableReportPdf(
          format: format,
          title: widget.kind.title,
          subtitle:
              '${DateFormatter.shortDate(_range.start)} – ${DateFormatter.shortDate(_range.end)}',
          headers: headers,
          rows: dataRows,
        );
        return Uint8List.fromList(bytes);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kind.title),
        actions: [
          IconButton(
            tooltip: 'Print / PDF',
            onPressed: _loading ? null : _printPdf,
            icon: const Icon(Icons.print_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Export',
            enabled: !_loading,
            onSelected: (v) {
              if (v == 'csv') _export(HospitalReportExportFormat.csv);
              if (v == 'xlsx') _export(HospitalReportExportFormat.xlsx);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'csv', child: Text('Export CSV')),
              PopupMenuItem(value: 'xlsx', child: Text('Export Excel')),
            ],
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: ResponsiveBody(
        builder: (context, bp) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _loading ? null : _pickRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    '${DateFormatter.shortDate(_range.start)} – ${DateFormatter.shortDate(_range.end)}',
                  ),
                ),
                if (widget.kind.requiresRequestType)
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _requestType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'lab', child: Text('Lab')),
                        DropdownMenuItem(
                          value: 'radiology',
                          child: Text('Radiology'),
                        ),
                        DropdownMenuItem(
                          value: 'pharmacy',
                          child: Text('Pharmacy'),
                        ),
                      ],
                      onChanged: _loading
                          ? null
                          : (v) => setState(() => _requestType = v),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _loading ? null : _load,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Run report'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            Expanded(
              child: _rows.isEmpty
                  ? Center(
                      child: Text(
                        _loading
                            ? 'Loading…'
                            : 'Choose a date range and run the report.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: [
                            for (final c in _columns)
                              DataColumn(
                                label: Text(
                                  c,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                          rows: [
                            for (final r in _rows)
                              DataRow(
                                cells: [
                                  for (final c in _columns)
                                    DataCell(
                                      Text(
                                        r[c] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
