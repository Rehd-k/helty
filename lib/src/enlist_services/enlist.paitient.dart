import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/paitients/patient_providers.dart';

import '../paitients/patient_model.dart';
import 'select.user.dart';
import 'selected.user.dart';

@RoutePage()
class EnlistPaitientScreen extends ConsumerStatefulWidget {
  const EnlistPaitientScreen({super.key});

  @override
  EnlistPaitientState createState() => EnlistPaitientState();
}

class EnlistPaitientState extends ConsumerState<EnlistPaitientScreen> {
  double spacing = 16.0;
  double runSpacing = 16.0;

  @override
  void initState() {
    super.initState();
    // Fetch patients on load
    Future.microtask(() => ref.read(patientProvider.notifier).fetchPatients());
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientProvider);
    final patients = patientState.patients;
    final selectedPatient = patientState.selectedPatient;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= 1100;

        if (!isWide) {
          return Column(
            children: [
              SelectUser(
                patients: patients,
                onSearch: (String value) {
                  ref
                      .read(patientProvider.notifier)
                      .fetchPatients(query: value);
                },
                onPatientSelected: (Patient value) {
                  ref.read(patientProvider.notifier).selectPatient(value);
                },
              ),
              const SizedBox(height: 20),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: SelectUser(
                  patients: patients,
                  onSearch: (String value) {
                    ref
                        .read(patientProvider.notifier)
                        .fetchPatients(query: value);
                  },
                  onPatientSelected: (Patient value) {
                    ref.read(patientProvider.notifier).selectPatient(value);
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: selectedPatient == null
                    ? const SizedBox()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SelectedPatientCard(),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                context.router.push(RenderServiceRoute());
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    40,
                                  ), // fully rounded
                                ),
                              ),
                              child: const Text(
                                "Continue",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
