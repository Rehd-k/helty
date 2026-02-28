class Transaction {
  final String trxId;
  final String initiator;
  final String patient;
  final double amountPaid;
  final double amountRemaining;
  final String paymentMethod;
  final String bankPaidTo;
  // Add other fields as needed
  final List<Service> services;

  Transaction({
    required this.trxId,
    required this.initiator,
    required this.patient,
    required this.amountPaid,
    required this.amountRemaining,
    required this.paymentMethod,
    required this.bankPaidTo,
    required this.services,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      trxId: json['trxId'],
      initiator: json['initiator'],
      patient: json['patient'],
      amountPaid: json['amountPaid'].toDouble(),
      amountRemaining: json['amountRemaining'].toDouble(),
      paymentMethod: json['paymentMethod'],
      bankPaidTo: json['bankPaidTo'],
      services: (json['services'] as List)
          .map((s) => Service.fromJson(s))
          .toList(),
    );
  }
}

class Service {
  final String name;
  final double cost;

  Service({required this.name, required this.cost});

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(name: json['name'], cost: json['cost'].toDouble());
  }
}
