import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/enlist_services/select.user.dart';
import 'package:helty/src/enlist_services/selected.user.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_providers.dart';

@RoutePage()
class DialysisSelectPatientScreen extends ConsumerWidget {
  const DialysisSelectPatientScreen({super.key});

  void _onContinue(BuildContext context, Patient patient) {
    final patientUuid = patient.id;
    if (patientUuid == null || patientUuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This patient has no system ID; cannot load encounters.',
          ),
        ),
      );
      return;
    }
    final name = '${patient.firstName} ${patient.surname}'.trim();
    context.router.push(
      DialysisPatientEncountersRoute(
        patientId: patientUuid,
        patientName: name.isNotEmpty ? name : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientState = ref.watch(patientProvider);
    final patients = patientState.patients;
    final selectedPatient = patientState.selectedPatient;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1100;

        if (!isWide) {
          return Scaffold(
            appBar: AppBar(title: const Text('Select patient')),
            body: Column(
              children: [
                SelectUser(
                  patients: patients,
                  serviceName: 'dialysis',
                  onSearch: (value) {
                    ref.read(patientProvider.notifier).searchPatients(
                          0,
                          10,
                          value,
                          'fullName',
                          null,
                          null,
                          'fullName',
                          true,
                          null,
                        );
                  },
                  onPatientSelected: (patient) {
                    ref.read(patientProvider.notifier).selectPatient(patient);
                  },
                ),
                if (selectedPatient != null) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: SelectedPatientCard(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: () => _onContinue(context, selectedPatient),
                        child: const Text('Continue'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Select patient')),
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SelectUser(
                    patients: patients,
                    serviceName: 'dialysis',
                    onSearch: (value) {
                      ref.read(patientProvider.notifier).searchPatients(
                            0,
                            10,
                            value,
                            'nameIdPhonenumber',
                            null,
                            null,
                            'surname',
                            true,
                            null,
                          );
                    },
                    onPatientSelected: (patient) {
                      ref.read(patientProvider.notifier).selectPatient(patient);
                    },
                  ),
                ),
                const SizedBox(width: 20),
                if (selectedPatient == null)
                  const Expanded(flex: 1, child: SizedBox())
                else
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: SelectedPatientCard(),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: () =>
                                _onContinue(context, selectedPatient),
                            child: const Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
