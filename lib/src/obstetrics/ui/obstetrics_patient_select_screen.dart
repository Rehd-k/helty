import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';

@RoutePage()
class ObstetricsPatientSelectScreen extends ConsumerStatefulWidget {
  const ObstetricsPatientSelectScreen({super.key});

  @override
  ConsumerState<ObstetricsPatientSelectScreen> createState() =>
      _ObstetricsPatientSelectScreenState();
}

class _ObstetricsPatientSelectScreenState
    extends ConsumerState<ObstetricsPatientSelectScreen> {
  final PatientService _patientService = PatientService();
  final TextEditingController _searchController = TextEditingController();
  List<Patient> _patients = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      setState(() {
        _patients = [];
        _error = 'Enter a name or patient ID to search.';
        _searched = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      final list = await _patientService.fetchPatients(
        query: q,
        skip: 0,
        take: 50,
        isAscending: true,
      );
      if (!mounted) return;
      setState(() {
        _patients = list;
        _loading = false;
        if (list.isEmpty) _error = 'No patients found.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _openPregnancies(Patient patient) {
    final id = patient.id ?? patient.patientId;
    context.router.replace(ObstetricsPregnanciesListRoute(patientId: id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select patient (mother)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or patient ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _patients = [];
                      _error = null;
                      _searched = false;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _search,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_loading ? 'Searching...' : 'Search'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
          Expanded(
            child: _searched && _patients.isEmpty && !_loading
                ? Center(
                    child: Text(
                      'No patients found. Try a different search.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _patients.length,
                    itemBuilder: (context, index) {
                      final p = _patients[index];
                      final name =
                          '${p.firstName} ${p.surname}'.trim();
                      final sub = p.patientId;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(
                              Icons.person,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(name.isNotEmpty ? name : 'No name'),
                          subtitle: Text(sub),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openPregnancies(p),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
