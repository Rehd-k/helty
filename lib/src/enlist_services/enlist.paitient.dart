import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Map<String, dynamic> data = {};

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
    Future.microtask(() => ref.read(patientProvider.notifier).fetchPatients());
    getNoIdPateitn();
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
                            context.router.push(RenderServiceRoute());
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
