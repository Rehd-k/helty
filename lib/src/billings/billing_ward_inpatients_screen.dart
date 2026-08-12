import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/models/ward_models.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/invoices_providers.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/services/ward_service.dart';

bool _looksLikeUuid(String s) {
  final t = s.trim();
  return RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(t);
}

bool _wardExcludedFromInpatientList(Ward w) {
  return w.name.trim().toUpperCase() == 'OPD';
}

String _admissionDateLabel(InpatientCensus row) {
  final d = row.admissionDate;
  if (d == null) return '${row.daysAdmitted} days';
  return '${DateFormatter.shortDate(d)} · ${row.daysAdmitted}d';
}

@RoutePage()
class BillingWardInpatientsScreen extends ConsumerStatefulWidget {
  const BillingWardInpatientsScreen({super.key});

  @override
  ConsumerState<BillingWardInpatientsScreen> createState() =>
      _BillingWardInpatientsScreenState();
}

class _BillingWardInpatientsScreenState
    extends ConsumerState<BillingWardInpatientsScreen> {
  final _wardService = WardService();
  final _searchController = TextEditingController();

  List<Ward> _wards = const [];
  Ward? _selectedWard;
  List<InpatientCensus> _rows = const [];
  List<InpatientCensus> _filteredRows = const [];

  bool _isLoadingWards = false;
  bool _isLoadingWardDetails = false;
  String? _openingPatientId;

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
    setState(() => _isLoadingWards = true);
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
      _showError('Failed to load wards: $e');
    } finally {
      if (mounted) setState(() => _isLoadingWards = false);
    }
  }

  Future<void> _loadWardDetails(String wardId) async {
    setState(() => _isLoadingWardDetails = true);
    try {
      final ward = await _wardService.getWardById(wardId);
      if (!mounted) return;
      setState(() {
        _selectedWard = ward;
        _rows = ward.inpatients;
      });
      _applySearch();
    } catch (e) {
      _showError('Failed to load ward patients: $e');
    } finally {
      if (mounted) setState(() => _isLoadingWardDetails = false);
    }
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredRows = _rows);
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
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPatientBilling(InpatientCensus row) async {
    if (_openingPatientId != null) return;

    final patientId = row.patientId.trim();
    if (patientId.isEmpty || !_looksLikeUuid(patientId)) {
      _showError('Patient id unavailable for billing.');
      return;
    }

    setState(() => _openingPatientId = row.id);
    try {
      final invoice = await ref
          .read(invoiceNotifierProvider.notifier)
          .getOrCreateBillingInvoice(
            patientId: patientId,
            staffId: ref.read(authProvider).staff?.id,
            encounterId: row.encounterId,
          );
      if (!mounted) return;
      await context.router.push(
        PatientBillingRoute(invoiceId: invoice.id, patientName: row.name),
      );
    } catch (e) {
      _showError('Failed to open billing: $e');
    } finally {
      if (mounted) setState(() => _openingPatientId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalCount = _filteredRows.length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final compact = bp.isMobile;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitleSection(colorScheme, totalCount, compact),
              SizedBox(height: compact ? 16 : 24),
              _buildFilterSection(colorScheme, compact),
              const SizedBox(height: 16),
              Expanded(
                child: compact
                    ? _buildCompactPatientList(colorScheme)
                    : _buildWidePatientTable(colorScheme),
              ),
            ],
          );
        },
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
          'Admitted Patients',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Browse wards and open inpatient billing for any admitted patient.',
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
            _isLoadingWardDetails ? 'Loading...' : '$totalCount admitted',
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
        hintText: 'Search by name, patient ID or bed',
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

    return Container(
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
  }

  Widget _buildWidePatientTable(ColorScheme colorScheme) {
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
            child: const Row(
              children: [
                _HeaderCell('PATIENT', flex: 3),
                _HeaderCell('WARD', flex: 2),
                _HeaderCell('BED', flex: 1),
                _HeaderCell('DIAGNOSIS', flex: 3),
                _HeaderCell('ADMITTED', flex: 2),
                _HeaderCell('BILLING', flex: 2, alignRight: true),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
          Expanded(child: _wideTableBody(colorScheme)),
        ],
      ),
    );
  }

  Widget _wideTableBody(ColorScheme colorScheme) {
    if (_isLoadingWardDetails) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_selectedWard == null) {
      return Center(
        child: Text(
          'Select a ward to view admitted patients.',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      );
    }
    if (_filteredRows.isEmpty) {
      return Center(
        child: Text(
          'No admitted patients in this ward.',
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
        final isOpening = _openingPatientId == row.id;
        return InkWell(
          onTap: isOpening ? null : () => _openPatientBilling(row),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(flex: 3, child: _patientCell(row, colorScheme)),
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
                    _admissionDateLabel(row),
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
                    child: isOpening
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: () => _openPatientBilling(row),
                            icon: const Icon(Icons.receipt_long, size: 16),
                            label: const Text('Open billing'),
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

  Widget _buildCompactPatientList(ColorScheme colorScheme) {
    if (_isLoadingWardDetails) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }
    if (_selectedWard == null) {
      return Center(
        child: Text(
          'Select a ward to view admitted patients.',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      );
    }
    if (_filteredRows.isEmpty) {
      return Center(
        child: Text(
          'No admitted patients in this ward.',
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
        final isOpening = _openingPatientId == row.id;
        return Material(
          elevation: 0,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isOpening ? null : () => _openPatientBilling(row),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _patientAvatar(row, colorScheme),
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
                        _admissionDateLabel(row),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: isOpening
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: () => _openPatientBilling(row),
                            icon: const Icon(Icons.receipt_long, size: 18),
                            label: const Text('Open billing'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _patientCell(InpatientCensus row, ColorScheme colorScheme) {
    return Row(
      children: [
        _patientAvatar(row, colorScheme),
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
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _patientAvatar(InpatientCensus row, ColorScheme colorScheme) {
    final nameParts = row.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    return PatientAvatar(
      avatarUrl: row.avatarUrl,
      firstName: nameParts.isNotEmpty ? nameParts.first : null,
      surname: nameParts.length > 1 ? nameParts.last : null,
      displayName: row.name,
      size: 32,
      backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
      foregroundColor: colorScheme.primary,
      fontWeight: FontWeight.bold,
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {this.alignRight = false, this.flex = 1});

  final String label;
  final bool alignRight;
  final int flex;

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
