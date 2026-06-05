import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/models/ward_models.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/services/ward_service.dart';

@RoutePage()
class InpatientsListScreen extends ConsumerStatefulWidget {
  const InpatientsListScreen({super.key});

  @override
  ConsumerState<InpatientsListScreen> createState() =>
      _InpatientsListScreenState();
}

/// Outpatient department is not an inpatient ward; hide from this census UI.
bool _wardExcludedFromInpatientList(Ward w) {
  return w.name.trim().toUpperCase() == 'OPD';
}

bool _staffIsDoctor(Staff? staff) {
  final role = staff?.staffRole.toLowerCase() ?? '';
  final accountType = staff?.accountType?.name.toLowerCase() ?? '';
  return role == 'doctor' ||
      role == 'consultant' ||
      role == 'resident' ||
      role == 'intern' ||
      role == 'junior_resident' ||
      role == 'senior_resident' ||
      role == 'chief_resident' ||
      role == 'medical_student' ||
      accountType == 'physician' ||
      accountType == 'consultant' ||
      accountType == 'inpatient_doctor';
}

class _InpatientsListScreenState extends ConsumerState<InpatientsListScreen> {
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
      final fetched = await _wardService.fetchWards();
      final wards = fetched
          .where((w) => !_wardExcludedFromInpatientList(w))
          .toList(growable: false);
      setState(() {
        _wards = wards;
        final currentId = _selectedWard?.id;
        final stillValid =
            currentId != null && wards.any((w) => w.id == currentId);
        if (!stillValid) {
          _selectedWard = wards.isNotEmpty ? wards.first : null;
        }
      });
      if (_selectedWard != null) {
        await _loadWardDetails(_selectedWard!.id);
      } else if (mounted) {
        setState(() {
          _rows = const [];
          _filteredRows = const [];
        });
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

  void _openEncounter(InpatientCensus row) {
    final encounterId = row.encounterId;
    if (encounterId == null || encounterId.isEmpty) return;
    if (row.patientId.isEmpty) return;
    context.router.push(
      DoctorEncounterViewRoute(
        encounterId: encounterId,
        patientId: row.patientId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDoctor = _staffIsDoctor(ref.watch(authProvider).staff);

    final totalCount = _filteredRows.length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < kInpatientCompactBreakpoint;
            final pad = compact ? 16.0 : 24.0;

            return Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTitleSection(colorScheme, totalCount, compact),
                  SizedBox(height: compact ? 16 : 24),
                  _buildFilterSection(colorScheme, compact),
                  const SizedBox(height: 16),
                  Expanded(
                    child: compact
                        ? _buildCompactPatientList(colorScheme, isDoctor)
                        : _buildWidePatientTable(colorScheme, isDoctor),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTitleSection(
    ColorScheme colorScheme,
    int totalCount,
    bool compact,
  ) {
    final titleBlock = Column(
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
    );

    final countBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bed, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            _isLoadingWardDetails ? 'Loading...' : '$totalCount Inpatients',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titleBlock, const SizedBox(height: 12), countBadge],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        countBadge,
      ],
    );
  }

  Widget _buildFilterSection(ColorScheme colorScheme, bool compact) {
    final wardDropdown = DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Ward'),
      initialValue: _selectedWard?.id,
      isExpanded: true,
      items: _wards
          .map(
            (w) => DropdownMenuItem<String>(value: w.id, child: Text(w.name)),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        _loadWardDetails(value);
      },
    );

    final searchField = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by name, patient ID or bed (local only)',
        prefixIcon: Icon(
          Icons.search,
          size: 18,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
    );

    final refreshButton = IconButton(
      tooltip: 'Refresh wards',
      onPressed: _isLoadingWards ? null : _loadWards,
      icon: const Icon(Icons.refresh),
    );

    final inner = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                wardDropdown,
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: searchField),
                    refreshButton,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: wardDropdown),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: searchField),
                const SizedBox(width: 12),
                refreshButton,
              ],
            ),
    );

    return inner;
  }

  Widget _buildWidePatientTable(ColorScheme colorScheme, bool isDoctor) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: const [
                _HeaderCell('PATIENT', flex: 3),
                _HeaderCell('WARD', flex: 2),
                _HeaderCell('BED', flex: 1),
                _HeaderCell('DIAGNOSIS', flex: 3),
                _HeaderCell('DAYS ADMITTED', flex: 2),
                _HeaderCell('ACTIONS', flex: 2, alignRight: true),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
          Expanded(child: _wideTableBody(colorScheme, isDoctor)),
        ],
      ),
    );
  }

  Widget _wideTableBody(ColorScheme colorScheme, bool isDoctor) {
    if (_isLoadingWardDetails) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_selectedWard == null) {
      return Center(
        child: Text(
          'Select a ward to view current inpatients.',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      );
    }
    if (_filteredRows.isEmpty) {
      return Center(
        child: Text(
          'No inpatients in this ward.',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      );
    }

    return ListView.separated(
      itemCount: _filteredRows.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: colorScheme.outline.withValues(alpha: 0.06),
      ),
      itemBuilder: (context, index) {
        final row = _filteredRows[index];
        return InkWell(
          onTap: () => _openInpatientView(row),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        child: Text(
                          row.initials,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (row.ageGender.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                row.ageGender,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    row.wardName,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    row.bedLabel,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    row.diagnosis,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${row.daysAdmitted} days',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (isDoctor &&
                            row.encounterId != null &&
                            row.encounterId!.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => _openEncounter(row),
                            icon: const Icon(
                              Icons.medical_information_outlined,
                              size: 16,
                            ),
                            label: const Text('Encounter'),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => _openInpatientView(row),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Open view'),
                        ),
                      ],
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

  Widget _buildCompactPatientList(ColorScheme colorScheme, bool isDoctor) {
    if (_isLoadingWardDetails) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }
    if (_selectedWard == null) {
      return Center(
        child: Text(
          'Select a ward to view current inpatients.',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      );
    }
    if (_filteredRows.isEmpty) {
      return Center(
        child: Text(
          'No inpatients in this ward.',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _filteredRows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final row = _filteredRows[index];
        return Material(
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openInpatientView(row),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        child: Text(
                          row.initials,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (row.ageGender.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                row.ageGender,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        '${row.daysAdmitted} d',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${row.wardName} · Bed ${row.bedLabel}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  if (row.diagnosis.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      row.diagnosis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (isDoctor &&
                          row.encounterId != null &&
                          row.encounterId!.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => _openEncounter(row),
                          icon: const Icon(
                            Icons.medical_information_outlined,
                            size: 18,
                          ),
                          label: const Text('Encounter'),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => _openInpatientView(row),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Open view'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final bool alignRight;
  final int flex;

  const _HeaderCell(this.label, {this.alignRight = false, this.flex = 1});

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
      flex: flex,
      child: alignRight
          ? Align(alignment: Alignment.centerRight, child: text)
          : text,
    );
  }
}
