import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/enlist_services/select.user.dart';
import 'package:helty/src/enlist_services/selected.user.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_notifier.dart';
import 'package:helty/src/paitients/patient_providers.dart';

/// Shared layout: [SelectUser] on the left (or top), [SelectedPatientCard] plus
/// [actionPanel] when a patient is selected.
class PatientSelectActionLayout extends ConsumerStatefulWidget {
  const PatientSelectActionLayout({
    super.key,
    required this.serviceName,
    this.title,
    this.subtitle,
    this.topBar,
    this.actionPanel,
    this.clearOnDispose = true,
    this.selectNoIdUser,
    this.padding = const EdgeInsets.all(24),
  });

  final String serviceName;
  final String? title;
  final String? subtitle;
  final Widget? topBar;
  final Widget? actionPanel;
  final bool clearOnDispose;
  final ValueChanged<Map<String, dynamic>>? selectNoIdUser;
  final EdgeInsets padding;

  @override
  ConsumerState<PatientSelectActionLayout> createState() =>
      _PatientSelectActionLayoutState();
}

class _PatientSelectActionLayoutState
    extends ConsumerState<PatientSelectActionLayout> {
  late final PatientNotifier _patientNotifier;

  @override
  void initState() {
    super.initState();
    _patientNotifier = ref.read(patientProvider.notifier);
  }

  @override
  void dispose() {
    final notifier = widget.clearOnDispose ? _patientNotifier : null;
    super.dispose();
    if (notifier != null) {
      Future.microtask(notifier.clearPatient);
    }
  }

  void _onSearch(String value, {required bool isWide}) {
    ref
        .read(patientProvider.notifier)
        .searchPatients(
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
  }

  Widget _buildSelectUser(List<Patient> patients, {required bool isWide}) {
    return SelectUser(
      patients: patients,
      serviceName: widget.serviceName,
      selectNoIdUser: widget.selectNoIdUser,
      onSearch: (value) => _onSearch(value, isWide: isWide),
      onPatientSelected: (patient) {
        ref.read(patientProvider.notifier).selectPatient(patient);
      },
    );
  }

  Widget _buildWideLayout(Widget selectUser, Patient? selectedPatient) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 2, child: selectUser),
        const SizedBox(width: 20),
        if (selectedPatient == null || widget.actionPanel == null)
          const Expanded(flex: 1, child: SizedBox())
        else
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SelectedPatientCard(),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(child: widget.actionPanel!),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNarrowLayout(Widget selectUser, Patient? selectedPatient) {
    if (selectedPatient == null || widget.actionPanel == null) {
      return selectUser;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 2, child: selectUser),
        const SizedBox(height: 16),
        const SelectedPatientCard(),
        const SizedBox(height: 16),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(child: widget.actionPanel!),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final patientState = ref.watch(patientProvider);
    final patients = patientState.patients;
    final selectedPatient = patientState.selectedPatient;

    return FlexPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= AppBreakpoints.desktopMin;
          final selectUser = _buildSelectUser(patients, isWide: isWide);

          return Padding(
            padding: widget.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.title != null) ...[
                  Text(
                    widget.title!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
                if (widget.topBar != null) widget.topBar!,
                Expanded(
                  child: isWide
                      ? _buildWideLayout(selectUser, selectedPatient)
                      : _buildNarrowLayout(selectUser, selectedPatient),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
