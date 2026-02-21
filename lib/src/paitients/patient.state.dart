import 'patient_model.dart';

class PatientState {
  final bool isLoading;
  final List<Patient> patients;
  final String? error;

  final int skip;
  final int take;
  final String? search;
  final String? filterCategory;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? sortBy;
  final bool isAscending;
  final Patient? selectedPatient;

  const PatientState({
    this.isLoading = false,
    this.patients = const [],
    this.error,
    this.skip = 0,
    this.take = 10,
    this.search,
    this.filterCategory,
    this.fromDate,
    this.toDate,
    this.sortBy,
    this.isAscending = false,
    this.selectedPatient,
  });

  /// Sentinel value used to distinguish "clear selected patient" from "keep existing".
  static const _unset = Object();

  PatientState copyWith({
    bool? isLoading,
    List<Patient>? patients,
    String? error,
    int? skip,
    int? take,
    String? search,
    String? filterCategory,
    DateTime? fromDate,
    DateTime? toDate,
    String? sortBy,
    bool? isAscending,
    // Use Object? so callers can pass null intentionally to clear the field.
    Object? selectedPatient = _unset,
  }) {
    return PatientState(
      isLoading: isLoading ?? this.isLoading,
      patients: patients ?? this.patients,
      error: error,
      skip: skip ?? this.skip,
      take: take ?? this.take,
      search: search ?? this.search,
      filterCategory: filterCategory ?? this.filterCategory,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      sortBy: sortBy ?? this.sortBy,
      isAscending: isAscending ?? this.isAscending,
      selectedPatient: identical(selectedPatient, _unset)
          ? this.selectedPatient
          : selectedPatient as Patient?,
    );
  }
}
