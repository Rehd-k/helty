class NoIdPatient {
  final String id;
  final String surname;
  final String firstName;
  final String age;
  final String gender;

  NoIdPatient({
    required this.id,
    required this.surname,
    required this.firstName,
    required this.age,
    required this.gender,
  });

  factory NoIdPatient.fromJson(Map<String, dynamic> json) {
    return NoIdPatient(
      id: json['id'],
      surname: json['surname'],
      firstName: json['firstName'],
      age: json['age'],
      gender: json['gender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surname': surname,
      'firstName': firstName,
      'gender': gender,
      'age': age,
    };
  }
}
