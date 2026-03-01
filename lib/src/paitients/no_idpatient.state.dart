import 'noid_patient.model.dart';

class NoIdPatientState {
  final bool isLoading;
  final List<NoIdPatient> patients;
  final String? error;

  final int skip;
  final int take;
  final String? query;
  final String? filterCategory;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? sortBy;
  final bool isAscending;
  final NoIdPatient? selectedPatient;

  const NoIdPatientState({
    this.isLoading = false,
    this.patients = const [],
    this.error,
    this.skip = 0,
    this.take = 10,
    this.query,
    this.filterCategory,
    this.fromDate,
    this.toDate,
    this.sortBy,
    this.isAscending = false,
    this.selectedPatient,
  });

  /// Sentinel value used to distinguish "clear selected patient" from "keep existing".
  static const _unset = Object();

  NoIdPatientState copyWith({
    bool? isLoading,
    List<NoIdPatient>? patients,
    String? error,
    int? skip,
    int? take,
    String? query,
    String? filterCategory,
    DateTime? fromDate,
    DateTime? toDate,
    String? sortBy,
    bool? isAscending,
    // Use Object? so callers can pass null intentionally to clear the field.
    Object? selectedPatient = _unset,
  }) {
    return NoIdPatientState(
      isLoading: isLoading ?? this.isLoading,
      patients: patients ?? this.patients,
      error: error,
      skip: skip ?? this.skip,
      take: take ?? this.take,
      query: query ?? this.query,
      filterCategory: filterCategory ?? this.filterCategory,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      sortBy: sortBy ?? this.sortBy,
      isAscending: isAscending ?? this.isAscending,
      selectedPatient: identical(selectedPatient, _unset)
          ? this.selectedPatient
          : selectedPatient as NoIdPatient?,
    );
  }
}
