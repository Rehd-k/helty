import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
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
    final name = patient.displayName.trim();
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
    final bp = AppBreakpoints.of(context);
    final useWideSearch = !bp.stackPanels;

    return Scaffold(
      appBar: AppBar(title: const Text('Select patient')),
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) => ResponsiveRowColumn(
          stackWhenWidthBelow: AppBreakpoints.desktopMin,
          firstFlex: 2,
          secondFlex: 1,
          gap: bp.isMobile ? 16 : 20,
          first: SelectUser(
            patients: patients,
            serviceName: 'dialysis',
            onSearch: (value) {
              ref.read(patientProvider.notifier).searchPatients(
                    0,
                    10,
                    value,
                    useWideSearch ? 'nameIdPhonenumber' : 'fullName',
                    null,
                    null,
                    useWideSearch ? 'surname' : 'fullName',
                    true,
                    null,
                  );
            },
            onPatientSelected: (patient) {
              ref.read(patientProvider.notifier).selectPatient(patient);
            },
          ),
          second: selectedPatient == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SelectedPatientCard(),
                    SizedBox(height: bp.isMobile ? 16 : 24),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: () => _onContinue(context, selectedPatient),
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
