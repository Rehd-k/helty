import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/admission_billing_clearance_models.dart';
import 'package:helty/src/models/admission_model.dart';
import 'package:helty/src/providers/admission_clearance_providers.dart';
import 'package:helty/src/services/admission_service.dart';

const _pageSize = 20;

@RoutePage()
class AwaitingNursesClearanceScreen extends ConsumerStatefulWidget {
  const AwaitingNursesClearanceScreen({super.key});

  @override
  ConsumerState<AwaitingNursesClearanceScreen> createState() =>
      _AwaitingNursesClearanceScreenState();
}

class _AwaitingNursesClearanceScreenState
    extends ConsumerState<AwaitingNursesClearanceScreen> {
  final _admissionService = AdmissionService();
  final _searchController = TextEditingController();

  int _skip = 0;
  String? _clearingAdmissionId;
  String? _openingAdmissionId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  PendingClearanceQuery get _query => (skip: _skip, take: _pageSize);

  void _reload() {
    ref.invalidate(pendingNursesClearanceProvider(_query));
  }

  List<AdmissionModel> _filterRows(List<AdmissionModel> rows) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((r) {
      final name = r.patient.displayName.toLowerCase();
      final id = r.patient.patientId.toLowerCase();
      final ward = (r.wardEntity?['name']?.toString() ?? r.ward ?? '')
          .toLowerCase();
      final room = (r.room ?? '').toLowerCase();
      final diagnosis =
          (r.primaryDiagnosis ?? r.provisionalDiagnosis ?? '').toLowerCase();
      final doctor = (r.attendingDoctor?.displayName ?? '').toLowerCase();
      return name.contains(q) ||
          id.contains(q) ||
          ward.contains(q) ||
          room.contains(q) ||
          diagnosis.contains(q) ||
          doctor.contains(q);
    }).toList(growable: false);
  }

  Future<void> _openPatientFile(AdmissionModel row) async {
    if (_openingAdmissionId != null) return;
    setState(() => _openingAdmissionId = row.id);
    try {
      await context.router.push(
        InpatientPatientViewRoute(
          admissionId: row.id,
          ward: row.wardEntity?['name']?.toString() ?? row.ward,
          bedNumber: row.bedPreference ?? row.bed?['bedNumber']?.toString(),
          diagnosis: row.primaryDiagnosis ?? row.provisionalDiagnosis,
        ),
      );
      if (mounted) _reload();
    } catch (e) {
      _showSnack('Failed to open patient file: $e');
    } finally {
      if (mounted) setState(() => _openingAdmissionId = null);
    }
  }

  Future<void> _clearAdmission(AdmissionModel row) async {
    if (_clearingAdmissionId != null) return;
    final billingCleared = row.billingClearedAt != null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear for discharge'),
        content: Text(
          billingCleared
              ? 'Clear nursing for ${row.patient.displayName}? '
                  'This will finalize discharge and move the patient to OPD.'
              : 'Clear nursing for ${row.patient.displayName}? '
                  'Billing is still pending — discharge finalizes only after '
                  'billing clearance too.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearingAdmissionId = row.id);
    try {
      final updated = await _admissionService.nursesClearance(row.id);
      if (!mounted) return;
      final finalized = updated.status.toUpperCase() == 'DISCHARGED' ||
          updated.status.toUpperCase() == 'DECEASED';
      _showSnack(
        finalized
            ? 'Patient cleared and discharged to OPD.'
            : 'Nurse clearance recorded. Awaiting billing clearance.',
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Clear failed: $e');
    } finally {
      if (mounted) setState(() => _clearingAdmissionId = null);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _wardName(AdmissionModel row) =>
      row.wardEntity?['name']?.toString().trim().isNotEmpty == true
          ? row.wardEntity!['name'].toString()
          : (row.ward?.trim().isNotEmpty == true ? row.ward! : '—');

  String _bedOrRoom(AdmissionModel row) {
    final bed = row.bedPreference ?? row.bed?['bedNumber']?.toString();
    if (bed != null && bed.trim().isNotEmpty) return bed.trim();
    if (row.room != null && row.room!.trim().isNotEmpty) return row.room!;
    return '—';
  }

  String _doctorName(AdmissionModel row) {
    final name = row.attendingDoctor?.displayName.trim() ?? '';
    return name.isEmpty ? '—' : name;
  }

  String _billingLabel(AdmissionModel row) {
    if (row.billingClearedAt != null) return 'Billing cleared';
    final billing = row.billing;
    if (billing == null) return 'Awaiting payment';
    if (billing.allPaid) return 'Paid — awaiting billing clear';
    return billing.clearanceStatusLabel;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pendingNursesClearanceProvider(_query));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final compact = bp.isMobile;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitleSection(colorScheme, async, compact),
              const SizedBox(height: 16),
              _buildSearchBar(colorScheme),
              const SizedBox(height: 16),
              Expanded(
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _buildError(colorScheme, e),
                  data: (page) => _buildContent(colorScheme, page, compact),
                ),
              ),
              async.maybeWhen(
                data: (page) => _buildPagination(colorScheme, page),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTitleSection(
    ColorScheme colorScheme,
    AsyncValue<PendingNursesClearancePage> async,
    bool compact,
  ) {
    final total = async.maybeWhen(data: (p) => p.total, orElse: () => null);

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Awaiting Nurses Clearance',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Clinically discharged patients waiting for nursing clearance. '
          'Open the file to chart; clear when ready to finalize.',
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
          Icon(Icons.local_hospital_outlined, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            total == null ? 'Loading...' : '$total pending',
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

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, patient ID, ward, room or doctor',
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
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme colorScheme, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Failed to load nurses clearance queue',
            style: TextStyle(color: colorScheme.error),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    ColorScheme colorScheme,
    PendingNursesClearancePage page,
    bool compact,
  ) {
    final rows = _filterRows(page.admissions);
    if (rows.isEmpty) {
      return Center(
        child: Text(
          page.admissions.isEmpty
              ? 'No patients awaiting nurses clearance.'
              : 'No matches for your search.',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      );
    }

    if (compact) {
      return RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _buildMobileCard(colorScheme, rows[index]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: _buildWideTable(colorScheme, rows),
    );
  }

  Widget _buildWideTable(ColorScheme colorScheme, List<AdmissionModel> rows) {
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
            ),
            child: const Row(
              children: [
                _HeaderCell('PATIENT', flex: 3),
                _HeaderCell('WARD', flex: 2),
                _HeaderCell('BED/ROOM', flex: 1),
                _HeaderCell('DISCHARGED', flex: 2),
                _HeaderCell('DOCTOR', flex: 2),
                _HeaderCell('DIAGNOSIS', flex: 2),
                _HeaderCell('BILLING', flex: 2),
                _HeaderCell('BALANCE', flex: 2, alignRight: true),
                _HeaderCell('ACTIONS', flex: 3, alignRight: true),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.08),
              ),
              itemBuilder: (context, index) =>
                  _buildWideRow(colorScheme, rows[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideRow(ColorScheme colorScheme, AdmissionModel row) {
    final billing = row.billing;
    final balance = billing?.totalBalance ?? 0;
    final billingCleared = row.billingClearedAt != null;
    final isOpening = _openingAdmissionId == row.id;
    final isClearing = _clearingAdmissionId == row.id;
    final diagnosis =
        row.primaryDiagnosis ?? row.provisionalDiagnosis ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.patient.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  row.patient.patientId,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(_wardName(row))),
          Expanded(flex: 1, child: Text(_bedOrRoom(row))),
          Expanded(
            flex: 2,
            child: Text(
              row.dischargeDateTime != null
                  ? DateFormatter.dateTime(row.dischargeDateTime!)
                  : '—',
            ),
          ),
          Expanded(flex: 2, child: Text(_doctorName(row))),
          Expanded(
            flex: 2,
            child: Text(
              diagnosis,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          Expanded(
            flex: 2,
            child: _StatusBadge(
              label: _billingLabel(row),
              ok: billingCleared,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                balance.toFinancial(isMoney: true),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: balance > 0
                      ? colorScheme.error
                      : colorScheme.primary,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed: isOpening ? null : () => _openPatientFile(row),
                    child: isOpening
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Open file'),
                  ),
                  FilledButton(
                    onPressed: isClearing ? null : () => _clearAdmission(row),
                    child: isClearing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Clear for discharge'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCard(ColorScheme colorScheme, AdmissionModel row) {
    final billing = row.billing;
    final balance = billing?.totalBalance ?? 0;
    final billingCleared = row.billingClearedAt != null;
    final isOpening = _openingAdmissionId == row.id;
    final isClearing = _clearingAdmissionId == row.id;
    final diagnosis =
        row.primaryDiagnosis ?? row.provisionalDiagnosis ?? '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.patient.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        row.patient.patientId,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  label: _billingLabel(row),
                  ok: billingCleared,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(label: 'Ward', value: _wardName(row)),
            _InfoLine(label: 'Bed / Room', value: _bedOrRoom(row)),
            _InfoLine(
              label: 'Discharged',
              value: row.dischargeDateTime != null
                  ? DateFormatter.dateTime(row.dischargeDateTime!)
                  : '—',
            ),
            _InfoLine(label: 'Doctor', value: _doctorName(row)),
            _InfoLine(label: 'Diagnosis', value: diagnosis),
            _InfoLine(
              label: 'Balance',
              value: balance.toFinancial(isMoney: true),
              valueColor: balance > 0 ? colorScheme.error : null,
            ),
            if (row.outcome != null && row.outcome!.trim().isNotEmpty)
              _InfoLine(label: 'Outcome', value: row.outcome!),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        isOpening ? null : () => _openPatientFile(row),
                    child: isOpening
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Open file'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        isClearing ? null : () => _clearAdmission(row),
                    child: isClearing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Clear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(
    ColorScheme colorScheme,
    PendingNursesClearancePage page,
  ) {
    final from = page.total == 0 ? 0 : page.skip + 1;
    final to = (page.skip + page.admissions.length).clamp(0, page.total);
    final canPrev = page.skip > 0;
    final canNext = page.skip + page.take < page.total;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Text(
            page.total == 0 ? '0 patients' : 'Showing $from–$to of ${page.total}',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Previous',
            onPressed: canPrev
                ? () {
                    setState(() => _skip = (_skip - _pageSize).clamp(0, 1 << 30));
                    _reload();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Next',
            onPressed: canNext
                ? () {
                    setState(() => _skip = _skip + _pageSize);
                    _reload();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {this.flex = 1, this.alignRight = false});

  final String label;
  final int flex;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = ok ? colorScheme.primary : colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: 13, color: muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
