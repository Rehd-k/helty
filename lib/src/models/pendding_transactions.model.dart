class Transactions {
  final String transactionId;
  final List<String> services;
  final String patientName;
  final double amountDue;
  final double amountPaid;
  final String ward;
  final String department;
  final String initaitor;
  final String status;
  final DateTime date;

  Transactions({
    required this.transactionId,
    required this.services,
    required this.patientName,
    required this.amountDue,
    required this.amountPaid,
    required this.ward,
    required this.department,
    required this.initaitor,
    required this.date,
    required this.status,
  });

  factory Transactions.fromJson(Map<String, dynamic> json) {
    return Transactions(
      transactionId: json['transactionId'] as String,
      services: List<String>.from(json['services'] as List<dynamic>),
      patientName: '${json['firstName']} ${json['lastName']}',
      amountDue: json['amountDue'] as double,
      amountPaid: json['amountPaid'] as double,
      ward: json['ward'] as String,
      department: json['department'] as String,
      initaitor: json['initaitor'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
    );
  }
  Map<String, dynamic> toJson() => {
    'transactionId': transactionId,
    'services': services,
    'patientName': patientName,
    'amountDue': amountDue,
    'amountPaid': amountPaid,
    'ward': ward,
    'department': department,
    'initaitor': initaitor,
    'date': date.toIso8601String(),
    'status': status,
  };
}
