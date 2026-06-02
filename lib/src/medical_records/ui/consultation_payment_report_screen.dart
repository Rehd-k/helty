import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/medical_records/models/consultation_payment_report_row.dart';
import 'package:helty/src/medical_records/services/consultation_payment_report_service.dart';
import 'package:helty/src/widgets/date.filter.dart';
import 'package:intl/intl.dart';

@RoutePage()
class ConsultationPaymentReportScreen extends StatefulWidget {
  const ConsultationPaymentReportScreen({super.key});

  @override
  State<ConsultationPaymentReportScreen> createState() =>
      _ConsultationPaymentReportScreenState();
}

class _ConsultationPaymentReportScreenState
    extends State<ConsultationPaymentReportScreen> {
  final _service = ConsultationPaymentReportService();
  final _searchCtrl = TextEditingController();

  List<ConsultationPaymentReportRow> _rows = [];
  bool _loading = false;
  String? _error;
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _searchQuery) setState(() => _searchQuery = q);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final from = _fromDate;
    final to = _toDate;
    if (from == null || to == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _service.fetchReport(fromDate: from, toDate: to);
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  List<ConsultationPaymentReportRow> get _filteredRows {
    if (_searchQuery.isEmpty) return _rows;
    final q = _searchQuery.toLowerCase();
    return _rows
        .where(
          (r) =>
              r.patientName.toLowerCase().contains(q) ||
              r.patientId.toLowerCase().contains(q) ||
              r.diagnosis.toLowerCase().contains(q) ||
              r.gender.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _copyAsCsv() async {
    final filtered = _filteredRows;
    if (filtered.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No rows to export.')),
      );
      return;
    }

    final buffer = StringBuffer('Name,Age,Gender,Diagnosis,Paid date,Patient ID\n');
    for (final r in filtered) {
      buffer.writeln(
        [
          _csvCell(r.patientName),
          _csvCell(r.ageLabel),
          _csvCell(r.gender),
          _csvCell(r.diagnosis),
          _csvCell(DateFormat.yMMMd().format(r.paidAt)),
          _csvCell(r.patientId),
        ].join(','),
      );
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${filtered.length} rows to clipboard.')),
    );
  }

  static String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filtered = _filteredRows;

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paid consultation report',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Patients who paid for consultation in the selected period. '
                              'Diagnosis is shown when a completed encounter exists.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        onPressed: _loading ? null : _copyAsCsv,
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        label: const Text('Copy CSV'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _loading ? null : _load,
                        icon: _loading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.refresh, size: 18),
                        label: const Text('Load'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search name, ID, gender, or diagnosis',
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FromToDateFilter(
                    doRefresh: _load,
                    dateFilter: true,
                    onFilterChanged: (
                      String query,
                      String category,
                      DateTime? from,
                      DateTime? to,
                    ) {
                      setState(() {
                        _fromDate = from;
                        _toDate = to != null
                            ? DateTime(
                                to.year,
                                to.month,
                                to.day,
                                23,
                                59,
                                59,
                                999,
                              )
                            : null;
                      });
                      _load();
                    },
                  ),
                  if (_rows.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${filtered.length} of ${_rows.length} patients',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_loading && _rows.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null && _rows.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  _rows.isEmpty
                      ? 'Select a date range and tap Load.'
                      : 'No matches for your search.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverToBoxAdapter(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStatePropertyAll(
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Age')),
                        DataColumn(label: Text('Gender')),
                        DataColumn(label: Text('Diagnosis')),
                        DataColumn(label: Text('Paid')),
                      ],
                      rows: filtered
                          .map(
                            (r) => DataRow(
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        r.patientName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        r.patientId,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(r.ageLabel)),
                                DataCell(Text(r.gender)),
                                DataCell(
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 360),
                                    child: Text(
                                      r.diagnosis,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(DateFormatter.medicalDate(r.paidAt)),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
