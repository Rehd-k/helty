import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/dialysis/models/dialysis_models.dart';
import 'package:helty/src/dialysis/providers/dialysis_providers.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/module_request_flow_provider.dart';
import 'package:helty/src/providers/staff_providers.dart';

@RoutePage()
class DialysisCreateSessionScreen extends ConsumerStatefulWidget {
  const DialysisCreateSessionScreen({super.key});

  @override
  ConsumerState<DialysisCreateSessionScreen> createState() =>
      _DialysisCreateSessionScreenState();
}

class _DialysisCreateSessionScreenState
    extends ConsumerState<DialysisCreateSessionScreen> {
  Patient? _patient;
  Staff? _doctor;
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  List<Patient> _patientSearchResults = [];
  List<Staff> _doctorSearchResults = [];
  bool _searchingPatients = false;
  bool _searchingDoctors = false;

  PaidInvoiceServiceLine? _selectedInvoiceLine;
  final Map<String, String> _sessionIdByInvoiceItemId = {};
  bool _externalPatientAcknowledged = false;
  String? _invoiceStaffLoadError;
  bool _doctorPrefillRequested = false;

  PaidModuleRequestContext? get _paidContext =>
      ref.read(paidModuleRequestContextProvider);

  bool get _patientLocked =>
      _paidContext?.moduleType == ModuleRequestFlowType.dialysis;

  bool get _needsExternalAck {
    final c = _paidContext;
    if (c?.moduleType != ModuleRequestFlowType.dialysis) return false;
    final id = c!.invoiceStaffId?.trim();
    return id == null || id.isEmpty;
  }

  bool get _externalAckSatisfied =>
      !_needsExternalAck || _externalPatientAcknowledged;

  void _clearPaidContextAndPop(BuildContext context) {
    final ctx = ref.read(paidModuleRequestContextProvider);
    if (ctx?.moduleType == ModuleRequestFlowType.dialysis) {
      ref.read(paidModuleRequestContextProvider.notifier).state = null;
    }
    context.router.maybePop();
  }

  void _selectInvoiceLine(PaidInvoiceServiceLine line) {
    setState(() {
      _selectedInvoiceLine = line;
      _error = null;
    });
  }

  String _formatPatientName(Patient p) {
    final name = p.displayName.trim();
    return name == 'Unknown' ? '—' : name;
  }

  String? _resolvedDoctorId() {
    final fromUi = _doctor?.id.trim();
    if (fromUi != null && fromUi.isNotEmpty) return fromUi;
    return ref.read(authProvider).staff?.id.trim();
  }

  Future<void> _prefillDoctorFromInvoice() async {
    if (!mounted || _doctorPrefillRequested) return;
    _doctorPrefillRequested = true;
    final ctx = ref.read(paidModuleRequestContextProvider);
    final id = ctx?.invoiceStaffId?.trim();
    if (id == null || id.isEmpty) return;
    try {
      final staff = await ref.read(staffServiceProvider).getStaffById(id);
      if (!mounted) return;
      setState(() {
        _doctor = staff;
        _invoiceStaffLoadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _invoiceStaffLoadError =
            'Could not load requesting doctor from the invoice.';
      });
    }
  }

  Future<void> _submit({
    required PaidModuleRequestContext? paidCtx,
    required bool isPaidDialysis,
    required List<PaidInvoiceServiceLine> dialysisLines,
  }) async {
    setState(() {
      _error = null;
      _loading = true;
    });

    final patientId = _patient?.id ?? _patient?.patientId;
    if (patientId == null || patientId.isEmpty) {
      setState(() {
        _error = 'Select a patient';
        _loading = false;
      });
      return;
    }
    if (!_externalAckSatisfied) {
      setState(() {
        _error = 'Confirm external patient (no doctor on invoice)';
        _loading = false;
      });
      return;
    }

    final api = ref.read(dialysisApiServiceProvider);
    final doctorId = _resolvedDoctorId();
    final notes = _notesCtrl.text.trim();

    if (isPaidDialysis) {
      final toCreate = dialysisLines
          .where((l) => !_sessionIdByInvoiceItemId.containsKey(l.invoiceItemId))
          .toList();
      if (toCreate.isEmpty) {
        setState(() {
          _error = 'All invoice lines already have a dialysis session.';
          _loading = false;
        });
        return;
      }

      try {
        DialysisSession? lastSession;
        for (final line in toCreate) {
          final session = await api.createSession(
            patientId: patientId,
            doctorId: doctorId,
            invoiceId: paidCtx?.invoiceId,
            invoiceItemId: line.invoiceItemId,
            serviceId: (line.serviceId?.isNotEmpty ?? false)
                ? line.serviceId
                : null,
            notes: notes.isNotEmpty ? notes : null,
          );
          if (!mounted) return;
          setState(() {
            _sessionIdByInvoiceItemId[line.invoiceItemId] = session.id;
          });
          lastSession = session;
        }

        setState(() => _loading = false);
        if (!mounted) return;

        ref.read(paidModuleRequestContextProvider.notifier).state = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              toCreate.length == 1
                  ? 'Created 1 session.'
                  : 'Created ${toCreate.length} sessions.',
            ),
          ),
        );
        if (lastSession != null) {
          await context.router.push(
            DialysisSessionDetailRoute(sessionId: lastSession.id),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
      return;
    }

    try {
      final session = await api.createSession(
        patientId: patientId,
        doctorId: doctorId,
        notes: notes.isNotEmpty ? notes : null,
      );
      setState(() => _loading = false);
      if (!mounted) return;
      await context.router.push(
        DialysisSessionDetailRoute(sessionId: session.id),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final paidContext = ref.read(paidModuleRequestContextProvider);
    if (paidContext != null &&
        paidContext.moduleType == ModuleRequestFlowType.dialysis &&
        paidContext.patientId.isNotEmpty) {
      var fn = paidContext.patientFirstName?.trim() ?? '';
      var sn = paidContext.patientSurname?.trim() ?? '';
      if (fn.isEmpty && sn.isEmpty) {
        fn = 'Patient';
        sn = 'Selected';
      }
      _patient = Patient(
        id: paidContext.patientId,
        patientId: paidContext.patientId,
        cardNo: '',
        title: '',
        surname: sn,
        firstName: fn,
        dob: DateTime.now(),
        gender: '',
        maritalStatus: '',
        nationality: '',
        stateOfOrigin: '',
        lga: '',
        town: '',
        permanentAddress: '',
      );
      if (dialysisServiceLines(paidContext).isNotEmpty) {
        _selectedInvoiceLine = dialysisServiceLines(paidContext).first;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prefillDoctorFromInvoice();
      });
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paidCtx = ref.watch(paidModuleRequestContextProvider);
    final dialysisLines = dialysisServiceLines(paidCtx);
    final isPaidDialysis =
        paidCtx?.moduleType == ModuleRequestFlowType.dialysis &&
        dialysisLines.isNotEmpty;
    final isPaidDialysisEmptyLines =
        paidCtx?.moduleType == ModuleRequestFlowType.dialysis &&
        paidCtx!.serviceLines.isNotEmpty &&
        dialysisLines.isEmpty;

    final patientService = ref.read(patientServiceProvider);
    final staffService = ref.read(staffServiceProvider);
    final enlistedPatient = ref.watch(patientProvider).selectedPatient;
    if (_patient == null && enlistedPatient != null) {
      _patient = enlistedPatient;
    }

    final selectedLine = _selectedInvoiceLine;
    final currentHasSession =
        selectedLine != null &&
        _sessionIdByInvoiceItemId.containsKey(selectedLine.invoiceItemId);
    final hasInvoiceRequestingStaff =
        paidCtx?.invoiceStaffId?.trim().isNotEmpty ?? false;
    final showDoctorSection = !isPaidDialysis || hasInvoiceRequestingStaff;

    final canSubmit = () {
      if (isPaidDialysisEmptyLines) return false;
      if (!_externalAckSatisfied) return false;
      final pid = _patient?.id ?? _patient?.patientId;
      if (pid == null || pid.isEmpty) return false;
      if (isPaidDialysis) {
        return dialysisLines.any(
          (l) => !_sessionIdByInvoiceItemId.containsKey(l.invoiceItemId),
        );
      }
      return true;
    }();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New dialysis session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _clearPaidContextAndPop(context),
        ),
      ),
      body: ResponsiveBody(
        expand: false,
        builder: (context, bp) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (isPaidDialysisEmptyLines)
              Card(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'This invoice has no dialysis service lines. '
                    'Add dialysis items to the invoice or contact billing.',
                  ),
                ),
              ),
            if (isPaidDialysisEmptyLines) const SizedBox(height: 20),
            if (_needsExternalAck) ...[
              CheckboxListTile(
                value: _externalPatientAcknowledged,
                onChanged: (v) {
                  setState(() => _externalPatientAcknowledged = v ?? false);
                },
                title: const Text('External patient'),
                subtitle: const Text(
                  'I confirm this invoice has no requesting doctor on file.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
            ],
            _SectionCard(
              title: 'Patient',
              child: _patient == null
                  ? _PatientSearchField(
                      onSearch: (q) async {
                        setState(() => _searchingPatients = true);
                        final list = await patientService.fetchPatients(
                          query: q,
                          take: 15,
                          isAscending: true,
                        );
                        if (mounted) {
                          setState(() {
                            _patientSearchResults = list;
                            _searchingPatients = false;
                          });
                        }
                      },
                      results: _patientSearchResults,
                      searching: _searchingPatients,
                      onSelect: (p) => setState(() => _patient = p),
                    )
                  : ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_formatPatientName(_patient!)),
                      subtitle:
                          _patientLocked &&
                              paidCtx != null &&
                              paidCtx.invoiceDisplayId.trim().isNotEmpty
                          ? Text('Invoice ${paidCtx.invoiceDisplayId}')
                          : null,
                      trailing: _patientLocked
                          ? const Icon(Icons.lock_rounded)
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(() => _patient = null),
                            ),
                    ),
            ),
            const SizedBox(height: 20),
            if (showDoctorSection) ...[
              _SectionCard(
                title: isPaidDialysis
                    ? 'Requesting doctor'
                    : 'Requesting doctor (optional)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_invoiceStaffLoadError != null)
                      Text(
                        _invoiceStaffLoadError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    _doctor == null
                        ? _StaffSearchField(
                            onSearch: (q) async {
                              setState(() => _searchingDoctors = true);
                              final list = await staffService.fetchStaff(
                                query: q,
                                limit: 15,
                              );
                              if (mounted) {
                                setState(() {
                                  _doctorSearchResults = list;
                                  _searchingDoctors = false;
                                });
                              }
                            },
                            results: _doctorSearchResults,
                            searching: _searchingDoctors,
                            onSelect: (s) => setState(() => _doctor = s),
                          )
                        : ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_doctor!.fullName),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(() => _doctor = null),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (isPaidDialysis) ...[
              Text(
                'Invoice items (dialysis)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final line in dialysisLines)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(line.serviceName),
                          selected:
                              selectedLine?.invoiceItemId == line.invoiceItemId,
                          onSelected: (_) => _selectInvoiceLine(line),
                          avatar:
                              _sessionIdByInvoiceItemId.containsKey(
                                line.invoiceItemId,
                              )
                              ? const Icon(Icons.check_circle, size: 18)
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
              if (currentHasSession)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton(
                    onPressed: () {
                      final sid =
                          _sessionIdByInvoiceItemId[selectedLine.invoiceItemId];
                      if (sid != null) {
                        context.router.push(
                          DialysisSessionDetailRoute(sessionId: sid),
                        );
                      }
                    },
                    child: const Text('Open existing session for this line'),
                  ),
                ),
              const SizedBox(height: 20),
            ],
            _SectionCard(
              title: 'Notes (optional)',
              child: TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Session notes…',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading || !canSubmit
                  ? null
                  : () => _submit(
                      paidCtx: paidCtx,
                      isPaidDialysis: isPaidDialysis,
                      dialysisLines: dialysisLines,
                    ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isPaidDialysis ? 'Create session(s)' : 'Create session',
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _PatientSearchField extends StatefulWidget {
  const _PatientSearchField({
    required this.onSearch,
    required this.results,
    required this.searching,
    required this.onSelect,
  });

  final Future<void> Function(String query) onSearch;
  final List<Patient> results;
  final bool searching;
  final void Function(Patient patient) onSelect;

  @override
  State<_PatientSearchField> createState() => _PatientSearchFieldState();
}

class _PatientSearchFieldState extends State<_PatientSearchField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            hintText: 'Search patient by name or ID',
            suffixIcon: widget.searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => widget.onSearch(_ctrl.text),
                  ),
          ),
          onSubmitted: widget.onSearch,
        ),
        if (widget.results.isNotEmpty)
          ...widget.results.map(
            (p) => ListTile(
              dense: true,
              leading: PatientAvatar.fromPatient(p, size: 36),
              title: Text('${p.surname} ${p.firstName}'),
              subtitle: Text(p.patientId),
              onTap: () => widget.onSelect(p),
            ),
          ),
      ],
    );
  }
}

class _StaffSearchField extends StatefulWidget {
  const _StaffSearchField({
    required this.onSearch,
    required this.results,
    required this.searching,
    required this.onSelect,
  });

  final Future<void> Function(String query) onSearch;
  final List<Staff> results;
  final bool searching;
  final void Function(Staff staff) onSelect;

  @override
  State<_StaffSearchField> createState() => _StaffSearchFieldState();
}

class _StaffSearchFieldState extends State<_StaffSearchField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            hintText: 'Search doctor / staff',
            suffixIcon: widget.searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => widget.onSearch(_ctrl.text),
                  ),
          ),
          onSubmitted: widget.onSearch,
        ),
        if (widget.results.isNotEmpty)
          ...widget.results.map(
            (s) => ListTile(
              dense: true,
              title: Text(s.fullName),
              onTap: () => widget.onSelect(s),
            ),
          ),
      ],
    );
  }
}
