class Patient {
  final String id;
  final String patientId;
  final String cardNo;
  final String title;
  final String surname;
  final String firstName;
  final String? otherName;
  final DateTime dob;
  final String gender;
  final String maritalStatus;
  final String nationality;
  final String stateOfOrigin;
  final String lga;
  final String town;
  final String permanentAddress;
  final String? religion;
  final String? email;
  final String? preferredLanguage;
  final String? phoneNumber;
  final String? addressOfResidence;
  final String? profession;
  final String? nextOfKinName;
  final String? nextOfKinPhone;
  final String? nextOfKinAddress;
  final String? nextOfKinRelationship;
  final String? hmo;
  final String? fingerprintData;

  Patient({
    required this.id,
    required this.patientId,
    required this.cardNo,
    required this.title,
    required this.surname,
    required this.firstName,
    this.otherName,
    required this.dob,
    required this.gender,
    required this.maritalStatus,
    required this.nationality,
    required this.stateOfOrigin,
    required this.lga,
    required this.town,
    required this.permanentAddress,
    this.religion,
    this.email,
    this.preferredLanguage,
    this.phoneNumber,
    this.addressOfResidence,
    this.profession,
    this.nextOfKinName,
    this.nextOfKinPhone,
    this.nextOfKinAddress,
    this.nextOfKinRelationship,
    this.hmo,
    this.fingerprintData,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      cardNo: json['cardNo'] as String,
      title: json['title'] as String,
      surname: json['surname'] as String,
      firstName: json['firstName'] as String,
      otherName: json['otherName'] as String?,
      dob: DateTime.parse(json['dob'] as String),
      gender: json['gender'] as String,
      maritalStatus: json['maritalStatus'] as String,
      nationality: json['nationality'] as String,
      stateOfOrigin: json['stateOfOrigin'] as String,
      lga: json['lga'] as String,
      town: json['town'] as String,
      permanentAddress: json['permanentAddress'] as String,
      religion: json['religion'] as String?,
      email: json['email'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      addressOfResidence: json['addressOfResidence'] as String?,
      profession: json['profession'] as String?,
      nextOfKinName: json['nextOfKinName'] as String?,
      nextOfKinPhone: json['nextOfKinPhone'] as String?,
      nextOfKinAddress: json['nextOfKinAddress'] as String?,
      nextOfKinRelationship: json['nextOfKinRelationship'] as String?,
      hmo: json['hmo'] as String?,
      fingerprintData: json['fingerprintData'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'cardNo': cardNo,
      'title': title,
      'surname': surname,
      'firstName': firstName,
      'otherName': otherName,
      'dob': dob.toIso8601String(),
      'gender': gender,
      'maritalStatus': maritalStatus,
      'nationality': nationality,
      'stateOfOrigin': stateOfOrigin,
      'lga': lga,
      'town': town,
      'permanentAddress': permanentAddress,
      'religion': religion,
      'email': email,
      'preferredLanguage': preferredLanguage,
      'phoneNumber': phoneNumber,
      'addressOfResidence': addressOfResidence,
      'profession': profession,
      'nextOfKinName': nextOfKinName,
      'nextOfKinPhone': nextOfKinPhone,
      'nextOfKinAddress': nextOfKinAddress,
      'nextOfKinRelationship': nextOfKinRelationship,
      'hmo': hmo,
      'fingerprintData': fingerprintData,
    };
  }
}
