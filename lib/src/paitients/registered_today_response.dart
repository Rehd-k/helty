import 'patient_model.dart';

class RegisteredTodayResponse {
  const RegisteredTodayResponse({
    required this.date,
    required this.from,
    required this.to,
    required this.patients,
    required this.total,
    required this.skip,
    required this.take,
  });

  final String date;
  final String from;
  final String to;
  final List<Patient> patients;
  final int total;
  final int skip;
  final int take;

  factory RegisteredTodayResponse.fromJson(Map<String, dynamic> json) {
    final rawPatients = json['patients'];
    final List<dynamic> list = rawPatients is List ? rawPatients : <dynamic>[];

    return RegisteredTodayResponse(
      date: json['date']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      patients: list
          .map(
            (e) => Patient.fromJson(
              Map<String, dynamic>.from(e as Map<String, dynamic>),
            ),
          )
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? list.length,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      take: (json['take'] as num?)?.toInt() ?? list.length,
    );
  }
}
