import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';

import '../../../app_router.gr.dart';
import '../../enlist_services/select.user.dart';
import '../../enlist_services/selected.user.dart';
import '../../paitients/patient_model.dart';
import '../../paitients/patient_providers.dart';

@RoutePage()
class PatientHubSearchScreen extends ConsumerWidget {
  const PatientHubSearchScreen({super.key});

  void _openHub(BuildContext context, Patient patient) {
    final uuid = patient.id;
    if (uuid == null || uuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This patient has no system ID; cannot open hub.'),
        ),
      );
      return;
    }
    context.router.push(PatientHubRoute(patientUuid: uuid));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientState = ref.watch(patientProvider);
    final patients = patientState.patients;
    final selectedPatient = patientState.selectedPatient;

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Hub')),
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final useWideSearch = bp.isDesktop;

          Widget buildSelectUser() {
            return SelectUser(
              patients: patients,
              serviceName: 'patient_hub',
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
            );
          }

          Widget buildActionPanel() {
            if (selectedPatient == null) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SelectedPatientCard(),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: () => _openHub(context, selectedPatient),
                    child: const Text('Open patient hub'),
                  ),
                ),
              ],
            );
          }

          if (bp.isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: buildSelectUser()),
                if (selectedPatient != null) ...[
                  const SizedBox(height: 16),
                  buildActionPanel(),
                  const SizedBox(height: 16),
                ],
              ],
            );
          }

          return ResponsiveRowColumn(
            stackWhenWidthBelow: AppBreakpoints.desktopMin,
            firstFlex: 2,
            secondFlex: 1,
            gap: 20,
            first: buildSelectUser(),
            second: buildActionPanel(),
          );
        },
      ),
    );
  }
}
