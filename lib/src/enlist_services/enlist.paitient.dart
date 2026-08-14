import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/billings/parked_billing_session.dart';
import 'package:helty/src/billings/widgets/parked_billing_chips_bar.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/module_request_flow_provider.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/providers/parked_billing_provider.dart';
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
      // _patientNotifier.fetchPatients();
    });
  }

  void _resumeParkedSession(ParkedBillingSession session) {
    ref.read(billingRestoreProvider.notifier).state = session;
    ref.read(parkedBillingProvider.notifier).remove(session.id);
    ref.read(moduleRequestFlowProvider.notifier).state = session.flowConfig;
    ref.read(patientProvider.notifier).selectPatient(session.patient);
    context.router.push(const RenderServiceRoute());
  }

  void _onContinue(Patient? selectedPatient) {
    final moduleFlowNotifier = ref.read(moduleRequestFlowProvider.notifier);
    final defaultOrHmo = ref.read(authProvider).staff?.accountType ==
            AccountType.hmo
        ? const ModuleRequestFlowConfig(type: ModuleRequestFlowType.hmo)
        : ModuleRequestFlowConfig.defaultBilling;
    if (serviceName == 'Pharmacy') {
      moduleFlowNotifier.state = ModuleRequestFlowConfig.defaultBilling;
      final staffId = ref.read(authProvider).staff?.id ?? '';
      context.router.push(
        DispenseRoute(
          patientId: selectedPatient!.patientId,
          patientName: selectedPatient.displayName,
          id: selectedPatient.id ?? '',
          staffId: staffId.isEmpty ? null : staffId,
        ),
      );
    } else if (serviceName == 'inpatient') {
      moduleFlowNotifier.state = defaultOrHmo;
      context.router.push(InpatientBillsListRoute());
    } else if (serviceName == 'billing_account') {
      moduleFlowNotifier.state = defaultOrHmo;
      context.router.push(const PatientBillingAccountRoute());
    } else if (serviceName == 'OPD') {
      moduleFlowNotifier.state = defaultOrHmo;
      context.router.push(RenderServiceRoute());
    } else if (serviceName == 'Investigation') {
      moduleFlowNotifier.state = defaultOrHmo;
      context.router.push(RenderServiceRoute());
    } else if (serviceName == 'Dialysis' || serviceName == 'dialysis') {
      moduleFlowNotifier.state = const ModuleRequestFlowConfig(
        type: ModuleRequestFlowType.dialysis,
        forcedCategoryNames: ['Dialysis', 'Dialysis Services'],
        hideServicePrices: true,
        sendToBillOnly: true,
      );
      context.router.push(RenderServiceRoute());
    } else if (serviceName == 'OBGYN') {
      moduleFlowNotifier.state = ModuleRequestFlowConfig.defaultBilling;
      context.router.push(ObstetricsPregnanciesListRoute());
    } else if (serviceName == 'OBGYN_GYNAE') {
      moduleFlowNotifier.state = ModuleRequestFlowConfig.defaultBilling;
      context.router.push(
        ObstetricsGynaeProceduresRoute(patientId: selectedPatient!.id),
      );
    } else if (serviceName == 'Radiology') {
      moduleFlowNotifier.state = const ModuleRequestFlowConfig(
        type: ModuleRequestFlowType.radiology,
        forcedCategoryNames: ['Radiology & Imaging'],
        hideServicePrices: true,
        sendToBillOnly: true,
      );
      context.router.push(RenderServiceRoute());
    } else if (serviceName == 'lab') {
      moduleFlowNotifier.state = const ModuleRequestFlowConfig(
        type: ModuleRequestFlowType.laboratory,
        forcedCategoryNames: ['Laboratory', 'Laboratory Tests'],
        hideServicePrices: true,
        sendToBillOnly: true,
      );
      context.router.push(RenderServiceRoute());
    } else if (serviceName == 'Consumables') {
      moduleFlowNotifier.state = ModuleRequestFlowConfig.defaultBilling;
      final staffId = ref.read(authProvider).staff?.id ?? '';
      context.router.push(
        PurchaseItemSalesRoute(
          patientId: selectedPatient!.patientId,
          patientName: selectedPatient.displayName,
          id: selectedPatient.id ?? '',
          staffId: staffId.isEmpty ? null : staffId,
        ),
      );
    } else {
      moduleFlowNotifier.state = defaultOrHmo;
      context.router.push(RenderServiceRoute());
    }
  }

  Widget _buildContinueButton(Patient? selectedPatient) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: selectedPatient == null
            ? null
            : () => _onContinue(selectedPatient),
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
    );
  }

  Widget _buildSelectUser({
    required List<Patient> patients,
    required bool isWide,
  }) {
    return SelectUser(
      patients: patients,
      serviceName: serviceName,
      selectNoIdUser: isWide ? selectNoIdUser : null,
      onSearch: (String value) {
        ref.read(patientProvider.notifier).searchPatients(
              0,
              10,
              value,
              isWide ? 'nameIdPhonenumber' : 'fullName',
              null,
              null,
              isWide ? 'surname' : 'fullName',
              true,
              null,
            );
      },
      onPatientSelected: (Patient value) {
        ref.read(patientProvider.notifier).selectPatient(value);
      },
    );
  }

  Widget _buildSelectedPanel(Patient? selectedPatient) {
    if (selectedPatient == null && data.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(
          width: double.infinity,
          child: SelectedPatientCard(),
        ),
        _buildContinueButton(selectedPatient),
      ],
    );
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
    return ResponsiveBody(
      center: false,
      builder: (context, bp) {
        if (!bp.isDesktop) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ParkedBillingChipsBar(onResume: _resumeParkedSession),
              Expanded(
                child: _buildSelectUser(patients: patients, isWide: false),
              ),
              if (selectedPatient != null || data.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSelectedPanel(selectedPatient),
                const SizedBox(height: 16),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ParkedBillingChipsBar(onResume: _resumeParkedSession),
            Expanded(
              child: ResponsiveRowColumn(
                firstFlex: 2,
                secondFlex: 1,
                gap: 20,
                first: _buildSelectUser(patients: patients, isWide: true),
                second: _buildSelectedPanel(selectedPatient),
              ),
            ),
          ],
        );
      },
    );
  }
}
