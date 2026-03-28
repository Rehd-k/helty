import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'patient.state.dart';
import 'patient_model.dart';
import 'patient_service.dart';

class PatientNotifier extends StateNotifier<PatientState> {
  final PatientService service;

  PatientNotifier(this.service) : super(const PatientState());

  void setListStatusFilter(PatientListStatusFilter filter) {
    state = state.copyWith(listStatusFilter: filter);
  }

  Future<void> fetchPatients({String? query, bool isAscending = true}) async {
    state = state.copyWith(isLoading: true);

    try {
      final data = await service.fetchPatients(
        query: state.query,
        skip: state.skip,
        take: state.take,
        filterCategory: state.filterCategory,
        fromDate: state.fromDate,
        toDate: state.toDate,
        sortBy: state.sortBy,
        isAscending: state.isAscending,
        listStatusFilter: state.listStatusFilter,
      );

      state = state.copyWith(isLoading: false, patients: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchNoIdPatients({
    String? query,
    bool isAscending = true,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final data = await service.fetchPatients(
        query: state.query,
        skip: state.skip,
        take: state.take,
        filterCategory: state.filterCategory,
        fromDate: state.fromDate,
        toDate: state.toDate,
        sortBy: state.sortBy,
        isAscending: state.isAscending,
        listStatusFilter: state.listStatusFilter,
      );

      state = state.copyWith(isLoading: false, patients: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectPatient(Patient patient) {
    state = state.copyWith(selectedPatient: patient);
  }

  void clearPatient() {
    state = state.copyWith(selectedPatient: null);
  }

  // SEARCH
  void searchPatients(
    int? skip,
    int? take,
    String? query,
    String? filterCategory,
    DateTime? fromDate,
    DateTime? toDate,
    String? sortBy,
    bool? isAscending,
    Patient? selectedPatient,
  ) {
    state = state.copyWith(
      skip: skip ?? 0,
      take: take ?? 10,
      query: query,
      filterCategory: filterCategory,
      fromDate: fromDate,
      toDate: toDate,
      sortBy: sortBy ?? 'surname',
      isAscending: isAscending,
      selectedPatient: selectedPatient,
    );
    fetchPatients();
  }

  // ➡ NEXT PAGE
  void nextPage() {
    state = state.copyWith(skip: state.skip + state.take);
    fetchPatients();
  }

  // ⬅ PREVIOUS PAGE
  void previousPage() {
    final newSkip = (state.skip - state.take).clamp(0, 999999);
    state = state.copyWith(skip: newSkip);
    fetchPatients();
  }
}
