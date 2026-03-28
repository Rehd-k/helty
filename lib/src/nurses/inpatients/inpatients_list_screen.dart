import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/models/ward_models.dart';
import 'package:helty/src/services/ward_service.dart';

@RoutePage()
class InpatientsListScreen extends StatefulWidget {
  const InpatientsListScreen({super.key});

  @override
  State<InpatientsListScreen> createState() => _InpatientsListScreenState();
}

class _InpatientsListScreenState extends State<InpatientsListScreen> {
  final _wardService = WardService();
  final _searchController = TextEditingController();

  List<Ward> _wards = const [];
  Ward? _selectedWard;
  List<InpatientCensus> _rows = const [];
  List<InpatientCensus> _filteredRows = const [];

  bool _isLoadingWards = false;
  bool _isLoadingWardDetails = false;

  @override
  void initState() {
    super.initState();
    _loadWards();
    _searchController.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applySearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWards() async {
    setState(() {
      _isLoadingWards = true;
    });
    try {
      final wards = await _wardService.fetchWards();
      setState(() {
        _wards = wards;
        if (wards.isNotEmpty) {
          _selectedWard ??= wards.first;
        }
      });
      if (_selectedWard != null) {
        await _loadWardDetails(_selectedWard!.id);
      }
    } catch (e) {
      _showError('Failed to load wards, $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWards = false;
        });
      }
    }
  }

  Future<void> _loadWardDetails(String wardId) async {
    setState(() {
      _isLoadingWardDetails = true;
    });
    try {
      final ward = await _wardService.getWardById(wardId);
      if (!mounted) return;
      setState(() {
        _selectedWard = ward;
        _rows = ward.inpatients;
      });
      _applySearch();
    } catch (e) {
      _showError('Failed to load ward details, $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWardDetails = false;
        });
      }
    }
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredRows = _rows;
      });
      return;
    }

    setState(() {
      _filteredRows = _rows
          .where((row) {
            final name = row.name.toLowerCase();
            final bed = row.bedLabel.toLowerCase();
            final id = row.patientId.toLowerCase();
            return name.contains(query) ||
                bed.contains(query) ||
                id.contains(query);
          })
          .toList(growable: false);
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openInpatientView(InpatientCensus row) {
    context.router.push(
      InpatientPatientViewRoute(
        admissionId: row.id,
        ward: row.wardName,
        bedNumber: row.bedLabel,
        diagnosis: row.diagnosis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final totalCount = _filteredRows.length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inpatients (Ward Census)',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a ward and patient to open the full inpatient view.',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bed, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          _isLoadingWardDetails
                              ? 'Loading...'
                              : '$totalCount Inpatients',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Ward'),
                        initialValue: _selectedWard?.id,
                        isExpanded: true,
                        items: _wards
                            .map(
                              (w) => DropdownMenuItem<String>(
                                value: w.id,
                                child: Text(w.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          _loadWardDetails(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Search by name, patient ID or bed (local only)',
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Refresh wards',
                      onPressed: _isLoadingWards ? null : _loadWards,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withValues(alpha: 0.02),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: const [
                            _HeaderCell('PATIENT'),
                            _HeaderCell('WARD'),
                            _HeaderCell('BED'),
                            _HeaderCell('DIAGNOSIS'),
                            _HeaderCell('DAYS ADMITTED'),
                            _HeaderCell('ACTIONS', alignRight: true),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: colorScheme.outline.withValues(alpha: 0.12),
                      ),
                      Expanded(
                        child: _isLoadingWardDetails
                            ? const Center(child: CircularProgressIndicator())
                            : _selectedWard == null
                            ? Center(
                                child: Text(
                                  'Select a ward to view current inpatients.',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              )
                            : _filteredRows.isEmpty
                            ? Center(
                                child: Text(
                                  'No inpatients in this ward.',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _filteredRows.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.06,
                                  ),
                                ),
                                itemBuilder: (context, index) {
                                  final row = _filteredRows[index];
                                  return InkWell(
                                    onTap: () => _openInpatientView(row),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.12),
                                                  child: Text(
                                                    row.initials,
                                                    style: TextStyle(
                                                      color:
                                                          colorScheme.primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      row.name,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    if (row
                                                        .ageGender
                                                        .isNotEmpty)
                                                      Text(
                                                        row.ageGender,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.7,
                                                              ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              row.wardName,
                                              style: TextStyle(
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              row.bedLabel,
                                              style: TextStyle(
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              row.diagnosis,
                                              style: TextStyle(
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.8),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '${row.daysAdmitted} days',
                                              style: TextStyle(
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.9),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: OutlinedButton.icon(
                                                onPressed: () =>
                                                    _openInpatientView(row),
                                                icon: const Icon(
                                                  Icons.open_in_new,
                                                  size: 16,
                                                ),
                                                label: const Text('Open view'),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
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
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final bool alignRight;

  const _HeaderCell(this.label, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.4,
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );

    return Expanded(
      child: alignRight
          ? Align(alignment: Alignment.centerRight, child: text)
          : text,
    );
  }
}
