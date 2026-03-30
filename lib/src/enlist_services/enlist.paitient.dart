import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../paitients/patient_model.dart';
import '../paitients/patient_notifier.dart';
import 'select.user.dart';
import 'selected.user.dart';

@RoutePage()
class EnlistPaitientScreen extends ConsumerStatefulWidget {
  const EnlistPaitientScreen({super.key, required this.serviceName});
  final String serviceName;

  @override
  EnlistPaitientState createState() => EnlistPaitientState();
}

class EnlistPaitientState extends ConsumerState<EnlistPaitientScreen> {
  double spacing = 16.0;
  double runSpacing = 16.0;
  Map<String, dynamic> data = {};
  String serviceName = '';
  late final PatientNotifier _patientNotifier;

  void selectNoIdUser(Map<String, dynamic> res) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      data = res;
    });
    await prefs.setString('noIdPatient', jsonEncode(res));
  }

  void getNoIdPateitn() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getString('noIdPatient') != null) {
        data = jsonDecode(prefs.getString('noIdPatient')!);
      }
    });
  }

  void unselect() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      data = {};
    });
    await prefs.remove('noIdPatient');
  }

  @override
  void initState() {
    super.initState();
    _patientNotifier = ref.read(patientProvider.notifier);
    serviceName = widget.serviceName;
    Future.microtask(() {
      final filter = switch (widget.serviceName) {
        'inpatient' => PatientListStatusFilter.onlyAdmitted,
        'OPD' => PatientListStatusFilter.excludeAdmitted,
        _ => PatientListStatusFilter.none,
      };
      _patientNotifier.setListStatusFilter(filter);
      _patientNotifier.fetchPatients();
    });
    getNoIdPateitn();
  }

  @override
  void dispose() {
    // Do not update Riverpod notifiers synchronously in dispose — it runs while
    // the tree is still tearing down (e.g. logout) and triggers StateNotifierListenerError.
    final notifier = _patientNotifier;
    super.dispose();
    Future.microtask(() {
      notifier.setListStatusFilter(PatientListStatusFilter.none);
    });
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
                serviceName: serviceName,
                onSearch: (String value) {
                  ref
                      .read(patientProvider.notifier)
                      .searchPatients(
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
                  serviceName: serviceName,
                  selectNoIdUser: selectNoIdUser,
                  onSearch: (String value) {
                    ref
                        .read(patientProvider.notifier)
                        .searchPatients(
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
                  onPatientSelected: (Patient value) {
                    ref.read(patientProvider.notifier).selectPatient(value);
                  },
                ),
              ),
              const SizedBox(width: 20),
              if (selectedPatient == null && data.isEmpty)
                const Expanded(flex: 1, child: SizedBox())
              else
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: SelectedPatientCard(
                          noIdPatient: data,
                          unselect: unselect,
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (serviceName == 'Pharmacy') {
                              final staffId =
                                  ref.read(authProvider).staff?.id ?? '';
                              context.router.push(
                                DispenseRoute(
                                  patientId: selectedPatient!.patientId,
                                  patientName:
                                      "${selectedPatient.firstName} ${selectedPatient.surname}",
                                  id: selectedPatient.id ?? '',
                                  staffId: staffId.isEmpty ? null : staffId,
                                ),
                              );
                            } else if (serviceName == 'inpatient') {
                              context.router.push(InpatientBillsListRoute());
                            } else if (serviceName == 'OPD') {
                              context.router.push(RenderServiceRoute());
                            } else if (serviceName == 'Investigation') {
                              context.router.push(RenderServiceRoute());
                            } else if (serviceName == 'Dialysis') {
                              context.router.push(RenderServiceRoute());
                            } else if (serviceName == 'OBGYN') {
                              context.router.push(
                                ObstetricsPregnanciesListRoute(),
                              );
                            } else if (serviceName == 'Radiology') {
                              context.router.push(
                                RadiologyPatientHistoryRoute(
                                  patientId: selectedPatient?.id ?? '',
                                ),
                              );
                            } else if (serviceName == 'lab') {
                              context.router.push(const LabCreateOrderRoute());
                            } else {
                              context.router.push(RenderServiceRoute());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
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
