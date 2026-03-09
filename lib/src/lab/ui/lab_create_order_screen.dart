import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/lab/providers/lab_providers.dart';
import 'package:helty/src/lab/services/lab_api_service.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:helty/src/providers/staff_providers.dart';

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
  final Set<String> _selectedTestIds = {};
  bool _loading = false;
  String? _error;
  List<Patient> _patientSearchResults = [];
  List<Staff> _doctorSearchResults = [];
  bool _searchingPatients = false;
  bool _searchingDoctors = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = ref.watch(labApiServiceProvider);
    final patientService = ref.read(patientServiceProvider);
    final staffService = ref.read(staffServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New lab order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.router.maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                        '${_patient!.surname} ${_patient!.firstName}',
                        style: theme.textTheme.titleSmall,
                      ),
                      subtitle: Text(_patient!.patientId),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _patient = null),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Requesting doctor',
              child: _doctor == null
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
                      subtitle: Text(_doctor!.role),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _doctor = null),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tests.map((t) {
                          final selected = _selectedTestIds.contains(t.id);
                          return FilterChip(
                            label: Text('${t.name} (${t.sampleType})'),
                            selected: selected,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _selectedTestIds.add(t.id);
                                } else {
                                  _selectedTestIds.remove(t.id);
                                }
                              });
                            },
                            selectedColor: theme.colorScheme.primaryContainer,
                            checkmarkColor:
                                theme.colorScheme.onPrimaryContainer,
                          );
                        }).toList(),
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
            FilledButton(
              onPressed: _loading ? null : () => _submit(context, ref),
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
                  : const Text('Create order'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
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
    if (_doctor == null) {
      setState(() {
        _error = 'Select a requesting doctor';
        _loading = false;
      });
      return;
    }
    if (_selectedTestIds.isEmpty) {
      setState(() {
        _error = 'Select at least one test';
        _loading = false;
      });
      return;
    }

    final api = ref.read(labApiServiceProvider);
    final versionIds = <String>[];
    for (final testId in _selectedTestIds) {
      try {
        final test = await api.getTestById(testId);
        final activeVersion = test.versions?.where((v) => v.isActive).firstOrNull;
        if (activeVersion == null) {
          setState(() {
            _error =
                'Test "${test.name}" has no active version. Activate a version in config.';
            _loading = false;
          });
          return;
        }
        versionIds.add(activeVersion.id);
      } catch (e) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
        return;
      }
    }

    try {
      final order = await api.createOrder(
        patientId: patientId,
        doctorId: _doctor!.id,
        testVersionIds: versionIds,
      );
      if (!mounted) return;
      router.replace(LabOrderDetailRoute(orderId: order.id));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
