import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/paid_without_encounter_invoice.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/invoice_service.dart';
import 'package:helty/src/services/waiting_patient_service.dart';
import 'package:helty/src/widgets/consultation_credit_chip.dart';

enum _CheckInMode { patient, transaction }

enum _CheckInStep { chooseMode, search, pickInvoice, confirm }

/// Multi-step dialog: lookup paid invoice without encounter, check in to triage queue.
class CheckInPatientDialog extends ConsumerStatefulWidget {
  const CheckInPatientDialog({super.key, this.onReEnlisted});

  final VoidCallback? onReEnlisted;

  @override
  ConsumerState<CheckInPatientDialog> createState() =>
      _CheckInPatientDialogState();
}

class _CheckInPatientDialogState extends ConsumerState<CheckInPatientDialog> {
  final _invoiceService = InvoiceService();
  final _waitingService = WaitingPatientService();
  final _searchCtrl = TextEditingController();

  _CheckInStep _step = _CheckInStep.chooseMode;
  _CheckInMode? _mode;
  bool _loading = false;
  bool _submitting = false;
  String? _error;

  List<PaidWithoutEncounterInvoice> _invoiceOptions = [];
  PaidWithoutEncounterInvoice? _selectedInvoice;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _goBack() {
    setState(() {
      _error = null;
      switch (_step) {
        case _CheckInStep.chooseMode:
          break;
        case _CheckInStep.search:
          _step = _CheckInStep.chooseMode;
          _mode = null;
          _searchCtrl.clear();
        case _CheckInStep.pickInvoice:
          _step = _CheckInStep.search;
          _invoiceOptions = [];
        case _CheckInStep.confirm:
          if (_invoiceOptions.length > 1) {
            _step = _CheckInStep.pickInvoice;
          } else {
            _step = _CheckInStep.search;
          }
          _selectedInvoice = null;
      }
    });
  }

  String? _creditSubtitle(PaidWithoutEncounterInvoice inv) {
    final credit = inv.primaryConsultationCredit;
    if (credit == null) return null;
    if (credit.consumable) {
      return 'OPD visit available (${credit.visitsRemaining} left)';
    }
    if (credit.isExpired) return 'Consultation credit expired';
    if (credit.visitsRemaining <= 0) return 'All consultation visits used';
    return '${credit.visitsRemaining} visit(s) remaining';
  }

  void _sortInvoicesByCredit(List<PaidWithoutEncounterInvoice> list) {
    list.sort((a, b) {
      final ca = a.primaryConsultationCredit;
      final cb = b.primaryConsultationCredit;
      final aScore = ca?.consumable == true ? 0 : (ca != null ? 1 : 2);
      final bScore = cb?.consumable == true ? 0 : (cb != null ? 1 : 2);
      return aScore.compareTo(bScore);
    });
  }

  Future<void> _runSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'Please enter an ID to search.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _invoiceOptions = [];
      _selectedInvoice = null;
    });

    try {
      if (_mode == _CheckInMode.patient) {
        final list = await _invoiceService.fetchPaidWithoutEncounter(
          patientId: query,
        );
        if (!mounted) return;
        if (list.isEmpty) {
          setState(() {
            _loading = false;
            _error =
                'No consumable consultation credit was found for this patient.';
          });
          return;
        }
        if (list.length == 1) {
          await _selectInvoice(list.first);
        } else {
          _sortInvoicesByCredit(list);
          setState(() {
            _loading = false;
            _invoiceOptions = list;
            _step = _CheckInStep.pickInvoice;
          });
        }
      } else {
        final invoice = await _invoiceService.getInvoice(query);
        final row = PaidWithoutEncounterInvoice.fromInvoice(invoice);
        if (!mounted) return;
        if (!row.canReEnlist) {
          setState(() {
            _loading = false;
            if (row.hasEncounter) {
              _error =
                  'This transaction already has an encounter and cannot be re-enlisted.';
            } else if (!row.appearsPaid) {
              _error = 'This invoice is not fully paid yet.';
            } else {
              _error = 'This transaction cannot be re-enlisted.';
            }
          });
          return;
        }
        await _selectInvoice(row);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _selectInvoice(PaidWithoutEncounterInvoice invoice) async {
    if (!invoice.canReEnlist) {
      setState(() {
        _loading = false;
        _error = invoice.hasEncounter
            ? 'This invoice already has an encounter.'
            : 'This invoice is not paid.';
      });
      return;
    }
    setState(() {
      _loading = false;
      _selectedInvoice = invoice;
      _step = _CheckInStep.confirm;
      _error = null;
    });
  }

  Future<void> _checkIn() async {
    final invoice = _selectedInvoice;
    if (invoice == null) {
      setState(() => _error = 'Select an invoice to continue.');
      return;
    }

    final staff = ref.read(authProvider).staff;
    final staffId = staff?.id ?? staff?.staffId ?? '';

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _waitingService.reEnlistToQueue(
        invoiceId: invoice.id,
        staffId: staffId.isEmpty ? null : staffId,
      );
      if (!mounted) return;
      widget.onReEnlisted?.call();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${invoice.patientName} checked in — awaiting vitals in triage.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  void _startMode(_CheckInMode mode) {
    setState(() {
      _mode = mode;
      _step = _CheckInStep.search;
      _searchCtrl.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = switch (_step) {
      _CheckInStep.chooseMode => 'Check-In Patient',
      _CheckInStep.search => _mode == _CheckInMode.patient
          ? 'Search by Patient ID'
          : 'Search by Transaction ID',
      _CheckInStep.pickInvoice => 'Select invoice',
      _CheckInStep.confirm => 'Confirm check-in',
    };

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (_step != _CheckInStep.chooseMode)
                    IconButton(
                      onPressed: _submitting ? null : _goBack,
                      icon: const Icon(Icons.arrow_back, size: 20),
                      visualDensity: VisualDensity.compact,
                    ),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                child: switch (_step) {
                  _CheckInStep.chooseMode => _buildModeStep(colorScheme),
                  _CheckInStep.search => _buildSearchStep(colorScheme),
                  _CheckInStep.pickInvoice => _buildPickStep(colorScheme),
                  _CheckInStep.confirm => _buildConfirmStep(colorScheme),
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(fontSize: 12, color: colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeStep(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How would you like to find the patient?',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        _modeCard(
          colorScheme: colorScheme,
          icon: Icons.badge_outlined,
          title: 'Search by Patient ID',
          subtitle: 'Hospital registration number',
          onTap: () => _startMode(_CheckInMode.patient),
        ),
        const SizedBox(height: 12),
        _modeCard(
          colorScheme: colorScheme,
          icon: Icons.receipt_long_outlined,
          title: 'Search by Transaction ID',
          subtitle: 'Invoice or bill number',
          onTap: () => _startMode(_CheckInMode.transaction),
        ),
      ],
    );
  }

  Widget _modeCard({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchStep(ColorScheme colorScheme) {
    final hint = _mode == _CheckInMode.patient
        ? 'Enter patient ID (e.g. HOS-12345)'
        : 'Enter transaction / invoice ID';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchCtrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _loading ? null : _runSearch(),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _loading ? null : _runSearch,
          icon: _loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.search, size: 18),
          label: Text(_loading ? 'Searching…' : 'Search'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickStep(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_invoiceOptions.length} invoices found. Select one to check in.',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        ..._invoiceOptions.map((inv) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _invoiceListTile(colorScheme, inv, () {
              setState(() => _loading = true);
              _selectInvoice(inv);
            }),
          );
        }),
      ],
    );
  }

  Widget _buildConfirmStep(ColorScheme colorScheme) {
    final inv = _selectedInvoice!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                inv.patientName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _summaryRow(colorScheme, 'Bill', inv.billLabel),
              _summaryRow(colorScheme, 'Patient ID', inv.patientId),
              _summaryRow(colorScheme, 'Services', inv.servicesLabel),
              _summaryRow(colorScheme, 'Status', inv.status),
              if (inv.createdAt != null)
                _summaryRow(
                  colorScheme,
                  'Paid',
                  DateFormatter.dateTime(inv.createdAt!.toLocal()),
                ),
              ...() {
                final credit = inv.primaryConsultationCredit;
                if (credit == null) return <Widget>[];
                return [
                  const SizedBox(height: 12),
                  ConsultationCreditChip.fromLine(line: credit),
                  if (credit.consumable)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Consultation credit on file; check in to queue for vitals.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ];
              }(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'The patient will appear in Triage & Vitals as unassigned. '
          'Nursing staff will record vitals and assign a consulting room.',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _submitting ? null : _checkIn,
          icon: _submitting
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.login_rounded, size: 18),
          label: Text(_submitting ? 'Checking in…' : 'Check In'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _invoiceListTile(
    ColorScheme colorScheme,
    PaidWithoutEncounterInvoice inv,
    VoidCallback onTap,
  ) {
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.billLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inv.servicesLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final sub = _creditSubtitle(inv);
                        if (sub == null) return const SizedBox.shrink();
                        final credit = inv.primaryConsultationCredit;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              if (credit != null && credit.consumable)
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                              if (credit != null && credit.consumable)
                                const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  sub,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: credit?.consumable == true
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: credit?.consumable == true
                                        ? colorScheme.primary
                                        : colorScheme.onSurface
                                            .withValues(alpha: 0.55),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(ColorScheme colorScheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
