import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/providers/lab_providers.dart';
import 'package:helty/src/lab/services/lab_api_service.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/module_request_flow_provider.dart';
import 'package:helty/src/providers/staff_providers.dart';

bool _isLabCategoryName(String name) {
  final c = name.toLowerCase().trim();
  return c == 'laboratory' || c == 'laboratory tests';
}

List<PaidInvoiceServiceLine> _labServiceLines(PaidModuleRequestContext? ctx) {
  if (ctx == null) return const [];
  return ctx.serviceLines.where((l) => _isLabCategoryName(l.categoryName)).toList();
}

LabTestVersion? _activeLabVersion(LabTest test) {
  for (final v in test.versions ?? const <LabTestVersion>[]) {
    if (v.isActive) return v;
  }
  return null;
}

@RoutePage()
class LabCreateOrderScreen extends ConsumerStatefulWidget {
  const LabCreateOrderScreen({super.key});

  @override
  ConsumerState<LabCreateOrderScreen> createState() =>
      _LabCreateOrderScreenState();
}

class _LabCreateOrderScreenState extends ConsumerState<LabCreateOrderScreen> {
  Patient? _patient;
  Staff? _doctor;
  /// Non–invoice flows (e.g. enlist) only.
  final Set<String> _selectedTestIds = {};
  /// Paid lab: test ids per invoice line.
  final Map<String, Set<String>> _testIdsByInvoiceItemId = {};
  /// Standard flow: AST requested per test id.
  final Map<String, bool> _astRequestedByTestId = {};
  /// Paid lab: AST requested per invoice line and test id.
  final Map<String, Map<String, bool>> _astRequestedByInvoiceItemAndTestId =
      {};
  bool _loading = false;
  String? _error;
  List<Patient> _patientSearchResults = [];
  List<Staff> _doctorSearchResults = [];
  bool _searchingPatients = false;
  bool _searchingDoctors = false;
  String _testSearchQuery = '';
  String? _selectedCategoryId;

  PaidInvoiceServiceLine? _selectedInvoiceLine;
  final Map<String, String> _orderIdByInvoiceItemId = {};
  final Map<String, LabOrder> _orderDetailByInvoiceItemId = {};
  bool _externalPatientAcknowledged = false;
  String? _invoiceStaffLoadError;
  bool _doctorPrefillRequested = false;

  PaidModuleRequestContext? get _paidContext =>
      ref.read(paidModuleRequestContextProvider);

  bool get _patientLocked =>
      _paidContext?.moduleType == ModuleRequestFlowType.laboratory;

  bool get _needsExternalAck {
    final c = _paidContext;
    if (c?.moduleType != ModuleRequestFlowType.laboratory) return false;
    final id = c!.invoiceStaffId?.trim();
    return id == null || id.isEmpty;
  }

  bool get _externalAckSatisfied =>
      !_needsExternalAck || _externalPatientAcknowledged;

  /// Clears paid lab context when leaving via the app bar. Do not call [ref]
  /// from [dispose] — it throws after logout/navigation tears down the tree.
  void _clearPaidLabContextAndPop(BuildContext context) {
    final ctx = ref.read(paidModuleRequestContextProvider);
    if (ctx?.moduleType == ModuleRequestFlowType.laboratory) {
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

  void _toggleTestId(String testId, {required bool isPaidLab}) {
    setState(() {
      if (isPaidLab && _selectedInvoiceLine != null) {
        final itemId = _selectedInvoiceLine!.invoiceItemId;
        final set =
            _testIdsByInvoiceItemId.putIfAbsent(itemId, () => <String>{});
        if (set.contains(testId)) {
          set.remove(testId);
          _astRequestedByInvoiceItemAndTestId[itemId]?.remove(testId);
        } else {
          set.add(testId);
        }
      } else {
        if (_selectedTestIds.contains(testId)) {
          _selectedTestIds.remove(testId);
          _astRequestedByTestId.remove(testId);
        } else {
          _selectedTestIds.add(testId);
        }
      }
    });
  }

  bool _isAstRequested(
    String testId, {
    required bool isPaidLab,
    String? invoiceItemId,
  }) {
    if (isPaidLab && invoiceItemId != null) {
      return _astRequestedByInvoiceItemAndTestId[invoiceItemId]?[testId] ??
          false;
    }
    return _astRequestedByTestId[testId] ?? false;
  }

  void _setAstRequested(
    String testId,
    bool value, {
    required bool isPaidLab,
    String? invoiceItemId,
  }) {
    setState(() {
      if (isPaidLab && invoiceItemId != null) {
        _astRequestedByInvoiceItemAndTestId
            .putIfAbsent(invoiceItemId, () => {})[testId] = value;
      } else {
        _astRequestedByTestId[testId] = value;
      }
    });
  }

  String _formatPatientName(Patient p) {
    final name = p.displayName.trim();
    return name == 'Unknown' ? '—' : name;
  }

  /// Signed-in staff used when no requesting doctor is chosen.
  String? _resolvedDoctorId(WidgetRef ref) {
    final fromUi = _doctor?.id.trim();
    if (fromUi != null && fromUi.isNotEmpty) return fromUi;
    return ref.read(authProvider).staff?.id.trim();
  }

  bool _canSubmit({
    required bool isPaidLab,
    required List<PaidInvoiceServiceLine> labLines,
    required bool isPaidLabEmptyLines,
  }) {
    if (isPaidLabEmptyLines) return false;
    if (!_externalAckSatisfied) return false;
    final patientId = _patient?.id ?? _patient?.patientId;
    if (patientId == null || patientId.isEmpty) return false;
    if (!isPaidLab) {
      return _selectedTestIds.isNotEmpty;
    }
    for (final line in labLines) {
      if (_orderIdByInvoiceItemId.containsKey(line.invoiceItemId)) continue;
      final ids = _testIdsByInvoiceItemId[line.invoiceItemId] ?? {};
      if (ids.isNotEmpty) return true;
    }
    return false;
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
            'Could not load requesting doctor from the invoice. Search to select.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paidCtx = ref.watch(paidModuleRequestContextProvider);
    final labLines = _labServiceLines(paidCtx);
    final isPaidLab =
        paidCtx?.moduleType == ModuleRequestFlowType.laboratory &&
        labLines.isNotEmpty;
    final isPaidLabEmptyLines =
        paidCtx?.moduleType == ModuleRequestFlowType.laboratory &&
        paidCtx!.serviceLines.isNotEmpty &&
        labLines.isEmpty;

    final api = ref.watch(labApiServiceProvider);
    final patientService = ref.read(patientServiceProvider);
    final staffService = ref.read(staffServiceProvider);

    final enlistedPatient = ref.watch(patientProvider).selectedPatient;
    if (_patient == null && enlistedPatient != null) {
      _patient = enlistedPatient;
    }

    final selectedLine = _selectedInvoiceLine;
    final currentItemId = selectedLine?.invoiceItemId;
    final currentHasOrder =
        currentItemId != null &&
        _orderIdByInvoiceItemId.containsKey(currentItemId);

    final hasInvoiceRequestingStaff =
        paidCtx?.invoiceStaffId?.trim().isNotEmpty ?? false;
    final showRequestingDoctorSection =
        !isPaidLab || hasInvoiceRequestingStaff;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New lab order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _clearPaidLabContextAndPop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isPaidLabEmptyLines)
              Card(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: theme.colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This invoice has no laboratory service lines. '
                          'Add laboratory items to the invoice or contact billing.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (isPaidLabEmptyLines) const SizedBox(height: 20),
            if (_needsExternalAck) ...[
              Material(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                child: CheckboxListTile(
                  value: _externalPatientAcknowledged,
                  onChanged: (v) {
                    setState(() => _externalPatientAcknowledged = v ?? false);
                  },
                  title: const Text('External patient'),
                  subtitle: const Text(
                    'I confirm this invoice has no requesting doctor on file '
                    '(external / walk-in billing).',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(height: 16),
            ],
            _SectionCard(
              title: 'Patient',
              child: _patient == null
                  ? _SearchField(
                      hint: 'Search patient by name or ID',
                      onSearch: (q) async {
                        setState(() {
                          _searchingPatients = true;
                        });
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
                      suggestions: _patientSearchResults,
                      searching: _searchingPatients,
                      suggestionTitle: (p) =>
                          '${p.surname} ${p.firstName} (${p.patientId})',
                      onSelect: (p) => setState(() => _patient = p),
                    )
                  : ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _formatPatientName(_patient!),
                        style: theme.textTheme.titleSmall,
                      ),
                      subtitle: _patientLocked &&
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
            if (showRequestingDoctorSection) ...[
              _SectionCard(
                title: isPaidLab
                    ? 'Requesting doctor'
                    : 'Requesting doctor (optional)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isPaidLab)
                      Text(
                        'If left empty, your signed-in account is used when the server requires a doctor id.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (!isPaidLab) const SizedBox(height: 12),
                    if (_invoiceStaffLoadError != null) ...[
                      Text(
                        _invoiceStaffLoadError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _doctor == null
                        ? _SearchField<Staff>(
                            hint: 'Search doctor / staff',
                            onSearch: (q) async {
                              setState(() {
                                _searchingDoctors = true;
                              });
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
                            suggestions: _doctorSearchResults,
                            searching: _searchingDoctors,
                            suggestionTitle: (s) => s.fullName,
                            onSelect: (s) => setState(() => _doctor = s),
                          )
                        : ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _doctor!.fullName,
                              style: theme.textTheme.titleSmall,
                            ),
                            subtitle: Text(_doctor!.staffRole),
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
            if (isPaidLab && currentHasOrder && selectedLine != null) ...[
              _ExistingOrderForLineCard(
                orderId: _orderIdByInvoiceItemId[selectedLine.invoiceItemId]!,
                cached: _orderDetailByInvoiceItemId[selectedLine.invoiceItemId],
                api: api,
                onLoaded: (order) {
                  setState(() {
                    _orderDetailByInvoiceItemId[selectedLine.invoiceItemId] =
                        order;
                  });
                },
                onOpenDetail: () {
                  final oid =
                      _orderIdByInvoiceItemId[selectedLine.invoiceItemId];
                  if (oid != null) {
                    context.router.push(LabOrderDetailRoute(orderId: oid));
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
            if (isPaidLab) ...[
              Text(
                'Invoice items (laboratory)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final line in labLines)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            line.serviceName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: selectedLine?.invoiceItemId == line.invoiceItemId,
                          onSelected: (_) => _selectInvoiceLine(line),
                          avatar: _orderIdByInvoiceItemId
                                  .containsKey(line.invoiceItemId)
                              ? const Icon(Icons.check_circle, size: 18)
                              : ((_testIdsByInvoiceItemId[line.invoiceItemId]
                                          ?.isNotEmpty ??
                                      false)
                                  ? const Icon(Icons.science_outlined, size: 18)
                                  : null),
                        ),
                      ),
                  ],
                ),
              ),
              if (_orderIdByInvoiceItemId.length == labLines.length)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'All ${labLines.length} invoice line(s) have a lab order.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
            if (!isPaidLab || !currentHasOrder)
              _SectionCard(
                title: 'Tests',
                child: FutureBuilder<LabTestsResponse>(
                  future: api.getTests(isActive: true, take: 500),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final tests = snapshot.data!.data;
                    if (tests.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No active lab tests configured.'),
                        ),
                      );
                    }

                    final activeTestIds = isPaidLab && selectedLine != null
                        ? (_testIdsByInvoiceItemId[selectedLine.invoiceItemId] ??
                            <String>{})
                        : _selectedTestIds;

                    final Map<String, List<LabTest>> byCategory = {};
                    for (final t in tests) {
                      final key = t.category?.name ?? 'Other';
                      byCategory.putIfAbsent(key, () => []).add(t);
                    }
                    final categoryEntries = byCategory.entries.toList()
                      ..sort((a, b) => a.key.compareTo(b.key));

                    final selectedCategoryName = _selectedCategoryId;

                    List<LabTest> filtered = tests;
                    if (selectedCategoryName != null &&
                        byCategory.containsKey(selectedCategoryName)) {
                      filtered = byCategory[selectedCategoryName]!;
                    }
                    if (_testSearchQuery.trim().isNotEmpty) {
                      final q = _testSearchQuery.trim().toLowerCase();
                      filtered = filtered.where((t) {
                        final inName = t.name.toLowerCase().contains(q);
                        final inSample = t.sampleType.toLowerCase().contains(q);
                        final inCategory =
                            (t.category?.name.toLowerCase() ?? '').contains(q);
                        return inName || inSample || inCategory;
                      }).toList();
                    }

                    filtered.sort((a, b) => a.name.compareTo(b.name));

                    final selectedTests = tests
                        .where((t) => activeTestIds.contains(t.id))
                        .toList()
                      ..sort((a, b) => a.name.compareTo(b.name));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText:
                                'Search tests by name, sample or category',
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (v) {
                            setState(() {
                              _testSearchQuery = v;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: const Text('All'),
                                selected: selectedCategoryName == null,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedCategoryId = null;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              ...categoryEntries.map((entry) {
                                final selected =
                                    selectedCategoryName == entry.key;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text(
                                        '${entry.key} (${entry.value.length})'),
                                    selected: selected,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedCategoryId = selected
                                            ? null
                                            : entry.key;
                                      });
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxHeight: 320),
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                                child: filtered.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Text(
                                            'No tests match your filters.',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final t = filtered[index];
                                          final selected =
                                              activeTestIds.contains(t.id);
                                          return ListTile(
                                            dense: true,
                                            onTap: () {
                                              _toggleTestId(
                                                t.id,
                                                isPaidLab: isPaidLab,
                                              );
                                            },
                                            leading: Checkbox(
                                              value: selected,
                                              onChanged: (v) {
                                                _toggleTestId(
                                                  t.id,
                                                  isPaidLab: isPaidLab,
                                                );
                                              },
                                            ),
                                            title: Text(
                                              t.name,
                                              style: theme
                                                  .textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Text(
                                              [
                                                t.sampleType,
                                                if (t.category != null)
                                                  t.category!.name,
                                              ].where((e) => e.isNotEmpty).join(
                                                    ' • ',
                                                  ),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            trailing: (paidCtx == null &&
                                                    t.price != null)
                                                ? Text(
                                                    t.price!.toStringAsFixed(2),
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: theme.colorScheme
                                                          .primary,
                                                    ),
                                                  )
                                                : null,
                                          );
                                        },
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected tests (${selectedTests.length})',
                                    style:
                                        theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (selectedTests.isEmpty)
                                    Text(
                                      'No tests selected yet.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    )
                                  else
                                    Container(
                                      constraints: const BoxConstraints(
                                          maxHeight: 220),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: theme
                                              .colorScheme.outlineVariant,
                                        ),
                                      ),
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: selectedTests.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final t = selectedTests[index];
                                          final invoiceItemId =
                                              selectedLine?.invoiceItemId;
                                          final astRequested = _isAstRequested(
                                            t.id,
                                            isPaidLab: isPaidLab,
                                            invoiceItemId: invoiceItemId,
                                          );
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              ListTile(
                                                dense: true,
                                                title: Text(
                                                  t.name,
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  t.sampleType,
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: theme.colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                                trailing: IconButton(
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                    size: 18,
                                                  ),
                                                  onPressed: () {
                                                    _toggleTestId(
                                                      t.id,
                                                      isPaidLab: isPaidLab,
                                                    );
                                                  },
                                                ),
                                              ),
                                              CheckboxListTile(
                                                dense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                ),
                                                title: Text(
                                                  'Include AST (antibiotic susceptibility)',
                                                  style: theme
                                                      .textTheme.bodySmall,
                                                ),
                                                value: astRequested,
                                                onChanged: (v) {
                                                  _setAstRequested(
                                                    t.id,
                                                    v ?? false,
                                                    isPaidLab: isPaidLab,
                                                    invoiceItemId:
                                                        invoiceItemId,
                                                  );
                                                },
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 32),
            if (!currentHasOrder || !isPaidLab)
              FilledButton(
                onPressed: _loading ||
                        !_canSubmit(
                          isPaidLab: isPaidLab,
                          labLines: labLines,
                          isPaidLabEmptyLines: isPaidLabEmptyLines,
                        )
                    ? null
                    : () => _submit(context, ref, paidCtx),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isPaidLab && labLines.length > 1
                            ? 'Create order(s)'
                            : 'Create order',
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Future<List<LabOrderItemInput>?> _buildOrderItems(
    LabApiService api,
    List<String> testIdsInOrder,
    bool Function(String testId) astRequestedFor,
  ) async {
    final items = <LabOrderItemInput>[];
    for (final testId in testIdsInOrder) {
      try {
        final test = await api.getTestById(testId);
        final activeVersion = _activeLabVersion(test);
        if (activeVersion == null) {
          if (mounted) {
            setState(() {
              _error =
                  'Test "${test.name}" has no active version. Activate a version in config.';
              _loading = false;
            });
          }
          return null;
        }
        items.add(
          LabOrderItemInput(
            testVersionId: activeVersion.id,
            astRequested: astRequestedFor(testId),
          ),
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _loading = false;
          });
        }
        return null;
      }
    }
    return items;
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    PaidModuleRequestContext? paidCtx,
  ) async {
    final router = context.router;
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

    final api = ref.read(labApiServiceProvider);
    final doctorId = _resolvedDoctorId(ref);

    if (paidCtx?.moduleType == ModuleRequestFlowType.laboratory) {
      final labLines = _labServiceLines(paidCtx);
      if (labLines.isEmpty) {
        setState(() {
          _error = 'No laboratory lines on this invoice';
          _loading = false;
        });
        return;
      }

      final toCreate = <PaidInvoiceServiceLine>[];
      for (final line in labLines) {
        if (_orderIdByInvoiceItemId.containsKey(line.invoiceItemId)) continue;
        final ids = _testIdsByInvoiceItemId[line.invoiceItemId] ?? {};
        if (ids.isNotEmpty) toCreate.add(line);
      }

      if (toCreate.isEmpty) {
        setState(() {
          _error =
              'Select tests for at least one invoice line that does not already have an order.';
          _loading = false;
        });
        return;
      }

      try {
        LabOrder? lastOrder;
        for (final line in toCreate) {
          final ids = _testIdsByInvoiceItemId[line.invoiceItemId]!;
          final items = await _buildOrderItems(
            api,
            ids.toList()..sort(),
            (testId) => _isAstRequested(
              testId,
              isPaidLab: true,
              invoiceItemId: line.invoiceItemId,
            ),
          );
          if (items == null || !mounted) return;

          final order = await api.createOrder(
            patientId: patientId,
            doctorId: doctorId,
            items: items,
            invoiceId: paidCtx?.invoiceId,
            invoiceItemId: line.invoiceItemId,
            serviceId: (line.serviceId?.isNotEmpty ?? false)
                ? line.serviceId
                : null,
          );

          if (!mounted) return;
          setState(() {
            _orderIdByInvoiceItemId[line.invoiceItemId] = order.id;
            _orderDetailByInvoiceItemId[line.invoiceItemId] = order;
          });
          lastOrder = order;
        }

        setState(() => _loading = false);

        if (!mounted) return;
        final n = toCreate.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              n == 1 ? 'Created 1 order.' : 'Created $n orders.',
            ),
          ),
        );
        if (lastOrder != null) {
          await router.push(LabOrderDetailRoute(orderId: lastOrder.id));
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

    if (_selectedTestIds.isEmpty) {
      setState(() {
        _error = 'Select at least one test';
        _loading = false;
      });
      return;
    }

    final items = await _buildOrderItems(
      api,
      _selectedTestIds.toList()..sort(),
      (testId) => _isAstRequested(testId, isPaidLab: false),
    );
    if (items == null || !mounted) return;

    try {
      final order = await api.createOrder(
        patientId: patientId,
        doctorId: doctorId,
        items: items,
        invoiceId: paidCtx?.invoiceId,
      );
      setState(() => _loading = false);
      if (!mounted) return;
      await router.push(LabOrderDetailRoute(orderId: order.id));
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
        paidContext.moduleType == ModuleRequestFlowType.laboratory &&
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
    }
    final ctx = ref.read(paidModuleRequestContextProvider);
    final lines = _labServiceLines(ctx);
    if (lines.isNotEmpty) {
      _selectedInvoiceLine = lines.first;
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _prefillDoctorFromInvoice());
  }
}

class _ExistingOrderForLineCard extends StatefulWidget {
  const _ExistingOrderForLineCard({
    required this.orderId,
    required this.cached,
    required this.api,
    required this.onLoaded,
    required this.onOpenDetail,
  });

  final String orderId;
  final LabOrder? cached;
  final LabApiService api;
  final void Function(LabOrder order) onLoaded;
  final VoidCallback onOpenDetail;

  @override
  State<_ExistingOrderForLineCard> createState() =>
      _ExistingOrderForLineCardState();
}

class _ExistingOrderForLineCardState extends State<_ExistingOrderForLineCard> {
  bool _dispatchedLoad = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.cached;

    return _SectionCard(
      title: 'Order for this invoice line',
      child: order != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: ${order.status.apiValue}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order ID: ${order.id}',
                  style: theme.textTheme.bodySmall,
                ),
                if (order.items.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tests:',
                    style: theme.textTheme.labelMedium,
                  ),
                  ...order.items.map(
                    (it) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '• ${it.testVersion?.test?.name ?? 'Test'}'
                        '${it.astRequested ? ' (AST)' : ''}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: widget.onOpenDetail,
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('View full order'),
                ),
              ],
            )
          : FutureBuilder<LabOrder>(
              future: widget.api.getOrderById(widget.orderId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Text(
                    'Could not load order.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  );
                }
                final o = snapshot.data!;
                if (!_dispatchedLoad) {
                  _dispatchedLoad = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    widget.onLoaded(o);
                  });
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: ${o.status.apiValue}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Order ID: ${o.id}', style: theme.textTheme.bodySmall),
                    if (o.items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Tests:', style: theme.textTheme.labelMedium),
                      ...o.items.map(
                        (it) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '• ${it.testVersion?.test?.name ?? 'Test'}'
                            '${it.astRequested ? ' (AST)' : ''}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                    TextButton.icon(
                      onPressed: widget.onOpenDetail,
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text('View full order'),
                    ),
                  ],
                );
              },
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
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

class _SearchField<T> extends StatelessWidget {
  const _SearchField({
    required this.hint,
    required this.onSearch,
    required this.suggestions,
    required this.searching,
    required this.suggestionTitle,
    required this.onSelect,
  });

  final String hint;
  final void Function(String) onSearch;
  final List<T> suggestions;
  final bool searching;
  final String Function(T) suggestionTitle;
  final void Function(T) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (v) => onSearch(v),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, i) {
                final s = suggestions[i];
                return ListTile(
                  title: Text(suggestionTitle(s)),
                  onTap: () => onSelect(s),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
